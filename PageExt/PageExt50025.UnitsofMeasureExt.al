pageextension 50025 "Units of Measure Ext." extends "Units of Measure"
{
    layout
    {
        // Add changes to page layout here
        addlast(Control1)
        {
            field("Numeric Code"; "Numeric Code")
            {
                ApplicationArea = All;

            }
        }
    }
}