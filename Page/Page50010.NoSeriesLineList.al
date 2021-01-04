page 50010 "No. Series Line List"
{
    CaptionML = ENU = 'No. Series Line List',
                RUS = 'Список строк серий номеров';
    // InsertAllowed = false;
    SourceTable = "No. Series Line";
    DataCaptionFields = "Series Code";
    ApplicationArea = All;
    PageType = List;
    UsageCategory = History;
    // Editable = true;


    layout
    {
        area(Content)
        {
            repeater(RepeaterName)
            {
                field("Series Code"; "Series Code")
                {
                    ApplicationArea = All;
                    // Visible = false;
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = All;
                    // Visible = false;
                }
                field("Starting No."; "Starting No.")
                {
                    ApplicationArea = All;
                    // Visible = false;
                }
                field("Last No. Used"; "Last No. Used")
                {
                    ApplicationArea = All;
                    // Visible = false;
                }
                field("Last Date Used"; "Last Date Used")
                {
                    ApplicationArea = All;
                    // Visible = false;
                }
                field("Warning No."; "Warning No.")
                {
                    ApplicationArea = All;
                    // Visible = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(DeleteLastNoUsed)
            {
                CaptionML = ENU = 'Delete Last No Used',
                            RUS = 'Удалить последний использованный номер';
                action(Delete)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'Delete',
                                RUS = 'Удалить';
                    Image = Delete;

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(NoSeriesLine);
                        NoSeriesLine.ModifyAll("Last No. Used", '', true);
                        NoSeriesLine.ModifyAll("Last Date Used", 0D, true);
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    var
        NoSeriesLine: Record "No. Series Line";
}