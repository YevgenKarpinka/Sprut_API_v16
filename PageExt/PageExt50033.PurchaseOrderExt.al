pageextension 50033 "Purchase Order Ext" extends "Purchase Order"
{
    layout
    {
        // Add changes to page layout here
        modify("Agreement No.")
        {
            ApplicationArea = Suite;
        }

    }
}