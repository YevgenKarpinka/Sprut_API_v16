report 50001 "Combine Customer/Vendor Ext"
{
    CaptionML = ENU = 'Combine Customer/Vendor Ext',
                RUS = 'Объединить клиента/поставщика доп.';
    ProcessingOnly = true;
    TransactionType = Update;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = SORTING("No.");

            trigger OnAfterGetRecord()
            var
                Vend: Record Vendor;
            begin
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

            trigger OnPreDataItem()
            begin
                if (OldVendor = '') or (NewVendor = '') then
                    exit
                else begin
                    Vendor.SetRange("No.", OldVendor);
                end;
            end;
        }
        dataitem(Customer; Customer)
        {
            DataItemTableView = SORTING("No.");

            trigger OnAfterGetRecord()
            var
                Cust: Record Customer;
            begin
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

            trigger OnPreDataItem()
            begin
                if (OldCustomer = '') or (NewCustomer = '') then
                    exit
                else begin
                    Customer.SetRange("No.", OldCustomer);
                end
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(Type; Type)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Type';
                        OptionCaption = 'Vendor,Customer';

                        trigger OnValidate()
                        begin
                            UpdateForm(true);
                        end;
                    }
                    field(OldCustomer; OldCustomer)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Old Customer No.';
                        Lookup = true;
                        TableRelation = Customer."No.";
                        ToolTip = 'Specifies the old customer number that will be combined.';

                        trigger OnValidate()
                        begin
                            if Type <> Type::Customer then
                                Error(Text005, Format(Type));
                            Customer.Get(OldCustomer);
                            OldName := Customer.Name;
                        end;
                    }
                    field(OldVendor; OldVendor)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Old Vendor No.';
                        Lookup = true;
                        TableRelation = Vendor."No.";
                        ToolTip = 'Specifies the old vendor number that will be combined.';

                        trigger OnValidate()
                        begin
                            if Type <> Type::Vendor then
                                Error(Text005, Format(Type));

                            Vendor.Get(OldVendor);
                            OldName := Vendor.Name;
                        end;
                    }
                    field(OldName; OldName)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        Enabled = true;
                    }
                    field(NewCustomer; NewCustomer)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Customer No.';
                        Lookup = true;
                        TableRelation = Customer;
                        ToolTip = 'Specifies the new customer number for the record that is being combined.';

                        trigger OnValidate()
                        begin
                            if Type <> Type::Customer then
                                Error(Text005, Format(Type));

                            Customer.Get(NewCustomer);
                            NewName := Customer.Name;
                        end;
                    }
                    field(NewVendor; NewVendor)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Vendor No.';
                        Lookup = true;
                        TableRelation = Vendor."No.";
                        ToolTip = 'Specifies the new vendor number for the record that is being combined.';

                        trigger OnValidate()
                        begin
                            if Type <> Type::Vendor then
                                Error(Text005, Format(Type));

                            Vendor.Get(NewVendor);
                            NewName := Vendor.Name;
                        end;
                    }
                    field(NewName; NewName)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        TmpCustomer: Record Customer;
        TmpVendor: Record Vendor;
        CustAgrmt: Record "Customer Agreement";
        VendAgrmt: Record "Vendor Agreement";
        OldCustomer: Code[20];
        NewCustomer: Code[20];
        OldName: Text[100];
        NewName: Text[100];
        OldVendor: Code[20];
        NewVendor: Code[20];
        Type: Option Vendor,Customer;
        Text005: Label 'Type must not be %1';

    procedure ChangeCustomer(var Rec: Record Customer)
    begin
        Type := Type::Customer;
        UpdateForm(false);
        OldCustomer := Rec."No.";
        OldName := Rec.Name;
        Customer.Get(Rec."No.");
    end;

    procedure ChangeVendor(var Rec: Record Vendor)
    begin
        Type := Type::Vendor;
        UpdateForm(false);
        OldVendor := Rec."No.";
        OldName := Rec.Name;
        Vendor.Get(Rec."No.");
    end;

    local procedure UpdateForm(TypeEnable: Boolean)
    begin
        OldName := '';
        NewName := '';
        OldVendor := '';
        OldCustomer := '';
        NewVendor := '';
        NewCustomer := '';
    end;

    procedure InitReport(_Type: Option Vendor,Customer; _OldCustomer: Code[20]; _NewCustomer: Code[20];
                                                    _OldVendor: Code[20]; _NewVendor: Code[20]);
    begin
        Type := _Type;
        OldVendor := _OldVendor;
        OldCustomer := _OldCustomer;
        NewVendor := _NewVendor;
        NewCustomer := _NewCustomer;
    end;
}

