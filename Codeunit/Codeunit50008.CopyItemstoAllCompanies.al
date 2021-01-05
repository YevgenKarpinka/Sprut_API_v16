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
    begin
        CompIntegrTo.SetCurrentKey("Copy Items To");
        CompIntegrTo.SetRange("Copy Items To", true);
        if CompIntegrTo.IsEmpty then exit;

        ItemFrom.LockTable();
        if ItemFrom.FindSet(false, false) then
            repeat
                if CompIntegrTo.FindSet(false, false) then
                    repeat
                        ItemTo.ChangeCompany(CompIntegrTo."Company Name");
                        ItemTo.SetRange("No.", ItemFrom."No.");
                        if not ItemTo.FindFirst() then begin
                            ItemTo.Init();
                            ItemTo.TransferFields(ItemFrom);
                            ItemTo.Insert();
                        end else begin
                            if (ItemFrom."Last DateTime Modified" <> ItemTo."Last DateTime Modified") then begin
                                ItemTo.TransferFields(ItemFrom);
                                ItemTo.Modify();
                            end;
                        end;
                        Commit();
                    until CompIntegrTo.Next() = 0;
            until ItemFrom.Next() = 0;
    end;

    var
        CompIntegrFrom: Record "Company Integration";
}