table 50006 "Integration Entity"
{
    DataClassification = CustomerContent;
    DataPerCompany = false;

    fields
    {
        field(1; "System Code"; code[20])
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'System Code',
                        RUS = 'Код системы';

        }
        field(2; "Table ID"; Integer)
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'Table ID',
                        RUS = 'ИД таблицы';
        }
        field(3; "Code 1"; Text[40])
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'Code 1',
                        RUS = 'Код 1';
        }
        field(4; "Code 2"; Text[40])
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'Code 2',
                        RUS = 'Код 2';
        }
        field(5; "Entity Id"; Guid)
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'Entity Id',
                        RUS = 'ИД сущности';
        }
        field(6; "Create Date Time"; DateTime)
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'Create Date Time',
                        RUS = 'Дата и время создания';
        }
        field(7; "Last Modify Date Time"; DateTime)
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'Last Modify Date Time',
                        RUS = 'Дата и время модификации';
        }
        field(8; "Company Name"; Text[30])
        {
            CaptionML = ENU = 'Company Name',
                        RUS = 'Имя компании';
            DataClassification = CustomerContent;
            TableRelation = Company.Name;
        }
        field(9; "Table Name"; Text[30])
        {
            CaptionML = ENU = 'Table Name',
                        RUS = 'Имя таблицы';
            FieldClass = FlowField;
            CalcFormula = Lookup(AllObjWithCaption."Object Name" where("Object Type" = const(Table), "Object ID" = field("Table ID")));
            Editable = false;
        }
        field(10; "Entity Code"; Text[40])
        {
            CaptionML = ENU = 'Entity Code',
                        RUS = 'Код сущности';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "System Code", "Table ID", "Code 1", "Code 2")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        "Create Date Time" := CurrentDateTime;
        "Last Modify Date Time" := CurrentDateTime;
    end;

    trigger OnModify()
    begin
        "Last Modify Date Time" := CurrentDateTime;
    end;

    trigger OnDelete()
    begin
        // Error(errDeleteNotAllowed);
    end;

    trigger OnRename()
    begin
        "Last Modify Date Time" := CurrentDateTime;
    end;

    var
        Window: Dialog;
        ConfirmDeletingEntriesQst: TextConst ENU = 'Are you sure that you want to delete job queue log entries?',
                                            RUS = 'Вы действительно хотите удалить записи журнала очереди работ?';
        DeletingMsg: TextConst ENU = 'Deleting Entries...',
                                RUS = 'Удаление операций...';
        DeletedMsg: TextConst ENU = 'Entries have been deleted.',
                                RUS = 'Операции удалены.';
        errDeleteNotAllowed: Label 'Delete Not Allowed!';

    procedure DeleteEntries(DaysOld: Integer)
    begin
        if not Confirm(ConfirmDeletingEntriesQst) then
            exit;
        Window.Open(DeletingMsg);
        // SetRange(Status, Status::Done);
        // SetRange("Work Status", "Work Status"::Done);
        IF DaysOld > 0 THEN
            SetFilter("Create Date Time", '<=%1', CreateDateTime(Today - DaysOld, Time));
        DeleteAll();
        Window.Close;
        SetRange("Create Date Time");
        // SetRange(Status);
        Message(DeletedMsg);
    end;
}