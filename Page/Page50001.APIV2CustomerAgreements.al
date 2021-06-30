page 50001 "APIV2 - Customer Agreements"
{
    APIPublisher = 'tcomtech';
    APIGroup = 'app';
    APIVersion = 'v1.0';
    Caption = 'customerAgreements', Locked = true;
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    EntityName = 'customerAgreement';
    EntitySetName = 'customerAgreements';
    ODataKeyFields = "Customer No.", "No.";
    PageType = API;
    SourceTable = "Customer Agreement";
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
                field(customerNo; Rec."Customer No.")
                {
                    ApplicationArea = All;
                    Caption = 'customerNo', Locked = true;
                }
                field(number; Rec."No.")
                {
                    ApplicationArea = All;
                    Caption = 'number', Locked = true;
                }
                field(displayName; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'displayName', Locked = true;
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        IF Rec.Description = '' THEN
                            ERROR(BlankAgreementDescriptionErr);
                        RegisterFieldSet(Rec.FIELDNO(Description));
                    end;
                }
                field(externalAgreementNo; Rec."External Agreement No.")
                {
                    ApplicationArea = All;
                    Caption = 'externalAgreementNo', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(Rec.FIELDNO("External Agreement No."));
                    end;
                }
                field(crmID; Rec."CRM ID")
                {
                    ApplicationArea = All;
                    Caption = 'crmID', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(Rec.FIELDNO("CRM ID"));
                    end;
                }
                field(print; Rec.Print)
                {
                    ApplicationArea = All;
                    Caption = 'print', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(Rec.FIELDNO(Print));
                    end;
                }
                field(active; Rec.Active)
                {
                    ApplicationArea = All;
                    Caption = 'active', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(Rec.FIELDNO(Active));
                    end;
                }
                field(status; Rec.Status)
                {
                    ApplicationArea = All;
                    Caption = 'status', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(Rec.FIELDNO(Status));
                    end;
                }
                field(agreementDate; Rec."Agreement Date")
                {
                    ApplicationArea = All;
                    Caption = 'agreementDate', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(Rec.FIELDNO("Agreement Date"));
                    end;
                }
                field(startingDate; Rec."Starting Date")
                {
                    ApplicationArea = All;
                    Caption = 'startingDate', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(Rec.FIELDNO("Starting Date"));
                    end;
                }
                field(expireDate; Rec."Expire Date")
                {
                    ApplicationArea = All;
                    Caption = 'expireDate', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(Rec.FIELDNO("Expire Date"));
                    end;
                }
                field(creditLimitLCY; Rec."Credit Limit (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'creditLimitLCY', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(Rec.FIELDNO("Credit Limit (LCY)"));
                    end;
                }
                field(currencyCode; CurrencyCodeTxt)
                {
                    ApplicationArea = All;
                    Caption = 'currencyCode', Locked = true;

                    trigger OnValidate()
                    begin
                        Rec."Currency Code" :=
                          GraphMgtGeneralTools.TranslateCurrencyCodeToNAVCurrencyCode(
                            LCYCurrencyCode, COPYSTR(CurrencyCodeTxt, 1, MAXSTRLEN(LCYCurrencyCode)));

                        IF Currency.Code <> '' THEN BEGIN
                            IF Currency.Code <> Rec."Currency Code" THEN
                                ERROR(CurrencyValuesDontMatchErr);
                            EXIT;
                        END;

                        RegisterFieldSet(Rec.FIELDNO("Currency Code"));
                    end;
                }
                field(blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                    Caption = 'blocked', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(Rec.FIELDNO(Blocked));
                    end;
                }
                field(balance; Rec.Balance)
                {
                    ApplicationArea = All;
                    Caption = 'balance', Locked = true;
                }
                field(netChange; Rec."Net Change")
                {
                    ApplicationArea = All;
                    Caption = 'netChange', Locked = true;
                }
                field(debitAmount; Rec."Debit Amount")
                {
                    ApplicationArea = All;
                    Caption = 'debitAmount', Locked = true;
                }
                field(creditAmount; Rec."Credit Amount")
                {
                    ApplicationArea = All;
                    Caption = 'creditAmount', Locked = true;
                }
                part(defaultDimensions; "Default Dimension Entity")
                {
                    ApplicationArea = All;
                    Caption = 'Default Dimensions', Locked = true;
                    EntityName = 'defaultDimensions';
                    EntitySetName = 'defaultDimensions';
                    SubPageLink = ParentId = FIELD(SystemId);
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        SetCalculatedFields();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        CustomerAgreement: Record "Customer Agreement";
        Cust: Record Customer;
        NoSeriesMgt: Codeunit NoSeriesManagement;
        RecRef: RecordRef;
    begin
        IF Rec.Description = '' THEN
            ERROR(NotProvidedCustomerNameErr);

        Cust.GET(Rec."Customer No.");
        Cust.TESTFIELD("Agreement Posting", Cust."Agreement Posting"::Mandatory);
        IF Rec."No." = '' THEN BEGIN
            Cust.TESTFIELD("Agreement Nos.");
            NoSeriesMgt.InitSeries(Cust."Agreement Nos.", xRec."No. Series", WORKDATE, Rec."No.", Rec."No. Series");
        end;

        CustomerAgreement.SETRANGE("Customer No.", Rec."Customer No.");
        CustomerAgreement.SETRANGE("No.", Rec."No.");
        IF NOT CustomerAgreement.ISEMPTY() THEN
            Rec.INSERT();

        Rec.INSERT(TRUE);

        RecRef.GETTABLE(Rec);
        ProcessNewRecordFromAPI(RecRef, TempFieldSet, CURRENTDATETIME());
        RecRef.SETTABLE(Rec);

        Rec.MODIFY(TRUE);
        SetCalculatedFields();
        EXIT(FALSE);
    end;

    trigger OnModifyRecord(): Boolean
    var
        CustomerAgreement: Record "Customer Agreement";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        // IF xRec.SystemId <> Rec.SystemId THEN
        //     GraphMgtGeneralTools.ErrorIdImmutable();

        CustomerAgreement.SETRANGE("Customer No.", Rec."Customer No.");
        CustomerAgreement.SETRANGE("No.", Rec."No.");
        CustomerAgreement.FINDFIRST();

        IF (Rec."No." = CustomerAgreement."No.") and (Rec."Customer No." = CustomerAgreement."Customer No.") THEN
            Rec.MODIFY(TRUE)
        ELSE BEGIN
            CustomerAgreement.TRANSFERFIELDS(Rec, FALSE);
            CustomerAgreement.RENAME(Rec."Customer No.", Rec."No.");
            Rec.TRANSFERFIELDS(CustomerAgreement);
        END;

        SetCalculatedFields();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ClearCalculatedFields();
    end;

    var
        Currency: Record Currency;
        TempFieldSet: Record Field temporary;
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        LCYCurrencyCode: Code[10];
        CurrencyCodeTxt: Text;
        CurrencyValuesDontMatchErr: Label 'The currency values do not match to a specific Currency.', Locked = true;
        NotProvidedCustomerNameErr: Label 'A "displayName" must be provided.', Locked = true;
        BlankAgreementDescriptionErr: Label 'The blank "displayName" is not allowed.', Locked = true;

    /// <summary> 
    /// Description for SetCalculatedFields.
    /// </summary>
    local procedure SetCalculatedFields()
    var
    begin
        CurrencyCodeTxt := GraphMgtGeneralTools.TranslateNAVCurrencyCodeToCurrencyCode(LCYCurrencyCode, Rec."Currency Code");
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
        IF TempFieldSet.GET(DATABASE::"Customer Agreement", FieldNo) THEN
            EXIT;

        TempFieldSet.INIT();
        TempFieldSet.TableNo := DATABASE::"Customer Agreement";
        TempFieldSet.VALIDATE("No.", FieldNo);

        TempFieldSet.INSERT(TRUE);
    end;

    /// <summary> 
    /// Description for ProcessNewRecordFromAPI.
    /// </summary>
    /// <param name="InsertedRecordRef">Parameter of type RecordRef.</param>
    /// <param name="TempFieldSet">Parameter of type Record "Field".</param>
    /// <param name="ModifiedDateTime">Parameter of type DateTime.</param>
    local procedure ProcessNewRecordFromAPI(var InsertedRecordRef: RecordRef; var TempFieldSet: Record "Field"; ModifiedDateTime: DateTime)
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        IntegrationManagement: Codeunit "Integration Management";
        ConfigTemplateManagement: Codeunit "Config. Template Management";
        UpdatedRecRef: RecordRef;
    begin
        if not FindTemplateBasedOnRecordFields(InsertedRecordRef, ConfigTemplateHeader) then
            exit;

        if ConfigTemplateManagement.ApplyTemplate(InsertedRecordRef, TempFieldSet, UpdatedRecRef, ConfigTemplateHeader) then
            InsertedRecordRef := UpdatedRecRef.Duplicate;

        IntegrationManagement.InsertUpdateIntegrationRecord(InsertedRecordRef, ModifiedDateTime);
    end;

    /// <summary> 
    /// Description for FindTemplateBasedOnRecordFields.
    /// </summary>
    /// <param name="RecordVariant">Parameter of type Variant.</param>
    /// <param name="ConfigTemplateHeader">Parameter of type Record "Config. Template Header".</param>
    /// <returns>Return variable "Boolean".</returns>
    local procedure FindTemplateBasedOnRecordFields(RecordVariant: Variant; var ConfigTemplateHeader: Record "Config. Template Header"): Boolean
    var
        ConfigTmplSelectionRules: Record "Config. Tmpl. Selection Rules";
        TempBlob: Codeunit "Temp Blob";
        DataTypeManagement: Codeunit "Data Type Management";
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        RecRef: RecordRef;
        SearchRecRef: RecordRef;
        SearchRecRefVariant: Variant;
    begin
        if not DataTypeManagement.GetRecordRef(RecordVariant, RecRef) then
            exit(false);

        ConfigTmplSelectionRules.SetCurrentKey(Order);
        ConfigTmplSelectionRules.Ascending(true);
        ConfigTmplSelectionRules.SetRange("Table ID", RecRef.Number);
        ConfigTmplSelectionRules.SetAutoCalcFields("Selection Criteria");
        if not ConfigTmplSelectionRules.FindSet(false) then
            exit(false);

        // Insert RecRef on a temporary table
        SearchRecRef.Open(RecRef.Number, true);
        SearchRecRefVariant := SearchRecRef;
        RecRef.SetTable(SearchRecRefVariant);
        DataTypeManagement.GetRecordRef(SearchRecRefVariant, SearchRecRef);
        SearchRecRef.Insert;

        repeat
            TempBlob.FromRecord(ConfigTmplSelectionRules, ConfigTmplSelectionRules.FieldNo("Selection Criteria"));
            if not TempBlob.HasValue then
                exit(ConfigTemplateHeader.Get(ConfigTmplSelectionRules."Template Code"));

            if RequestPageParametersHelper.ConvertParametersToFilters(SearchRecRef, TempBlob) then
                if SearchRecRef.Find then
                    exit(ConfigTemplateHeader.Get(ConfigTmplSelectionRules."Template Code"));

        until ConfigTmplSelectionRules.Next = 0;

        exit(false);
    end;
}