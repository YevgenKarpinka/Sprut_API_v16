codeunit 50008 "Copy Items to All Companies"
{
    trigger OnRun()
    begin
        // check main company
        if CheckMainCompany() then exit;

        // Copy Item From Main Company
        CopyItemFromMainCompany();

    end;

    // [EventSubscriber(ObjectType::Table, 23, 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertEventVendor(var Rec: Record Vendor)
    begin
        if CheckVendorFieldsFilled(Rec) then
            AddEntityToCopy(entityType::Vendor, Rec."No.");
    end;

    // [EventSubscriber(ObjectType::Table, 23, 'OnAfterModifyEvent', '', false, false)]
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

    local procedure AddEntityToCopy(Type: Enum "Entity Type"; VendorNo: Code[20])
    var
        ItemToCopy: Record "Item To Copy";
    begin
        ItemToCopy.Init();
        ItemToCopy."No." := VendorNo;
        ItemToCopy.Type := Type::Vendor;
        ItemToCopy.Insert();
    end;

    // [EventSubscriber(ObjectType::Table, 27, 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertEventItem(var Rec: Record Item)
    begin
        if CheckItemFieldsFilled(Rec) then
            AddEntityToCopy(entityType::Item, Rec."No.");
    end;

    // [EventSubscriber(ObjectType::Table, 27, 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyEventItem(var Rec: Record Item)
    begin
        if CheckItemFieldsFilled(Rec) then
            AddEntityToCopy(entityType::Item, Rec."No.");
    end;

    local procedure CheckItemFieldsFilled(Rec: Record Item): Boolean
    begin
        if Rec."No." = '' then exit(false);
        if Rec.Description = '' then exit(false);
        if Rec."Base Unit of Measure" = '' then exit(false);
        if Rec."CRM Item Id" = blankGuid then exit(false);
        if Rec."Inventory Posting Group" = '' then exit(false);
        if Rec."VAT Prod. Posting Group" = '' then exit(false);
        if Rec."Gen. Prod. Posting Group" = '' then exit(false);
        if Rec."Sales Unit of Measure" = '' then exit(false);
        if Rec."Purch. Unit of Measure" = '' then exit(false);

        exit(true);
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
        ItemFrom: Record Item;
        ItemTo: Record Item;
        ItemUoMFrom: Record "Item Unit of Measure";
        ItemUoMTo: Record "Item Unit of Measure";
        UoMFrom: Record "Unit of Measure";
        UoMTo: Record "Unit of Measure";
        DaleteAllFlag: Boolean;
        blankGuid: Guid;
    begin
        CompIntegrTo.SetCurrentKey("Copy Items To");
        CompIntegrTo.SetRange("Copy Items To", true);
        if CompIntegrTo.IsEmpty then exit;

        // DaleteAllFlag := Confirm('DeleteAll Item of Measure?', true);

        ItemFrom.LockTable();
        ItemFrom.SetCurrentKey("CRM Item Id");
        ItemFrom.SetFilter("CRM Item Id", '<>%1', blankGuid);

        ItemUoMFrom.LockTable();
        ItemTo.LockTable();
        ItemUoMTo.LockTable();

        if CompIntegrTo.FindSet(false, false) then
            repeat
                ItemTo.ChangeCompany(CompIntegrTo."Company Name");
                ItemUoMTo.ChangeCompany(CompIntegrTo."Company Name");
                ConfProgressBar.Init(0, 0, StrSubstNo(txtCopyItemToCompany,
                                                            CompanyName,
                                                            CompIntegrTo."Company Name"));

                // if DaleteAllFlag then begin
                //     ItemUoMFrom.FindSet(false, false);
                //     ItemUoMTo.DeleteAll();
                //     repeat
                //         ItemUoMTo := ItemUoMFrom;
                //         ItemUoMTo.Insert();
                //     until ItemUoMFrom.Next() = 0;
                // end;

                if ItemFrom.FindSet(false, false) then
                    repeat
                        ConfProgressBar.Update(StrSubstNo(txtProcessHeader, ItemFrom."No."));
                        ItemTo.SetRange("No.", ItemFrom."No.");
                        // copy UoM before Items
                        UoMTo.ChangeCompany(CompIntegrTo."Company Name");
                        if UoMFrom.FindSet(false, false) then
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
                                ItemUoMFrom.FindSet(false, false);
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
                                    ItemUoMFrom.FindSet(false, false);
                                    repeat
                                        ItemUoMTo := ItemUoMFrom;
                                        ItemUoMTo.Insert();
                                    until ItemUoMFrom.Next() = 0;
                                end;

                                ItemTo.TransferFields(ItemFrom, false);
                                ItemTo.Modify();
                            end;
                        end;
                        Commit();

                    until ItemFrom.Next() = 0;
            until CompIntegrTo.Next() = 0;

        ConfProgressBar.Close();
    end;

    var
        CompIntegrFrom: Record "Company Integration";
        ConfProgressBar: Codeunit "Config Progress Bar";
        txtCopyItemToCompany: TextConst ENU = 'From Company %1 To Company %2',
                                        RUS = 'С Организации %1 в Организацию %2';
        txtProcessHeader: TextConst ENU = 'Copy Item %1',
                                    RUS = 'Копирование товара %1';
        blankGuid: Guid;
        entityType: Enum "Entity Type";
}