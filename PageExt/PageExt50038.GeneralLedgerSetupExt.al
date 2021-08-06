pageextension 50038 "General Ledger Setup Ext" extends "General Ledger Setup"
{
    layout
    {
        // Add changes to page layout here
        addafter("VAT Rounding Type")
        {
            field("VAT Order Rounding Precision"; "VAT Order Rounding Precision")
            {
                ApplicationArea = All;
            }
        }
    }

}