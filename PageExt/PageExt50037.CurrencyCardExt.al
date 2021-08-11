pageextension 50037 "Currency Card Ext" extends "Currency Card"
{
    layout
    {
        // Add changes to page layout here
        addafter("VAT Rounding Type")
        {
            field("Enable VAT Order Round"; "Enable VAT Order Round")
            {
                ApplicationArea = All;
            }
            field("VAT Order Rounding Precision"; "VAT Order Rounding Precision")
            {
                ApplicationArea = All;
            }
        }
    }

}