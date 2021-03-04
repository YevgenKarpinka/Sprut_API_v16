tableextension 50007 "Customer Agreement Ext" extends "Customer Agreement"
{
    fields
    {
        // Add changes to table fields here
        field(50000; Status; Text[20])
        {
            DataClassification = CustomerContent;
        }
        field(50001; "CRM ID"; Guid)
        {
            DataClassification = CustomerContent;
        }
        field(50002; "Last DateTime Modified"; DateTime)
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

enum 50001 AgreementStatus
{
    // - Активирован
    // - Приостановлен
    // - Активен
    // - Разорван

    Extensible = true;
    value(0; "")
    {
        CaptionML = ENU = '', RUS = '';
    }
    value(1; Activated)
    {
        CaptionML = ENU = 'Activated', RUS = 'Активирован';
    }
    value(2; Suspended)
    {
        CaptionML = ENU = 'Suspended', RUS = 'Приостановлен';
    }
    value(3; Active)
    {
        CaptionML = ENU = 'Active', RUS = 'Активен';
    }
    value(4; Broken)
    {
        CaptionML = ENU = 'Broken', RUS = 'Разорван';
    }
}

