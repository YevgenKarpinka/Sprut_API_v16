codeunit 50015 "Copy Whses. to All Companies"
{
    trigger OnRun()
    begin
        // check main company
        if CheckMainCompany() then exit;

        // Copy Item From Main Company
        CopyWhseFromMainCompany();

    end;

    local procedure CheckMainCompany(): Boolean
    begin
        CompIntegrFrom.Reset();
        CompIntegrFrom.SetCurrentKey("Company Name", "Copy Items From");
        CompIntegrFrom.SetRange("Company Name", CompanyName);
        CompIntegrFrom.SetRange("Copy Items From", true);
        exit(CompIntegrFrom.IsEmpty);
    end;

    local procedure CopyWhseFromMainCompany()
    var
        CompIntegrTo: Record "Company Integration";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        InvPostSetupFrom: Record "Inventory Posting Setup";
        InvPostSetupTo: Record "Inventory Posting Setup";
    begin
        CompIntegrTo.SetCurrentKey("Copy Items To");
        CompIntegrTo.SetRange("Copy Items To", true);
        if CompIntegrTo.IsEmpty then exit;

        // LocationFrom.LockTable();
        if CompIntegrTo.FindSet(false, false) then
            repeat
                LocationTo.ChangeCompany(CompIntegrTo."Company Name");
                InvPostSetupTo.ChangeCompany(CompIntegrTo."Company Name");
                // if InvPostSetupTo.get() then
                //     InvPostSetupTo.Delete();
                if LocationFrom.FindSet(false, false) then
                    repeat
                        LocationTo.SetRange(Code, LocationFrom.Code);
                        if not LocationTo.FindFirst() then begin
                            LocationTo.Init();
                            LocationTo.TransferFields(LocationFrom);
                            LocationTo.Insert();
                        end else begin
                            if (LocationFrom."Last Modified Date Time" <> LocationTo."Last Modified Date Time") then begin

                                LocationTo.TransferFields(LocationFrom);
                                LocationTo.Modify();
                            end;
                        end;

                        // copy Inv posting setup
                        InvPostSetupFrom.SetRange("Location Code", LocationFrom.Code);
                        if InvPostSetupFrom.FindSet(false, false) then
                            repeat
                                InvPostSetupTo.TransferFields(InvPostSetupFrom);
                                if InvPostSetupTo.Insert() then;
                            until InvPostSetupFrom.Next() = 0;

                        Commit();

                    until LocationFrom.Next() = 0;
            until CompIntegrTo.Next() = 0;
    end;

    var
        CompIntegrFrom: Record "Company Integration";
}