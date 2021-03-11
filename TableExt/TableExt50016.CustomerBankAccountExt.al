tableextension 50016 "Customer Bank Account Ext." extends "Customer Bank Account"
{
    fields
    {
        field(50000; "Last DateTime Modified"; DateTime)
        {
            DataClassification = CustomerContent;
        }
    }

    trigger OnInsert()
    begin
        UpdateLastDateTimeModified();
    end;

    trigger OnModify()
    begin
        UpdateLastDateTimeModified();
    end;

    trigger OnDelete()
    begin
    end;

    trigger OnRename()
    begin
        UpdateLastDateTimeModified();
    end;

    local procedure UpdateLastDateTimeModified()
    var
        Cust: Record Customer;
    begin
        "Last DateTime Modified" := CurrentDateTime;
        Cust.Get("Customer No.");
        Cust."Last Modified Date Time" := "Last DateTime Modified";
        Cust.Modify();
    end;
}