page 50004 "Task Modify Order List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Task Modify Order";
    Editable = false;
    CaptionML = ENU = 'Task Modify Order List',
                RUS = 'Task Modify Order List';

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
}