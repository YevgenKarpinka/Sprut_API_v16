pageextension 50026 "Item Card Ext." extends "Item Card"
{
    layout
    {
        // Add changes to page layout here
        addlast(Purchase)
        {
            field("CRM Item Id"; "CRM Item Id")
            {
                ApplicationArea = All;

            }
        }
    }
}