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

            trigger OnValidate()
            var
                CustomerAgr: Record "Customer Agreement";
            begin
                if IsNullGuid("CRM ID") then exit;

                CustomerAgr.SetCurrentKey("CRM ID");
                CustomerAgr.SetRange("CRM ID", "CRM ID");
                if not CustomerAgr.IsEmpty then
                    Error(errCustomerAgreementWithCRMIDAlreadyExist, "CRM ID");
            end;
        }
        field(50002; "Last DateTime Modified"; DateTime)
        {
            DataClassification = CustomerContent;
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
            CaptionML = ENU = 'Create Date Time',
                        RUS = 'Дата и время создания';
            Editable = false;
        }
        field(50005; "Modify User ID"; Code[50])
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'Create Date Time',
                        RUS = 'Дата и время создания';
            Editable = false;
        }
        field(50006; "Init 1C"; Boolean)
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'Transfer to 1C',
                        RUS = 'Переслать в 1С';
            // Editable = false;

            trigger OnValidate()
            begin
                // if xRec."Init 1C" = Rec."Init 1C" then exit;
                CheckAgreementEntries();
                UpdateIn1CCRMId2BCId();
                FillBCID();
            end;
        }
        field(50007; Print; Boolean)
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'Print',
                        RUS = 'Печатать';
            // Editable = false;

        }
        field(50008; "Additional Date"; Date)
        {
            DataClassification = SystemMetadata;
            CaptionML = ENU = 'Additional Date',
                        RUS = 'Дата Дополнения';
            // Editable = false;
        }
        field(50010; "BC Id"; Guid)
        {
            DataClassification = SystemMetadata;
            CaptionML = ENU = 'BC Id',
                        RUS = 'Идентификатор БЦ';
            // Editable = false;
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

    var
        blankGuid: Guid;
        errAgreementUsedInUnPostedSalesDocuments: TextConst ENU = 'Agreement Used In UnPosted Sales Documents',
                                                            RUS = 'Договор используется в неучтенных документах продажи';

        errAgreementUsedInPostedSalesDocuments: TextConst ENU = 'Agreement Used In Posted Sales Documents',
                                                        RUS = 'Договор используется в учтенных документах продажи';
        msgAgreementUsedInUnPostedSalesDocuments: TextConst ENU = 'Agreement Used In UnPosted Sales Documents',
                                                            RUS = 'Договор используется в неучтенных документах продажи';
        msgAgreementUsedInPostedSalesDocuments: TextConst ENU = 'Agreement Used In Posted Sales Documents',
                                                        RUS = 'Договор используется в учтенных документах продажи';

        errCustomerAgreementWithCRMIDAlreadyExist: TextConst ENU = 'Customer Agreement With CRM_ID %1 Already Exist!',
                                                            RUS = 'Договор клиента с CRM ID %1 уже существует!';

    local procedure CheckAgreementEntries()
    var
        SalesHeader: Record "Sales Header";
        CustLE: Record "Cust. Ledger Entry";
    begin
        SalesHeader.SetCurrentKey("Agreement No.");
        SalesHeader.SetRange("Agreement No.", "No.");
        if not SalesHeader.IsEmpty then
            // Error(errAgreementUsedInUnPostedSalesDocuments);
            Message(msgAgreementUsedInUnPostedSalesDocuments);

        CustLE.SetCurrentKey("Agreement No.");
        CustLE.SetRange("Agreement No.", "No.");
        if not CustLE.IsEmpty then
            // Error(errAgreementUsedInPostedSalesDocuments);
            Message(msgAgreementUsedInPostedSalesDocuments);
    end;

    local procedure FillBCID()
    begin
        if "Init 1C" and ("BC Id" = blankGuid) then
            "BC Id" := SystemId;
    end;

    local procedure UpdateIn1CCRMId2BCId()
    begin
        // Error('Procedure UpdateIn1CCRMId2BCId not implemented.');
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

