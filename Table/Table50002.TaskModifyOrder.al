table 50002 "Task Modify Order"
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

enum 50002 TaskStatus
{
    Extensible = true;

    value(0; OnModifyOrder)
    {
        CaptionML = ENU = 'OnModifyOrder', RUS = 'OnModifyOrder';
    }
    value(1; OnSendToCRM)
    {
        CaptionML = ENU = 'OnSendToCRM', RUS = 'OnSendToCRM';
    }
    value(2; OnSendToEmail)
    {
        CaptionML = ENU = 'OnSendToEmail', RUS = 'OnSendToEmail';
    }
    value(3; Done)
    {
        CaptionML = ENU = 'Done', RUS = 'Done';
    }
}

enum 50003 WorkStatus
{
    Extensible = true;

    value(0; WaitingForWork)
    {
        CaptionML = ENU = 'WaitingForWork', RUS = 'WaitingForWork';
    }
    value(1; InWork)
    {
        CaptionML = ENU = 'InWork', RUS = 'InWork';
    }
    value(2; Error)
    {
        CaptionML = ENU = 'Error', RUS = 'Error';
    }
    value(3; Done)
    {
        CaptionML = ENU = 'Done', RUS = 'Done';
    }
}