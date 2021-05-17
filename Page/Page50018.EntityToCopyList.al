page 50018 "Entity To Copy List"
{
    CaptionML = ENU = 'Entity To Copy List',
                RUS = 'Сущности для клонирования список';
    SourceTable = "Entity To Copy";
    DataCaptionFields = Type, "No.";
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
                field(Type; Type)
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
            }
        }
    }
}