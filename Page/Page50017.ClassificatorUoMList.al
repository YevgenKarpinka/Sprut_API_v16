page 50017 "Classificator UoM List"
{
    CaptionML = ENU = 'Classificator UoM List',
                RUS = 'Классификатор единиц измерения список';
    SourceTable = "Classificator Unit of Measure";
    DataCaptionFields = "Short Name", "Numeric Code", Description;
    ApplicationArea = All;
    PageType = List;
    UsageCategory = History;

    layout
    {
        area(Content)
        {
            repeater(RepeaterName)
            {
                field("Numeric Code"; "Numeric Code")
                {
                    ApplicationArea = All;

                }
                field("Short Name"; "Short Name")
                {
                    ApplicationArea = All;

                }
                field(Description; Description)
                {
                    ApplicationArea = All;

                }
                field("Short Name EU"; "Short Name EU")
                {
                    ApplicationArea = All;

                }
                field("Numeric Code EU"; "Numeric Code EU")
                {
                    ApplicationArea = All;

                }
            }
        }
    }
}