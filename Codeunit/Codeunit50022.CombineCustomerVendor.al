codeunit 50022 "Combine Customer/Vendor"
{
    trigger OnRun()
    begin
        Execute();
    end;

    var
        Customer: Record Customer;
        TmpCustomer: Record Customer;
        CustAgrmt: Record "Customer Agreement";
        Vendor: Record Vendor;
        TmpVendor: Record Vendor;
        VendAgrmt: Record "Vendor Agreement";

    local procedure Execute()
    begin
        CombineCustomersVendors();
    end;

    local procedure CombineCustomersVendors()
    var
        Cust: Record Customer;
        Vend: Record Vendor;
        blankGuid: Guid;
        newCustomerNo: Code[20];
        newVendorNo: Code[20];
    begin
        // combine customers
        Cust.SetCurrentKey("Deduplicate Id");
        Cust.SetFilter("Deduplicate Id", '<>%1', blankGuid);
        if Cust.FindSet() then
            repeat
                if GetNewCustomerNo(Cust."Deduplicate Id", newCustomerNo) then begin
                    CombineCustomers(Cust."No.", newCustomerNo);
                end;
            until Cust.Next() = 0;

        // combine vendors
        Vend.SetCurrentKey("Deduplicate No.");
        Vend.SetFilter("Deduplicate No.", '<>%1', '');
        if Vend.FindSet() then
            repeat
                if GetNewVendorNo(Vend."Deduplicate No.", newCustomerNo) then begin
                    CombineVendors(Vend."No.", newVendorNo);
                end;
            until Vend.Next() = 0;
    end;

    local procedure GetNewCustomerNo(_DeduplicateId: Guid; var _newCustomerNo: Code[20]): Boolean
    var
        locCust: Record Customer;
    begin
        locCust.SetCurrentKey("Deduplicate Id");
        locCust.SetRange("CRM ID", _DeduplicateId);
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
        if locVend.Get(_DeduplicateNo) then begin
            _newVendorNo := locVend."No.";
            exit(true);
        end;
        exit(false);
    end;

    local procedure CombineCustomers(OldCustomer: Code[20]; NewCustomer: Code[20])
    var
        Cust: Record Customer;
    begin
        Customer.Get(OldCustomer);
        if (OldCustomer <> '') and (NewCustomer <> '') then
            with Customer do begin
                Cust.Get(NewCustomer);
                TmpCustomer.Init();
                TmpCustomer.TransferFields(Cust, false);
                Cust.Delete();
                if CustAgrmt.Get(OldCustomer, '') then
                    CustAgrmt.Delete();
                if Rename(NewCustomer) then begin
                    TransferFields(TmpCustomer, false);
                    Modify;
                end else begin
                    TmpCustomer.Insert();
                end;
                Sleep(200);
            end;
    end;

    local procedure CombineVendors(OldVendor: Code[20]; NewVendor: Code[20])
    var
        Vend: Record Vendor;
    begin
        Vendor.Get(OldVendor);
        if (OldVendor <> '') and (NewVendor <> '') then
            with Vendor do begin
                Vend.Get(NewVendor);
                TmpVendor.Init();
                TmpVendor.TransferFields(Vend, false);
                Vend.Delete();
                if VendAgrmt.Get(OldVendor, '') then
                    VendAgrmt.Delete();
                if Rename(NewVendor) then begin
                    TransferFields(TmpVendor, false);
                    Modify;
                end else begin
                    TmpVendor.Insert();
                end;
                Sleep(200);
            end;
    end;
}