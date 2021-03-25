page 50018 "Item To Copy List"
{
    CaptionML = ENU = 'Item To Copy List',
                RUS = 'Товары для клонирования список';
    SourceTable = "Item To Copy";
    DataCaptionFields = Type, "No.";
    ApplicationArea = All;
    PageType = List;
    UsageCategory = History;
    Editable = false;

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