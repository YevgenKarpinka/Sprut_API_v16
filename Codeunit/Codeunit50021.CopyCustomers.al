codeunit 50021 "Copy Customers"
{
    trigger OnRun()
    begin
        // check main company
        if CheckMainCompany() then exit;

        // Copy Item From Main Company
        CopyCustomerFromMainCompany();

        // Delete Copied Items
        DeleteItemsAfterCopy();
    end;

    var
        glCustomerAgr: Record "Customer Agreement";
        CaptionMgt: Codeunit "Caption Mgt.";
        CompIntegrFrom: Record "Company Integration";
        ConfProgressBar: Codeunit "Config Progress Bar";
        WebServiceMgt: Codeunit "Web Service Mgt.";
        txtCopyItemToCompany: TextConst ENU = 'From Company %1 To Company %2',
                                        RUS = 'С Организации %1 в Организацию %2';
        txtProcessHeader: TextConst ENU = 'Copy CustomerTo %1',
                                    RUS = 'Копирование клиента %1';
        blankGuid: Guid;
        entityType: Enum EntityType;
        Base64Convert: Codeunit "Base64 Convert";

        qstSendItemsToCRM: TextConst ENU = 'Send Items To CRM?', RUS = 'Отправлять товары в CRM?';
        ApplyingURLMsg: TextConst ENU = 'Sending Table %1',
                                RUS = 'Пересылается таблица %1';
        RecordsXofYMsg: TextConst ENU = 'Records: %1 of %2',
                                RUS = 'Запись: %1 из %2';
        sentToCRM: Boolean;
        ConfigProgressBarRecord: Codeunit "Config Progress Bar";
        Text007: Label 'You cannot assign numbers greater than %1 from the number series %2.';
        CopyItemsToAllCompanies: Codeunit "Copy Items to All Companies";

    [EventSubscriber(ObjectType::Codeunit, 5150, 'OnGetIntegrationDisabled', '', false, false)]
    local procedure OnGetIntegrationDisabled(var IsSyncDisabled: Boolean)
    var
        locCompIntegr: Record "Company Integration";
    begin
        locCompIntegr.SetCurrentKey("Company Name");
        locCompIntegr.SetRange("Company Name", CompanyName);
        if locCompIntegr.FindFirst() then
            IsSyncDisabled := locCompIntegr."Copy Items From";
    end;

    local procedure CheckMainCompany(): Boolean
    begin
        CompIntegrFrom.Reset();
        CompIntegrFrom.SetCurrentKey("Company Name", "Copy Items From");
        CompIntegrFrom.SetRange("Company Name", CompanyName);
        CompIntegrFrom.SetRange("Copy Items From", true);
        exit(CompIntegrFrom.IsEmpty);
    end;

    local procedure CopyCustomerFromMainCompany()
    var
        CompIntegrTo: Record "Company Integration";
        ItemToCopy: Record "Entity To Copy";
        tempItemToCopy: Record "Entity To Copy" temporary;
        CustomerFrom: Record Customer;
        CustomerTo: Record Customer;
        CustomerBankAccountFrom: Record "Customer Bank Account";
        CustomerBankAccountTo: Record "Customer Bank Account";
        DaleteAllFlag: Boolean;
        currentGuid: Guid;
    begin
        ItemToCopy.SetRange(Type, ItemToCopy.Type::Customer);
        if ItemToCopy.IsEmpty then exit;
        ItemToCopy.FindSet();
        repeat
            if CustomerFrom.Get(ItemToCopy."No.")
            and CopyItemsToAllCompanies.CheckCustomerFieldsFilled(CustomerFrom) then begin
                tempItemToCopy := ItemToCopy;
                tempItemToCopy.Insert();
            end;
        until ItemToCopy.Next() = 0;


        CompIntegrTo.SetCurrentKey("Copy Items To");
        CompIntegrTo.SetRange("Copy Items To", true);
        if CompIntegrTo.IsEmpty then exit;

        if CompIntegrTo.FindSet() then
            repeat
                CustomerTo.ChangeCompany(CompIntegrTo."Company Name");
                CustomerBankAccountTo.ChangeCompany(CompIntegrTo."Company Name");
                ConfProgressBar.Init(0, 0, StrSubstNo(txtCopyItemToCompany,
                                                            CompanyName,
                                                            CompIntegrTo."Company Name"));

                if tempItemToCopy.FindSet() then
                    repeat
                        ConfProgressBar.Update(StrSubstNo(txtProcessHeader, CustomerFrom."No."));

                        CustomerTo.SetCurrentKey("BC Id");
                        CustomerTo.SetRange("BC Id", CustomerFrom."BC Id");
                        // CustomerTo.SetCurrentKey(Name);
                        // CustomerTo.SetRange(Name, CustomerFrom.Name);
                        Clear(currentGuid);
                        if CustomerTo.FindFirst() then begin
                            if not IsNullGuid(CustomerTo."BC Id") then
                                currentGuid := CustomerTo."BC Id";
                            CustomerTo.TransferFields(CustomerFrom, false);
                            if not IsNullGuid(currentGuid) then
                                CustomerTo."BC Id" := currentGuid
                            else
                                CustomerTo."BC Id" := CustomerFrom.SystemId;
                            CustomerTo.Modify();
                        end else begin
                            CustomerTo.Init();
                            CustomerTo := CustomerFrom;
                            CustomerTo."No." := GetNextCustomerNoByCompany(CompIntegrTo."Company Name");
                            CustomerTo.Insert();
                        end;

                        CustomerBankAccountFrom.SetRange("Customer No.", CustomerFrom."No.");
                        if CustomerBankAccountFrom.FindSet(false, false) then
                            repeat
                                CustomerBankAccountTo := CustomerBankAccountFrom;
                                if CustomerBankAccountTo.Insert() then CustomerBankAccountTo.Modify();
                            until CustomerBankAccountFrom.Next() = 0;
                    until tempItemToCopy.Next() = 0;
                Commit();
            until CompIntegrTo.Next() = 0;

        ConfProgressBar.Close();
    end;

    local procedure GetNextCustomerNoByCompany(_companyName: Text[30]): Code[20]
    var
        SalesSetup: Record "Sales & Receivables Setup";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        if CompanyName <> _companyName then begin
            SalesSetup.ChangeCompany(_companyName);
            NoSeries.ChangeCompany(_companyName);
            NoSeriesLine.ChangeCompany(_companyName);
        end;

        SalesSetup.Get();
        SalesSetup.TestField("Customer Nos.");
        NoSeries.Get(SalesSetup."Customer Nos.");

        NoSeriesLine.SetCurrentKey("Series Code", "Starting Date");
        NoSeriesLine.SetRange("Series Code", NoSeries.Code);
        NoSeriesLine.SetRange("Starting Date", 0D, WorkDate);
        if NoSeriesLine.FindLast() then begin
            NoSeriesLine.SetRange("Starting Date", NoSeriesLine."Starting Date");
            NoSeriesLine.SetRange(Open, true);
        end;

        NoSeriesLine."Last No. Used" := IncStr(NoSeriesLine."Last No. Used");

        if (NoSeriesLine."Ending No." <> '') and
           (NoSeriesLine."Last No. Used" > NoSeriesLine."Ending No.") then
            Error(Text007, NoSeriesLine."Ending No.", NoSeries.Code);

        NoSeriesLine.Modify;

        exit(NoSeriesLine."Last No. Used");
    end;

    local procedure DeleteItemsAfterCopy()
    var
        ItemToCopy: Record "Entity To Copy";
    begin
        ItemToCopy.SetRange(Type, ItemToCopy.Type::Customer);
        if ItemToCopy.IsEmpty then exit;
        ItemToCopy.DeleteAll();
    end;

    procedure SendItemToCRM()
    var
        _Item: Record Item;
        _jsonItem: JsonObject;
        _jsonToken: JsonToken;
        _jsonText: Text;
        responseText: Text;
        connectorCode: Label 'CRM';
        entityType: Label 'products';
        POSTrequestMethod: Label 'POST';
        PATCHrequestMethod: Label 'PATCH';
        TokenType: Text;
        AccessToken: Text;
        APIResult: Text;
        requestMethod: Text[20];
        entityTypeValue: Text;
        ItemToCopy: Record "Entity To Copy";
        TotalCount: Integer;
        Counter: Integer;
    begin
        ItemToCopy.SetRange(Type, ItemToCopy.Type::Item);
        if ItemToCopy.IsEmpty then exit;
        WebServiceMgt.GetOauthToken(TokenType, AccessToken, APIResult);

        TotalCount := ItemToCopy.Count;
        ConfigProgressBarRecord.Init(TotalCount, Counter, STRSUBSTNO(ApplyingURLMsg, ItemToCopy.TableCaption));

        if ItemToCopy.FindSet() then begin
            repeat
                _Item.Get(ItemToCopy."No.");
                // Create JSON for CRM
                if not IsNullGuid(_Item."CRM Item Id") then begin
                    requestMethod := PATCHrequestMethod;
                    _jsonItem := WebServiceMgt.jsonItemsToPatch(_Item."No.");
                    entityTypeValue := StrSubstNo('%1(%2)', entityType, LowerCase(DelChr(_Item."CRM Item Id", '<>', '{}')));
                end else begin
                    requestMethod := POSTrequestMethod;
                    _jsonItem := WebServiceMgt.jsonItemsToPost(_Item."No.");
                    entityTypeValue := entityType;
                end;

                _jsonItem.WriteTo(_jsonText);
                Counter += 1;
                ConfigProgressBarRecord.Update(STRSUBSTNO(RecordsXofYMsg, Counter, TotalCount));

                // try send to CRM
                if WebServiceMgt.CreateProductInCRM(entityTypeValue, requestMethod, TokenType, AccessToken, _jsonText) then
                    WebServiceMgt.AddCRMproductIdToItem(_jsonText)
                else begin
                    // TempBlob._jsonText
                    // _jsonText
                end;
            until ItemToCopy.Next() = 0;
            ConfigProgressBarRecord.Close;
        end;
    end;

    // procedure CopyAllItemsToClone()
    // var
    //     Item: Record Item;
    // begin
    //     if UserId <> 'EKAR' then exit;
    //     if Item.FindSet() then
    //         repeat
    //             if CheckItemFieldsFilled(Item) then
    //                 AddEntityToCopy(entityType::Item, Item."No.");
    //         until Item.Next() = 0;
    // end;

    procedure InitSentToCRM(newSentToCRM: Boolean)
    begin
        sentToCRM := newSentToCRM;
    end;

    procedure FillBCIDAllCustomers()
    var
        locCustomer: Record Customer;
    begin
        CaptionMgt.CheckModifyAllowed();

        locCustomer.SetCurrentKey("CRM ID");
        locCustomer.SetRange("CRM ID", blankGuid);
        locCustomer.SetRange("BC Id", blankGuid);
        if locCustomer.FindSet() then
            repeat
                locCustomer."BC Id" := locCustomer.SystemId;
                locCustomer.Modify();
            until locCustomer.Next() = 0;

    end;

    procedure FillBCIDAllCustomerAgreements()
    var
        locCustomerAgreement: Record "Customer Agreement";
    begin
        // CaptionMgt.CheckModifyAllowed();

        locCustomerAgreement.SetCurrentKey("Init 1C", "BC Id");
        locCustomerAgreement.SetRange("Init 1C", true);
        locCustomerAgreement.SetRange("BC Id", blankGuid);
        if locCustomerAgreement.FindSet() then
            repeat
                // to do refill crm id in 1C from bc id

                // 
                locCustomerAgreement."BC Id" := locCustomerAgreement.SystemId;
                locCustomerAgreement.Modify();
            until locCustomerAgreement.Next() = 0;

    end;

    procedure GetAgreements(CustNo: Code[20]): Text
    var
        txtCustAgr: Text;
    begin
        glCustomerAgr.Reset();
        glCustomerAgr.SetRange("Customer No.", CustNo);
        if glCustomerAgr.FindSet() then
            repeat
                txtCustAgr += glCustomerAgr."External Agreement No." + '; ';
            until glCustomerAgr.Next() = 0;

        exit(txtCustAgr);
    end;
}