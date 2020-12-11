tableextension 50002 "Sales Header Ext" extends "Sales Header"
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
            DataClassification = SystemMetadata;
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
    }

    trigger OnInsert()
    begin
        "Last Modified Date Time" := CurrentDateTime;
    end;

    trigger OnModify()
    begin
        "Last Modified Date Time" := CurrentDateTime;
    end;
}