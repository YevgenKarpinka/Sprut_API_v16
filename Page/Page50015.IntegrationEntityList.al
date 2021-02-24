page 50015 "Integration Entity List"
{
    CaptionML = ENU = 'Integration Entity List',
                RUS = 'Список сущностей интеграции';
    InsertAllowed = false;
    SourceTable = "Integration Entity";
    // SourceTableView = sorting("Entry No.") order(Descending);
    DataCaptionFields = "System Code", "Table Name", "Code 1", "Code 2";
    ApplicationArea = All;
    Editable = false;
    PageType = List;
    UsageCategory = History;
    AccessByPermission = tabledata "Integration Entity" = r;

    layout
    {
        area(Content)
        {
            repeater(RepeaterName)
            {
                Editable = false;
                field("System Code"; "System Code")
                {
                    ApplicationArea = All;

                }
                field("Table ID"; "Table ID")
                {
                    ApplicationArea = All;

                }
                field("Table Name"; "Table Name")
                {
                    ApplicationArea = All;

                }
                field("Code 1"; "Code 1")
                {
                    ApplicationArea = All;

                }
                field("Code 2"; "Code 2")
                {
                    ApplicationArea = All;

                }
                field("Company Name"; "Company Name")
                {
                    ApplicationArea = All;

                }
                field("Entity Id"; "Entity Id")
                {
                    ApplicationArea = All;

                }
                field("Create Date Time"; "Create Date Time")
                {
                    ApplicationArea = All;

                }
                field("Last Modify Date Time"; "Last Modify Date Time")
                {
                    ApplicationArea = All;

                }
            }
        }
    }

    actions
    { }
}