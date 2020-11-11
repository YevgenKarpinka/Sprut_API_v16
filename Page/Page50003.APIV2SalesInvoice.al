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
        SalesHeader: Record "Sales Header";
        invoiceId: Text[50];
        prepaymentPercent: Decimal;
        PrepaymentAmount: Decimal;
        TotalOrderAmountExclVAT: Decimal;
        BasePrepaymentAmountExclVAT: Decimal;
        PrepaymentAmountExclVAT: Decimal;
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
        if not GetSalesOrder(SalesOrderNo) then exit;

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

    local procedure GetSalesOrder(_SalesOrderNo: Code[20]): Boolean
    begin
        if not SalesHeader.Get(SalesHeader."Document Type"::Order, _SalesOrderNo) then
            exit(false);
        exit(true);
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

        TotalOrderAmountExclVAT := locSalesLine."Line Amount";
        BasePrepaymentAmountExclVAT := locSalesLine."Prepmt. Line Amount";

        if SalesHeader."Prices Including VAT" then
            PrepaymentAmountExclVAT := PrepaymentAmount
        else
            PrepaymentAmountExclVAT := PrepaymentAmount * (1 - locSalesLine."VAT %" / 100);

        exit(TotalOrderAmountExclVAT >= (BasePrepaymentAmountExclVAT + PrepaymentAmountExclVAT))
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
        TotalPrepaymentAmountExclVAT: Decimal;
        FirstLinePrepaymentAmountExclVAT: Decimal;
        PrepaymentPercent: Decimal;
        DiffPrepaymentAmount: Decimal;
    begin
        // calculate prepayment percent
        TotalPrepaymentAmountExclVAT := BasePrepaymentAmountExclVAT + PrepaymentAmountExclVAT;
        PrepaymentPercent := TotalPrepaymentAmountExclVAT * 100 / TotalOrderAmountExclVAT;

        // update prepayment percent sales header
        SalesHeader."CRM Invoice No." := invoiceId;
        SalesHeader.Validate("Prepayment %", PrepaymentPercent);
        SalesHeader.Modify();

        // update prepayment percent sales line
        locSalesLine.SetCurrentKey(Quantity);
        locSalesLine.SetRange("Document Type", locSalesLine."Document Type"::Order);
        locSalesLine.SetRange("Document No.", SalesOrderNo);
        locSalesLine.SetFilter(Quantity, '<>%1', 0);

        locSalesLine.FindSet(false, true);
        FirstLinePrepaymentAmountExclVAT := locSalesLine."Prepmt. Amt. Incl. VAT";
        repeat
            locSalesLine.Validate("Prepayment %", PrepaymentPercent);
            locSalesLine.UpdatePrePaymentAmounts();
            locSalesLine.Modify();
        until locSalesLine.Next() = 0;

        // added difference amount in last sales line 
        locSalesLine.CalcSums("Prepmt. Amt. Incl. VAT");
        DiffPrepaymentAmount := PrepaymentAmountExclVAT - (BasePrepaymentAmountExclVAT - locSalesLine."Prepmt. Amt. Incl. VAT");

        locSalesLine.Validate("Prepmt. Amt. Incl. VAT", FirstLinePrepaymentAmountExclVAT + DiffPrepaymentAmount);
        locSalesLine.Modify();
    end;
}