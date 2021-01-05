table 50003 "Task Payment Send"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            CaptionML = ENU = 'Entry No.',
                        RUS = 'Номер операции';
            DataClassification = CustomerContent;
            AutoIncrement = true;
        }
        field(2; Status; Enum TaskPaymentStatus)
        {
            CaptionML = ENU = 'Status',
                        RUS = 'Статус ';
            DataClassification = CustomerContent;
        }
        field(3; "Dtld. Cust. Ledg. Entry No."; Integer)
        {
            CaptionML = ENU = 'Dtld. Cust. Ledg. Entry No.',
                        RUS = 'Номер операции подробной книги клиента';
            DataClassification = CustomerContent;
        }
        field(4; "Invoice Entry No."; Integer)
        {
            CaptionML = ENU = 'Invoice Entry No.',
                        RUS = 'Номер операции счета';
            DataClassification = CustomerContent;
        }
        field(5; "Invoice No."; Code[20])
        {
            CaptionML = ENU = 'Invoice No.',
                        RUS = 'Номер счета';
            DataClassification = CustomerContent;
        }
        field(6; "Payment Entry No."; Integer)
        {
            CaptionML = ENU = 'Payment Entry No.',
                        RUS = 'Номер операции платежа';
            DataClassification = CustomerContent;
        }
        field(7; "Payment No."; Code[20])
        {
            CaptionML = ENU = 'Payment No.',
                        RUS = 'Номер платежа';
            DataClassification = CustomerContent;
        }
        field(8; "Payment Amount"; Decimal)
        {
            CaptionML = ENU = 'Payment Amount',
                        RUS = 'Сумма платежа';
            DataClassification = CustomerContent;
        }
        field(9; "CRM Payment Id"; Guid)
        {
            CaptionML = ENU = 'CRM Payment Id',
                        RUS = 'Id платежа в CRM';
            DataClassification = CustomerContent;
        }
        field(10; "Create User Name"; Code[50])
        {
            CaptionML = ENU = 'Create User Name',
                        RUS = 'Имя пользователя создания';
            DataClassification = CustomerContent;
        }
        field(11; "Create Date Time"; DateTime)
        {
            CaptionML = ENU = 'Create Date Time',
                        RUS = 'Дата и время создания';
            DataClassification = CustomerContent;
        }
        field(12; "Modify User Name"; Code[50])
        {
            CaptionML = ENU = 'Modify User Name',
                        RUS = 'Имя пользователя модификации';
            DataClassification = CustomerContent;
        }
        field(13; "Modify Date Time"; DateTime)
        {
            CaptionML = ENU = 'Modify Date Time',
                        RUS = 'Дата и время модификации';
            DataClassification = CustomerContent;
        }
        field(14; "Work Status"; Enum WorkStatus)
        {
            CaptionML = ENU = 'Work Status',
                        RUS = 'Сатату работы';
            DataClassification = CustomerContent;
        }
        field(15; "Attempts Send"; Integer)
        {
            CaptionML = ENU = 'Attempts Send',
                        RUS = 'Попытки отправить';
            DataClassification = CustomerContent;
        }
        field(16; "Entry Type"; Enum EntryType)
        {
            CaptionML = ENU = 'Entry Type',
                        RUS = 'Тип операции';
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
        CaptionML = ENU = 'OnPaymentSend',
                    RUS = 'ПлатежОтсылается';
    }
    value(1; Error)
    {
        CaptionML = ENU = 'Error',
                    RUS = 'Ошибка';
    }
    value(2; Done)
    {
        CaptionML = ENU = 'Done',
                    RUS = 'Завершено';
    }
}

enum 50005 EntryType
{
    Extensible = true;

    value(0; Apply)
    {
        CaptionML = ENU = 'Apply',
                    RUS = 'Применение';
    }
    value(1; UnApply)
    {
        CaptionML = ENU = 'UnApply',
                    RUS = 'ОтменаПрименения';
    }
}