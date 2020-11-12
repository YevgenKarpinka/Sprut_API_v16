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
                    begin
                        IF invoiceId = '' THEN
                            ERROR(BlankInvoiceIdErr);
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
                            Error(PrepaymentPercentCannotBeLessOrEqualErr, SalesHeader."Prepayment %");
                    end;
                }
                field(prepaymentAmount; prepaymentAmount)
                {
                    ApplicationArea = All;
                    Caption = 'prepaymentAmount', Locked = true;
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        IF prepaymentAmount = 0 THEN
                            ERROR(BlankPrepaymentAmountErr);
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
        if SalesHeader.Get(Rec."Document Type", Rec."No.") then
            if (prepaymentAmount <> 0)
            and (prepaymentPercent <> 0)
            and (invoiceId <> '') then
                // CreatePrepaymentInvoice(SalesHeader."No.");

                // while testing CRM
                postedInvoiceNo := 'TEST_INVOICE_NO';
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
        postedInvoiceNo: Code[20];
        SalesPostPrepaymentsSprut: Codeunit "Sales-Post Prepayments Sprut";
        BlankPrepaymentAmountErr: Label 'The blank "prepaymentAmount" is not allowed.', Locked = true;
        BlankInvoiceIdErr: Label 'The blank "invoiceId" is not allowed.', Locked = true;
        PrepaymentPercentCannotBeLessOrEqualErr: Label 'The "prepaymentPercent" cannot be less or equal %1.', Locked = true;
        errTotalAmountLessPrepaymentAmount: Label 'Total order amount less prepayment invoice amount.';

    procedure SetInit(_invoiceID: Text[50]; _prepaymentAmount: Decimal)
    begin
        invoiceId := _invoiceID;
        prepaymentAmount := _prepaymentAmount;
    end;

    procedure CreatePrepaymentInvoice(SalesOrderNo: Code[20])
    begin
        // Get Sales Order
        GetSalesOrder(SalesOrderNo);

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

    local procedure GetVAT(VATBusPostingGroup: Code[20]): Decimal
    var
        myInt: Integer;
    begin

    end;

    local procedure CheckAllowedPrepaymentAmount(SalesOrderNo: Code[20]; PrepaymentAmount: Decimal): Boolean
    var
        locSalesLine: Record "Sales Line";
    begin
        locSalesLine.SetRange("Document Type", locSalesLine."Document Type"::Order);
        locSalesLine.SetRange("Document No.", SalesOrderNo);
        locSalesLine.SetFilter(Quantity, '<>%1', 0);
        locSalesLine.CalcSums("Line Amount", "Prepmt. Line Amount");

        TotalOrderAmount := locSalesLine."Line Amount";
        TotalPrepaymentAmountBefore := locSalesLine."Prepmt. Line Amount";

        exit(TotalOrderAmount >= (TotalPrepaymentAmountBefore + PrepaymentAmount))
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
        LinesCount: Integer;
        Counter: Integer;
    begin
        Currency.Initialize(SalesHeader."Currency Code");

        // calculate prepayment percent
        TotalPrepaymentAmount := TotalPrepaymentAmountBefore + PrepaymentAmount;
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
        LinesCount := locSalesLine.Count;

        LinePrepaymentAmount := Round(PrepaymentAmount / LinesCount, Currency."Amount Rounding Precision");
        Counter := 1;
        locSalesLine.FindSet(false, true);
        repeat
            if LinesCount = Counter then
                locSalesLine."Prepmt. Line Amount" := locSalesLine."Prepmt. Line Amount" + PrepaymentAmount
            else
                locSalesLine."Prepmt. Line Amount" := locSalesLine."Prepmt. Line Amount" + LinePrepaymentAmount;
            locSalesLine.Modify();

            PrepaymentAmount -= LinePrepaymentAmount;
            Counter += 1;
        until locSalesLine.Next() = 0;

    end;
}