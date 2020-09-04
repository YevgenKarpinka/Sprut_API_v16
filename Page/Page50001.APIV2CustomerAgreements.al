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
    ODataKeyFields = systemId;
    PageType = API;
    SourceTable = "Customer Agreement";
    Extensible = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(systemId; SystemId)
                {
                    ApplicationArea = All;
                    Caption = 'systemId', Locked = true;
                    Editable = false;
                }
                field(customerNo; "Customer No.")
                {
                    ApplicationArea = All;
                    Caption = 'customerNo', Locked = true;
                }
                field(number; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'number', Locked = true;
                }
                field(displayName; Description)
                {
                    ApplicationArea = All;
                    Caption = 'displayName', Locked = true;
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        IF Description = '' THEN
                            ERROR(BlankAgreementDescriptionErr);
                        RegisterFieldSet(FIELDNO(Description));
                    end;
                }
                field(externalAgreementNo; "External Agreement No.")
                {
                    ApplicationArea = All;
                    Caption = 'externalAgreementNo', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("External Agreement No."));
                    end;
                }
                field(active; Active)
                {
                    ApplicationArea = All;
                    Caption = 'active', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO(Active));
                    end;
                }
                field(agreementDate; "Agreement Date")
                {
                    ApplicationArea = All;
                    Caption = 'agreementDate', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("Agreement Date"));
                    end;
                }
                field(startingDate; "Starting Date")
                {
                    ApplicationArea = All;
                    Caption = 'startingDate', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("Starting Date"));
                    end;
                }
                field(expireDate; "Expire Date")
                {
                    ApplicationArea = All;
                    Caption = 'expireDate', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("Expire Date"));
                    end;
                }
                field(creditLimitLCY; "Credit Limit (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'creditLimitLCY', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("Credit Limit (LCY)"));
                    end;
                }
                field(currencyCode; CurrencyCodeTxt)
                {
                    ApplicationArea = All;
                    Caption = 'currencyCode', Locked = true;

                    trigger OnValidate()
                    begin
                        "Currency Code" :=
                          GraphMgtGeneralTools.TranslateCurrencyCodeToNAVCurrencyCode(
                            LCYCurrencyCode, COPYSTR(CurrencyCodeTxt, 1, MAXSTRLEN(LCYCurrencyCode)));

                        IF Currency.Code <> '' THEN BEGIN
                            IF Currency.Code <> "Currency Code" THEN
                                ERROR(CurrencyValuesDontMatchErr);
                            EXIT;
                        END;

                        RegisterFieldSet(FIELDNO("Currency Code"));
                    end;
                }
                field(blocked; Blocked)
                {
                    ApplicationArea = All;
                    Caption = 'blocked', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO(Blocked));
                    end;
                }
                field(balance; Balance)
                {
                    ApplicationArea = All;
                    Caption = 'balance', Locked = true;
                }
                field(netChange; "Net Change")
                {
                    ApplicationArea = All;
                    Caption = 'netChange', Locked = true;
                }
                field(debitAmount; "Debit Amount")
                {
                    ApplicationArea = All;
                    Caption = 'debitAmount', Locked = true;
                }
                field(creditAmount; "Credit Amount")
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
        RecRef: RecordRef;
    begin
        IF Description = '' THEN
            ERROR(NotProvidedCustomerNameErr);

        CustomerAgreement.SETRANGE("Customer No.", "Customer No.");
        CustomerAgreement.SETRANGE("No.", "No.");
        IF NOT CustomerAgreement.ISEMPTY() THEN
            INSERT();

        INSERT(TRUE);

        RecRef.GETTABLE(Rec);
        ProcessNewRecordFromAPI(RecRef, TempFieldSet, CURRENTDATETIME());
        RecRef.SETTABLE(Rec);

        MODIFY(TRUE);
        SetCalculatedFields();
        EXIT(FALSE);
    end;

    trigger OnModifyRecord(): Boolean
    var
        CustomerAgreement: Record "Customer Agreement";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        IF xRec.SystemId <> SystemId THEN
            GraphMgtGeneralTools.ErrorIdImmutable();

        CustomerAgreement.SETRANGE(SystemId, SystemId);
        CustomerAgreement.FINDFIRST();

        IF ("No." = CustomerAgreement."No.") and ("Customer No." = CustomerAgreement."Customer No.") THEN
            MODIFY(TRUE)
        ELSE BEGIN
            CustomerAgreement.TRANSFERFIELDS(Rec, FALSE);
            CustomerAgreement.RENAME("Customer No.", "No.");
            TRANSFERFIELDS(CustomerAgreement);
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

    local procedure SetCalculatedFields()
    var
    begin
        CurrencyCodeTxt := GraphMgtGeneralTools.TranslateNAVCurrencyCodeToCurrencyCode(LCYCurrencyCode, "Currency Code");

    end;

    local procedure ClearCalculatedFields()
    begin
        CLEAR(SystemId);
        TempFieldSet.DELETEALL();
    end;

    local procedure RegisterFieldSet(FieldNo: Integer)
    begin
        IF TempFieldSet.GET(DATABASE::"Customer Agreement", FieldNo) THEN
            EXIT;

        TempFieldSet.INIT();
        TempFieldSet.TableNo := DATABASE::"Customer Agreement";
        TempFieldSet.VALIDATE("No.", FieldNo);
        TempFieldSet.INSERT(TRUE);
    end;

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