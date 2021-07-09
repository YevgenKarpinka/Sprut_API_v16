tableextension 50023 "Warehouse Shipment Line Ext" extends "Warehouse Shipment Line"
{
    fields
    {
        // Add changes to table fields here
        // field(50000; "CRM ID"; Guid)
        // {
        //     DataClassification = CustomerContent;
        //     CaptionML = ENU = 'CRM ID',
        //                 RUS = 'CRM ID';
        // }
        // field(50003; "Create Date Time"; DateTime)
        // {
        //     DataClassification = SystemMetadata;
        //     CaptionML = ENU = 'Create Date Time',
        //                 RUS = 'Дата и время создания';
        //     // Editable = false;
        // }
        // field(50004; "Create User ID"; Code[50])
        // {
        //     DataClassification = SystemMetadata;
        //     CaptionML = ENU = 'Create Date Time',
        //                 RUS = 'Дата и время создания';
        //     // Editable = false;
        // }
        // field(50005; "Last Modified Date Time"; DateTime)
        // {
        //     DataClassification = SystemMetadata;
        //     CaptionML = ENU = 'Last Modified Date Time',
        //                 RUS = 'Дата и время последнего изменения';
        //     // Editable = false;
        // }
        // field(50006; "Modify User ID"; Code[50])
        // {
        //     DataClassification = SystemMetadata;
        //     CaptionML = ENU = 'Create Date Time',
        //                 RUS = 'Дата и время создания';
        //     // Editable = false;
        // }
        field(50007; "Description Extended"; Text[350])
        {
            DataClassification = SystemMetadata;
            CaptionML = ENU = 'Description Extended',
                        RUS = 'Описание расширенное';
            // Editable = false;
        }
    }
}