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
        field(9; "Error Text"; Text[250])
        {
            DataClassification = CustomerContent;
        }
        field(10; "Attempts Send"; Integer)
        {
            CaptionML = ENU = 'Attempts Send',
                        RUS = 'Попытки отправить';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if xRec."Attempts Send" >= "Attempts Send" then exit;

                "Error Text" := CopyStr(GetLastErrorText, 1, MaxStrLen("Error Text"));
                ClearLastError();
            end;
        }
        field(11; "CRM Specification"; Blob)
        {
            DataClassification = CustomerContent;
        }
        field(12; "CRM Invoice"; Blob)
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


    var
        Window: Dialog;
        ConfirmDeletingEntriesQst: TextConst ENU = 'Are you sure that you want to delete job queue log entries?',
                                                RUS = 'Вы действительно хотите удалить записи журнала очереди работ?';
        DeletingMsg: TextConst ENU = 'Deleting Entries...',
                                RUS = 'Удаление операций...';
        DeletedMsg: TextConst ENU = 'Entries have been deleted.',
                                RUS = 'Операции удалены.';

    procedure SetCRMSpecification(NewSpecification: Text)
    var
        OutStream: OutStream;
    begin
        Clear("CRM Specification");
        "CRM Specification".CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(NewSpecification);
        Modify();
    end;

    procedure GetCRMSpecification(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        CalcFields("CRM Specification");
        "CRM Specification".CreateInStream(InStream, TEXTENCODING::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator));
    end;

    procedure SetCRMInvoices(NewInvoice: Text)
    var
        OutStream: OutStream;
    begin
        Clear("CRM Invoice");
        "CRM Invoice".CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(NewInvoice);
        Modify();
    end;

    procedure GetCRMInvoices(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        CalcFields("CRM Invoice");
        "CRM Invoice".CreateInStream(InStream, TEXTENCODING::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator));
    end;

    procedure DeleteEntries(DaysOld: Integer)
    begin
        if GuiAllowed then
            if not Confirm(ConfirmDeletingEntriesQst) then
                exit;
        Window.Open(DeletingMsg);
        SetRange(Status, Status::Done);
        // SetRange("Work Status", "Work Status"::Done);
        IF DaysOld > 0 THEN
            SetFilter("Create Date Time", '<=%1', CreateDateTime(Today - DaysOld, Time));
        DeleteAll();
        Window.Close;
        SetRange("Create Date Time");
        SetRange(Status);
        Message(DeletedMsg);
    end;
}

enum 50002 TaskStatus
{
    Extensible = true;

    value(0; OnModifyOrder)
    {
        CaptionML = ENU = 'OnModifyOrder',
                    RUS = 'НаМодификациюЗаказа';
    }
    value(1; OnSendToCRM)
    {
        CaptionML = ENU = 'OnSendToCRM',
                    RUS = 'НаОбновлениеCRM';
    }
    value(2; OnEmail)
    {
        CaptionML = ENU = 'OnEmail',
                    RUS = 'НаПочту';
    }
    value(3; Done)
    {
        CaptionML = ENU = 'Done',
                    RUS = 'Звершено';
    }
}

enum 50003 WorkStatus
{
    Extensible = true;

    value(0; WaitingForWork)
    {
        CaptionML = ENU = 'WaitingForWork',
                    RUS = 'ОжиданиеОчереди';
    }
    value(1; InWork)
    {
        CaptionML = ENU = 'InWork',
                    RUS = 'вРаботе';
    }
    value(2; Error)
    {
        CaptionML = ENU = 'Error',
                    RUS = 'Ошибка';
    }
    value(3; Done)
    {
        CaptionML = ENU = 'Done',
                    RUS = 'Завершено';
    }
}