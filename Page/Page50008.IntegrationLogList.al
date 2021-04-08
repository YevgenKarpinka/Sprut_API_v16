page 50008 "Integration Log List"
{
    CaptionML = ENU = 'Integration Log List',
                RUS = 'Список операций интеграции';
    InsertAllowed = false;
    SourceTable = "Integration Log";
    CardPageId = "Integration Log Card";
    SourceTableView = sorting("Entry No.") order(Descending);
    DataCaptionFields = "Entry No.", "Source Operation";
    ApplicationArea = All;
    Editable = false;
    PageType = List;
    UsageCategory = History;
    AccessByPermission = tabledata "Integration Log" = r;

    layout
    {
        area(Content)
        {
            repeater(RepeaterName)
            {
                Editable = false;
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;

                }
                field("Operation Date"; Rec."Operation Date")
                {
                    ApplicationArea = All;

                }
                field("Source Operation"; Rec."Source Operation")
                {
                    ApplicationArea = All;

                }
                field("Operation Status"; Rec.Success)
                {
                    ApplicationArea = All;

                }
                field("Company Name"; "Company Name")
                {
                    ApplicationArea = All;

                }
                field("User Id"; "User Id")
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