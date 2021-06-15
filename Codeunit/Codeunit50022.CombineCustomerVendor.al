codeunit 50022 "Combine Customer/Vendor"
{
    trigger OnRun()
    begin
        Execute();
    end;

    var
        repCombineCustVend: Report "Combine Customer/Vendor Ext";
        CompIntegr: Record "Company Integration";

    local procedure Execute()
    var
        myInt: Integer;
    begin
        if CompIntegr.FindSet() then
            repeat
                if CompIntegr."Copy Items To" or CompIntegr."Copy Items From" then begin
                    CombineCustomersVendors(CompIntegr."Company Name");
                end;
            until CompIntegr.Next() = 0;
    end;

    local procedure CombineCustomersVendors(_CompanyName: Text[30])
    var
        Cust: Record Customer;
        Vend: Record Vendor;
        blankGuid: Guid;
        newCustomerNo: Code[20];
        newVendorNo: Code[20];
    begin
        if CompanyName <> _CompanyName then begin
            Cust.ChangeCompany(_CompanyName);
            Vend.ChangeCompany(_CompanyName);
        end;

        // combine customers
        Cust.SetCurrentKey("Deduplicate Id");
        Cust.SetFilter("Deduplicate Id", '<>%1', blankGuid);
        if Cust.FindSet() then
            repeat
                if GetNewCustomerNo(Cust."Deduplicate Id", newCustomerNo) then
                    repCombineCustVend.InitReport(0, Cust."No.", newCustomerNo, '', '');
            until Cust.Next() = 0;

        // combine vendors
        Vend.SetCurrentKey("Deduplicate No.");
        Vend.SetFilter("Deduplicate No.", '<>%1', '');
        if Vend.FindSet() then
            repeat
                if GetNewVendorNo(Vend."Deduplicate No.", newCustomerNo) then
                    repCombineCustVend.InitReport(1, '', '', Vend."No.", newVendorNo);
            until Vend.Next() = 0;
    end;

    local procedure GetNewCustomerNo(_DeduplicateId: Guid; var _newCustomerNo: Code[20]): Boolean
    var
        locCust: Record Customer;
    begin
        locCust.SetCurrentKey("Deduplicate Id");
        locCust.SetRange("Deduplicate Id", _DeduplicateId);
        if locCust.FindFirst() then begin
            _newCustomerNo := locCust."No.";
            exit(true);
        end;
        exit(false);
    end;

    local procedure GetNewVendorNo(_DeduplicateNo: Code[20]; var _newVendorNo: Code[20]): Boolean
    var
        locVend: Record Vendor;
    begin
        locVend.SetCurrentKey("Deduplicate No.");
        locVend.SetRange("Deduplicate No.", _DeduplicateNo);
        if locVend.FindFirst() then begin
            _newVendorNo := locVend."No.";
            exit(true);
        end;
        exit(false);
    end;
}