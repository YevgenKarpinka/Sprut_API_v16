codeunit 50016 "Copy Vend. to All Companies"
{
    trigger OnRun()
    begin
        // check main company
        if CheckMainCompany() then exit;

        // Copy Item From Main Company
        CopyVendFromMainCompany();

    end;

    local procedure CheckMainCompany(): Boolean
    begin
        CompIntegrFrom.Reset();
        CompIntegrFrom.SetCurrentKey("Company Name", "Copy Items From");
        CompIntegrFrom.SetRange("Company Name", CompanyName);
        CompIntegrFrom.SetRange("Copy Items From", true);
        exit(CompIntegrFrom.IsEmpty);
    end;

    local procedure CopyVendFromMainCompany()
    var
        CompIntegrTo: Record "Company Integration";
        VendorFrom: Record Vendor;
        VendorTo: Record Vendor;
    begin
        CompIntegrTo.SetCurrentKey("Copy Items To");
        CompIntegrTo.SetRange("Copy Items To", true);
        if CompIntegrTo.IsEmpty then exit;

        VendorFrom.LockTable();
        if VendorFrom.FindSet(false, false) then
            repeat
                if CompIntegrTo.FindSet(false, false) then
                    repeat
                        VendorTo.ChangeCompany(CompIntegrTo."Company Name");
                        VendorTo.SetRange("No.", VendorFrom."No.");
                        if not VendorTo.FindFirst() then begin
                            VendorTo.Init();
                            VendorTo.TransferFields(VendorFrom);
                            VendorTo.Insert();
                        end else begin
                            if (VendorFrom."Last Modified Date Time" <> VendorTo."Last Modified Date Time") then begin

                                VendorTo.TransferFields(VendorFrom);
                                VendorTo.Modify();
                            end;
                        end;
                        Commit();
                    until CompIntegrTo.Next() = 0;
            until VendorFrom.Next() = 0;
    end;

    var
        CompIntegrFrom: Record "Company Integration";
}