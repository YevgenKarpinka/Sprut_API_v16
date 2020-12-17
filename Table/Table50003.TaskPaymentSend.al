table 50003 "Task Payment Send"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            AutoIncrement = true;
        }
        field(2; Status; Enum TaskPaymentStatus)
        {
            DataClassification = CustomerContent;
        }
        field(3; "Dtld. Cust. Ledg. Entry No."; Integer)
        {
            DataClassification = CustomerContent;
        }
        field(4; "Invoice Entry No."; Integer)
        {
            DataClassification = CustomerContent;
        }
        field(5; "Invoice No."; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(6; "Payment Entry No."; Integer)
        {
            DataClassification = CustomerContent;
        }
        field(7; "Payment No."; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(8; "Payment Amount"; Decimal)
        {
            DataClassification = CustomerContent;
        }
        field(9; "CRM Payment Id"; Guid)
        {
            DataClassification = CustomerContent;
        }
        field(10; "Create User Name"; Code[50])
        {
            DataClassification = CustomerContent;
        }
        field(11; "Create Date Time"; DateTime)
        {
            DataClassification = CustomerContent;
        }
        field(12; "Modify User Name"; Code[50])
        {
            DataClassification = CustomerContent;
        }
        field(13; "Modify Date Time"; DateTime)
        {
            DataClassification = CustomerContent;
        }
        field(14; "Work Status"; Enum WorkStatus)
        {
            DataClassification = CustomerContent;
        }
        field(15; "Attempts Send"; Integer)
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
        "Create User Name" := UserId;
        "Create Date Time" := CurrentDateTime;
    end;

    trigger OnModify()
    begin
        "Modify User Name" := UserId;
        "Modify Date Time" := CurrentDateTime;
    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

}

enum 50004 TaskPaymentStatus
{
    Extensible = true;

    value(0; OnModifyOrder)
    {
        CaptionML = ENU = 'OnPaymentSend', RUS = 'OnPaymentSend';
    }
    value(1; Error)
    {
        CaptionML = ENU = 'Error', RUS = 'Error';
    }
    value(2; Done)
    {
        CaptionML = ENU = 'Done', RUS = 'Done';
    }
}