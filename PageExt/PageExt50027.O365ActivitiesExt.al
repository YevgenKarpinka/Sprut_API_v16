pageextension 50027 "O365 Activities Ext." extends "O365 Activities"
{
    layout
    {
        // Add changes to page layout here
        addbefore("Ongoing Sales")
        {
            cuegroup(Sprut)
            {
                CaptionML = ENU = 'Sprut',
                            RUS = 'Спрут';

                field("UnApply Prepm. Doc."; "UnApply Prepm. Doc.")
                {
                    ApplicationArea = All;

                }
                field("Deduplicated Customers"; "Deduplicated Customers")
                {
                    ApplicationArea = All;

                }
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}