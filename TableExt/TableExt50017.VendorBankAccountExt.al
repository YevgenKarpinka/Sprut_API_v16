tableextension 50017 "Vendor Bank Account Ext." extends "Vendor Bank Account"
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
        Vend: Record Vendor;
    begin
        "Last DateTime Modified" := CurrentDateTime;
        Vend.Get("Vendor No.");
        Vend."Last Modified Date Time" := "Last DateTime Modified";
        Vend.Modify();
    end;
}