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
                    Editable = false;
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
                        // RegisterFieldSet(Rec.FIELDNO("Prepayment %"));
                    end;
                }
                field(prepaymentPercent; Rec."Prepayment %")
                {
                    ApplicationArea = All;
                    Caption = 'prepaymentPercent', Locked = true;
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        IF Rec."Prepayment %" = 0 THEN
                            ERROR(BlankPrepaymentPercentErr);
                        // RegisterFieldSet(Rec.FIELDNO("Prepayment %"));
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
    var
    begin

    end;

    trigger OnModifyRecord(): Boolean
    var
        SalesHeader: Record "Sales Header";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        IF xRec.SystemId <> Rec.SystemId THEN
            GraphMgtGeneralTools.ErrorIdImmutable();

        if SalesHeader.Get(Rec."Document Type", Rec."No.") then begin
            Rec.Modify(true);

            if (PrepaymentAmount <> 0)
            and (Rec."Prepayment %" <> 0)
            and (invoiceId <> '') then
                CreatePrepaymentInvoice(Rec."No.");
        end;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        // ClearCalculatedFields();
    end;

    var

        TempFieldSet: Record Field temporary;
        invoiceId: Text[50];
        PrepaymentAmount: Decimal;
        AdjAmount: Decimal;
        postedInvoiceNo: Code[20];
        ReleaseSalesDoc: Codeunit "Release Sales Document";
        SalesPostPrepaymentsSprut: Codeunit "Sales-Post Prepayments Sprut";
        BlankPrepaymentPercentErr: Label 'The blank "prepaymentPercent" is not allowed.', Locked = true;
        BlankPrepaymentAmountErr: Label 'The blank "prepaymentAmount" is not allowed.', Locked = true;
        BlankInvoiceIdErr: Label 'The blank "invoiceId" is not allowed.', Locked = true;

    local procedure CreatePrepaymentInvoice(SalesOrderNo: Code[20])
    var
        SalesHeader: Record "Sales Header";

    begin
        // update "External Document No." to invoiceId
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesOrderNo);
        SalesHeader."External Document No." := invoiceId;
        SalesHeader.Modify();

        // Check Prepayment amount
        CheckedPrepaymentAmount(Rec."No.", PrepaymentAmount, AdjAmount);
        if AdjAmount <> 0 then
            // Update Prepayment amount if delta not aqual 0
            UpdatePrepaymentAmount(Rec."No.", AdjAmount);
        // Release Sales order
        ReleaseSalesDoc.PerformManualRelease(Rec);
        // Create prepayment invoice
        SalesPostPrepaymentsSprut.PostPrepaymentInvoiceSprut(Rec);
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
    var
        locSalesHeader: Record "Sales Header";
    begin
        locSalesHeader.Get(locSalesHeader."Document Type"::Order, SalesOrderNo);
        if locSalesHeader.Status <> locSalesHeader.Status::Open then begin
            locSalesHeader.Status := locSalesHeader.Status::Open;
            locSalesHeader.Modify();
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

    /// <summary> 
    /// Description for ClearCalculatedFields.
    /// </summary>
    local procedure ClearCalculatedFields()
    begin
        CLEAR(Rec.SystemId);
        TempFieldSet.DELETEALL();
    end;

    /// <summary> 
    /// Description for RegisterFieldSet.
    /// </summary>
    /// <param name="FieldNo">Parameter of type Integer.</param>
    local procedure RegisterFieldSet(FieldNo: Integer)
    begin
        IF TempFieldSet.GET(DATABASE::"Sales Header", FieldNo) THEN
            EXIT;

        TempFieldSet.Init();
        TempFieldSet.TableNo := DATABASE::"Sales Header";
        TempFieldSet.Validate("No.", FieldNo);
        TempFieldSet.Insert(true);
    end;
}