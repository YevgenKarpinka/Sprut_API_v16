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

    [EventSubscriber(ObjectType::Table, 23, 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertEventVendor(var Rec: Record Vendor)
    begin
        // check main company
        if CheckMainCompany() then exit;
        if Rec.IsTemporary then exit;
        if CheckVendorFieldsFilled(Rec) then
            AddEntityToCopy(entityType::Vendor, Rec."No.");
    end;

    [EventSubscriber(ObjectType::Table, 23, 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyEventVendor(var Rec: Record Vendor)
    begin
        // check main company
        if CheckMainCompany() then exit;
        if Rec.IsTemporary then exit;
        if CheckVendorFieldsFilled(Rec) then
            AddEntityToCopy(entityType::Vendor, Rec."No.");
    end;

    local procedure CheckVendorFieldsFilled(Rec: Record Vendor): Boolean
    begin
        if Rec."No." = '' then exit(false);
        if Rec.Name = '' then exit(false);
        if Rec."OKPO Code" = '' then exit(false);
        if Rec."Prices Including VAT" = false then exit(false);
        if Rec."Gen. Bus. Posting Group" = '' then exit(false);
        if Rec."Vendor Posting Group" = '' then exit(false);
        if Rec."VAT Bus. Posting Group" = '' then exit(false);
        if Rec."Currency Code" = '' then exit(false);

        exit(true);
    end;

    local procedure AddEntityToCopy(Type: Enum EntityType; EntityNo: Code[20])
    var
        ItemToCopy: Record "Entity To Copy";
    begin
        if ItemToCopy.Get(Type, EntityNo) then exit;
        ItemToCopy.Init();
        ItemToCopy.Type := Type;
        ItemToCopy.Validate("No.", EntityNo);
        ItemToCopy.Insert();
    end;

    [EventSubscriber(ObjectType::Table, 27, 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertEventItem(var Rec: Record Item)
    begin
        // check main company
        if CheckMainCompany() then exit;
        if Rec.IsTemporary then exit;
        if CheckItemFieldsFilled(Rec) then
            AddEntityToCopy(entityType::Item, Rec."No.");
    end;

    [EventSubscriber(ObjectType::Table, 27, 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyEventItem(var Rec: Record Item)
    begin
        // check main company
        if CheckMainCompany() then exit;
        if Rec.IsTemporary then exit;
        if CheckItemFieldsFilled(Rec) then
            AddEntityToCopy(entityType::Item, Rec."No.");
    end;

    procedure CheckItemFieldsFilled(Rec: Record Item): Boolean
    begin
        if Rec."No." = '' then exit(false);
        if Rec.Description = '' then exit(false);
        if Rec."Base Unit of Measure" = '' then exit(false);
        // if Rec."CRM Item Id" = blankGuid then exit(false);
        if Rec.IsInventoriableType() then
            if Rec."Inventory Posting Group" = '' then exit(false);
        if Rec."VAT Prod. Posting Group" = '' then exit(false);
        if Rec."Gen. Prod. Posting Group" = '' then exit(false);
        if Rec."Sales Unit of Measure" = '' then exit(false);
        if Rec."Purch. Unit of Measure" = '' then exit(false);

        exit(true);
    end;

    procedure GetErrorFillingItem(Rec: Record Item)
    begin
        Rec.TestField("No.");
        Rec.TestField(Description);
        Rec.TestField("Base Unit of Measure");
        if Rec.IsInventoriableType() then
            Rec.TestField("Inventory Posting Group");
        Rec.TestField("VAT Prod. Posting Group");
        Rec.TestField("Gen. Prod. Posting Group");
        Rec.TestField("Sales Unit of Measure");
        Rec.TestField("Purch. Unit of Measure");
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
        blankGuid: Guid;
    begin
        ItemToCopy.SetRange(Type, ItemToCopy.Type::Customer);
        if ItemToCopy.IsEmpty then exit;
        ItemToCopy.FindSet();
        repeat
            tempItemToCopy := ItemToCopy;
            tempItemToCopy.Insert();
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
                        CustomerFrom.Get(tempItemToCopy."No.");
                        ConfProgressBar.Update(StrSubstNo(txtProcessHeader, CustomerFrom."No."));

                        CustomerTo.SetCurrentKey("BC Id");
                        CustomerTo.SetRange("BC Id", CustomerFrom."BC Id");
                        // CustomerTo.SetCurrentKey(Name);
                        // CustomerTo.SetRange(Name, CustomerFrom.Name);
                        if CustomerTo.FindFirst() then begin
                            CustomerTo.TransferFields(CustomerFrom, false);
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

    procedure CopyAllItemsToClone()
    var
        Item: Record Item;
    begin
        if UserId <> 'EKAR' then exit;
        if Item.FindSet() then
            repeat
                if CheckItemFieldsFilled(Item) then
                    AddEntityToCopy(entityType::Item, Item."No.");
            until Item.Next() = 0;
    end;

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
}