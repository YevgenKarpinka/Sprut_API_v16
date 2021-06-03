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

        if CompIntegrTo.FindSet() then
            repeat
                LocationTo.ChangeCompany(CompIntegrTo."Company Name");
                InvPostSetupTo.ChangeCompany(CompIntegrTo."Company Name");
                ConfProgressBar.Init(0, 0, StrSubstNo(txtCopyItemToCompany,
                                                            CompanyName,
                                                            CompIntegrTo."Company Name"));
                if LocationFrom.FindSet() then
                    repeat
                        ConfProgressBar.Update(StrSubstNo(txtProcessHeader, LocationFrom.Code));
                        if not LocationTo.Get(LocationFrom.Code) then begin
                            LocationTo.Init();
                            LocationTo.TransferFields(LocationFrom);
                            LocationTo.Insert();
                        end else begin
                            if (LocationFrom."Last Modified Date Time" <> LocationTo."Last Modified Date Time") then begin
                                LocationTo.TransferFields(LocationFrom, false);
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

                    until LocationFrom.Next() = 0;
                Commit();
            until CompIntegrTo.Next() = 0;
        ConfProgressBar.Close();
    end;

    var
        CompIntegrFrom: Record "Company Integration";
        ConfProgressBar: Codeunit "Config Progress Bar";
        txtCopyItemToCompany: TextConst ENU = 'From Company %1 To Company %2',
                                        RUS = 'С Организации %1 в Организацию %2';
        txtProcessHeader: TextConst ENU = 'Copy Location %1',
                                    RUS = 'Копирование склада %1';
}