tableextension 50009 "Sales Line Ext" extends "Sales Line"
{
    fields
    {
        // Add changes to table fields here
        field(50000; "CRM ID"; Guid)
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'CRM ID',
                        RUS = 'CRM ID';

            trigger OnValidate()
            begin
                CheckCRMIdExist("CRM ID");
            end;
        }
        field(50003; "Create Date Time"; DateTime)
        {
            DataClassification = SystemMetadata;
            CaptionML = ENU = 'Create Date Time',
                        RUS = 'Дата и время создания';
            Editable = false;
        }
        field(50004; "Create User ID"; Code[50])
        {
            DataClassification = SystemMetadata;
            CaptionML = ENU = 'Create Date Time',
                        RUS = 'Дата и время создания';
            Editable = false;
        }
        field(50005; "Last Modified Date Time"; DateTime)
        {
            DataClassification = SystemMetadata;
            CaptionML = ENU = 'Last Modified Date Time',
                        RUS = 'Дата и время последнего изменения';
            Editable = false;
        }
        field(50006; "Modify User ID"; Code[50])
        {
            DataClassification = SystemMetadata;
            CaptionML = ENU = 'Create Date Time',
                        RUS = 'Дата и время создания';
            Editable = false;
        }
        field(50007; "Description Extended"; Text[350])
        {
            DataClassification = SystemMetadata;
            CaptionML = ENU = 'Description Extended',
                        RUS = 'Описание расширенное';
            // Editable = false;

            trigger OnValidate()
            begin
                if "Description Extended" <> '' then
                    Description := CopyStr("Description Extended", 1, MaxStrLen(Description));
            end;
        }
    }

    trigger OnInsert()
    begin
        Commit();
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

    var
        errCRMIdInSalesLineAlreadyExist: Label 'CRM ID %1 in sales line already exist';
        errCRMIdInPostedSalesLineAlreadyExist: Label 'CRM ID %1 in posted sales line already exist';

    local procedure UpdateCreateDateTime()
    begin
        "Create Date Time" := CurrentDateTime;
        "Create User ID" := UserId;
    end;

    local procedure UpdateLastDateTimeModified()
    begin
        "Last Modified Date Time" := CurrentDateTime;
        "Modify User ID" := UserId;
    end;

    procedure CheckCRMIdExist(crmID: Guid)
    var
        locSL: Record "Sales Line";
        locSIL: Record "Sales Invoice Line";
    begin
        locSL.SetCurrentKey("CRM ID");
        locSL.SetRange("CRM ID", crmID);
        if not locSL.IsEmpty then
            Error(errCRMIdInSalesLineAlreadyExist, crmID);

        locSIL.SetCurrentKey("CRM ID");
        locSIL.SetRange("CRM ID", crmID);
        if not locSIL.IsEmpty then
            Error(errCRMIdInPostedSalesLineAlreadyExist, crmID);
    end;

    procedure CheckPostedCRMIdExist(crmID: Guid)
    var
        locSL: Record "Sales Line";
        locSIL: Record "Sales Invoice Line";
    begin
        // locSL.SetCurrentKey("CRM ID");
        // locSL.SetRange("CRM ID", crmID);
        // if not locSL.IsEmpty then
        //     Error(errCRMIdInSalesLineAlreadyExist, crmID);

        locSIL.SetCurrentKey("CRM ID");
        locSIL.SetRange("CRM ID", crmID);
        if not locSIL.IsEmpty then
            Error(errCRMIdInPostedSalesLineAlreadyExist, crmID);
    end;
}