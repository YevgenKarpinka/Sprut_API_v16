tableextension 50022 "Vendor Agreement Ext" extends "Vendor Agreement"
{
    fields
    {
        // Add changes to table fields here
        field(50002; "Last DateTime Modified"; DateTime)
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'Last DateTime Modified',
                        RUS = 'Дата и время последней модификации';
            Editable = false;
        }
        field(50003; "Create Date Time"; DateTime)
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'Create Date Time',
                        RUS = 'Дата и время создания';
            Editable = false;
        }
        field(50004; "Create User ID"; Code[50])
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'Create User ID',
                        RUS = 'Создал пользователь ИД';
            Editable = false;
        }
        field(50005; "Modify User ID"; Code[50])
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'Modify User ID',
                        RUS = 'Модифицировал пользователь ИД';
            Editable = false;
        }
    }

    trigger OnInsert()
    begin
        UpdateCreateDateTime();
    end;

    trigger OnModify()
    begin
        UpdateLastDateTimeModified();
    end;

    trigger OnRename()
    begin
        UpdateLastDateTimeModified();
    end;

    local procedure UpdateCreateDateTime()
    begin
        "Create Date Time" := CurrentDateTime;
        "Create User ID" := UserId;
    end;

    local procedure UpdateLastDateTimeModified()
    begin
        "Last DateTime Modified" := CurrentDateTime;
        "Modify User ID" := UserId;
    end;
}