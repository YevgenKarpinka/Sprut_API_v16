table 50009 "Entity To 1C"
{
    DataClassification = CustomerContent;
    DataPerCompany = false;
    DrillDownPageId = "Entity To 1C List";

    fields
    {
        field(1; "Company Name"; Text[30])
        {
            DataClassification = SystemMetadata;
            CaptionML = ENU = 'Company Name',
                        RUS = 'Название компании';
            TableRelation = "Company Integration";
        }
        field(2; "Table ID"; Integer)
        {
            CaptionML = ENU = 'Table ID',
                        RUS = 'ИД таблицы';
        }
        field(3; "No."; Code[20])
        {
            DataClassification = SystemMetadata;
            CaptionML = ENU = 'No.',
                        RUS = 'Но.';
        }
        field(4; "Description"; Text[100])
        {
            CaptionML = ENU = 'Description',
                        RUS = 'Описание';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = Lookup(AllObjWithCaption."Object Name" where("Object Type" = const(Table), "Object ID" = field("Table ID")));
        }

    }

    keys
    {
        key(PK; "Company Name", "Table ID", "No.")
        {
            Clustered = true;
        }
    }

}