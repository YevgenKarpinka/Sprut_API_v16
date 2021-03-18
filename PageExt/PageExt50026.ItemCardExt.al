pageextension 50026 "Item Card Ext." extends "Item Card"
{
    layout
    {
        // Add changes to page layout here
        addlast(Item)
        {
            field("CRM Item Id"; "CRM Item Id")
            {
                ApplicationArea = All;

            }
            field("1C Path"; "1C Path")
            {
                ApplicationArea = All;

            }
        }
    }
}