codeunit 50008 "Copy Items to All Companies"
{
    trigger OnRun()
    begin
        // check main company
        if CheckMainCompany() then exit;

        sentToCRM := false;
        if GuiAllowed then begin
            if Confirm(qstSendItemsToCRM, false) then begin
                // Send Items to CRM
                SendItemToCRM();
                sentToCRM := true;
            end;
        end else
            SendItemToCRM();

        // Copy Item From Main Company
        CopyItemFromMainCompany();

        // Delete Copied Items
        DeleteItemsAfterCopy();
    end;

    [EventSubscriber(ObjectType::Table, 23, 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertEventVendor(var Rec: Record Vendor)
    begin
        if CheckVendorFieldsFilled(Rec) then
            AddEntityToCopy(entityType::Vendor, Rec."No.");
    end;

    [EventSubscriber(ObjectType::Table, 23, 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyEventVendor(var Rec: Record Vendor)
    begin
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
        if CheckItemFieldsFilled(Rec) then
            AddEntityToCopy(entityType::Item, Rec."No.");
    end;

    [EventSubscriber(ObjectType::Table, 27, 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyEventItem(var Rec: Record Item)
    begin
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

    local procedure CopyItemFromMainCompany()
    var
        CompIntegrTo: Record "Company Integration";
        ItemToCopy: Record "Entity To Copy";
        ItemFrom: Record Item;
        ItemTo: Record Item;
        ItemUoMFrom: Record "Item Unit of Measure";
        ItemUoMTo: Record "Item Unit of Measure";
        UoMFrom: Record "Unit of Measure";
        UoMTo: Record "Unit of Measure";
        DaleteAllFlag: Boolean;
        blankGuid: Guid;
    begin
        ItemToCopy.SetRange(Type, ItemToCopy.Type::Item);
        if ItemToCopy.IsEmpty then exit;

        CompIntegrTo.SetCurrentKey("Copy Items To");
        CompIntegrTo.SetRange("Copy Items To", true);
        if CompIntegrTo.IsEmpty then exit;

        if CompIntegrTo.FindSet() then
            repeat
                ItemTo.ChangeCompany(CompIntegrTo."Company Name");
                ItemUoMTo.ChangeCompany(CompIntegrTo."Company Name");
                ConfProgressBar.Init(0, 0, StrSubstNo(txtCopyItemToCompany,
                                                            CompanyName,
                                                            CompIntegrTo."Company Name"));


                if ItemToCopy.FindSet() then
                    repeat
                        ItemFrom.Get(ItemToCopy."No.");
                        ConfProgressBar.Update(StrSubstNo(txtProcessHeader, ItemFrom."No."));
                        ItemTo.SetRange("No.", ItemFrom."No.");
                        // copy UoM before Items
                        UoMTo.ChangeCompany(CompIntegrTo."Company Name");
                        if UoMFrom.FindSet() then
                            repeat
                                if not UoMTo.Get(UoMFrom.Code)
                                or (UoMTo."Last Modified Date Time" < UoMFrom."Last Modified Date Time") then begin
                                    UoMTo := UoMFrom;
                                    if not UoMTo.Insert() then UoMTo.Modify();
                                end;
                            until UoMFrom.Next() = 0;

                        if not ItemTo.FindFirst() then begin
                            if ItemFrom."Sales Unit of Measure" <> '' then begin

                                ItemUoMTo.SetRange("Item No.", ItemFrom."No.");
                                ItemUoMTo.DeleteAll();

                                ItemUoMFrom.SetRange("Item No.", ItemFrom."No.");
                                ItemUoMFrom.FindSet();
                                repeat
                                    ItemUoMTo := ItemUoMFrom;
                                    ItemUoMTo.Insert();
                                until ItemUoMFrom.Next() = 0;
                            end;

                            ItemTo := ItemFrom;
                            ItemTo.Insert();
                        end else begin
                            if (ItemFrom."Last DateTime Modified" <> ItemTo."Last DateTime Modified") then begin
                                if (ItemFrom."Sales Unit of Measure" <> '')
                                    and not ItemUoMTo.Get(ItemFrom."No.", ItemFrom."Sales Unit of Measure") then begin

                                    ItemUoMTo.SetRange("Item No.", ItemFrom."No.");
                                    ItemUoMTo.DeleteAll();

                                    ItemUoMFrom.SetRange("Item No.", ItemFrom."No.");
                                    ItemUoMFrom.FindSet();
                                    repeat
                                        ItemUoMTo := ItemUoMFrom;
                                        ItemUoMTo.Insert();
                                    until ItemUoMFrom.Next() = 0;
                                end;

                                ItemTo.TransferFields(ItemFrom, false);
                                ItemTo.Modify();
                            end;
                        end;
                    // Commit();

                    until ItemToCopy.Next() = 0;
            until CompIntegrTo.Next() = 0;

        ConfProgressBar.Close();
    end;

    local procedure DeleteItemsAfterCopy()
    var
        ItemToCopy: Record "Entity To Copy";
    begin
        ItemToCopy.SetRange(Type, ItemToCopy.Type::Item);
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

    var
        CompIntegrFrom: Record "Company Integration";
        ConfProgressBar: Codeunit "Config Progress Bar";
        WebServiceMgt: Codeunit "Web Service Mgt.";
        txtCopyItemToCompany: TextConst ENU = 'From Company %1 To Company %2',
                                        RUS = 'С Организации %1 в Организацию %2';
        txtProcessHeader: TextConst ENU = 'Copy Item %1',
                                    RUS = 'Копирование товара %1';
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
}