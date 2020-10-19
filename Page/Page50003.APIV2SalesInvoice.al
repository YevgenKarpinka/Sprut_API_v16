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
    ODataKeyFields = systemId;
    PageType = API;
    SourceTable = "Sales Header";
    Extensible = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(systemId; Rec.SystemId)
                {
                    ApplicationArea = All;
                    Caption = 'systemId', Locked = true;
                    Editable = false;
                }
                field(number; Rec."No.")
                {
                    ApplicationArea = All;
                    Caption = 'systemId', Locked = true;
                    Editable = false;
                }
                // >>
                field(prepaymentPercent; Rec."Prepayment %")
                {
                    ApplicationArea = All;
                    Caption = 'prepaymentPercent', Locked = true;
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        IF Rec."Prepayment %" = 0 THEN
                            ERROR(BlankPrepaymentPercentErr);
                        RegisterFieldSet(Rec.FIELDNO("Prepayment %"));
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
                // <<
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

        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        ReleaseSalesDoc: Codeunit "Release Sales Document";
        SalesPostPrepaymentsSprut: Codeunit "Sales-Post Prepayments Sprut";
    begin
        IF xRec.SystemId <> Rec.SystemId THEN
            GraphMgtGeneralTools.ErrorIdImmutable();

        SalesHeader.SetRange(SystemId, Rec.SystemId);
        SalesHeader.FindFirst();

        IF (Rec."No." = SalesHeader."No.") THEN begin
            Rec.MODIFY(TRUE);

            if (PrepaymentAmount <> 0) and (Rec."Prepayment %" <> 0) then begin
                // Check Prepayment amount
                CheckedPrepaymentAmount(Rec."No.", PrepaymentAmount, AdjAmount);
                if AdjAmount <> 0 then
                    // Update Prepayment amount if delta not aqual 0
                    UpdatePrepaymentAmount(AdjAmount);
                // Release Sales order
                ReleaseSalesDoc.PerformManualRelease(Rec);
                // Create prepayment invoice
                SalesPostPrepaymentsSprut.PostPrepaymentInvoiceSprut(Rec);
            end;
        end;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ClearCalculatedFields();
    end;

    var
        SalesHeader: Record "Sales Header";
        TempFieldSet: Record Field temporary;
        PrepaymentAmount: Decimal;
        AdjAmount: Decimal;
        BlankPrepaymentPercentErr: Label 'The blank "prepaymentPercent" is not allowed.', Locked = true;
        BlankPrepaymentAmountErr: Label 'The blank "prepaymentAmount" is not allowed.', Locked = true;

    /// <summary> 
    /// Description for CheckedPrepaymentAmount.
    /// </summary>
    /// <param name="SalesOrderNo">Parameter of type Code[20].</param>
    /// <param name="PrepaymentAmount">Parameter of type Decimal.</param>
    /// <param name="AdjAmount">Parameter of type Decimal.</param>
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