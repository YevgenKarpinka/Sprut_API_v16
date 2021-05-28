page 50023 "Activity Entries List"
{
    CaptionML = ENU = 'Activity Entries List',
                RUS = 'Операции событий список';
    SourceTable = "Activity Entries";
    DataCaptionFields = "Company Name", "Table ID", "No.";
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
                field("Company Name"; "Company Name")
                {
                    ApplicationArea = All;

                }
                field("Table ID"; "Table ID")
                {
                    ApplicationArea = All;

                }
                field("No."; "No.")
                {
                    ApplicationArea = All;

                }
                field(Description; Description)
                {
                    ApplicationArea = All;

                }
                field("Error Text"; "Error Text")
                {
                    ApplicationArea = All;

                }
                field("Object Name"; "Object Name")
                {
                    ApplicationArea = All;

                }
            }
        }
    }
}