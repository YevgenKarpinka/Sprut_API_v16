page 50003 "APIV2 - Sales Invoice"
{
    APIPublisher = 'tcomtech';
    APIGroup = 'app';
    APIVersion = 'v1.0';
    Caption = 'salesInvoices', Locked = true;
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    EntityName = 'salesInvoice';
    EntitySetName = 'salesInvoices';
    ODataKeyFields = "Document Type", "No.";
    PageType = API;
    SourceTable = "Sales Header";
    Extensible = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(type; Rec."Document Type")
                {
                    ApplicationArea = All;
                    Caption = 'type', Locked = true;
                    Editable = false;
                }
                field(number; Rec."No.")
                {
                    ApplicationArea = All;
                    Caption = 'number', Locked = true;
                    Editable = false;
                }
                field(postedInvoiceNo; postedInvoiceNo)
                {
                    ApplicationArea = All;
                    Caption = 'postedInvoiceNo', Locked = true;
                    ShowMandatory = true;
                }
                field(invoiceId; invoiceId)
                {
                    ApplicationArea = All;
                    Caption = 'invoiceId', Locked = true;
                    ShowMandatory = true;

                    trigger OnValidate()
                    var
                        SalesInvoiceHeader: Record "Sales Invoice Header";
                    begin
                        if invoiceId = '' then
                            ERROR(errBlankInvoiceId);

                        SalesInvoiceHeader.SetCurrentKey("CRM Invoice No.");
                        SalesInvoiceHeader.SetRange("CRM Invoice No.", invoiceId);
                        if not SalesInvoiceHeader.IsEmpty then
                            Error(errPrepaymentInvoiceIsPosted, invoiceId);
                    end;
                }
                field(prepaymentPercent; prepaymentPercent)
                {
                    ApplicationArea = All;
                    Caption = 'prepaymentPercent', Locked = true;
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        GetSalesOrder(Rec."No.");
                        if prepaymentPercent <= SalesHeader."Prepayment %" then
                            Error(errPrepaymentPercentCannotBeLessOrEqual, SalesHeader."Prepayment %");
                    end;
                }
                field(prepaymentAmount; prepaymentAmount)
                {
                    ApplicationArea = All;
                    Caption = 'prepaymentAmount', Locked = true;
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        if prepaymentAmount = 0 then
                            ERROR(errBlankPrepaymentAmount);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin

    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin

    end;

    trigger OnModifyRecord(): Boolean
    begin

        if (prepaymentAmount <> 0)
        and (prepaymentPercent <> 0)
        and (invoiceId <> '') then begin
            CreatePrepaymentInvoice(SalesHeader."No.");
            Rec := SalesHeader;

            // while testing CRM
            // postedInvoiceNo := 'TEST_INVOICE_NO';
        end;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin

    end;

    var
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
        invoiceId: Text[50];
        prepaymentPercent: Decimal;
        PrepaymentAmount: Decimal;
        TotalOrderAmount: Decimal;
        TotalPrepaymentAmountBefore: Decimal;
        TotalPrepaymentAmountInvoice: Decimal;
        postedInvoiceNo: Code[20];
        SalesPostPrepaymentsSprut: Codeunit "Sales-Post Prepayments Sprut";
        errBlankPrepaymentAmount: Label 'The blank "prepaymentAmount" is not allowed.', Locked = true;
        errBlankInvoiceId: Label 'The blank "invoiceId" is not allowed.', Locked = true;
        errPrepaymentPercentCannotBeLessOrEqual: Label 'The "prepaymentPercent" cannot be less or equal %1.', Locked = true;
        errTotalAmountLessPrepaymentAmount: Label 'Total order amount less prepayment invoice amount.';
        errPrepaymentInvoiceIsPosted: Label 'Prepayment invoice %1 has already been created.';

    procedure SetInit(_invoiceID: Text[50]; _prepaymentAmount: Decimal)
    begin
        invoiceId := _invoiceID;
        prepaymentAmount := _prepaymentAmount;
    end;

    procedure CreatePrepaymentInvoice(SalesOrderNo: Code[20])
    begin
        // Get Sales Order
        GetSalesOrder(SalesOrderNo);

        Currency.Initialize(SalesHeader."Currency Code");
        PrepaymentAmount := Round(PrepaymentAmount, Currency."Amount Rounding Precision");

        // Check Allowed Prepayment Amount
        if not CheckAllowedPrepaymentAmount(SalesOrderNo, PrepaymentAmount) then
            Error(errTotalAmountLessPrepaymentAmount, PrepaymentAmount);

        // Set Order Status Open
        SetSalesOrderStatusOpen(SalesOrderNo);

        // Update Prepayment Amount in Sales Order
        UpdatePrepaymentAmountInSalesOrder(SalesOrderNo, PrepaymentAmount);

        // Create Prepayment Invoice
        SalesPostPrepaymentsSprut.PostPrepaymentInvoiceSprut(SalesHeader);

        // get last prepayment invoice no
        postedInvoiceNo := SalesHeader."Last Prepayment No.";
    end;

    local procedure GetSalesOrder(_SalesOrderNo: Code[20])
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Order, _SalesOrderNo);
        SalesHeader.TestField("Prices Including VAT", true);
    end;

    local procedure CheckAllowedPrepaymentAmount(SalesOrderNo: Code[20]; PrepaymentAmount: Decimal): Boolean
    var
        locSalesLine: Record "Sales Line";
    begin
        locSalesLine.SetRange("Document Type", locSalesLine."Document Type"::Order);
        locSalesLine.SetRange("Document No.", SalesOrderNo);
        locSalesLine.SetFilter(Quantity, '<>%1', 0);
        locSalesLine.CalcSums("Line Amount", "Prepmt. Line Amount", "Prepmt. Amt. Inv.");

        TotalOrderAmount := locSalesLine."Line Amount";
        TotalPrepaymentAmountBefore := locSalesLine."Prepmt. Line Amount";
        TotalPrepaymentAmountInvoice := locSalesLine."Prepmt. Amt. Inv.";

        exit(TotalOrderAmount >= (TotalPrepaymentAmountInvoice + PrepaymentAmount))
    end;

    local procedure SetSalesOrderStatusOpen(SalesOrderNo: Code[20])
    begin
        if SalesHeader.Status = SalesHeader.Status::Open then exit;
        SalesHeader.Status := SalesHeader.Status::Open;
        SalesHeader.Modify();
    end;

    local procedure UpdatePrepaymentAmountInSalesOrder(SalesOrderNo: Code[20]; PrepaymentAmount: Decimal)
    var
        locSalesLine: Record "Sales Line";
        TotalPrepaymentAmount: Decimal;
        PrepaymentPercent: Decimal;
        LinePrepaymentAmount: Decimal;
        DiffAmounts: Decimal;
        LinesCount: Integer;
        Counter: Integer;
    begin
        Currency.Initialize(SalesHeader."Currency Code");

        // calculate prepayment percent
        TotalPrepaymentAmount := TotalPrepaymentAmountInvoice + PrepaymentAmount;
        PrepaymentPercent := TotalPrepaymentAmount * 100 / TotalOrderAmount;

        // update prepayment percent sales header
        SalesHeader."CRM Invoice No." := invoiceId;
        SalesHeader.Validate("Prepayment %", PrepaymentPercent);
        SalesHeader.Modify();

        // update prepayment percent sales line
        locSalesLine.SetCurrentKey(Quantity);
        locSalesLine.SetRange("Document Type", locSalesLine."Document Type"::Order);
        locSalesLine.SetRange("Document No.", SalesOrderNo);
        locSalesLine.SetFilter(Quantity, '<>%1', 0);
        locSalesLine.CalcSums("Prepmt. Line Amount");

        DiffAmounts := TotalPrepaymentAmount - locSalesLine."Prepmt. Line Amount";

        if DiffAmounts < Currency."Amount Rounding Precision" then exit;

        LinesCount := locSalesLine.Count;
        LinePrepaymentAmount := Round(DiffAmounts / LinesCount, Currency."Amount Rounding Precision");
        if LinePrepaymentAmount > 0 then begin

            locSalesLine.FindSet(false, true);
            repeat
                if Counter = LinesCount then
                    locSalesLine."Prepmt. Line Amount" := locSalesLine."Prepmt. Line Amount" + DiffAmounts
                else
                    locSalesLine."Prepmt. Line Amount" := locSalesLine."Prepmt. Line Amount" + LinePrepaymentAmount;
                locSalesLine.Modify();

                DiffAmounts -= LinePrepaymentAmount;
            until locSalesLine.Next() = 0;

        end else begin
            locSalesLine.FindLast();
            locSalesLine."Prepmt. Line Amount" := locSalesLine."Prepmt. Line Amount" + DiffAmounts;
            locSalesLine.Modify();
        end;

    end;
}