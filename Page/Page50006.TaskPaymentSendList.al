page 50006 "Task Payment Send List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Task Payment Send";
    // Editable = false;
    CaptionML = ENU = 'Task Payment Send List',
                RUS = 'Список задач передачи платежей';

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
                field("Entry Type"; "Entry Type")
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
                field("Dtld. Cust. Ledg. Entry No."; "Dtld. Cust. Ledg. Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Invoice Entry No."; "Invoice Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Payment Entry No."; "Payment Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Payment No."; "Payment No.")
                {
                    ApplicationArea = All;
                }
                field("Payment Amount"; "Payment Amount")
                {
                    ApplicationArea = All;
                }
                field("CRM Payment Id"; "CRM Payment Id")
                {
                    ApplicationArea = All;
                }
                field("Attempts Send"; "Attempts Send")
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