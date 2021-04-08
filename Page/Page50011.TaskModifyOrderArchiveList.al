page 50011 "Task Modify Order Archive List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Task Modify Order";
    Editable = false;
    SourceTableView = order(descending) where(Status = const(Done));
    CaptionML = ENU = 'Task Modify Order Archive List',
                RUS = 'Архив списка задач модификации заказа';

    layout
    {
        area(Content)
        {
            repeater(ItemsTransferSite)
            {
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = All;
                }
                field(Status; Status)
                {
                    ApplicationArea = All;
                }
                field("Work Status"; "Work Status")
                {
                    ApplicationArea = All;
                }
                field("Order No."; "Order No.")
                {
                    ApplicationArea = All;
                }
                field("Create User Name"; "Create User Name")
                {
                    ApplicationArea = All;
                }
                field("Create Date Time"; "Create Date Time")
                {
                    ApplicationArea = All;
                }
                field("Modify User Name"; "Modify User Name")
                {
                    ApplicationArea = All;
                }
                field("Modify Date Time"; "Modify Date Time")
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