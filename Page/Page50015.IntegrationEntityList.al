page 50015 "Integration Entity List"
{
    CaptionML = ENU = 'Integration Entity List',
                RUS = 'Список сущностей интеграции';
    // InsertAllowed = false;
    SourceTable = "Integration Entity";
    DataCaptionFields = "System Code", "Table Name", "Code 1", "Code 2";
    ApplicationArea = All;
    // Editable = false;
    PageType = List;
    UsageCategory = History;
    // AccessByPermission = tabledata "Integration Entity" = r;

    layout
    {
        area(Content)
        {
            repeater(RepeaterName)
            {
                // Editable = false;
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
                field("Entity Id"; "Entity Id")
                {
                    ApplicationArea = All;

                }
                field("Entity Code"; "Entity Code")
                {
                    ApplicationArea = All;

                }
                field("Company Name"; "Company Name")
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
    {
        area(Processing)
        {
            group(DeleteEntries)
            {
                CaptionML = ENU = 'Delete Entries',
                            RUS = 'Удалить операции';
                action(DeleteSevenDaysOld)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'Delete 7 Days Old',
                                RUS = 'Удалить старше 7ми дней';

                    trigger OnAction()
                    begin
                        DeleteEntries(7);
                    end;
                }
                action(DeleteAll)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'Delete All',
                                RUS = 'Удалить все';

                    trigger OnAction()
                    begin
                        DeleteEntries(0);
                    end;
                }
            }
        }
    }
}