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
        field(50008; "Init 1C"; Boolean)
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'Transfer to 1C',
                        RUS = 'Переслать в 1С';

            trigger OnValidate()
            begin
                if xRec."Init 1C" <> Rec."Init 1C" then
                    CheckAgreementEntries();
            end;
        }
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
        if CheckModifyAllowed() then begin
            Customer.SetCurrentKey("CRM ID");
            Customer.SetRange("CRM ID", "CRM ID");
            if not IsNullGuid("CRM ID") and not Customer.IsEmpty then
                Error(errCustomerWithCRMIDAlreadyExist, "No.", "CRM ID");
        end;
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

    var
        errCustomerUsedInUnPostedSalesDocuments: TextConst ENU = 'Customer Used In UnPosted Sales Documents',
                                                            RUS = 'Клиент используется в неучтенных документах продажи';

        errCustomerUsedInPostedSalesDocuments: TextConst ENU = 'Customer Used In Posted Sales Documents',
                                                        RUS = 'Клиент используется в учтенных документах продажи';
        msgCustomerUsedInUnPostedSalesDocuments: TextConst ENU = 'Customer Used In UnPosted Sales Documents',
                                                            RUS = 'Клиент используется в неучтенных документах продажи';
        msgCustomerUsedInPostedSalesDocuments: TextConst ENU = 'Customer Used In Posted Sales Documents',
                                                        RUS = 'Клиент используется в учтенных документах продажи';

        errCustomerWithCRMIDAlreadyExist: TextConst ENU = 'Customer %1 with CRM_ID %2 already exist!',
                                                    RUS = 'Клиент %1 с CRM ID %2 уже существует!';

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

    local procedure CheckAgreementEntries()
    var
        SalesHeader: Record "Sales Header";
        CustLE: Record "Cust. Ledger Entry";
    begin
        SalesHeader.SetCurrentKey("Sell-to Customer No.");
        SalesHeader.SetRange("Sell-to Customer No.", "No.");
        if not SalesHeader.IsEmpty then
            // Error(errAgreementUsedInUnPostedSalesDocuments);
            Message(msgCustomerUsedInUnPostedSalesDocuments);

        CustLE.SetCurrentKey("Customer No.");
        CustLE.SetRange("Customer No.", "No.");
        if not CustLE.IsEmpty then
            // Error(errAgreementUsedInPostedSalesDocuments);
            Message(msgCustomerUsedInPostedSalesDocuments);
    end;

    procedure CheckModifyAllowed(): Boolean
    var
        CompIntegr: Record "Company Integration";
    begin
        CompIntegr.SetCurrentKey("Company Name");
        CompIntegr.SetRange("Company Name", CompanyName);
        if CompIntegr.FindFirst()
        and CompIntegr."Copy Items To" then
            exit(true);
        exit(false);
    end;
}