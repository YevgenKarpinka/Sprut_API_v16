tableextension 50003 "Sales Invoice Header Ext" extends "Sales Invoice Header"
{
    fields
    {
        // Add changes to table fields here
        field(50000; "CRM Invoice No."; Text[50])
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'CRM Invoice No.',
                        RUS = 'Номер инвойса в CRM';
        }
        field(50001; "Last Modified Date Time"; DateTime)
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'Last Modified Date Time',
                        RUS = 'Дата и время последнего изменения';
            Editable = false;
        }
        field(50002; "CRM ID"; Guid)
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'CRM ID',
                        RUS = 'CRM ID';
        }
        field(50003; "CRM Header ID"; Guid)
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'CRM Header ID',
                        RUS = 'CRM Заголовок ID';
        }
        field(50004; "CRM Source Type"; Text[20])
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'CRM Source Type',
                        RUS = 'CRM Тип Источника';
        }
        field(50005; "Create Date Time"; DateTime)
        {
            DataClassification = SystemMetadata;
            CaptionML = ENU = 'Create Date Time',
                        RUS = 'Дата и время создания';
            Editable = false;
        }
        field(50006; "Create User ID"; Code[50])
        {
            DataClassification = SystemMetadata;
            CaptionML = ENU = 'Create User ID',
                        RUS = 'Создание пользователь ИД';
            Editable = false;
        }
        field(50007; "Modify User ID"; Code[50])
        {
            DataClassification = SystemMetadata;
            CaptionML = ENU = 'Modify User ID',
                        RUS = 'Модификация пользователь ИД';
            Editable = false;
        }
        field(50008; "Invoice No. 1C"; Code[50])
        {
            DataClassification = SystemMetadata;
            CaptionML = ENU = 'Invoice No. 1C',
                        RUS = 'Номер счета 1C';
            Editable = false;
        }
    }

    trigger OnInsert()
    begin
        UpdateCreateDateTime();
    end;

    trigger OnModify()
    begin
        UpdateLastModifyDateTime();
    end;

    trigger OnRename()
    begin
        UpdateLastModifyDateTime();
    end;

    local procedure UpdateCreateDateTime()
    begin
        "Create Date Time" := CurrentDateTime;
        "Create User ID" := UserId;
    end;

    local procedure UpdateLastModifyDateTime()
    begin
        "Last Modified Date Time" := CurrentDateTime;
        "Modify User ID" := UserId;
    end;
}