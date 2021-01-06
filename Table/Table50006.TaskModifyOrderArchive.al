table 50006 "Task Modify Order Archive"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            AutoIncrement = true;
        }
        field(2; Status; Enum TaskStatus)
        {
            DataClassification = CustomerContent;
        }
        field(3; "Order No."; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(4; "Create User Name"; Code[50])
        {
            DataClassification = CustomerContent;
        }
        field(5; "Create Date Time"; DateTime)
        {
            DataClassification = CustomerContent;
        }
        field(6; "Modify User Name"; Code[50])
        {
            DataClassification = CustomerContent;
        }
        field(7; "Modify Date Time"; DateTime)
        {
            DataClassification = CustomerContent;
        }
        field(8; "Work Status"; Enum WorkStatus)
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(SK; Status) { }
    }

    trigger OnInsert()
    begin
    end;

    trigger OnModify()
    begin
    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

}