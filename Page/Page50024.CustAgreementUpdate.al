page 50024 "Cust. Agreement Update"
{
    CaptionML = ENU = 'Cust. Agreement Update',
                RUS = 'Договора клиентов для обновления';
    SourceTable = "Customer Agreement";
    DataCaptionFields = "No.", "Customer No.";
    ApplicationArea = All;
    PageType = List;
    UsageCategory = History;
    // Editable = false;

    layout
    {
        area(Content)
        {
            repeater(RepeaterName)
            {
                field("Customer No."; "Customer No.")
                {
                    ApplicationArea = All;

                }
                field("No."; "No.")
                {
                    ApplicationArea = All;

                }
                field("External Agreement No."; "External Agreement No.")
                {
                    ApplicationArea = All;

                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = All;

                }
                field("CRM ID"; "CRM ID")
                {
                    ApplicationArea = All;

                }
                field("Init 1C"; "Init 1C")
                {
                    ApplicationArea = All;

                }
            }
        }
    }
}