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
        VendorBankAccountFrom: Record "Vendor Bank Account";
        VendorBankAccountTo: Record "Vendor Bank Account";
    begin
        CompIntegrTo.SetCurrentKey("Copy Items To");
        CompIntegrTo.SetRange("Copy Items To", true);
        if CompIntegrTo.IsEmpty then exit;

        VendorFrom.LockTable();
        VendorBankAccountFrom.LockTable();
        if VendorFrom.FindSet(false, false) then
            repeat
                if CompIntegrTo.FindSet(false, false) then
                    repeat
                        VendorTo.ChangeCompany(CompIntegrTo."Company Name");
                        VendorBankAccountTo.ChangeCompany(CompIntegrTo."Company Name");
                        // VendorTo.SetRange("No.", VendorFrom."No.");
                        if not VendorTo.Get(VendorFrom."No.") then begin
                            // VendorTo.Init();
                            VendorTo.TransferFields(VendorFrom);
                            VendorTo.Insert();
                            // to do copy vendor bank account
                            if VendorFrom."Default Bank Code" <> '' then begin
                                VendorBankAccountFrom.SetRange("Vendor No.", VendorFrom."No.");
                                if VendorBankAccountFrom.FindSet(false, false) then
                                    repeat
                                        VendorBankAccountTo.TransferFields(VendorBankAccountFrom);
                                        VendorBankAccountTo.Insert();
                                    until VendorBankAccountFrom.Next() = 0;
                            end;
                        end else begin
                            if (VendorFrom."Last Modified Date Time" <> VendorTo."Last Modified Date Time") then begin
                                VendorTo.TransferFields(VendorFrom, false);
                                VendorTo.Modify();
                                // to do copy vendor bank account
                                if VendorFrom."Default Bank Code" <> '' then begin
                                    VendorBankAccountFrom.SetRange("Vendor No.", VendorFrom."No.");
                                    if VendorBankAccountFrom.FindSet(false, false) then
                                        repeat
                                            if not VendorBankAccountTo.Get(VendorBankAccountFrom."Vendor No.", VendorBankAccountFrom.Code) then begin
                                                VendorBankAccountTo.TransferFields(VendorBankAccountFrom);
                                                VendorBankAccountTo.Insert();
                                            end else begin
                                                VendorBankAccountTo.TransferFields(VendorBankAccountFrom, false);
                                                VendorBankAccountTo.Modify();
                                            end;
                                        until VendorBankAccountFrom.Next() = 0;
                                end;
                            end;
                        end;
                        Commit();
                    until CompIntegrTo.Next() = 0;
            until VendorFrom.Next() = 0;
    end;

    var
        CompIntegrFrom: Record "Company Integration";
}