table 50010 "Activity Entries"
{
    DataClassification = CustomerContent;
    DataPerCompany = false;
    DrillDownPageId = "Activity Entries List";

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
        field(3; "No."; Text[50])
        {
            DataClassification = SystemMetadata;
            CaptionML = ENU = 'No.',
                        RUS = 'Но.';
        }
        field(4; "Description"; Text[250])
        {
            DataClassification = SystemMetadata;
            CaptionML = ENU = 'Description',
                        RUS = 'Описание';
        }
        field(5; "Object Name"; Text[30])
        {
            CaptionML = ENU = 'Object Name',
                        RUS = 'Имя объекта';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = Lookup(AllObjWithCaption."Object Name" where("Object Type" = const(Table), "Object ID" = field("Table ID")));
        }
        field(6; "Error Text"; Text[2048])
        {
            DataClassification = SystemMetadata;
            CaptionML = ENU = 'Error Text',
                        RUS = 'Текст ошибки';
        }
        field(7; "Last Modify Date Time"; DateTime)
        {
            DataClassification = SystemMetadata;
            CaptionML = ENU = 'Last Modify Date Time',
                        RUS = 'Дата и время последней модификации';
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