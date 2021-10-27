pageextension 50038 "General Ledger Setup Ext" extends "General Ledger Setup"
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
            field("Disable Check Cust. Prep."; "Disable Check Cust. Prep.")
            {
                ApplicationArea = All;
            }
            field("Disable Check Vend. Prep."; "Disable Check Vend. Prep.")
            {
                ApplicationArea = All;
            }
        }
    }
}