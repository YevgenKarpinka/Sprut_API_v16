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
                        GetSalesOrder();
                        if prepaymentPercent <= SalesHeader."Prepayment %" then
                            Error(PrepaymentPercentCannotBeLessOrEqualErr, SalesHeader."Prepayment %");
                    end;
                }
                field(prepaymentAmount; PrepaymentAmount)
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
        if SalesHeader.Get(Rec."Document Type", Rec."No.") then begin

            if (PrepaymentAmount <> 0)
            and (prepaymentPercent <> 0)
            and (invoiceId <> '') then
                // CreatePrepaymentInvoice(SalesHeader."No.");

                // while testing CRM
                postedInvoiceNo := 'TEST_INVOICE_NO';
        end;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin

    end;

    var
        SalesHeader: Record "Sales Header";
        invoiceId: Text[50];
        prepaymentPercent: Decimal;
        PrepaymentAmount: Decimal;
        AdjAmount: Decimal;
        postedInvoiceNo: Code[20];
        ReleaseSalesDoc: Codeunit "Release Sales Document";
        SalesPostPrepaymentsSprut: Codeunit "Sales-Post Prepayments Sprut";
        BlankPrepaymentPercentErr: Label 'The blank "prepaymentPercent" is not allowed.', Locked = true;
        BlankPrepaymentAmountErr: Label 'The blank "prepaymentAmount" is not allowed.', Locked = true;
        BlankInvoiceIdErr: Label 'The blank "invoiceId" is not allowed.', Locked = true;
        PrepaymentPercentCannotBeLessOrEqualErr: Label 'The "prepaymentPercent" cannot be less or equal %1.', Locked = true;
        AmountAdjustmentCannotBeMoreErr: Label 'The the amount adjustment cannot be more %1.', Locked = true;

    local procedure CreatePrepaymentInvoice(SalesOrderNo: Code[20])
    begin
        // update "External Document No." and "Prepayment %" to invoiceId
        GetSalesOrder();
        SalesHeader."CRM Invoice No." := invoiceId;
        SalesHeader.Validate("Prepayment %", prepaymentPercent);
        SalesHeader.Modify();

        // Check Prepayment amount
        CheckedPrepaymentAmount(SalesHeader."No.", PrepaymentAmount, AdjAmount);
        if ABS(AdjAmount) > 1 then
            Error(AmountAdjustmentCannotBeMoreErr, 1);

        if AdjAmount <> 0 then
            // Update Prepayment amount if delta not aqual 0
            UpdatePrepaymentAmount(SalesHeader."No.", AdjAmount);
        // Release Sales order
        ReleaseSalesDoc.PerformManualRelease(SalesHeader);
        // Create prepayment invoice
        SalesPostPrepaymentsSprut.PostPrepaymentInvoiceSprut(SalesHeader);


        // comment while tested from CRM
        // postedInvoiceNo := SalesHeader."Last Prepayment No."; 
    end;

    local procedure UpdatePrepaymentAmount(SalesOrderNo: Code[20]; AdjAmount: Decimal)
    var
        locSalesLine: Record "Sales Line";
    begin
        ReopenOrder(SalesOrderNo);

        locSalesLine.SetRange("Document Type", locSalesLine."Document Type"::Order);
        locSalesLine.SetRange("Document No.", SalesOrderNo);
        locSalesLine.FindFirst();

        locSalesLine.Validate("Prepayment Amount", locSalesLine."Prepayment Amount" + AdjAmount);
        locSalesLine.Modify(true);
    end;

    local procedure ReopenOrder(SalesOrderNo: Code[20])
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesOrderNo);
        if SalesHeader.Status <> SalesHeader.Status::Open then begin
            SalesHeader.Status := SalesHeader.Status::Open;
            SalesHeader.Modify();
        end;
    end;

    local procedure CheckedPrepaymentAmount(SalesOrderNo: Code[20]; PrepaymentAmount: Decimal; var AdjAmount: Decimal)
    var
        locSalesLine: Record "Sales Line";
    begin
        locSalesLine.SetRange("Document Type", locSalesLine."Document Type"::Order);
        locSalesLine.SetRange("Document No.", SalesOrderNo);
        locSalesLine.CalcSums("Prepayment Amount");
        AdjAmount := locSalesLine."Prepayment Amount" - PrepaymentAmount;
    end;

    local procedure GetSalesOrder()
    begin
        if (SalesHeader."Document Type" <> SalesHeader."Document Type"::Order)
        and (SalesHeader."No." <> Rec."No.") then
            SalesHeader.Get(SalesHeader."Document Type"::Order, Rec."No.");
    end;
}