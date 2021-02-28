tableextension 50015 "Bank Directory Ext." extends "Bank Directory"
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
        UpdateLastDateTimeModified();
    end;

    trigger OnRename()
    begin
        UpdateLastDateTimeModified();
    end;

    local procedure UpdateLastDateTimeModified()
    begin
        "Last DateTime Modified" := CurrentDateTime;
    end;
}