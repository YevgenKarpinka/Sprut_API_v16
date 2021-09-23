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
                UpdateBCID();
                UpdateInegrationCode1();
            end;
        }
        field(50009; "Modify User ID"; Code[50])
        {
            DataClassification = SystemMetadata;
            CaptionML = ENU = 'Create Date Time',
                        RUS = 'Дата и время создания';
            Editable = false;
        }
        field(50010; "BC Id"; Guid)
        {
            DataClassification = SystemMetadata;
            CaptionML = ENU = 'BC Id',
                        RUS = 'Идентификатор БЦ';
            // Editable = false;

            trigger OnValidate()
            begin
                if "Init 1C" then
                    TestField("BC Id");
            end;
        }

    }

    trigger OnBeforeInsert()
    var
        Customer: Record Customer;
    begin
        if IsNullGuid("CRM ID") then
            if CheckModifyAllowed() then begin
                Customer.SetCurrentKey("CRM ID");
                Customer.SetRange("CRM ID", "CRM ID");
                if not IsNullGuid("CRM ID") and not Customer.IsEmpty then
                    Error(errCustomerWithCRMIDAlreadyExist, "No.", "CRM ID");
            end;

        if IsNullGuid("BC Id") and IsNullGuid("CRM ID") then begin
            "BC Id" := SystemId;
        end;
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
        Integration1C: Codeunit "Integration 1C";
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
        lblSystemCode1C: Label '1C';

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

    procedure UpdateBCID()
    begin
        // if IsNullGuid("BC Id") then
        "BC Id" := SystemId;
    end;

    procedure UpdateInegrationCode1()
    var
        FindIntEntity: Record "Integration Entity";
        UpdIntEntity: Record "Integration Entity";
    begin
        FindIntEntity.SetCurrentKey("System Code", "Table ID", "Company Name", "Entity Code");
        FindIntEntity.SetRange("System Code", lblSystemCode1C);
        FindIntEntity.SetRange("Table ID", Database::Customer);
        FindIntEntity.SetRange("Company Name", CompanyName);
        FindIntEntity.SetRange("Entity Code", "No.");
        if FindIntEntity.FindFirst() then begin
            if "Init 1C" then begin
                if (FindIntEntity."Code 1" = Integration1C.Guid2APIStr("BC Id"))
                or IsNullGuid("BC Id") then
                    exit;

                UpdIntEntity.TransferFields(FindIntEntity, false);
                UpdIntEntity."Code 1" := Integration1C.Guid2APIStr("BC Id");
            end else begin
                if (FindIntEntity."Code 1" = Integration1C.Guid2APIStr("CRM ID"))
                or IsNullGuid("CRM ID") then
                    exit;

                UpdIntEntity.TransferFields(FindIntEntity, false);
                UpdIntEntity."Code 1" := Integration1C.Guid2APIStr("CRM ID");
            end;
            UpdIntEntity.Insert();
            FindIntEntity.Delete();
        end;

    end;

    procedure CheckModifyAllowed(): Boolean
    var
        CompIntegr: Record "Company Integration";
    begin
        CompIntegr.SetCurrentKey("Company Name");
        CompIntegr.SetRange("Company Name", CompanyName);
        if CompIntegr.FindFirst() then
            CompIntegr.TestField("Copy Items To", false);

        exit(true);
    end;
}