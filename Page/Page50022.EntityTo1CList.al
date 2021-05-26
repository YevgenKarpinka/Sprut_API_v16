page 50022 "Entity To 1C List"
{
    CaptionML = ENU = 'Entity To 1C List',
                RUS = 'Сущности для 1С список';
    SourceTable = "Entity To 1C";
    DataCaptionFields = "Company Name", "Table ID", "Key 1", "Key 2";
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
                field("Key 1"; "Key 1")
                {
                    ApplicationArea = All;

                }
                field("Key 2"; "Key 2")
                {
                    ApplicationArea = All;

                }
                field(Description; Description)
                {
                    ApplicationArea = All;

                }
            }
        }
    }
}