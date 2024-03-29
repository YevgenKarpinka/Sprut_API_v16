codeunit 50018 "Integration 1C"
{
    trigger OnRun()
    var
        CompanyIntegration: Record "Company Integration";
    begin
        if IntegrationWith1CDisabled() then exit;

        if ItemCompanyFrom() then begin
            GetCompanyIdFrom1C();
            GetItemsIdFrom1C();
            GetVendorIdFrom1C();
            GetBankDirectoryIdFrom1C(CompanyName);
            GetCustomerIdFrom1C(CompanyName);
            GetCustomerAgreementIdFrom1C(glCustAgreement, CompanyName);
            GetVendorAgreementIdFrom1C(glVendAgreement, CompanyName);
        end;

        CompanyIntegration.SetCurrentKey("Copy Items To");
        CompanyIntegration.SetRange("Copy Items To", true);
        if CompanyIntegration.FindSet(true) then
            repeat
                GetBankDirectoryIdFrom1C(CompanyIntegration."Company Name");
                GetCustomerIdFrom1C(CompanyIntegration."Company Name");
                GetCustomerAgreementIdFrom1C(glCustAgreement, CompanyIntegration."Company Name");
                GetVendorAgreementIdFrom1C(glVendAgreement, CompanyIntegration."Company Name");
            until CompanyIntegration.Next() = 0;
    end;

    var
        SRSetup: Record "Sales & Receivables Setup";
        IntegrationLog: Record "Integration Log";
        WebServiceMgt: Codeunit "Web Service Mgt.";
        glCustAgreement: Record "Customer Agreement";
        glVendAgreement: Record "Vendor Agreement";
        glCompanyPrefix: Code[10];
        TestMode: Boolean;

    procedure GetCompanyIdFrom1C(): Boolean
    var
        entityType: Label 'Catalog_Организации';
        entityTypePATCH: Label 'Catalog_Организации(%1)';
        entityTypePATCHValue: Text;
        requestMethodGET: Label 'GET';
        requestMethodPOST: Label 'POST';
        requestMethodPATCH: Label 'PATCH';
        Body: Text;
        filterValue: Text;
        lblfilter: Label '&$filter=%1 eq ''%2''';
        lblSystemCode: Label '1C';
        CompanyIntegration: Record "Company Integration";
        CompanyInfo: Record "Company Information";
        tempCompanyIntegration: Record "Company Integration" temporary;
        IntegrationEntity: Record "Integration Entity";
        ResponceTokenLine: Text;
        jsonLines: JsonArray;
        jsonBody: JsonObject;
        LineToken: JsonToken;
        codeISO: Code[10];
    begin
        // create entity list for getting id from 1C
        if CompanyIntegration.FindSet(true) then
            repeat
                CompanyInfo.ChangeCompany(CompanyIntegration."Company Name");
                CompanyInfo.Get();
                if not IntegrationEntity.Get(lblSystemCode, Database::"Company Information", CompanyInfo."OKPO Code", '')
                and (CompanyIntegration."Copy Items To" or CompanyIntegration."Copy Items From") then begin
                    tempCompanyIntegration := CompanyIntegration;
                    tempCompanyIntegration.Insert();
                end;
            until CompanyIntegration.Next() = 0;

        // link between 1C and BC
        // get entity from 1C
        if tempCompanyIntegration.FindSet(true) then
            repeat
                CompanyInfo.ChangeCompany(tempCompanyIntegration."Company Name");
                CompanyInfo.Get();
                filterValue := StrSubstNo(lblfilter, 'КодПоЕДРПОУ', CompanyInfo."OKPO Code");
                if not ConnectTo1C(entityType, requestMethodGET, Body, filterValue) then exit(false);
                jsonBody.ReadFrom(Body);
                jsonLines := WebServiceMgt.GetJSToken(jsonBody, 'value').AsArray();
                if jsonLines.Count <> 0 then begin
                    foreach LineToken in jsonLines do
                        AddIDToIntegrationEntity(lblSystemCode, Database::"Company Information", CompanyInfo."OKPO Code", '',
                                                WebServiceMgt.GetJSToken(LineToken.AsObject(), 'Ref_Key').AsValue().AsText(),
                                                tempCompanyIntegration."Company Name", CompanyName);

                    AddCompanyIntegrationPrefix(tempCompanyIntegration."Company Name", WebServiceMgt.GetJSToken(LineToken.AsObject(), 'Префикс').AsValue().AsText());
                end else begin
                    // create entity in 1C
                    // create json for create company
                    CreateRequestBodyToCompany(tempCompanyIntegration."Company Name", jsonBody, requestMethodPOST, tempCompanyIntegration.Prefix);
                    // get body from 1C
                    jsonBody.WriteTo(Body);
                    if not ConnectTo1C(entityType, requestMethodPOST, Body, '') then exit(false);
                    jsonBody.ReadFrom(Body);
                    // jsonLines := WebServiceMgt.GetJSToken(jsonBody, 'value').AsArray();
                    AddIDToIntegrationEntity(lblSystemCode, Database::"Company Information", CompanyInfo."OKPO Code", '',
                                            WebServiceMgt.GetJSToken(jsonBody, 'Ref_Key').AsValue().AsText(),
                                            tempCompanyIntegration."Company Name", CompanyName);
                end;
            until tempCompanyIntegration.Next() = 0;

        exit(true);
    end;

    local procedure CreateRequestBodyToCompany(_CompanyName: Text[30]; var Body: JsonObject; requestMethodPATCH: Text[10]; prefixComp: Text[10]);
    var
        CompInfo: Record "Company Information";
        lblLegalEntity: Label 'ЮридическоеЛицо';
    begin
        if CompanyName <> _CompanyName then
            CompInfo.ChangeCompany(_CompanyName);

        CompInfo.Get();
        Clear(Body);
        Body.Add('Description', CompInfo.Name);
        Body.Add('КодПоЕДРПОУ', CompInfo."OKPO Code");
        Body.Add('НаименованиеПолное', CompInfo."Full Name");
        Body.Add('Префикс', prefixComp);
        Body.Add('ЮридическоеФизическоеЛицо', lblLegalEntity);
        Body.Add('ИмяКомпанииВС', _CompanyName);
        // comment for test
        Body.Add('КонтактнаяИнформация', GetContactInfoFromCompanyInfo(_CompanyName));
    end;

    local procedure GetContactInfoFromCompanyInfo(_CompanyName: Text[30]): JsonArray
    var
        CompInfo: Record "Company Information";
        jsonContactInfoLine: JsonObject;
        jsonContactInfo: JsonArray;
        LineNo: Integer;
        lblbPhoneKey: Label 'ebccdced-2cab-11ea-acf7-545049000031';
        lblAddressLegalKey: Label 'ebccdcf0-2cab-11ea-acf7-545049000031';
        lblAddressKey: Label 'ebccdcef-2cab-11ea-acf7-545049000031';
        lblTypePhone: Label 'Телефон';
        lblTypeAddress: Label 'Адрес';
    begin
        if CompanyName <> _CompanyName then
            CompInfo.ChangeCompany(_CompanyName);

        CompInfo.Get();

        LineNo := 0;
        if CompInfo."Phone No." <> '' then begin
            LineNo += 1;
            jsonContactInfoLine.Add('LineNumber', LineNo);
            jsonContactInfoLine.Add('Тип', lblTypePhone);
            jsonContactInfoLine.Add('Вид_Key', lblbPhoneKey);
            jsonContactInfoLine.Add('НомерТелефона', CompInfo."Phone No.");
            jsonContactInfoLine.Add('Представление', CompInfo."Phone No.");
            jsonContactInfo.Add(jsonContactInfoLine);
            Clear(jsonContactInfoLine);
        end;

        if CompInfo.Address <> '' then begin
            LineNo += 1;
            jsonContactInfoLine.Add('LineNumber', LineNo);
            jsonContactInfoLine.Add('Тип', lblTypeAddress);
            jsonContactInfoLine.Add('Вид_Key', lblAddressLegalKey);
            jsonContactInfoLine.Add('Город', CompInfo.City);
            jsonContactInfoLine.Add('Представление', CompInfo.Address + CompInfo."Address 2");
            jsonContactInfoLine.Add('АдресЭП', CompInfo.Address + CompInfo."Address 2");
            jsonContactInfo.Add(jsonContactInfoLine);
        end;

        exit(jsonContactInfo);
    end;

    local procedure GetCompanyIdFromIntegrEntity(_CompanyName: Text[30]): Text
    var
        CompanyInfo: Record "Company Information";
        IntegrEntity: Record "Integration Entity";
        lblSystemCode: Label '1C';
    begin
        if CompanyName <> _CompanyName then
            CompanyInfo.ChangeCompany(_CompanyName);

        CompanyInfo.Get();
        if CompanyInfo."OKPO Code" = '' then exit('');
        // if IntegrEntity.Get(lblSystemCode, Database::"Company Information", CompanyInfo."OKPO Code", '') then
        IntegrEntity.Get(lblSystemCode, Database::"Company Information", CompanyInfo."OKPO Code", '');
        exit(GuidToClearText(IntegrEntity."Entity Id"));

        // GetCompanyIdFrom1C();
        // IntegrEntity.Get(lblSystemCode, Database::"Company Information", CompanyInfo."OKPO Code", '');
        // exit(GuidToClearText(IntegrEntity."Entity Id"));
    end;

    procedure GetCustomerAgreementIdFrom1C(CustomerAgreement: Record "Customer Agreement"; _CompanyName: Text[30]): Boolean
    var
        entityType: Label 'Catalog_ДоговорыКонтрагентов';
        entityTypePATCH: Label 'Catalog_ДоговорыКонтрагентов(%1)';
        entityTypePATCHValue: Text;
        requestMethodGET: Label 'GET';
        requestMethodPOST: Label 'POST';
        requestMethodPATCH: Label 'PATCH';
        Body: Text;
        filterValue: Text;
        lblfilter: Label '&$filter=%1 eq ''%2''';
        lblSystemCode: Label '1C';
        tempCustomerAgreement: Record "Customer Agreement" temporary;
        Customer: Record Customer;
        IntegrationEntity: Record "Integration Entity";
        ResponceTokenLine: Text;
        jsonLines: JsonArray;
        jsonBody: JsonObject;
        LineToken: JsonToken;
        codeISO: Code[10];
        blankGuid: Guid;
        locCustomerAgreement: Record "Customer Agreement";
    begin
        if CompanyName <> _CompanyName then begin
            locCustomerAgreement.ChangeCompany(_CompanyName);
            locCustomerAgreement.SetFilter("Customer No.", CustomerAgreement.GetFilter("Customer No."));
            Customer.ChangeCompany(_CompanyName);
        end;
        tempCustomerAgreement.DeleteAll();

        // create Agreement list for getting id from 1C
        if locCustomerAgreement.FindSet() then
            repeat
                if Customer.Get(locCustomerAgreement."Customer No.")
                and (IntegrationEntity.Get(lblSystemCode, Database::Customer, GuidToClearText(Customer."CRM ID"), '')
                    or (IntegrationEntity.Get(lblSystemCode, Database::Customer, GuidToClearText(Customer."BC Id"), ''))) then begin

                    if locCustomerAgreement."Init 1C" then begin
                        if not IntegrationEntity.Get(lblSystemCode, Database::"Customer Agreement", GuidToClearText(locCustomerAgreement.SystemId), '') then begin
                            tempCustomerAgreement := locCustomerAgreement;
                            tempCustomerAgreement."CRM ID" := locCustomerAgreement.SystemId;
                            tempCustomerAgreement.Insert();
                        end;
                    end else begin
                        if (locCustomerAgreement."CRM ID" <> blankGuid)
                        and not IntegrationEntity.Get(lblSystemCode, Database::"Customer Agreement", GuidToClearText(locCustomerAgreement."CRM ID"), '') then begin
                            tempCustomerAgreement := locCustomerAgreement;
                            if tempCustomerAgreement.Insert() then;
                        end;
                    end;
                end;
            until locCustomerAgreement.Next() = 0;

        // link between 1C and BC
        // create entity in 1C or get it
        if tempCustomerAgreement.FindSet() then
            repeat
                filterValue := StrSubstNo(lblfilter, 'CRM_ID', GuidToClearText(tempCustomerAgreement."CRM ID"));
                if not ConnectTo1C(entityType, requestMethodGET, Body, filterValue) then exit(false);
                jsonBody.ReadFrom(Body);
                jsonLines := WebServiceMgt.GetJSToken(jsonBody, 'value').AsArray();
                if jsonLines.Count <> 0 then begin
                    foreach LineToken in jsonLines do
                        AddIDToIntegrationEntity(lblSystemCode, Database::"Customer Agreement", GuidToClearText(tempCustomerAgreement."CRM ID"),
                                                    '',
                                                    WebServiceMgt.GetJSToken(LineToken.AsObject(), 'Ref_Key').AsValue().AsText(),
                                                    tempCustomerAgreement."No.", _CompanyName);
                end else begin
                    // create request body
                    CreateRequestBodyToCustomerAgreement(tempCustomerAgreement."Customer No.", tempCustomerAgreement."No.", jsonBody, requestMethodPATCH, _CompanyName);
                    // get body from 1C
                    jsonBody.WriteTo(Body);
                    if not ConnectTo1C(entityType, requestMethodPOST, Body, '') then exit(false);
                    jsonBody.ReadFrom(Body);
                    AddIDToIntegrationEntity(lblSystemCode, Database::"Customer Agreement", GuidToClearText(tempCustomerAgreement."CRM ID"),
                                                '',
                                                WebServiceMgt.GetJSToken(jsonBody, 'Ref_Key').AsValue().AsText(),
                                                tempCustomerAgreement."No.", _CompanyName);
                end;
            // Commit();
            until tempCustomerAgreement.Next() = 0;

        // update entity in 1C
        // create list for updating in 1C
        tempCustomerAgreement.DeleteAll();
        if locCustomerAgreement.FindSet() then
            repeat
                if Customer.Get(locCustomerAgreement."Customer No.") then
                    if locCustomerAgreement."Init 1C" then begin
                        if IntegrationEntity.Get(lblSystemCode, Database::"Customer Agreement", GuidToClearText(locCustomerAgreement.SystemId), '')
                                        and (IntegrationEntity."Last Modify Date Time" < locCustomerAgreement."Last DateTime Modified")
                                        then begin
                            tempCustomerAgreement := locCustomerAgreement;
                            tempCustomerAgreement."CRM ID" := locCustomerAgreement.SystemId;
                            tempCustomerAgreement.Insert();
                        end;
                    end else begin
                        if IntegrationEntity.Get(lblSystemCode, Database::"Customer Agreement", GuidToClearText(locCustomerAgreement."CRM ID"), '')
                                        and (IntegrationEntity."Last Modify Date Time" < locCustomerAgreement."Last DateTime Modified")
                                        then begin
                            tempCustomerAgreement := locCustomerAgreement;
                            tempCustomerAgreement.Insert();
                        end;
                    end;
            until locCustomerAgreement.Next() = 0;

        if tempCustomerAgreement.FindSet() then
            repeat
                // create request body
                CreateRequestBodyToCustomerAgreement(tempCustomerAgreement."Customer No.", tempCustomerAgreement."No.", jsonBody, requestMethodPATCH, _CompanyName);
                entityTypePATCHValue := StrSubstNo(entityTypePATCH, GetCustomerAgreementIdFromIntegrEntity(tempCustomerAgreement."CRM ID", _CompanyName));
                // patch entity in 1C
                jsonBody.WriteTo(Body);
                if not ConnectTo1C(entityTypePATCHValue, requestMethodPATCH, Body, '') then
                    exit(false);
                UpdateDateTimeIntegrationEntity(lblSystemCode, Database::"Customer Agreement", GuidToClearText(tempCustomerAgreement."CRM ID"), '');
            // Commit();
            until tempCustomerAgreement.Next() = 0;

        exit(true);
    end;

    local procedure GetCustomerAgreementIdFromIntegrEntity(CustomerAgreementCRMID: Guid; _CompanyName: Text[30]): Text[50]
    var
        // CustomerAgreement: Record "Customer Agreement";
        IntegrEntity: Record "Integration Entity";
        lblSystemCode: Label '1C';
        BlankGuid: Guid;
        Code2: Text[40];
    begin
        if CustomerAgreementCRMID = BlankGuid then exit('');


        IntegrEntity.Get(lblSystemCode, Database::"Customer Agreement", GuidToClearText(CustomerAgreementCRMID), '');
        exit(GuidToClearText(IntegrEntity."Entity Id"));
    end;

    local procedure CreateRequestBodyToCustomerAgreement(CustomerNo: Code[20]; AgreementNo: Code[20]; var Body: JsonObject;
                                            requestMethod: Text[10]; _CompanyName: Text[30])
    var
        CustomerAgreement: Record "Customer Agreement";
        lblPaymentView: Label 'ПоДоговоруВЦелом';
        lblPaymentViewVAT: Label 'ПоДоговоруВЦелом';
        lblAgreementView: Label 'СПокупателем';
        lblSchemaPostingVAT: Label 'fee33cc5-2cab-11ea-acf7-545049000031';
        lblSchemaPostingVATTara: Label 'fee33cc5-2cab-11ea-acf7-545049000031';
    begin
        if CompanyName <> _CompanyName then
            CustomerAgreement.ChangeCompany(_CompanyName);

        CustomerAgreement.Get(CustomerNo, AgreementNo);
        Clear(Body);
        Body.Add('Номер', CustomerAgreement."External Agreement No.");
        Body.Add('Description', CustomerAgreement."No.");
        Body.Add('Дата', CustomerAgreement."Agreement Date");
        Body.Add('СрокДействия', CustomerAgreement."Expire Date");
        Body.Add('ВедениеВзаиморасчетов', lblPaymentView);
        Body.Add('ВедениеВзаиморасчетовНУ', lblPaymentViewVAT);
        Body.Add('ВидДоговора', lblAgreementView);
        if requestMethod = 'PATCH' then
            Body.Add('Owner_Key', GetCustomerIdFromIntegrEntity(CustomerNo, _CompanyName));
        Body.Add('ВалютаВзаиморасчетов_Key', GetCurrencyIdFromIntegrEntity(CustomerAgreement."Currency Code", _CompanyName));
        Body.Add('Организация_Key', GetCompanyIdFromIntegrEntity(_CompanyName));
        Body.Add('СхемаНалоговогоУчета_Key', lblSchemaPostingVAT);
        Body.Add('СхемаНалоговогоУчетаПоТаре_Key', lblSchemaPostingVATTara);
        Body.Add('DeletionMark', not CustomerAgreement.Active);
        // Body.Add('НаименованиеДляПечати', CustomerAgreement."External Agreement No.");
        if CustomerAgreement."Init 1C" then
            Body.Add('CRM_ID', GuidToClearText(CustomerAgreement.SystemId))
        else
            Body.Add('CRM_ID', GuidToClearText(CustomerAgreement."CRM ID"));
        Body.Add('ПризнакПечати', CustomerAgreement.Print);

    end;

    local procedure GuidToClearText(TextToConvert: Text): Text
    begin
        if StrLen(TextToConvert) > 35 then
            exit(LowerCase(DelChr(TextToConvert, '<>', '{}')));
        exit(TextToConvert);
    end;

    procedure GetCustomerIdFrom1C(_CompanyName: Text[30]): Boolean
    var
        entityType: Label 'Catalog_Контрагенты';
        entityTypePATCH: Label 'Catalog_Контрагенты(%1)';
        entityTypePATCHValue: Text;
        requestMethodGET: Label 'GET';
        requestMethodPOST: Label 'POST';
        requestMethodPATCH: Label 'PATCH';
        Body: Text;
        filterValue: Text;
        lblfilter: Label '&$filter=%1 eq ''%2''';
        lblSystemCode: Label '1C';
        Customer: Record Customer;
        tempCustomer: Record Customer temporary;
        CustBankAcc: Record "Customer Bank Account";
        CustAgreement: Record "Customer Agreement";
        IntegrationEntity: Record "Integration Entity";
        ResponceTokenLine: Text;
        jsonLines: JsonArray;
        jsonBody: JsonObject;
        LineToken: JsonToken;
        codeISO: Code[10];
        blankGuid: Guid;
    begin
        if CompanyName <> _CompanyName then begin
            Customer.ChangeCompany(_CompanyName);
            CustBankAcc.ChangeCompany(_CompanyName);
            CustAgreement.ChangeCompany(_CompanyName);
        end;
        tempCustomer.DeleteAll();

        GetSRSetup(_CompanyName);
        GetCompanyPrefix(_CompanyName);
        // create Currency list for getting id from 1C
        if Customer.FindSet(true) then
            repeat
                if Customer."Init 1C" then begin
                    if not IntegrationEntity.Get(lblSystemCode, Database::Customer, GuidToClearText(Customer."BC Id"), '')
                    and not IsNullGuid(Customer."BC Id") then begin
                        tempCustomer := Customer;
                        tempCustomer."CRM ID" := Customer."BC Id";
                        tempCustomer.Insert();
                    end;
                end else begin
                    if (Customer."CRM ID" <> blankGuid)
                    and not IntegrationEntity.Get(lblSystemCode, Database::Customer, GuidToClearText(Customer."CRM ID"), '') then begin
                        tempCustomer := Customer;
                        if tempCustomer.Insert() then;
                    end;
                end;

            until (Customer.Next() = 0) or TestMode;

        // link between 1C and BC
        // create entity in 1C or get it
        if tempCustomer.FindSet(true) then
            repeat
                // filterValue := StrSubstNo(lblfilter, 'ID_CRM', GuidToClearText(tempCustomer."CRM ID"));
                filterValue := StrSubstNo(lblfilter, 'Code', glCompanyPrefix + tempCustomer."No.");
                if not ConnectTo1C(entityType, requestMethodGET, Body, filterValue) then exit(false);
                jsonBody.ReadFrom(Body);
                jsonLines := WebServiceMgt.GetJSToken(jsonBody, 'value').AsArray();
                if jsonLines.Count <> 0 then begin
                    foreach LineToken in jsonLines do
                        AddIDToIntegrationEntity(lblSystemCode, Database::Customer, GuidToClearText(tempCustomer."CRM ID"), '',
                                                WebServiceMgt.GetJSToken(LineToken.AsObject(), 'Ref_Key').AsValue().AsText(),
                                                tempCustomer."No.", _CompanyName);
                end else begin
                    // create request body
                    CreateRequestBodyToCustomer(tempCustomer."No.", jsonBody, requestMethodPOST, _CompanyName);
                    // get body from 1C
                    jsonBody.WriteTo(Body);
                    if not ConnectTo1C(entityType, requestMethodPOST, Body, '') then exit(false);
                    jsonBody.ReadFrom(Body);
                    AddIDToIntegrationEntity(lblSystemCode, Database::Customer, GuidToClearText(tempCustomer."CRM ID"), '',
                                                WebServiceMgt.GetJSToken(jsonBody, 'Ref_Key').AsValue().AsText(),
                                                tempCustomer."No.", _CompanyName);
                end;

                if tempCustomer."Default Bank Code" <> '' then begin
                    // create request body
                    CreateRequestBodyToCustomer(tempCustomer."No.", jsonBody, requestMethodPATCH, _CompanyName);
                    entityTypePATCHValue := StrSubstNo(entityTypePATCH, GetCustomerIdFromIntegrEntity(tempCustomer."No.", _CompanyName));
                    // patch entity in 1C
                    jsonBody.WriteTo(Body);
                    if not ConnectTo1C(entityTypePATCHValue, requestMethodPATCH, Body, '') then
                        exit(false);
                end else begin

                    if CustomerBankAccountExist(tempCustomer."No.", _CompanyName) then begin
                        CustBankAcc.SetRange("Customer No.", tempCustomer."No.");
                        GetCustomerBankAccountIdFrom1C(CustBankAcc, _CompanyName);
                    end;

                    if CustomerAgreementExist(tempCustomer."No.", _CompanyName) then begin
                        CustAgreement.SetRange("Customer No.", tempCustomer."No.");
                        GetCustomerAgreementIdFrom1C(CustAgreement, _CompanyName);
                    end;

                end;

            // if CustomerAgreementExist(tempCustomer."No.", _CompanyName) then begin
            //     CustAgreement.SetRange("Customer No.", tempCustomer."No.");
            //     GetCustomerAgreementIdFrom1C(CustAgreement, _CompanyName);
            // end;

            // Commit();
            until tempCustomer.Next() = 0;

        // update entity in 1C
        // create list for updating in 1C
        tempCustomer.DeleteAll();
        if Customer.FindSet(true) then
            repeat
                if Customer."Init 1C" then begin
                    if IntegrationEntity.Get(lblSystemCode, Database::Customer, GuidToClearText(Customer."BC Id"), '')
                                    and (IntegrationEntity."Last Modify Date Time" < Customer."Last Modified Date Time")
                                    then begin
                        tempCustomer := Customer;
                        tempCustomer."CRM ID" := Customer."BC Id";
                        tempCustomer.Insert();
                    end;
                end else begin
                    if IntegrationEntity.Get(lblSystemCode, Database::Customer, GuidToClearText(Customer."CRM ID"), '')
                                    and (IntegrationEntity."Last Modify Date Time" < Customer."Last Modified Date Time")
                                    then begin
                        tempCustomer := Customer;
                        tempCustomer.Insert();
                    end;
                end;
            until (Customer.Next() = 0) or TestMode;

        if tempCustomer.FindSet(true) then
            repeat
                // create request body
                CreateRequestBodyToCustomer(tempCustomer."No.", jsonBody, requestMethodPATCH, _CompanyName);
                entityTypePATCHValue := StrSubstNo(entityTypePATCH, GetCustomerIdFromIntegrEntity(tempCustomer."No.", _CompanyName));
                // patch entity in 1C
                jsonBody.WriteTo(Body);
                if not ConnectTo1C(entityTypePATCHValue, requestMethodPATCH, Body, '') then
                    exit(false);
                UpdateDateTimeIntegrationEntity(lblSystemCode, Database::Customer, GuidToClearText(tempCustomer."CRM ID"), '');
            // Commit();
            until tempCustomer.Next() = 0;

        exit(true);
    end;

    local procedure CreateRequestBodyToCustomer(CustomerNo: Code[20]; var Body: JsonObject; requestMethod: Text[10]; _CompanyName: Text[30])
    var
        Customer: Record Customer;
        CustBankAcc: Record "Customer Bank Account";
        CustAgreement: Record "Customer Agreement";
        lblLegalEntity: Label 'ЮридическоеЛицо';
        // lblCustomerParentKey: Label '5df557a2-80ae-11eb-b1ab-0022489ae653';
        lblCustomerParentKey: Label 'c0a62194-b47b-11eb-b1b0-0022489ae653';
        requestMethodPATCH: Label 'PATCH';
        mainBankAccId: Text[40];
    begin
        if CompanyName <> _CompanyName then begin
            Customer.ChangeCompany(_CompanyName);
            CustBankAcc.ChangeCompany(_CompanyName);
            CustAgreement.ChangeCompany(_CompanyName);
        end;

        Customer.Get(CustomerNo);
        Clear(Body);
        if (requestMethod <> requestMethodPATCH) then
            Body.Add('Code', glCompanyPrefix + Customer."No.");
        Body.Add('Description', Customer.Name + Customer."Name 2");
        Body.Add('НаименованиеПолное', Customer."Full Name");
        Body.Add('ЮридическоеФизическоеЛицо', lblLegalEntity);
        if Customer."VAT Registration No." = '' then begin
            if Customer."TAX Registration No." <> '' then
                Body.Add('ИНН', Customer."TAX Registration No.")
        end else
            Body.Add('ИНН', Customer."VAT Registration No.");
        Body.Add('Parent_Key', lblCustomerParentKey);
        if Customer."OKPO Code" <> '' then
            Body.Add('КодПоЕДРПОУ', Customer."OKPO Code");
        if Customer."Init 1C" then
            Body.Add('ID_CRM', GuidToClearText(Customer."BC Id"))
        else
            Body.Add('ID_CRM', GuidToClearText(Customer."CRM ID"));

        if (requestMethod = requestMethodPATCH) then begin

            if CustomerBankAccountExist(CustomerNo, _CompanyName) then begin
                CustBankAcc.SetRange("Customer No.", CustomerNo);
                GetCustomerBankAccountIdFrom1C(CustBankAcc, _CompanyName);
            end;

            if CustomerAgreementExist(CustomerNo, _CompanyName) then begin
                CustAgreement.SetRange("Customer No.", CustomerNo);
                GetCustomerAgreementIdFrom1C(CustAgreement, _CompanyName);
            end;

            mainBankAccId := GetCustomerBankAccountIDFromIntegrEntity(Customer."No.", Customer."Default Bank Code", _CompanyName);
            if (mainBankAccId <> '') then
                Body.Add('ОсновнойБанковскийСчет_Key', mainBankAccId);
        end;

        Body.Add('НеЯвляетсяРезидентом', GetCustomerResident(Customer."No.", _CompanyName));
        Body.Add('КонтактнаяИнформация', GetCustomerContactInfo(Customer."No.", _CompanyName));
        Body.Add('DeletionMark', Customer.IsBlocked());
    end;

    local procedure GetCustomerContactInfo(CustomerNo: Code[20]; _CompanyName: Text[30]): JsonArray
    var
        Cust: Record Customer;
        ShipToAdress: Record "Ship-to Address";
        LineNo: Integer;
        jsonContactInfoLine: JsonObject;
        jsonContactInfo: JsonArray;
        lblbPhoneKey: Label 'ebccdced-2cab-11ea-acf7-545049000031';
        lblAddressLegalKey: Label 'ebccdcf0-2cab-11ea-acf7-545049000031';
        lblAddressKey: Label 'ebccdcef-2cab-11ea-acf7-545049000031';
        lblTypePhone: Label 'Телефон';
        lblTypeAddress: Label 'Адрес';
    begin
        if CompanyName <> _CompanyName then begin
            Cust.ChangeCompany(_CompanyName);
            ShipToAdress.ChangeCompany(_CompanyName);
        end;

        Cust.Get(CustomerNo);
        LineNo := 0;
        if Cust."Phone No." <> '' then begin
            LineNo += 1;
            jsonContactInfoLine.Add('LineNumber', LineNo);
            jsonContactInfoLine.Add('Тип', lblTypePhone);
            jsonContactInfoLine.Add('Вид_Key', lblbPhoneKey);
            jsonContactInfoLine.Add('Представление', Cust."Phone No.");
            jsonContactInfoLine.Add('НомерТелефона', Cust."Phone No.");
            jsonContactInfo.Add(jsonContactInfoLine);
            Clear(jsonContactInfoLine);
        end;

        if Cust.Address <> '' then begin
            LineNo += 1;
            jsonContactInfoLine.Add('LineNumber', LineNo);
            jsonContactInfoLine.Add('Тип', lblTypeAddress);
            jsonContactInfoLine.Add('Вид_Key', lblAddressLegalKey);
            jsonContactInfoLine.Add('Город', Cust.City);
            jsonContactInfoLine.Add('Представление', Cust.Address + Cust."Address 2");
            jsonContactInfoLine.Add('АдресЭП', Cust.Address + Cust."Address 2");
            jsonContactInfo.Add(jsonContactInfoLine);
            Clear(jsonContactInfoLine);
        end;

        ShipToAdress.SetCurrentKey("Customer No.");
        ShipToAdress.SetRange("Customer No.", CustomerNo);
        if ShipToAdress.FindSet(true) then begin
            // repeat
            LineNo += 1;
            jsonContactInfoLine.Add('LineNumber', LineNo);
            jsonContactInfoLine.Add('Тип', lblTypeAddress);
            jsonContactInfoLine.Add('Вид_Key', lblAddressKey);
            if Cust."Phone No." <> '' then
                jsonContactInfoLine.Add('НомерТелефона', ShipToAdress."Phone No.");
            if Cust.City <> '' then
                jsonContactInfoLine.Add('Город', ShipToAdress.City);
            if Cust.Address <> '' then begin
                jsonContactInfoLine.Add('Представление', Cust.Address + Cust."Address 2");
                jsonContactInfoLine.Add('АдресЭП', ShipToAdress.Address + ShipToAdress."Address 2");
            end;
            jsonContactInfo.Add(jsonContactInfoLine);
            // until ShipToAdress.Next() = 0;
        end;
        exit(jsonContactInfo);
    end;

    local procedure GetCustomerResident(CustNo: Code[20]; _CompanyName: Text[30]): Boolean
    begin
        // to do
        exit(false);
    end;

    local procedure GetCustomerBankAccountIDFromIntegrEntity(CustNo: Code[20]; CustomerDefaultBankCode: Code[20]; _CompanyName: Text[30]): Text
    var
        CustBankAcc: Record "Customer Bank Account";
        IntegrEntity: Record "Integration Entity";
        lblSystemCode: Label '1C';
    begin
        if CompanyName <> _CompanyName then
            CustBankAcc.ChangeCompany(_CompanyName);

        if not CustBankAcc.Get(CustNo, CustomerDefaultBankCode) then exit('');
        CustBankAcc.Get(CustNo, CustomerDefaultBankCode);

        if IntegrEntity.Get(lblSystemCode, Database::"Customer Bank Account", CustBankAcc.IBAN, '') then
            exit(LowerCase(DelChr(IntegrEntity."Entity Id", '<>', '{}')));

        CustBankAcc.SetRange("Customer No.", CustBankAcc."Customer No.");
        GetCustomerBankAccountIdFrom1C(CustBankAcc, _CompanyName);
        IntegrEntity.Get(lblSystemCode, Database::"Customer Bank Account", CustBankAcc.IBAN, '');
        exit(LowerCase(DelChr(IntegrEntity."Entity Id", '<>', '{}')));
    end;

    procedure GetVendorIdFrom1C(): Boolean
    var
        entityType: Label 'Catalog_Контрагенты';
        entityTypePATCH: Label 'Catalog_Контрагенты(%1)';
        entityTypePATCHValue: Text;
        requestMethodGET: Label 'GET';
        requestMethodPOST: Label 'POST';
        requestMethodPATCH: Label 'PATCH';
        Body: Text;
        filterValue: Text;
        lblfilter: Label '&$filter=%1 eq ''%2''';
        lblSystemCode: Label '1C';
        Vendor: Record Vendor;
        tempVendor: Record Vendor temporary;
        VendBankAcc: Record "Vendor Bank Account";
        IntegrationEntity: Record "Integration Entity";
        ResponceTokenLine: Text;
        jsonLines: JsonArray;
        jsonBody: JsonObject;
        LineToken: JsonToken;
        codeISO: Code[10];

    begin
        // create Currency list for getting id from 1C
        if Vendor.FindSet(true) then
            repeat
                if not IntegrationEntity.Get(lblSystemCode, Database::Vendor, Vendor."No.", '') then begin
                    tempVendor := Vendor;
                    tempVendor.Insert();
                end;
            until Vendor.Next() = 0;

        // link between 1C and BC
        // create entity in 1C or get it
        if tempVendor.FindSet(true) then
            repeat
                filterValue := StrSubstNo(lblfilter, 'Code', tempVendor."No.");
                if not ConnectTo1C(entityType, requestMethodGET, Body, filterValue) then exit(false);
                jsonBody.ReadFrom(Body);
                jsonLines := WebServiceMgt.GetJSToken(jsonBody, 'value').AsArray();
                if jsonLines.Count <> 0 then begin
                    foreach LineToken in jsonLines do
                        AddIDToIntegrationEntity(lblSystemCode, Database::Vendor, tempVendor."No.", '',
                                                    WebServiceMgt.GetJSToken(LineToken.AsObject(), 'Ref_Key').AsValue().AsText(),
                                                    tempVendor."No.", CompanyName);
                end else begin
                    // create request body
                    CreateRequestBodyToVendor(tempVendor."No.", jsonBody, requestMethodPOST);
                    // get body from 1C
                    jsonBody.WriteTo(Body);
                    if not ConnectTo1C(entityType, requestMethodPOST, Body, '') then exit(false);
                    jsonBody.ReadFrom(Body);
                    AddIDToIntegrationEntity(lblSystemCode, Database::Vendor, tempVendor."No.", '',
                                                WebServiceMgt.GetJSToken(jsonBody, 'Ref_Key').AsValue().AsText(),
                                                tempVendor."No.", CompanyName);
                end;

                // patch when bank account exist
                if tempVendor."Default Bank Code" <> '' then begin
                    // create request body
                    CreateRequestBodyToVendor(tempVendor."No.", jsonBody, requestMethodPATCH);
                    entityTypePATCHValue := StrSubstNo(entityTypePATCH, GetVendorIdFromIntegrEntity(tempVendor."No."));
                    // patch entity in 1C
                    jsonBody.WriteTo(Body);
                    if not ConnectTo1C(entityTypePATCHValue, requestMethodPATCH, Body, '') then
                        exit(false);
                end else begin

                    // comment for test
                    if VendorBankAccountExist(tempVendor."No.") then begin
                        VendBankAcc.SetRange("Vendor No.", tempVendor."No.");
                        GetVendorBankAccountIdFrom1C(VendBankAcc);
                    end;

                end;

            // Commit();
            until tempVendor.Next() = 0;

        // update entity in 1C
        // create list for updating in 1C
        tempVendor.DeleteAll();
        if Vendor.FindSet(true) then
            repeat
                if IntegrationEntity.Get(lblSystemCode, Database::Vendor, Vendor."No.", '')
                and (IntegrationEntity."Last Modify Date Time" < Vendor."Last Modified Date Time")
                then begin
                    tempVendor := Vendor;
                    tempVendor.Insert();
                end;
            until Vendor.Next() = 0;

        if tempVendor.FindSet(true) then
            repeat
                // create request body
                CreateRequestBodyToVendor(tempVendor."No.", jsonBody, requestMethodPATCH);
                entityTypePATCHValue := StrSubstNo(entityTypePATCH, GetVendorIdFromIntegrEntity(tempVendor."No."));
                // patch entity in 1C
                jsonBody.WriteTo(Body);
                if not ConnectTo1C(entityTypePATCHValue, requestMethodPATCH, Body, '') then
                    exit(false);

                UpdateDateTimeIntegrationEntity(lblSystemCode, Database::Vendor, tempVendor."No.", '');
            // Commit();
            until tempVendor.Next() = 0;

        exit(true);
    end;

    local procedure CreateRequestBodyToVendor(VendorNo: Code[20]; var Body: JsonObject; requestMethod: Text[10])
    var
        Vendor: Record Vendor;
        lblLegalEntity: Label 'ЮридическоеЛицо';
        // lblVendorParentKey: Label '5df557a3-80ae-11eb-b1ab-0022489ae653';
        lblVendorParentKey: Label 'c0a62195-b47b-11eb-b1b0-0022489ae653';
        requestMethodPATCH: Label 'PATCH';
        mainBankAccId: Text[40];
    begin
        Vendor.Get(VendorNo);
        Clear(Body);
        if (requestMethod <> requestMethodPATCH) then
            Body.Add('Code', Vendor."No.");
        Body.Add('Description', Vendor.Name);
        Body.Add('НаименованиеПолное', Vendor."Full Name");
        Body.Add('ЮридическоеФизическоеЛицо', lblLegalEntity);
        Body.Add('ИНН', Vendor."VAT Registration No.");
        Body.Add('Parent_Key', lblVendorParentKey);
        Body.Add('КодПоЕДРПОУ', Vendor."OKPO Code");

        if (requestMethod = requestMethodPATCH) then begin
            mainBankAccId := GetVendorBankAccountIDFromIntegrEntity(Vendor."No.", Vendor."Default Bank Code");
            if (mainBankAccId <> '') then
                Body.Add('ОсновнойБанковскийСчет_Key', mainBankAccId);
        end;

        Body.Add('НеЯвляетсяРезидентом', GetVendorResident(Vendor."No."));
        Body.Add('КонтактнаяИнформация', GetVendorContactInfo(Vendor."No."));
        Body.Add('DeletionMark', Vendor.Blocked = Vendor.Blocked::All);
    end;

    local procedure GetVendorContactInfo(VendorNo: Code[20]): JsonArray
    var
        Vend: Record Vendor;
        OrderAdress: Record "Order Address";
        LineNo: Integer;
        jsonContactInfoLine: JsonObject;
        jsonContactInfo: JsonArray;
        lblbPhoneKey: Label 'ebccdced-2cab-11ea-acf7-545049000031';
        lblAddressLegalKey: Label 'ebccdcf0-2cab-11ea-acf7-545049000031';
        lblAddressKey: Label 'ebccdcef-2cab-11ea-acf7-545049000031';
        lblTypePhone: Label 'Телефон';
        lblTypeAddress: Label 'Адрес';
    begin
        Vend.Get(VendorNo);
        LineNo := 0;
        if Vend."Phone No." <> '' then begin
            LineNo += 1;
            jsonContactInfoLine.Add('LineNumber', LineNo);
            jsonContactInfoLine.Add('Тип', lblTypePhone);
            jsonContactInfoLine.Add('Вид_Key', lblbPhoneKey);
            jsonContactInfoLine.Add('НомерТелефона', Vend."Phone No.");
            jsonContactInfoLine.Add('Представление', Vend."Phone No.");
            jsonContactInfo.Add(jsonContactInfoLine);
            Clear(jsonContactInfoLine);
        end;

        if Vend.Address <> '' then begin
            LineNo += 1;
            jsonContactInfoLine.Add('LineNumber', LineNo);
            jsonContactInfoLine.Add('Тип', lblTypeAddress);
            jsonContactInfoLine.Add('Вид_Key', lblAddressLegalKey);
            jsonContactInfoLine.Add('Город', Vend.City);
            jsonContactInfoLine.Add('Представление', Vend.Address + Vend."Address 2");
            jsonContactInfoLine.Add('АдресЭП', Vend.Address + Vend."Address 2");
            jsonContactInfo.Add(jsonContactInfoLine);
            Clear(jsonContactInfoLine);
        end;

        OrderAdress.SetCurrentKey("Vendor No.");
        OrderAdress.SetRange("Vendor No.", VendorNo);
        if OrderAdress.FindSet() then begin
            // repeat
            Clear(jsonContactInfoLine);
            LineNo += 1;
            jsonContactInfoLine.Add('LineNumber', LineNo);
            jsonContactInfoLine.Add('Тип', lblTypeAddress);
            jsonContactInfoLine.Add('Вид_Key', lblAddressKey);
            if Vend."Phone No." <> '' then
                jsonContactInfoLine.Add('НомерТелефона', OrderAdress."Phone No.");
            if Vend.City <> '' then
                jsonContactInfoLine.Add('Город', OrderAdress.City);
            if Vend.Address <> '' then begin
                jsonContactInfoLine.Add('Представление', Vend.Address + Vend."Address 2");
                jsonContactInfoLine.Add('АдресЭП', OrderAdress.Address + OrderAdress."Address 2");
            end;
            jsonContactInfo.Add(jsonContactInfoLine);
        end;
        // until OrderAdress.Next() = 0;
        exit(jsonContactInfo);
    end;

    local procedure GetVendorResident(VendorNo: Code[20]): Boolean
    begin
        // to do
        exit(false);
    end;

    local procedure GetVendorBankAccountIDFromIntegrEntity(VendNo: Code[20]; VendorDefaultBankCode: Code[20]): Text
    var
        VendBankAcc: Record "Vendor Bank Account";
        IntegrEntity: Record "Integration Entity";
        lblSystemCode: Label '1C';
    begin
        if not VendBankAcc.Get(VendNo, VendorDefaultBankCode) then exit('');

        if IntegrEntity.Get(lblSystemCode, Database::"Vendor Bank Account", VendBankAcc.IBAN, '') then
            exit(LowerCase(DelChr(IntegrEntity."Entity Id", '<>', '{}')));

        VendBankAcc.SetRange("Vendor No.", VendBankAcc."Vendor No.");
        GetVendorBankAccountIdFrom1C(VendBankAcc);
        IntegrEntity.Get(lblSystemCode, Database::"Vendor Bank Account", VendBankAcc.IBAN, '');
        exit(LowerCase(DelChr(IntegrEntity."Entity Id", '<>', '{}')));
    end;

    procedure GetVendorBankAccountIdFrom1C(VendBankAcc: Record "Vendor Bank Account"): Boolean
    var
        entityType: Label 'Catalog_БанковскиеСчета';
        entityTypePATCH: Label 'Catalog_БанковскиеСчета(%1)';
        entityTypePATCHValue: Text;
        requestMethodGET: Label 'GET';
        requestMethodPOST: Label 'POST';
        requestMethodPATCH: Label 'PATCH';
        Body: Text;
        filterValue: Text;
        lblfilter: Label '&$filter=%1 eq ''%2''';
        lblSystemCode: Label '1C';
        tempVendBankAcc: Record "Vendor Bank Account" temporary;
        Vendor: Record Vendor;
        IntegrationEntity: Record "Integration Entity";
        ResponceTokenLine: Text;
        jsonLines: JsonArray;
        jsonBody: JsonObject;
        LineToken: JsonToken;
        codeISO: Code[10];
    begin
        tempVendBankAcc.DeleteAll();

        // create Currency list for getting id from 1C
        if VendBankAcc.FindSet(true) then
            repeat
                if not IntegrationEntity.Get(lblSystemCode, Database::"Vendor Bank Account", VendBankAcc.IBAN, '')
                and Vendor.Get(VendBankAcc."Vendor No.")
                and IntegrationEntity.Get(lblSystemCode, Database::Vendor, Vendor."No.", '') then begin
                    tempVendBankAcc := VendBankAcc;
                    tempVendBankAcc.Insert();
                end;
            until VendBankAcc.Next() = 0;

        // link between 1C and BC
        // create entity in 1C or get it
        if tempVendBankAcc.FindSet(true) then
            repeat
                filterValue := StrSubstNo(lblfilter, 'НомерСчета', tempVendBankAcc.IBAN);
                if not ConnectTo1C(entityType, requestMethodGET, Body, filterValue) then exit(false);
                jsonBody.ReadFrom(Body);
                jsonLines := WebServiceMgt.GetJSToken(jsonBody, 'value').AsArray();
                if jsonLines.Count <> 0 then begin
                    foreach LineToken in jsonLines do
                        AddIDToIntegrationEntity(lblSystemCode, Database::"Vendor Bank Account", tempVendBankAcc.IBAN, '',
                                                    WebServiceMgt.GetJSToken(LineToken.AsObject(), 'Ref_Key').AsValue().AsText(),
                                                    tempVendBankAcc.Code, CompanyName);
                end else begin
                    // create request body
                    CreateRequestBodyToVendorBankAccount(tempVendBankAcc.IBAN, jsonBody);
                    // get body from 1C
                    jsonBody.WriteTo(Body);
                    if not ConnectTo1C(entityType, requestMethodPOST, Body, '') then exit(false);
                    jsonBody.ReadFrom(Body);
                    AddIDToIntegrationEntity(lblSystemCode, Database::"Vendor Bank Account", tempVendBankAcc.IBAN, '',
                                                WebServiceMgt.GetJSToken(jsonBody, 'Ref_Key').AsValue().AsText(),
                                                tempVendBankAcc.Code, CompanyName);
                end;
            // Commit();
            until tempVendBankAcc.Next() = 0;

        // update entity in 1C
        // create list for updating in 1C
        tempVendBankAcc.DeleteAll();
        if VendBankAcc.FindSet(true) then
            repeat
                if IntegrationEntity.Get(lblSystemCode, Database::"Vendor Bank Account", VendBankAcc.IBAN, '')
                and (IntegrationEntity."Last Modify Date Time" < VendBankAcc."Last DateTime Modified") then begin
                    tempVendBankAcc := VendBankAcc;
                    tempVendBankAcc.Insert();
                end;
            until VendBankAcc.Next() = 0;

        if tempVendBankAcc.FindSet(true) then
            repeat
                // create request body
                CreateRequestBodyToVendorBankAccount(tempVendBankAcc.IBAN, jsonBody);
                entityTypePATCHValue := StrSubstNo(entityTypePATCH, GetVendBankAccIdFromIntegrEntity(tempVendBankAcc.IBAN));
                // patch entity in 1C
                jsonBody.WriteTo(Body);
                if not ConnectTo1C(entityTypePATCHValue, requestMethodPATCH, Body, '') then
                    exit(false);
                UpdateDateTimeIntegrationEntity(lblSystemCode, Database::"Vendor Bank Account", tempVendBankAcc.IBAN, '');
            // Commit();
            until tempVendBankAcc.Next() = 0;

        exit(true);
    end;

    local procedure CreateRequestBodyToVendorBankAccount(VendBankAccIBAN: Code[50]; var Body: JsonObject)
    var
        VendorBankAccount: Record "Vendor Bank Account";
        lblContragent: Label 'StandardODATA.Catalog_Контрагенты';
    begin
        VendorBankAccount.SetCurrentKey(IBAN);
        VendorBankAccount.SetRange(IBAN, VendBankAccIBAN);
        VendorBankAccount.FindSet(true);
        Clear(Body);
        Body.Add('НомерСчета', VendorBankAccount.IBAN);
        Body.Add('НомерСчетаУстаревший', VendorBankAccount."Bank Account No.");
        Body.Add('Description', VendorBankAccount.Name + VendorBankAccount."Name 2");
        Body.Add('Банк_Key', GetBankDirectoryIdFromIntegrEntity(VendorBankAccount.BIC, CompanyName));
        Body.Add('Валютный', GetCurrencyAccount(VendorBankAccount."Currency Code", CompanyName));
        Body.Add('ВалютаДенежныхСредств_Key', GetCurrencyIdFromIntegrEntity(VendorBankAccount."Currency Code", CompanyName));
        Body.Add('Owner', GetVendorIdFromIntegrEntity(VendorBankAccount."Vendor No."));
        Body.Add('Owner_Type', lblContragent);
    end;

    procedure GetCustomerBankAccountIdFrom1C(CustBankAcc: Record "Customer Bank Account"; _CompanyName: Text[30]): Boolean
    var
        entityType: Label 'Catalog_БанковскиеСчета';
        entityTypePATCH: Label 'Catalog_БанковскиеСчета(%1)';
        entityTypePATCHValue: Text;
        requestMethodGET: Label 'GET';
        requestMethodPOST: Label 'POST';
        requestMethodPATCH: Label 'PATCH';
        Body: Text;
        filterValue: Text;
        lblfilter: Label '&$filter=%1 eq ''%2''';
        lblSystemCode: Label '1C';
        tempCustBankAcc: Record "Customer Bank Account" temporary;
        Customer: Record Customer;
        IntegrationEntity: Record "Integration Entity";
        ResponceTokenLine: Text;
        jsonLines: JsonArray;
        jsonBody: JsonObject;
        LineToken: JsonToken;
        codeISO: Code[10];
    begin
        if CompanyName <> _CompanyName then begin
            CustBankAcc.ChangeCompany(_CompanyName);
            Customer.ChangeCompany(_CompanyName);
        end;
        tempCustBankAcc.DeleteAll();

        // create Currency list for getting id from 1C
        if CustBankAcc.FindSet(true) then
            repeat

                if not IntegrationEntity.Get(lblSystemCode, Database::"Customer Bank Account", CustBankAcc.IBAN, '')
                and Customer.Get(CustBankAcc."Customer No.")
                and IntegrationEntity.Get(lblSystemCode, Database::Customer, GuidToClearText(Customer."CRM ID"), '') then begin
                    tempCustBankAcc := CustBankAcc;
                    tempCustBankAcc.Insert();
                end;
            until CustBankAcc.Next() = 0;

        // link between 1C and BC
        // create entity in 1C or get it
        if tempCustBankAcc.FindSet(true) then
            repeat
                filterValue := StrSubstNo(lblfilter, 'НомерСчета', tempCustBankAcc.IBAN);
                if not ConnectTo1C(entityType, requestMethodGET, Body, filterValue) then exit(false);
                jsonBody.ReadFrom(Body);
                jsonLines := WebServiceMgt.GetJSToken(jsonBody, 'value').AsArray();
                if jsonLines.Count <> 0 then begin
                    foreach LineToken in jsonLines do
                        AddIDToIntegrationEntity(lblSystemCode, Database::"Customer Bank Account", tempCustBankAcc.IBAN, '',
                                                    WebServiceMgt.GetJSToken(LineToken.AsObject(), 'Ref_Key').AsValue().AsText(),
                                                    tempCustBankAcc.Code, _CompanyName);
                end else begin
                    // create request body
                    CreateRequestBodyToCustomerBankAccount(tempCustBankAcc.IBAN, jsonBody, _CompanyName);
                    // get body from 1C
                    jsonBody.WriteTo(Body);
                    if not ConnectTo1C(entityType, requestMethodPOST, Body, '') then exit(false);
                    jsonBody.ReadFrom(Body);
                    AddIDToIntegrationEntity(lblSystemCode, Database::"Customer Bank Account", tempCustBankAcc.IBAN, '',
                                                WebServiceMgt.GetJSToken(jsonBody, 'Ref_Key').AsValue().AsText(),
                                                tempCustBankAcc.Code, _CompanyName);
                end;
            // Commit();
            until tempCustBankAcc.Next() = 0;

        // update entity in 1C
        // create list for updating in 1C
        tempCustBankAcc.DeleteAll();
        if CustBankAcc.FindSet(true) then
            repeat
                if IntegrationEntity.Get(lblSystemCode, Database::"Customer Bank Account", CustBankAcc.IBAN, '')
                and (IntegrationEntity."Last Modify Date Time" < CustBankAcc."Last DateTime Modified") then begin
                    tempCustBankAcc := CustBankAcc;
                    tempCustBankAcc.Insert();
                end;
            until CustBankAcc.Next() = 0;

        if tempCustBankAcc.FindSet(true) then
            repeat
                // create request body
                CreateRequestBodyToCustomerBankAccount(tempCustBankAcc.IBAN, jsonBody, _CompanyName);
                entityTypePATCHValue := StrSubstNo(entityTypePATCH, GetCustBankAccIdFromIntegrEntity(tempCustBankAcc.IBAN, _CompanyName));
                // patch entity in 1C
                jsonBody.WriteTo(Body);
                if not ConnectTo1C(entityTypePATCHValue, requestMethodPATCH, Body, '') then
                    exit(false);
                UpdateDateTimeIntegrationEntity(lblSystemCode, Database::"Customer Bank Account", tempCustBankAcc.IBAN, '');
            // Commit();
            until tempCustBankAcc.Next() = 0;

        exit(true);
    end;

    local procedure CreateRequestBodyToCustomerBankAccount(CustBankAccIBAN: Code[50]; var Body: JsonObject; _CompanyName: Text[30])
    var
        CustomerBankAccount: Record "Customer Bank Account";
        lblContragent: Label 'StandardODATA.Catalog_Контрагенты';
    begin
        if CompanyName <> _CompanyName then
            CustomerBankAccount.ChangeCompany(_CompanyName);

        CustomerBankAccount.SetCurrentKey("Customer No.", IBAN);
        CustomerBankAccount.SetRange(IBAN, CustBankAccIBAN);
        CustomerBankAccount.SetFilter("Customer No.", '<>%1', '');
        CustomerBankAccount.FindSet();
        Clear(Body);
        Body.Add('НомерСчета', CustomerBankAccount.IBAN);
        Body.Add('НомерСчетаУстаревший', CustomerBankAccount."Bank Account No.");
        Body.Add('Description', CustomerBankAccount.Name + CustomerBankAccount."Name 2");
        Body.Add('Банк_Key', GetBankDirectoryIdFromIntegrEntity(CustomerBankAccount.BIC, _CompanyName));
        Body.Add('Валютный', GetCurrencyAccount(CustomerBankAccount."Currency Code", _CompanyName));
        Body.Add('ВалютаДенежныхСредств_Key', GetCurrencyIdFromIntegrEntity(CustomerBankAccount."Currency Code", _CompanyName));
        Body.Add('Owner', GetCustomerIdFromIntegrEntity(CustomerBankAccount."Customer No.", _CompanyName));
        Body.Add('Owner_Type', lblContragent);
    end;

    local procedure GetCurrencyAccount(CustomerBankAccountCurrencyCode: Code[10]; _CompanyName: Text[30]): Boolean
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if CompanyName <> _CompanyName then
            GLSetup.ChangeCompany(_CompanyName);

        GLSetup.Get();
        exit(GLSetup."LCY Code" <> CustomerBankAccountCurrencyCode);
    end;

    procedure GetCurrencyIdFrom1C(_CompanyName: Text[30]): Boolean
    var
        entityType: Label 'Catalog_Валюты';
        entityTypePATCH: Label 'Catalog_Валюты(%1)';
        entityTypePATCHValue: Text;
        requestMethodGET: Label 'GET';
        requestMethodPOST: Label 'POST';
        requestMethodPATCH: Label 'PATCH';
        Body: Text;
        filterValue: Text;
        lblfilter: Label '&$filter=%1 eq ''%2''';
        lblSystemCode: Label '1C';
        Currency: Record Currency;
        tempCurrency: Record Currency temporary;
        IntegrationEntity: Record "Integration Entity";
        ResponceTokenLine: Text;
        jsonLines: JsonArray;
        jsonBody: JsonObject;
        LineToken: JsonToken;
        codeISO: Code[10];
    begin
        if CompanyName <> _CompanyName then
            Currency.ChangeCompany(_CompanyName);
        tempCurrency.DeleteAll();

        // create Currency list for getting id from 1C
        if Currency.FindSet(true) then
            repeat
                if not IntegrationEntity.Get(lblSystemCode, Database::Currency, Currency."ISO Numeric Code", '') then begin
                    tempCurrency := Currency;
                    tempCurrency.Insert();
                end;
            until Currency.Next() = 0;

        // link between 1C and BC
        // create entity in 1C or get it
        if tempCurrency.FindSet(true) then
            repeat
                filterValue := StrSubstNo(lblfilter, 'Code', tempCurrency."ISO Numeric Code");
                if not ConnectTo1C(entityType, requestMethodGET, Body, filterValue) then exit(false);
                jsonBody.ReadFrom(Body);
                jsonLines := WebServiceMgt.GetJSToken(jsonBody, 'value').AsArray();
                if jsonLines.Count <> 0 then begin
                    foreach LineToken in jsonLines do
                        AddIDToIntegrationEntity(lblSystemCode, Database::Currency, tempCurrency."ISO Numeric Code", '',
                                            WebServiceMgt.GetJSToken(LineToken.AsObject(), 'Ref_Key').AsValue().AsText(),
                                            tempCurrency.Code, _CompanyName);
                end else begin
                    // create request body
                    CreateRequestBodyToCurrency(tempCurrency."ISO Numeric Code", jsonBody, _CompanyName);
                    // get body from 1C
                    jsonBody.WriteTo(Body);
                    if not ConnectTo1C(entityType, requestMethodPOST, Body, '') then exit(false);
                    jsonBody.ReadFrom(Body);
                    AddIDToIntegrationEntity(lblSystemCode, Database::Currency, tempCurrency."ISO Numeric Code", '',
                                            WebServiceMgt.GetJSToken(jsonBody, 'Ref_Key').AsValue().AsText(),
                                            tempCurrency.Code, _CompanyName);
                end;
            // Commit();
            until tempCurrency.Next() = 0;

        // update entity in 1C
        // create list for updating in 1C
        tempCurrency.DeleteAll();
        if Currency.FindSet(true) then
            repeat
                if IntegrationEntity.Get(lblSystemCode, Database::Currency, Currency."ISO Numeric Code", '')
                and (IntegrationEntity."Last Modify Date Time" < Currency."Last Modified Date Time") then begin
                    tempCurrency := Currency;
                    tempCurrency.Insert();
                end;
            until Currency.Next() = 0;

        if tempCurrency.FindSet(true) then
            repeat
                // create request body
                CreateRequestBodyToCurrency(tempCurrency."ISO Numeric Code", jsonBody, _CompanyName);
                entityTypePATCHValue := StrSubstNo(entityTypePATCH, GetCurrencyIdFromIntegrEntity(tempCurrency.Code, _CompanyName));
                // patch entity in 1C
                jsonBody.WriteTo(Body);
                if not ConnectTo1C(entityTypePATCHValue, requestMethodPATCH, Body, '') then
                    exit(false);
                UpdateDateTimeIntegrationEntity(lblSystemCode, Database::Currency, tempCurrency."ISO Numeric Code", '');
            // Commit();
            until tempCurrency.Next() = 0;

        exit(true);
    end;

    local procedure CreateRequestBodyToCurrency(ISONumericCode: Code[3]; var Body: JsonObject; _CompanyName: Text[30])
    var
        Currency: Record Currency;
    begin
        if CompanyName <> _CompanyName then
            Currency.ChangeCompany(_CompanyName);
        Currency.SetCurrentKey("ISO Numeric Code");
        Currency.SetRange("ISO Numeric Code", ISONumericCode);
        Currency.FindSet(true);
        Clear(Body);
        Body.Add('Code', ISONumericCode);
        Body.Add('Description', Currency.Code);
        Body.Add('НаименованиеПолное', Currency.Description + Currency."Description 2");
    end;

    procedure GetBankDirectoryIdFrom1C(_CompanyName: Text[30]): Boolean
    var
        entityType: Label 'Catalog_Банки';
        entityTypePATCH: Label 'Catalog_Банки(%1)';
        entityTypePATCHValue: Text;
        requestMethodGET: Label 'GET';
        requestMethodPOST: Label 'POST';
        requestMethodPATCH: Label 'PATCH';
        Body: Text;
        filterValue: Text;
        lblfilter: Label '&$filter=%1 eq ''%2''';
        lblSystemCode: Label '1C';
        BankDirectory: Record "Bank Directory";
        tempBankDirectory: Record "Bank Directory" temporary;
        IntegrationEntity: Record "Integration Entity";
        ResponceTokenLine: Text;
        jsonLines: JsonArray;
        jsonBody: JsonObject;
        LineToken: JsonToken;
        codeBIC: Code[10];
        codeBIC1C: Text[10];
        tempcodeBIC1C: Text[10];
    begin
        // create UoMs list for getting id from 1C
        if _CompanyName <> CompanyName then
            BankDirectory.ChangeCompany(_CompanyName);
        tempBankDirectory.DeleteAll();

        if BankDirectory.FindSet(true) then
            repeat
                if not IntegrationEntity.Get(lblSystemCode, Database::"Bank Directory", BankDirectory.BIC, '') then begin
                    tempBankDirectory := BankDirectory;
                    tempBankDirectory.Insert();
                end;
            until BankDirectory.Next() = 0;

        // link between 1C МФО and BIC in BC
        if tempBankDirectory.FindSet(true) then
            repeat
                filterValue := StrSubstNo(lblfilter, 'Code', tempBankDirectory.BIC);
                if not ConnectTo1C(entityType, requestMethodGET, Body, filterValue) then exit(false);
                jsonBody.ReadFrom(Body);
                jsonLines := WebServiceMgt.GetJSToken(jsonBody, 'value').AsArray();
                if jsonLines.Count <> 0 then begin
                    foreach LineToken in jsonLines do
                        AddIDToIntegrationEntity(lblSystemCode, Database::"Bank Directory", tempBankDirectory.BIC, '',
                                                WebServiceMgt.GetJSToken(LineToken.AsObject(), 'Ref_Key').AsValue().AsText(),
                                                tempBankDirectory."Short Name", _CompanyName);
                end else begin
                    // create request body
                    CreateRequestBodyToBankDirectory(tempBankDirectory.BIC, jsonBody, _CompanyName);
                    // get body from 1C
                    jsonBody.WriteTo(Body);
                    if not ConnectTo1C(entityType, requestMethodPOST, Body, '') then exit(false);
                    jsonBody.ReadFrom(Body);
                    AddIDToIntegrationEntity(lblSystemCode, Database::"Bank Directory", tempBankDirectory.BIC, '',
                                            WebServiceMgt.GetJSToken(jsonBody, 'Ref_Key').AsValue().AsText(),
                                            tempBankDirectory."Short Name", _CompanyName);
                end;
            // Commit();
            until tempBankDirectory.Next() = 0;

        // update entity in 1C
        // create list for updating in 1C
        tempBankDirectory.DeleteAll();
        if BankDirectory.FindSet(true) then
            repeat
                if IntegrationEntity.Get(lblSystemCode, Database::"Bank Directory", BankDirectory.BIC, '')
                and (IntegrationEntity."Last Modify Date Time" < BankDirectory."Last DateTime Modified") then begin
                    tempBankDirectory := BankDirectory;
                    tempBankDirectory.Insert();
                end;
            until BankDirectory.Next() = 0;

        if tempBankDirectory.FindSet(true) then
            repeat
                // create request body
                CreateRequestBodyToBankDirectory(tempBankDirectory.BIC, jsonBody, _CompanyName);
                entityTypePATCHValue := StrSubstNo(entityTypePATCH, GetBankDirectoryIdFromIntegrEntity(tempBankDirectory.BIC, _CompanyName));
                // patch entity in 1C
                jsonBody.WriteTo(Body);
                if not ConnectTo1C(entityTypePATCHValue, requestMethodPATCH, Body, '') then
                    exit(false);
                UpdateDateTimeIntegrationEntity(lblSystemCode, Database::"Bank Directory", tempBankDirectory.BIC, '');
            // Commit();
            until tempBankDirectory.Next() = 0;

        exit(true);
    end;

    local procedure CreateRequestBodyToBankDirectory(BankDirectoryBIC: Code[10]; var Body: JsonObject; _CompanyName: Text[30])
    var
        BankDirectory: Record "Bank Directory";
    begin
        if _CompanyName <> CompanyName then
            BankDirectory.ChangeCompany(_CompanyName);

        BankDirectory.Get(BankDirectoryBIC);
        Clear(Body);
        Body.Add('Code', BankDirectory.BIC);
        Body.Add('Description', BankDirectory."Short Name");
        if BankDirectory."Area Name" <> '' then
            Body.Add('Город', BankDirectory."Area Name");
        if BankDirectory.Address <> '' then
            Body.Add('Адрес', BankDirectory.Address);
        if BankDirectory.Telephone <> '' then
            Body.Add('Телефоны', BankDirectory.Telephone);
        if BankDirectory.OKPO <> '' then
            Body.Add('КодПоЕДРПОУ', BankDirectory.OKPO);
    end;

    procedure GetUoMIdFrom1C(): Boolean
    var
        entityType: Label 'Catalog_КлассификаторЕдиницИзмерения';
        entityTypePATCH: Label 'Catalog_КлассификаторЕдиницИзмерения(%1)';
        entityTypePATCHValue: Text;
        requestMethodGET: Label 'GET';
        requestMethodPOST: Label 'POST';
        requestMethodPATCH: Label 'PATCH';
        Body: Text;
        filterValue: Text;
        lblSystemCode: Label '1C';
        UnitOfMeasure: Record "Unit of Measure";
        tempUnitOfMeasure: Record "Unit of Measure" temporary;
        IntegrationEntity: Record "Integration Entity";
        ResponceTokenLine: Text;
        jsonLines: JsonArray;
        jsonBody: JsonObject;
        LineToken: JsonToken;
        codeUoM: Code[10];
    begin
        // create UoMs list for getting id from 1C
        if UnitOfMeasure.FindSet(true) then
            repeat
                if not IntegrationEntity.Get(lblSystemCode, Database::"Unit of Measure", UnitOfMeasure."Numeric Code", '') then begin
                    tempUnitOfMeasure := UnitOfMeasure;
                    tempUnitOfMeasure.Insert();
                end;
            until UnitOfMeasure.Next() = 0;

        // link between BC and 1C by Code and Description

        // get body from 1C
        if not ConnectTo1C(entityType, requestMethodGET, Body, filterValue) then exit(false);
        jsonBody.ReadFrom(Body);
        jsonLines := WebServiceMgt.GetJSToken(jsonBody, 'value').AsArray();
        tempUnitOfMeasure.SetCurrentKey("Numeric Code");
        foreach LineToken in jsonLines do begin
            codeUoM := DelChr(WebServiceMgt.GetJSToken(LineToken.AsObject(), 'Code').AsValue().AsText(), '<>', ' ');
            tempUnitOfMeasure.SetRange("Numeric Code", codeUoM);
            if tempUnitOfMeasure.FindFirst() then begin
                AddIDToIntegrationEntity(lblSystemCode, Database::"Unit of Measure", tempUnitOfMeasure."Numeric Code", '',
                                        WebServiceMgt.GetJSToken(LineToken.AsObject(), 'Ref_Key').AsValue().AsText(),
                                        tempUnitOfMeasure.Code, CompanyName);
                tempUnitOfMeasure.Delete();
            end;
        end;
        // Commit();

        // create entity in 1C
        Clear(jsonBody);
        Clear(jsonLines);
        tempUnitOfMeasure.Reset();
        if tempUnitOfMeasure.FindSet(true) then
            repeat
                // create request body
                CreateRequestBodyToUoM(tempUnitOfMeasure.Code, jsonBody);

                // get body from 1C
                jsonBody.WriteTo(Body);
                if not ConnectTo1C(entityType, requestMethodPOST, Body, '') then exit(false);
                jsonBody.ReadFrom(Body);
                AddIDToIntegrationEntity(lblSystemCode, Database::"Unit of Measure", tempUnitOfMeasure."Numeric Code", '',
                                        WebServiceMgt.GetJSToken(jsonBody, 'Ref_Key').AsValue().AsText(),
                                        tempUnitOfMeasure.Code, CompanyName);
            // Commit();
            until tempUnitOfMeasure.Next() = 0;

        // update entity in 1C
        // create list for updating in 1C
        tempUnitOfMeasure.DeleteAll();
        if UnitOfMeasure.FindSet(true) then
            repeat
                if IntegrationEntity.Get(lblSystemCode, Database::"Unit of Measure", UnitOfMeasure."Numeric Code", '')
                and (IntegrationEntity."Last Modify Date Time" < UnitOfMeasure."Last Modified Date Time") then begin
                    tempUnitOfMeasure := UnitOfMeasure;
                    tempUnitOfMeasure.Insert();
                end;
            until UnitOfMeasure.Next() = 0;

        if tempUnitOfMeasure.FindSet(true) then
            repeat
                // create request body
                CreateRequestBodyToUoM(tempUnitOfMeasure.Code, jsonBody);
                entityTypePATCHValue := StrSubstNo(entityTypePATCH, GetUoMIdFromIntegrEntity(tempUnitOfMeasure.Code));
                // patch entity in 1C
                jsonBody.WriteTo(Body);
                if not ConnectTo1C(entityTypePATCHValue, requestMethodPATCH, Body, '') then
                    exit(false);
                UpdateDateTimeIntegrationEntity(lblSystemCode, Database::"Unit of Measure", tempUnitOfMeasure.Code, '');
            // Commit();
            until tempUnitOfMeasure.Next() = 0;

        exit(true);
    end;

    local procedure CreateRequestBodyToUoM(UnitOfMeasureCode: Code[10]; var Body: JsonObject)
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        UnitOfMeasure.Get(UnitOfMeasureCode);
        Clear(Body);
        Body.Add('Code', UnitOfMeasure."Numeric Code");
        Body.Add('Description', LowerCase(UnitOfMeasureCode));
        Body.Add('НаименованиеПолное', UnitOfMeasure.Description);
    end;

    local procedure AddIDToIntegrationEntity(SystemCode: Code[20]; tableID: Integer; Code1: Text[40]; Code2: Text[40]; entityID: Guid; entityCode: Text[40]; companyName: Text[30]);
    var
        IntegrationEntity: Record "Integration Entity";
        blankEntityID: Guid;
    begin
        if entityID = blankEntityID then exit;

        if IntegrationEntity.Get(SystemCode, tableID, Code1, Code2) then begin
            IntegrationEntity."Entity Id" := entityID;
            IntegrationEntity."Entity Code" := entityCode;
            IntegrationEntity."Company Name" := companyName;
            IntegrationEntity.Modify(true);
            exit;
        end;

        IntegrationEntity.Init();
        IntegrationEntity."System Code" := SystemCode;
        IntegrationEntity."Table ID" := tableID;
        IntegrationEntity."Code 1" := GuidToClearText(CopyStr(Code1, 1, MaxStrLen(IntegrationEntity."Code 1")));
        IntegrationEntity."Code 2" := Code2;
        IntegrationEntity."Entity Id" := entityID;
        IntegrationEntity."Entity Code" := entityCode;
        IntegrationEntity."Company Name" := companyName;
        IntegrationEntity.Insert(true);
        Commit();
    end;

    local procedure UpdateDateTimeIntegrationEntity(SystemCode: Code[20]; tableID: Integer; Code1: Text[40]; Code2: Text[40]);
    var
        IntegrationEntity: Record "Integration Entity";
    begin
        IntegrationEntity.Get(SystemCode, tableID, Code1, Code2);
        // IntegrationEntity."Last Modify Date Time" := CurrentDateTime;
        IntegrationEntity.Modify(true);
        Commit();
    end;

    procedure GetItemsIdFrom1C(): Boolean
    var
        entityType: Label 'Catalog_Номенклатура';
        entityTypePATCH: Label 'Catalog_Номенклатура(%1)';
        entityTypePATCHValue: Text;
        requestMethodGET: Label 'GET';
        requestMethodPOST: Label 'POST';
        requestMethodPATCH: Label 'PATCH';
        Body: Text;
        lblfilter: Label '&$filter=%1 eq ''%2''';
        filterValue: Text;
        lblSystemCode: Label '1C';
        Item: Record Item;
        tempItem: Record Item temporary;
        IntegrationEntity: Record "Integration Entity";
        ResponceTokenLine: Text;
        jsonLines: JsonArray;
        jsonBody: JsonObject;
        LineToken: JsonToken;
        ItemNo: Code[20];
    begin
        // create Items list for getting id from 1C
        if Item.FindSet(true) then
            repeat
                if not IntegrationEntity.Get(lblSystemCode, Database::Item, Item."No.", '') then begin
                    tempItem := Item;
                    tempItem.Insert();
                end;
            until Item.Next() = 0;

        if tempItem.FindSet(true) then
            repeat
                // get item by code from 1C
                filterValue := StrSubstNo(lblfilter, 'Code', tempItem."No.");
                if not ConnectTo1C(entityType, requestMethodGET, Body, filterValue) then
                    exit(false);
                jsonBody.ReadFrom(Body);
                jsonLines := WebServiceMgt.GetJSToken(jsonBody, 'value').AsArray();
                if jsonLines.Count <> 0 then begin
                    foreach LineToken in jsonLines do
                        AddIDToIntegrationEntity(lblSystemCode, Database::Item, tempItem."No.", '',
                                                    WebServiceMgt.GetJSToken(LineToken.AsObject(), 'Ref_Key').AsValue().AsText(),
                                                    tempItem."No.", CompanyName);

                    // patch item in 1C
                    CreateRequestBodyToItems(tempItem."No.", jsonBody);
                    entityTypePATCHValue := StrSubstNo(entityTypePATCH, GetItemIdFromIntegrEntity(tempItem."No."));
                    jsonBody.WriteTo(Body);
                    if not ConnectTo1C(entityTypePATCHValue, requestMethodPATCH, Body, '') then
                        exit(false);
                    UpdateDateTimeIntegrationEntity(lblSystemCode, Database::Item, tempItem."No.", '');
                end else begin
                    // request body for create Item in 1C
                    CreateRequestBodyToItems(tempItem."No.", jsonBody);
                    jsonBody.WriteTo(Body);
                    // get body from 1C
                    if not ConnectTo1C(entityType, requestMethodPOST, Body, '') then
                        exit(false);
                    jsonBody.ReadFrom(Body);
                    AddIDToIntegrationEntity(lblSystemCode, Database::Item, tempItem."No.", '',
                                                WebServiceMgt.GetJSToken(jsonBody, 'Ref_Key').AsValue().AsText(),
                                                tempItem."No.", CompanyName);
                end;
            // Commit();
            until tempItem.Next() = 0;

        // update entity in 1C
        // create Items list for updating in 1C
        tempItem.DeleteAll();
        if Item.FindSet(true) then
            repeat
                if IntegrationEntity.Get(lblSystemCode, Database::Item, Item."No.", '')
                and (IntegrationEntity."Last Modify Date Time" < Item."Last DateTime Modified") then begin
                    tempItem := Item;
                    tempItem.Insert();
                end;
            until Item.Next() = 0;

        if tempItem.FindSet(true) then
            repeat
                // create request body
                CreateRequestBodyToItems(tempItem."No.", jsonBody);
                entityTypePATCHValue := StrSubstNo(entityTypePATCH, GetItemIdFromIntegrEntity(tempItem."No."));
                // patch item in 1C
                jsonBody.WriteTo(Body);
                if not ConnectTo1C(entityTypePATCHValue, requestMethodPATCH, Body, filterValue) then
                    exit(false);
                UpdateDateTimeIntegrationEntity(lblSystemCode, Database::Item, tempItem."No.", '');
            // Commit();
            until tempItem.Next() = 0;

        exit(true);
    end;

    local procedure CreateRequestBodyToItems(ItemNo: Code[20]; var Body: JsonObject)
    var
        Items: Record Item;
    begin
        Items.Get(ItemNo);
        Clear(Body);
        Body.Add('Code', ItemNo);
        Body.Add('Description', Items.Description);
        Body.Add('НаименованиеПолное', Items."Description Print");
        Body.Add('Услуга', Items.Type = Items.Type::"Non-Inventory");
        Body.Add('СтавкаНДС', GetVAT(Items."VAT Bus. Posting Gr. (Price)", Items."VAT Prod. Posting Group"));
        if Items."Base Unit of Measure" <> '' then
            Body.Add('БазоваяЕдиницаИзмерения_Key', GetUoMIdFromIntegrEntity(Items."Base Unit of Measure"));
        Body.Add('ЕдиницыИзмерения', GetJsonItemUoM(ItemNo));
        Body.Add('DeletionMark', Items.Blocked);
    end;

    local procedure GetVAT(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]): Text[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        lblVAT20: Label 'НДС20';
        lblVAT7: Label 'НДС7';
        lblVAT0: Label 'НДС0';
        lblWithoutVAT: Label 'БезНДС';
        lblNotVAT: Label 'НеНДС';
    begin
        if not VATPostingSetup.Get(VATBusPostingGroup, VATProdPostingGroup) then exit('');
        case VATPostingSetup."VAT %" of
            0:
                begin
                    if VATPostingSetup."VAT Exempt" then
                        exit(lblWithoutVAT);
                    exit(lblVAT0);
                end;
            7:
                begin
                    exit(lblVAT7);
                end;
            20:
                begin
                    exit(lblVAT20);
                end;
        end;
    end;

    local procedure GetJsonItemUoM(ItemNo: Code[20]): JsonArray
    var
        ItemUoM: Record "Item Unit of Measure";
        jsonUoMLine: JsonObject;
        jsonUoMs: JsonArray;
        LineNo: Integer;
    begin
        ItemUoM.SetCurrentKey("Item No.");
        ItemUoM.SetRange("Item No.", ItemNo);
        ItemUoM.SetFilter(Code, '<>%1', '');
        if ItemUoM.FindSet(true) then begin
            Clear(jsonUoMs);
            LineNo := 0;
            repeat
                LineNo += 1;
                Clear(jsonUoMLine);
                jsonUoMLine.Add('LineNumber', LineNo);
                jsonUoMLine.Add('ЕдиницаИзмерения_Key', GetUoMIdFromIntegrEntity(ItemUoM.Code));
                jsonUoMLine.Add('Коэффициент', ItemUoM."Qty. per Unit of Measure");
                jsonUoMs.Add(jsonUoMLine);
            until ItemUoM.Next() = 0;
        end;
        exit(jsonUoMs);
    end;

    local procedure GetVendBankAccIdFromIntegrEntity(VendBankAccIBAN: Code[50]): Text
    var
        VendBankAcc: Record "Vendor Bank Account";
        VendNo: Code[20];
        IntegrEntity: Record "Integration Entity";
        lblSystemCode: Label '1C';
    begin
        if IntegrEntity.Get(lblSystemCode, Database::"Vendor Bank Account", VendBankAccIBAN, '') then
            exit(LowerCase(DelChr(IntegrEntity."Entity Id", '<>', '{}')));

        VendBankAcc.SetRange(IBAN, VendBankAccIBAN);
        VendBankAcc.FindFirst();
        VendNo := VendBankAcc."Vendor No.";
        VendBankAcc.Reset();
        VendBankAcc.SetRange("Vendor No.", VendNo);

        GetVendorBankAccountIdFrom1C(VendBankAcc);
        IntegrEntity.Get(lblSystemCode, Database::"Vendor Bank Account", VendBankAccIBAN, '');
        exit(LowerCase(DelChr(IntegrEntity."Entity Id", '<>', '{}')));
    end;

    local procedure GetCustBankAccIdFromIntegrEntity(CustBankAccIBAN: Code[50]; _CompanyName: Text[30]): Text
    var
        CustBankAcc: Record "Customer Bank Account";
        CustNo: Code[20];
        IntegrEntity: Record "Integration Entity";
        lblSystemCode: Label '1C';
    begin
        if IntegrEntity.Get(lblSystemCode, Database::"Customer Bank Account", CustBankAccIBAN, '') then
            exit(LowerCase(DelChr(IntegrEntity."Entity Id", '<>', '{}')));

        if CompanyName <> _CompanyName then
            CustBankAcc.ChangeCompany(_CompanyName);

        CustBankAcc.SetRange(IBAN, CustBankAccIBAN);
        CustBankAcc.FindFirst();
        CustNo := CustBankAcc."Customer No.";
        CustBankAcc.Reset();
        CustBankAcc.SetRange("Customer No.", CustNo);

        GetCustomerBankAccountIdFrom1C(CustBankAcc, _CompanyName);
        IntegrEntity.Get(lblSystemCode, Database::"Customer Bank Account", CustBankAccIBAN, '');
        exit(LowerCase(DelChr(IntegrEntity."Entity Id", '<>', '{}')));
    end;

    local procedure GetBankDirectoryIdFromIntegrEntity(BankDirectoryBIC: Code[9]; _CompanyName: Text[30]): Text
    var
        IntegrEntity: Record "Integration Entity";
        lblSystemCode: Label '1C';
    begin
        if IntegrEntity.Get(lblSystemCode, Database::"Bank Directory", BankDirectoryBIC, '') then
            exit(LowerCase(DelChr(IntegrEntity."Entity Id", '<>', '{}')));

        GetBankDirectoryIdFrom1C(_CompanyName);
        IntegrEntity.Get(lblSystemCode, Database::"Bank Directory", BankDirectoryBIC, '');
        exit(LowerCase(DelChr(IntegrEntity."Entity Id", '<>', '{}')));
    end;

    local procedure GetCustomerIdFromIntegrEntity(CustomerNo: Code[20]; _CompanyName: Text[30]): Text
    var
        IntegrEntity: Record "Integration Entity";
        Customer: Record Customer;
        lblSystemCode: Label '1C';
    begin
        if CompanyName <> _CompanyName then
            Customer.ChangeCompany(_CompanyName);

        Customer.Get(CustomerNo);
        if Customer."Init 1C" then
            IntegrEntity.Get(lblSystemCode, Database::Customer, GuidToClearText(Customer."BC Id"), '')
        else
            IntegrEntity.Get(lblSystemCode, Database::Customer, GuidToClearText(Customer."CRM ID"), '');
        exit(LowerCase(DelChr(IntegrEntity."Entity Id", '<>', '{}')));
    end;

    local procedure GetCurrencyIdFromIntegrEntity(CurrencyCode: Code[10]; _CompanyName: Text[30]): Text
    var
        IntegrEntity: Record "Integration Entity";
        Currency: Record Currency;
        lblSystemCode: Label '1C';
    begin
        if CompanyName <> _CompanyName then
            Currency.ChangeCompany(_CompanyName);

        Currency.Get(CurrencyCode);
        if IntegrEntity.Get(lblSystemCode, Database::Currency, Currency."ISO Numeric Code", '') then
            exit(LowerCase(DelChr(IntegrEntity."Entity Id", '<>', '{}')));

        GetCurrencyIdFrom1C(_CompanyName);
        IntegrEntity.Get(lblSystemCode, Database::Currency, Currency."ISO Numeric Code", '');
        exit(LowerCase(DelChr(IntegrEntity."Entity Id", '<>', '{}')));
    end;

    local procedure GetItemIdFromIntegrEntity(ItemNo: Code[20]): Text
    var
        IntegrEntity: Record "Integration Entity";
        lblSystemCode: Label '1C';
    begin
        IntegrEntity.Get(lblSystemCode, Database::Item, ItemNo, '');
        exit(LowerCase(DelChr(IntegrEntity."Entity Id", '<>', '{}')));
    end;

    local procedure GetUoMIdFromIntegrEntity(UoMCode: Code[10]): Text
    var
        UoM: Record "Unit of Measure";
        IntegrEntity: Record "Integration Entity";
        lblSystemCode: Label '1C';
    begin
        UoM.Get(UoMCode);
        if IntegrEntity.Get(lblSystemCode, Database::"Unit of Measure", UoM."Numeric Code", '') then begin
            exit(LowerCase(DelChr(IntegrEntity."Entity Id", '<>', '{}')));
        end;

        // create UoM in 1C
        GetUoMIdFrom1C();
        IntegrEntity.Get(lblSystemCode, Database::"Unit of Measure", UoM."Numeric Code", '');
        exit(LowerCase(DelChr(IntegrEntity."Entity Id", '<>', '{}')));
    end;

    local procedure VendorBankAccountExist(VendorNo: Code[20]): Boolean
    var
        VendBankAcc: Record "Vendor Bank Account";
    begin
        VendBankAcc.SetRange("Vendor No.", VendorNo);
        exit(not VendBankAcc.IsEmpty);
    end;

    local procedure CustomerBankAccountExist(CustomerNo: Code[20]; _CompanyName: Text[30]): Boolean
    var
        CustBankAcc: Record "Customer Bank Account";
    begin
        if CompanyName <> _CompanyName then
            CustBankAcc.ChangeCompany(_CompanyName);

        CustBankAcc.SetRange("Customer No.", CustomerNo);
        exit(not CustBankAcc.IsEmpty);
    end;

    local procedure CustomerAgreementExist(CustomerNo: Code[20]; _CompanyName: Text[30]): Boolean
    var
        CustAgreement: Record "Customer Agreement";
    begin
        if CompanyName <> _CompanyName then
            CustAgreement.ChangeCompany(_CompanyName);

        CustAgreement.SetRange("Customer No.", CustomerNo);
        exit(not CustAgreement.IsEmpty);
    end;

    local procedure IntegrationWith1CDisabled(): Boolean
    var
        CompanyIntegration: Record "Company Integration";
    begin
        CompanyIntegration.SetCurrentKey("Company Name", "Integration With 1C");
        CompanyIntegration.SetRange("Company Name", CompanyName);
        CompanyIntegration.SetRange("Integration With 1C", true);
        exit(CompanyIntegration.IsEmpty);
    end;

    local procedure AddCompanyIntegrationPrefix(_CompanyName: Text[30]; _Prefix: Code[10])
    var
        CompIntegr: Record "Company Integration";
    begin
        if _Prefix = '' then exit;
        CompIntegr.SetCurrentKey("Company Name");
        CompIntegr.SetRange("Company Name", _CompanyName);
        CompIntegr.ModifyAll(Prefix, _Prefix);
    end;

    local procedure GetCompanyPrefix(_CompanyName: Text[30])
    var
        CompIntegr: Record "Company Integration";
    begin
        CompIntegr.SetCurrentKey("Company Name");
        CompIntegr.SetRange("Company Name", _CompanyName);
        if CompIntegr.FindFirst() then begin
            glCompanyPrefix := CompIntegr.Prefix;
            exit;
        end;
        Clear(glCompanyPrefix);
    end;

    local procedure ItemCompanyFrom(): Boolean
    var
        CompIntegr: Record "Company Integration";
    begin
        CompIntegr.SetRange("Company Name", CompanyName);
        if CompIntegr.FindFirst() then
            exit(CompIntegr."Copy Items From");
        exit(false);
    end;

    procedure Get1CRoot()
    var
        entityType: Text;
        requestMethod: Label 'GET';
        Body: Text;
        filterValue: Text;
    begin
        ConnectTo1C(entityType, requestMethod, Body, filterValue);
    end;

    procedure ConnectTo1C(entityType: Text; requestMethod: Code[20]; var Body: Text; filterValue: Text): Boolean
    var
        Base64Convert: Codeunit "Base64 Convert";
        ClientId: Label 'Марина Кващук';
        ClientSecret: Label '888';
        ResourceTest: Label 'http://20.67.250.23/testdb/odata/standard.odata';
        ResourceProd: Label 'http://20.67.250.23/conf/odata/standard.odata';
        HttpClient: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        RequestHeader: HttpHeaders;
        webAPI_URL: Label '%1/%2?%3';
        Accept: Label 'application/json';
        ParameterAuthorization: Label 'Authorization';
        Authorization: Text;
        MethodGET: Label 'GET';
        MethodPOST: Label 'POST';
        MethodPATCH: Label 'PATCH';
        ContentType: Label 'Content-Type';
        ContentTypeFormUrlencoded: Label 'application/x-www-form-urlencoded';
        ParameterFormat: Label '$format';
        ParameterFormatValue: Label 'json';
        API_URL: Text;
        APIResult: Text;
        Basic: Label 'Basic %1';
        ClientIdSecretBase64: Label '%1:%2';
        ParameterBody: Label '%1=%2%3';
    begin
        if WebServiceMgt.GetResourceProductionNotAllowed() then
            API_URL := StrSubstNo(webAPI_URL, ResourceTest, entityType,
                            StrSubstNo(ParameterBody, ParameterFormat, ParameterFormatValue, filterValue))
        else
            API_URL := StrSubstNo(webAPI_URL, ResourceProd, entityType,
                            StrSubstNo(ParameterBody, ParameterFormat, ParameterFormatValue, filterValue));

        RequestMessage.Method := requestMethod;
        RequestMessage.SetRequestUri(API_URL);
        RequestMessage.GetHeaders(RequestHeader);
        Authorization := StrSubstNo(Basic,
                Base64Convert.ToBase64(StrSubstNo(ClientIdSecretBase64, ClientId, ClientSecret)));
        RequestHeader.Add(ParameterAuthorization, Authorization);

        if requestMethod in [MethodPOST, MethodPATCH] then begin
            RequestMessage.Content.WriteFrom(Body);
            RequestMessage.Content.GetHeaders(RequestHeader);
            RequestHeader.Remove(ContentType);
            RequestHeader.Add(ContentType, Accept);
        end;

        HttpClient.Send(RequestMessage, ResponseMessage);
        ResponseMessage.Content().ReadAs(APIResult);

        // Insert Operation to Log
        IntegrationLog.InsertOperationToLog('STANDART_1C_API', requestMethod, API_URL, '', Body, APIResult, ResponseMessage.IsSuccessStatusCode());
        // for testing
        // Message(APIResult);
        // response body
        Body := APIResult;

        exit(ResponseMessage.IsSuccessStatusCode);
    end;

    procedure UpdateBankDirectoryByCompany(newCompanyName: Text[20])
    var
        CustBankAccount: Record "Customer Bank Account";
        VendBankAccount: Record "Vendor Bank Account";
        BankDirectory: Record "Bank Directory";
    begin
        CustBankAccount.ChangeCompany(newCompanyName);
        VendBankAccount.ChangeCompany(newCompanyName);
        BankDirectory.ChangeCompany(newCompanyName);

        CustBankAccount.SetFilter(IBAN, '<>%1', '');
        if CustBankAccount.FindSet(true) then begin
            repeat
                if (CustBankAccount.BIC = '') then begin
                    if StrLen(CustBankAccount.IBAN) > 25 then begin
                        // create bank directory from iban
                        if not BankDirectory.Get(CopyStr(CustBankAccount.IBAN, 5, 6)) then begin
                            BankDirectory.Init();
                            BankDirectory.BIC := CopyStr(CustBankAccount.IBAN, 5, 6);
                            BankDirectory.Insert();
                        end;
                        CustBankAccount.BIC := BankDirectory.BIC;
                        CustBankAccount.Modify();
                    end;
                end else begin
                    if not BankDirectory.Get(CustBankAccount.BIC) then begin
                        BankDirectory.Init();
                        BankDirectory.BIC := CustBankAccount.BIC;
                        BankDirectory.Insert();
                    end;
                end;

            until CustBankAccount.Next() = 0;
        end;

        VendBankAccount.SetFilter(IBAN, '<>%1', '');
        if VendBankAccount.FindSet(true) then begin
            repeat
                if (VendBankAccount.BIC = '') then begin
                    if StrLen(VendBankAccount.IBAN) > 25 then begin
                        // create bank directory from iban
                        if not BankDirectory.Get(CopyStr(VendBankAccount.IBAN, 5, 6)) then begin
                            BankDirectory.Init();
                            BankDirectory.BIC := CopyStr(VendBankAccount.IBAN, 5, 6);
                            BankDirectory.Insert();
                        end;
                        VendBankAccount.BIC := BankDirectory.BIC;
                        VendBankAccount.Modify();
                    end;
                end else begin
                    if not BankDirectory.Get(VendBankAccount.BIC) then begin
                        BankDirectory.Init();
                        BankDirectory.BIC := VendBankAccount.BIC;
                        BankDirectory.Insert();
                    end;
                end;

            until VendBankAccount.Next() = 0;
        end;
    end;

    local procedure GetSRSetup(_CompanyName: Text[30])
    begin
        if _CompanyName <> CompanyName then
            SRSetup.ChangeCompany(_CompanyName);

        if not SRSetup.Get() then begin
            SRSetup.Init();
            SRSetup.Insert();
        end;
    end;

    procedure GetVendorAgreementIdFrom1C(VendorAgreement: Record "Vendor Agreement"; _CompanyName: Text[30]): Boolean
    var
        entityType: Label 'Catalog_ДоговорыКонтрагентов';
        entityTypePATCH: Label 'Catalog_ДоговорыКонтрагентов(%1)';
        entityTypePATCHValue: Text;
        requestMethodGET: Label 'GET';
        requestMethodPOST: Label 'POST';
        requestMethodPATCH: Label 'PATCH';
        Body: Text;
        filterValue: Text;
        lblfilter: Label '&$filter=%1 eq ''%2''';
        lblSystemCode: Label '1C';
        tempVendorAgreement: Record "Vendor Agreement" temporary;
        Vendor: Record Vendor;
        IntegrationEntity: Record "Integration Entity";
        ResponceTokenLine: Text;
        jsonLines: JsonArray;
        jsonBody: JsonObject;
        LineToken: JsonToken;
        codeISO: Code[10];
        blankGuid: Guid;
        locVendorAgreement: Record "Vendor Agreement";
    begin
        if CompanyName <> _CompanyName then begin
            locVendorAgreement.ChangeCompany(_CompanyName);
            locVendorAgreement.SetFilter("Vendor No.", VendorAgreement.GetFilter("Vendor No."));
            Vendor.ChangeCompany(_CompanyName);
        end;
        tempVendorAgreement.DeleteAll();

        // create Currency list for getting id from 1C
        if locVendorAgreement.FindSet(true) then
            repeat
                if not IntegrationEntity.Get(lblSystemCode, Database::"Vendor Agreement", GuidToClearText(locVendorAgreement.SystemId), '') then begin
                    tempVendorAgreement := locVendorAgreement;
                    tempVendorAgreement.Insert();
                end;
            until locVendorAgreement.Next() = 0;

        // link between 1C and BC
        // create entity in 1C or get it
        if tempVendorAgreement.FindSet(true) then
            repeat
                filterValue := StrSubstNo(lblfilter, 'CRM_ID', GuidToClearText(tempVendorAgreement.SystemId));
                if not ConnectTo1C(entityType, requestMethodGET, Body, filterValue) then exit(false);
                jsonBody.ReadFrom(Body);
                jsonLines := WebServiceMgt.GetJSToken(jsonBody, 'value').AsArray();
                if jsonLines.Count <> 0 then begin
                    foreach LineToken in jsonLines do
                        AddIDToIntegrationEntity(lblSystemCode, Database::"Vendor Agreement", GuidToClearText(tempVendorAgreement.SystemId),
                                                    '',
                                                    WebServiceMgt.GetJSToken(LineToken.AsObject(), 'Ref_Key').AsValue().AsText(),
                                                    tempVendorAgreement."No.", _CompanyName);
                end else begin
                    // create request body
                    CreateRequestBodyToVendorAgreement(tempVendorAgreement."Vendor No.", tempVendorAgreement."No.", jsonBody, requestMethodPATCH, _CompanyName);
                    // get body from 1C
                    jsonBody.WriteTo(Body);
                    if not ConnectTo1C(entityType, requestMethodPOST, Body, '') then exit(false);
                    jsonBody.ReadFrom(Body);
                    AddIDToIntegrationEntity(lblSystemCode, Database::"Vendor Agreement", GuidToClearText(tempVendorAgreement.SystemId),
                                                '',
                                                WebServiceMgt.GetJSToken(jsonBody, 'Ref_Key').AsValue().AsText(),
                                                tempVendorAgreement."No.", _CompanyName);
                end;
            // Commit();
            until tempVendorAgreement.Next() = 0;

        // update entity in 1C
        // create list for updating in 1C
        tempVendorAgreement.DeleteAll();
        if locVendorAgreement.FindSet(true) then
            repeat
                if IntegrationEntity.Get(lblSystemCode, Database::"Vendor Agreement", GuidToClearText(locVendorAgreement.SystemId), '')
                                and (IntegrationEntity."Last Modify Date Time" < locVendorAgreement."Last DateTime Modified")
                                then begin
                    tempVendorAgreement := locVendorAgreement;
                    tempVendorAgreement.Insert();
                end;

            until locVendorAgreement.Next() = 0;

        if tempVendorAgreement.FindSet(true) then
            repeat
                // create request body
                CreateRequestBodyToVendorAgreement(tempVendorAgreement."Vendor No.", tempVendorAgreement."No.", jsonBody, requestMethodPATCH, _CompanyName);
                entityTypePATCHValue := StrSubstNo(entityTypePATCH, GetVendorAgreementIdFromIntegrEntity(tempVendorAgreement.SystemId, _CompanyName));
                // patch entity in 1C
                jsonBody.WriteTo(Body);
                if not ConnectTo1C(entityTypePATCHValue, requestMethodPATCH, Body, '') then
                    exit(false);
                UpdateDateTimeIntegrationEntity(lblSystemCode, Database::"Vendor Agreement", GuidToClearText(tempVendorAgreement.SystemId), '');
            // Commit();
            until tempVendorAgreement.Next() = 0;

        exit(true);
    end;

    local procedure GetVendorAgreementIdFromIntegrEntity(VendorAgreementID: Guid; _CompanyName: Text[30]): Text[50]
    var
        IntegrEntity: Record "Integration Entity";
        lblSystemCode: Label '1C';
        BlankGuid: Guid;
        Code2: Text[40];
    begin
        IntegrEntity.Get(lblSystemCode, Database::"Vendor Agreement", GuidToClearText(VendorAgreementID), '');
        exit(GuidToClearText(IntegrEntity."Entity Id"));
    end;

    local procedure CreateRequestBodyToVendorAgreement(VendorNo: Code[20]; AgreementNo: Code[20]; var Body: JsonObject;
                                                        requestMethod: Text[10]; _CompanyName: Text[30])
    var
        VendorAgreement: Record "Vendor Agreement";
        lblPaymentView: Label 'ПоДоговоруВЦелом';
        lblPaymentViewVAT: Label 'ПоДоговоруВЦелом';
        lblAgreementView: Label 'СПоставщиком';
        lblSchemaPostingVAT: Label 'fee33cc5-2cab-11ea-acf7-545049000031';
        lblSchemaPostingVATTara: Label 'fee33cc5-2cab-11ea-acf7-545049000031';
    begin
        if CompanyName <> _CompanyName then
            VendorAgreement.ChangeCompany(_CompanyName);

        VendorAgreement.Get(VendorNo, AgreementNo);
        Clear(Body);
        Body.Add('Номер', VendorAgreement."External Agreement No.");
        Body.Add('Description', VendorAgreement."No.");
        Body.Add('Дата', VendorAgreement."Starting Date");
        Body.Add('СрокДействия', VendorAgreement."Expire Date");
        Body.Add('ВедениеВзаиморасчетов', lblPaymentView);
        Body.Add('ВедениеВзаиморасчетовНУ', lblPaymentViewVAT);
        Body.Add('ВидДоговора', lblAgreementView);
        if requestMethod = 'PATCH' then
            Body.Add('Owner_Key', GetVendorIdFromIntegrEntity(VendorNo));
        Body.Add('ВалютаВзаиморасчетов_Key', GetCurrencyIdFromIntegrEntity(VendorAgreement."Currency Code", _CompanyName));
        Body.Add('Организация_Key', GetCompanyIdFromIntegrEntity(_CompanyName));
        Body.Add('СхемаНалоговогоУчета_Key', lblSchemaPostingVAT);
        Body.Add('СхемаНалоговогоУчетаПоТаре_Key', lblSchemaPostingVATTara);
        Body.Add('DeletionMark', not VendorAgreement.Active);
        // Body.Add('НаименованиеДляПечати', CustomerAgreement."External Agreement No.");
        Body.Add('CRM_ID', GuidToClearText(VendorAgreement.SystemId))

    end;

    local procedure GetVendorIdFromIntegrEntity(VendorNo: Code[20]): Text
    var
        IntegrEntity: Record "Integration Entity";
        lblSystemCode: Label '1C';
    begin
        IntegrEntity.Get(lblSystemCode, Database::Vendor, VendorNo, '');
        exit(LowerCase(DelChr(IntegrEntity."Entity Id", '<>', '{}')));
    end;

    procedure InitTest(initTest: Boolean)
    begin
        TestMode := initTest;
    end;

    procedure Guid2APIStr(_Guid: Guid): Text
    begin
        exit(Format(_Guid, 36, 4));
    end;

    procedure Date2APIStr(_Date: Date): Text
    begin
        exit(Format(_Date, 10, 9));
    end;

    procedure DateTime2APIStr(_Date: DateTime): Text
    begin
        exit(Format(_Date, 24, 9));
    end;
}