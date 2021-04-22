tableextension 50006 "Customer Ext" extends Customer
{
    fields
    {
        // Add changes to table fields here
        field(50000; "TAX Registration No."; Text[20])
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'TAX Registration No.',
                        RUS = 'ИНН Sprut';
        }
        field(50001; "CRM ID"; Guid)
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'CRM ID',
                        RUS = 'CRM ID';
            // Editable = false;
        }
        field(50002; "1C Path"; Text[30])
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = '1C Path',
                        RUS = '1C Путь';
            // Editable = false;
        }
        field(50003; "Certificate"; Text[20])
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'Certificate',
                        RUS = 'Свидетельство';
        }
        field(50004; "Deduplicate Id"; Guid)
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'Deduplicate Id',
                        RUS = 'Дедубликат ИД';
            // Editable = false;
        }
        field(50005; Status; Text[20])
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'Status CRM',
                        RUS = 'Статус CRM';
            // Editable = false;
        }
        field(50006; "Create Date Time"; DateTime)
        {
            DataClassification = SystemMetadata;
            CaptionML = ENU = 'Create Date Time',
                        RUS = 'Дата и время создания';
            Editable = false;
        }
        field(50007; "Create User ID"; Code[50])
        {
            DataClassification = SystemMetadata;
            CaptionML = ENU = 'Create Date Time',
                        RUS = 'Дата и время создания';
            Editable = false;
        }
        // field(50008; "Last Modified Date Time"; DateTime)
        // {
        //     DataClassification = SystemMetadata;
        //     CaptionML = ENU = 'Last Modified Date Time',
        //                 RUS = 'Дата и время последнего изменения';
        //     Editable = false;
        // }
        field(50009; "Modify User ID"; Code[50])
        {
            DataClassification = SystemMetadata;
            CaptionML = ENU = 'Create Date Time',
                        RUS = 'Дата и время создания';
            Editable = false;
        }
    }

    trigger OnBeforeInsert()
    var
        Customer: Record Customer;
    begin
        Customer.SetCurrentKey("CRM ID");
        Customer.SetRange("CRM ID", "CRM ID");
        if Customer.FindFirst() then
            Error(errCustomerWithCRMIDAlreadyExist, "No.", "CRM ID");
    end;

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

    var
        errCustomerWithCRMIDAlreadyExist: TextConst ENU = 'Customer %1 with CRM_ID %2 already exist!',
                                                    RUS = 'Клиент %1 с CRM ID %2 уже существует!';
}