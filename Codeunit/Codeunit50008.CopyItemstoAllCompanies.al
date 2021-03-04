codeunit 50008 "Copy Items to All Companies"
{
    trigger OnRun()
    begin
        // check main company
        if CheckMainCompany() then exit;

        // Copy Item From Main Company
        CopyItemFromMainCompany();

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
    begin
        CompIntegrTo.SetCurrentKey("Copy Items To");
        CompIntegrTo.SetRange("Copy Items To", true);
        if CompIntegrTo.IsEmpty then exit;

        ItemFrom.LockTable();
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
                if ItemFrom.FindSet(false, false) then
                    repeat
                        ConfProgressBar.Update(StrSubstNo(txtProcessHeader, ItemFrom."No."));
                        ItemTo.SetRange("No.", ItemFrom."No.");
                        // copy UoM before Items
                        UoMTo.ChangeCompany(CompIntegrTo."Company Name");
                        // if UoMTo.get('ПОСЛУГА') then
                        //     UoMTo.Delete();
                        if UoMFrom.FindSet(false, false) then
                            repeat
                                if not UoMTo.Get(UoMFrom.Code)
                                or (UoMTo."Last Modified Date Time" < UoMFrom."Last Modified Date Time") then begin
                                    UoMTo.TransferFields(UoMFrom, false);
                                    if not UoMTo.Insert() then UoMTo.Modify();
                                end;
                            until UoMFrom.Next() = 0;

                        if not ItemTo.FindFirst() then begin
                            if ItemFrom."Sales Unit of Measure" <> '' then begin
                                ItemUoMFrom.Get(ItemFrom."No.", ItemFrom."Sales Unit of Measure");
                                ItemUoMTo.Init();
                                ItemUoMTo.TransferFields(ItemUoMFrom);
                                ItemUoMTo.Insert();
                            end;

                            ItemTo.Init();
                            ItemTo.TransferFields(ItemFrom);
                            ItemTo.Insert();
                        end else begin
                            if (ItemFrom."Last DateTime Modified" <> ItemTo."Last DateTime Modified") then begin
                                if (ItemFrom."Sales Unit of Measure" <> '')
                                    and not ItemUoMTo.Get(ItemFrom."No.", ItemFrom."Sales Unit of Measure") then begin
                                    ItemUoMFrom.Get(ItemFrom."No.", ItemFrom."Sales Unit of Measure");
                                    ItemUoMTo.Init();
                                    ItemUoMTo.TransferFields(ItemUoMFrom);
                                    ItemUoMTo.Insert();
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
}