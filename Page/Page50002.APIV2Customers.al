page 50002 "APIV2 - Customers"
{
    APIPublisher = 'tcomtech';
    APIGroup = 'app';
    APIVersion = 'v1.0';
    Caption = 'customersSprut', Locked = true;
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    EntityName = 'customerSprut';
    EntitySetName = 'customersSprut';
    ODataKeyFields = "No.";
    PageType = API;
    SourceTable = Customer;
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
                    Caption = 'number', Locked = true;
                }
                field(displayName; txtDisplayName)
                {
                    ApplicationArea = All;
                    Caption = 'displayName', Locked = true;
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        IF txtDisplayName = '' THEN
                            ERROR(BlankCustomerNameErr);

                        Name := CopyStr(txtDisplayName, 1, MaxStrLen(Name));
                        "Name 2" := CopyStr(txtDisplayName, MaxStrLen(Name) + 1, MaxStrLen("Name 2"));

                        RegisterFieldSet(Rec.FIELDNO(Name));
                        RegisterFieldSet(Rec.FIELDNO("Name 2"));
                    end;
                }
                field(fullName; "Full Name")
                {
                    ApplicationArea = All;
                    Caption = 'fullName', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("Full Name"));
                    end;
                }
                field(type; Rec."Contact Type")
                {
                    ApplicationArea = All;
                    Caption = 'type', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(Rec.FIELDNO("Contact Type"));
                    end;
                }
                field(phoneNumber; Rec."Phone No.")
                {
                    ApplicationArea = All;
                    Caption = 'phoneNumber', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(Rec.FIELDNO("Phone No."));
                    end;
                }
                field(email; Rec."E-Mail")
                {
                    ApplicationArea = All;
                    Caption = 'email', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(Rec.FIELDNO("E-Mail"));
                    end;
                }
                field(website; Rec."Home Page")
                {
                    ApplicationArea = All;
                    Caption = 'website', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(Rec.FIELDNO("Home Page"));
                    end;
                }
                field(taxLiable; Rec."Tax Liable")
                {
                    ApplicationArea = All;
                    Caption = 'taxLiable', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(Rec.FIELDNO("Tax Liable"));
                    end;
                }
                field(taxAreaId; Rec."Tax Area ID")
                {
                    ApplicationArea = All;
                    Caption = 'taxAreaId', Locked = true;

                    trigger OnValidate()
                    var
                        GeneralLedgerSetup: Record "General Ledger Setup";
                    begin
                        RegisterFieldSet(Rec.FIELDNO("Tax Area ID"));

                        IF NOT GeneralLedgerSetup.UseVat() THEN
                            RegisterFieldSet(Rec.FIELDNO("Tax Area Code"))
                        ELSE
                            RegisterFieldSet(Rec.FIELDNO("VAT Bus. Posting Group"));
                    end;
                }
                field(taxAreaDisplayName; TaxAreaDisplayName)
                {
                    ApplicationArea = All;
                    Caption = 'taxAreaDisplayName', Locked = true;
                    Editable = false;
                    ToolTip = 'Specifies the display name of the tax area.';
                }
                field(taxRegistrationNumber; Rec."TAX Registration No.")
                {
                    ApplicationArea = All;
                    Caption = 'taxRegistrationNumber', Locked = true;
                    ToolTip = 'Specifies the display name of the tax registration number.';

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(Rec.FIELDNO("TAX Registration No."));
                        if "TAX Registration No." <> '' then begin
                            "VAT Registration No." := "TAX Registration No.";
                            RegisterFieldSet(Rec.FIELDNO("VAT Registration No."));
                        end;
                    end;
                }
                field(currencyId; Rec."Currency Id")
                {
                    ApplicationArea = All;
                    Caption = 'currencyId', Locked = true;

                    trigger OnValidate()
                    begin
                        IF Rec."Currency Id" = BlankGUID THEN
                            Rec."Currency Code" := ''
                        ELSE BEGIN
                            Currency.SETRANGE(SystemId, Rec."Currency Id");
                            IF NOT Currency.FINDFIRST() THEN
                                ERROR(CurrencyIdDoesNotMatchACurrencyErr);

                            Rec."Currency Code" := Currency.Code;
                        END;

                        RegisterFieldSet(Rec.FIELDNO("Currency Id"));
                        RegisterFieldSet(Rec.FIELDNO("Currency Code"));
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

                        IF Rec."Currency Code" = '' THEN
                            Rec."Currency Id" := BlankGUID
                        ELSE BEGIN
                            IF NOT Currency.GET(Rec."Currency Code") THEN
                                ERROR(CurrencyCodeDoesNotMatchACurrencyErr);

                            Rec."Currency Id" := Currency.SystemId;
                        END;

                        RegisterFieldSet(Rec.FIELDNO("Currency Id"));
                        RegisterFieldSet(Rec.FIELDNO("Currency Code"));
                    end;
                }
                field(paymentTermsId; Rec."Payment Terms Id")
                {
                    ApplicationArea = All;
                    Caption = 'paymentTermsId', Locked = true;

                    trigger OnValidate()
                    begin
                        IF Rec."Payment Terms Id" = BlankGUID THEN
                            Rec."Payment Terms Code" := ''
                        ELSE BEGIN
                            PaymentTerms.SETRANGE(SystemId, Rec."Payment Terms Id");
                            IF NOT PaymentTerms.FINDFIRST() THEN
                                ERROR(PaymentTermsIdDoesNotMatchAPaymentTermsErr);

                            Rec."Payment Terms Code" := PaymentTerms.Code;
                        END;

                        RegisterFieldSet(Rec.FIELDNO("Payment Terms Id"));
                        RegisterFieldSet(Rec.FIELDNO("Payment Terms Code"));
                    end;
                }
                field(shipmentMethodId; Rec."Shipment Method Id")
                {
                    ApplicationArea = All;
                    Caption = 'shipmentMethodId', Locked = true;

                    trigger OnValidate()
                    begin
                        IF Rec."Shipment Method Id" = BlankGUID THEN
                            Rec."Shipment Method Code" := ''
                        ELSE BEGIN
                            ShipmentMethod.SETRANGE(SystemId, Rec."Shipment Method Id");
                            IF NOT ShipmentMethod.FINDFIRST() THEN
                                ERROR(ShipmentMethodIdDoesNotMatchAShipmentMethodErr);

                            Rec."Shipment Method Code" := ShipmentMethod.Code;
                        END;

                        RegisterFieldSet(Rec.FIELDNO("Shipment Method Id"));
                        RegisterFieldSet(Rec.FIELDNO("Shipment Method Code"));
                    end;
                }
                field(paymentMethodId; Rec."Payment Method Id")
                {
                    ApplicationArea = All;
                    Caption = 'paymentMethodId', Locked = true;

                    trigger OnValidate()
                    begin
                        IF Rec."Payment Method Id" = BlankGUID THEN
                            Rec."Payment Method Code" := ''
                        ELSE BEGIN
                            PaymentMethod.SETRANGE(SystemId, Rec."Payment Method Id");
                            IF NOT PaymentMethod.FINDFIRST() THEN
                                ERROR(PaymentMethodIdDoesNotMatchAPaymentMethodErr);

                            Rec."Payment Method Code" := PaymentMethod.Code;
                        END;

                        RegisterFieldSet(Rec.FIELDNO("Payment Method Id"));
                        RegisterFieldSet(Rec.FIELDNO("Payment Method Code"));
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

                // >>

                field(crmID; Rec."CRM ID")
                {
                    ApplicationArea = All;
                    Caption = 'crmID', Locked = true;

                    trigger OnValidate()
                    begin
                        // if "CRM ID" = BlankGUID then
                        //     Error(errCRMIdIsNullNotAllowed, "CRM ID");
                        RegisterFieldSet(FIELDNO("CRM ID"));
                    end;
                }
                field(deduplicateId; Rec."Deduplicate Id")
                {
                    ApplicationArea = All;
                    Caption = 'deduplicateId', Locked = true;

                    trigger OnValidate()
                    begin
                        // if "Deduplicate Id" = BlankGUID then
                        //     Error(errDeduplicateIdIsNullNotAllowed, "Deduplicate Id");
                        RegisterFieldSet(FIELDNO("Deduplicate Id"));
                    end;
                }
                field(status; Rec.Status)
                {
                    ApplicationArea = All;
                    Caption = 'status', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO(Status));
                    end;
                }

                field(codeOKPO; Rec."OKPO Code")
                {
                    ApplicationArea = All;
                    Caption = 'codeOKPO', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(Rec.FIELDNO("OKPO Code"));
                    end;
                }
                field(taxRegistrationNo; Rec."TAX Registration No.")
                {
                    ApplicationArea = All;
                    Caption = 'codeOKPO', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(Rec.FIELDNO("TAX Registration No."));
                    end;
                }
                field(certificate; Certificate)
                {
                    ApplicationArea = All;
                    Caption = 'certificate', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(Rec.FIELDNO(Certificate));
                    end;
                }
                field(accountIBAN; txtIBAN)
                {
                    ApplicationArea = All;
                    Caption = 'IBAN', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterIBAN();
                    end;
                }
                field(address; Address)
                {
                    ApplicationArea = All;
                    Caption = 'address', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(Rec.FIELDNO(Address));
                    end;
                }
                field(address2; "Address 2")
                {
                    ApplicationArea = All;
                    Caption = 'address2', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(Rec.FIELDNO("Address 2"));
                    end;
                }
                field(city; City)
                {
                    ApplicationArea = All;
                    Caption = 'city', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(Rec.FIELDNO(City));
                    end;
                }
                field(countryRegionCode; "Country/Region Code")
                {
                    ApplicationArea = All;
                    Caption = 'countryRegionCode', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(Rec.FIELDNO("Country/Region Code"));
                    end;
                }
                field(county; County)
                {
                    ApplicationArea = All;
                    Caption = 'county', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(Rec.FIELDNO(County));
                    end;
                }
                field(postCode; "Post Code")
                {
                    ApplicationArea = All;
                    Caption = 'postCode', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(Rec.FIELDNO("Post Code"));
                    end;
                }
                // field(contactName; Contact)
                // {
                //     ApplicationArea = All;
                //     Caption = 'contactName', Locked = true;

                //     trigger OnValidate()
                //     begin
                //         RegisterFieldSet(Rec.FIELDNO(Contact));
                //     end;
                // }
                // <<

                field(lastModifiedDateTime; Rec."Last Modified Date Time")
                {
                    ApplicationArea = All;
                    Caption = 'lastModifiedDateTime', Locked = true;
                }
                part(picture; "Picture Entity")
                {
                    ApplicationArea = All;
                    Caption = 'picture';
                    EntityName = 'picture';
                    EntitySetName = 'picture';
                    SubPageLink = Id = FIELD(SystemId);
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
        Customer: Record Customer;
        RecRef: RecordRef;
    begin
        IF Rec.Name = '' THEN
            ERROR(NotProvidedCustomerNameErr);

        Customer.SETRANGE("No.", Rec."No.");
        IF NOT Customer.ISEMPTY() THEN
            Rec.INSERT();

        Rec.INSERT(TRUE);

        ProcessPostalAddress();
        // RegisterIBAN(); // <<

        RecRef.GETTABLE(Rec);
        // GraphMgtGeneralTools.ProcessNewRecordFromAPI(RecRef, TempFieldSet, CURRENTDATETIME());
        ProcessNewRecordFromAPI(RecRef, TempFieldSet, CURRENTDATETIME());
        RecRef.SETTABLE(Rec);

        Rec.MODIFY(TRUE);
        SetCalculatedFields();
        EXIT(FALSE);
    end;

    trigger OnModifyRecord(): Boolean
    var
        Customer: Record Customer;
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        IF xRec.SystemId <> Rec.SystemId THEN
            GraphMgtGeneralTools.ErrorIdImmutable();

        Customer.SETRANGE(SystemId, Rec.SystemId);
        Customer.FINDFIRST();

        ProcessPostalAddress();
        // RegisterIBAN(); // <<

        IF Rec."No." = Customer."No." THEN
            Rec.MODIFY(TRUE)
        ELSE BEGIN
            Customer.TRANSFERFIELDS(Rec, FALSE);
            Customer.RENAME(Rec."No.");
            Rec.TRANSFERFIELDS(Customer);
        END;

        SetCalculatedFields();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ClearCalculatedFields();
    end;

    var
        Currency: Record Currency;
        PaymentTerms: Record "Payment Terms";
        ShipmentMethod: Record "Shipment Method";
        PaymentMethod: Record "Payment Method";
        TempFieldSet: Record Field temporary;
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        LCYCurrencyCode: Code[10];
        CurrencyCodeTxt: Text;
        PostalAddressJSON: Text;
        TaxAreaDisplayName: Text;
        txtIBAN: Text;
        txtDisplayName: Text;
        CurrencyValuesDontMatchErr: Label 'The currency values do not match to a specific Currency.', Locked = true;
        CurrencyIdDoesNotMatchACurrencyErr: Label 'The "currencyId" does not match to a Currency.', Locked = true;
        CurrencyCodeDoesNotMatchACurrencyErr: Label 'The "currencyCode" does not match to a Currency.', Locked = true;
        PaymentTermsIdDoesNotMatchAPaymentTermsErr: Label 'The "paymentTermsId" does not match to a Payment Terms.', Locked = true;
        ShipmentMethodIdDoesNotMatchAShipmentMethodErr: Label 'The "shipmentMethodId" does not match to a Shipment Method.', Locked = true;
        PaymentMethodIdDoesNotMatchAPaymentMethodErr: Label 'The "paymentMethodId" does not match to a Payment Method.', Locked = true;
        BlankGUID: Guid;
        NotProvidedCustomerNameErr: Label 'A "displayName" must be provided.', Locked = true;
        BlankCustomerNameErr: Label 'The blank "displayName" is not allowed.', Locked = true;
        errDeduplicateIdIsNullNotAllowed: Label 'The "deduplicateId" %1 is not allowed.', Locked = true;
        errCRMIdIsNullNotAllowed: Label 'The "crmID" %1 is not allowed.', Locked = true;
        PostalAddressSet: Boolean;

    local procedure RegisterIBAN()
    var
        CustBankAccount: Record "Customer Bank Account";
        GLSetup: Record "General Ledger Setup";
    begin
        if (txtIBAN = "Default Bank Code")
        or ("No." = '') then
            exit;

        if txtIBAN = '' then begin
            CustBankAccount.Get("Default Bank Code");
            txtIBAN := CustBankAccount.IBAN;
            exit;
        end;

        CustBankAccount.SetCurrentKey("Customer No.", IBAN);
        CustBankAccount.SetRange("Customer No.", "No.");
        CustBankAccount.SetRange(IBAN, txtIBAN);
        if not CustBankAccount.FindFirst() then begin
            CustBankAccount.SetRange(IBAN);
            CustBankAccount.SetRange(Code, 'CRM_IBAN_CODE');
            if not CustBankAccount.FindFirst() then begin
                CustBankAccount.Init();
                CustBankAccount."Customer No." := "No.";
                CustBankAccount.Code := 'CRM_IBAN_CODE';
                CustBankAccount.BIC := GetBankBIC(CopyStr(txtIBAN, 5, 6));
                if "Currency Code" <> '' then
                    CustBankAccount."Currency Code" := "Currency Code"
                else begin
                    GLSetup.Get();
                    CustBankAccount."Currency Code" := GLSetup."LCY Code";
                end;
                CustBankAccount.IBAN := txtIBAN;
                CustBankAccount.Insert();
            end else begin
                CustBankAccount.IBAN := txtIBAN;
                CustBankAccount.Modify();
            end;
        end;
        if CustBankAccount.Code <> '' then begin
            "Default Bank Code" := CustBankAccount.Code;
            RegisterFieldSet(FIELDNO("Default Bank Code"));
        end;
    end;

    local procedure SetCalculatedFields()
    var
        TaxAreaBuffer: Record "Tax Area Buffer";
        GraphMgtCustomer: Codeunit "Graph Mgt - Customer";
    begin
        PostalAddressJSON := GraphMgtCustomer.PostalAddressToJSON(Rec);
        CurrencyCodeTxt := GraphMgtGeneralTools.TranslateNAVCurrencyCodeToCurrencyCode(LCYCurrencyCode, Rec."Currency Code");
        TaxAreaDisplayName := TaxAreaBuffer.GetTaxAreaDisplayName(Rec."Tax Area ID");
        txtDisplayName := Name + "Name 2";
    end;

    local procedure ClearCalculatedFields()
    begin
        CLEAR(Rec.SystemId);
        CLEAR(TaxAreaDisplayName);
        CLEAR(PostalAddressJSON);
        CLEAR(PostalAddressSet);
        TempFieldSet.DELETEALL();
        Clear(txtDisplayName);
    end;

    local procedure RegisterFieldSet(FieldNo: Integer)
    begin
        IF TempFieldSet.GET(DATABASE::Customer, FieldNo) THEN
            EXIT;

        TempFieldSet.INIT();
        TempFieldSet.TableNo := DATABASE::Customer;
        TempFieldSet.VALIDATE("No.", FieldNo);
        TempFieldSet.INSERT(TRUE);
    end;

    local procedure ProcessPostalAddress()
    var
        GraphMgtCustomer: Codeunit "Graph Mgt - Customer";
    begin
        IF NOT PostalAddressSet THEN
            EXIT;

        GraphMgtCustomer.UpdatePostalAddress(PostalAddressJSON, Rec);

        IF xRec.Address <> Rec.Address THEN
            RegisterFieldSet(Rec.FIELDNO(Address));

        IF xRec."Address 2" <> Rec."Address 2" THEN
            RegisterFieldSet(Rec.FIELDNO("Address 2"));

        IF xRec.City <> Rec.City THEN
            RegisterFieldSet(Rec.FIELDNO(City));

        IF xRec."Country/Region Code" <> Rec."Country/Region Code" THEN
            RegisterFieldSet(Rec.FIELDNO("Country/Region Code"));

        IF xRec."Post Code" <> Rec."Post Code" THEN
            RegisterFieldSet(Rec.FIELDNO("Post Code"));

        IF xRec.County <> Rec.County THEN
            RegisterFieldSet(Rec.FIELDNO(County));
    end;

    local procedure ProcessNewRecordFromAPI(var InsertedRecordRef: RecordRef; var TempFieldSet: Record "Field"; ModifiedDateTime: DateTime)
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTmplSelectionRules: Record "Config. Tmpl. Selection Rules";
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

    local procedure GetBankBIC(BankBIC: Code[9]): Code[9]
    var
        BankDirectory: Record "Bank Directory";
    begin
        if not BankDirectory.Get(BankBIC) then begin
            BankDirectory.Init();
            BankDirectory.BIC := BankBIC;
            BankDirectory.Insert();
        end;

        exit(BankDirectory.BIC);
    end;

    // <<
}