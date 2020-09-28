pageextension 50001 "Sales Order Subform Ext" extends "Sales Order Subform"
{
    layout
    {
        // Add changes to page layout here
        addafter("Prepayment %")
        {
            field("Prepmt. Amount Inv. (LCY)"; "Prepmt. Amount Inv. (LCY)")
            {
                ApplicationArea = All;
            }
            field("Prepmt. Amount Inv. Incl. VAT"; "Prepmt. Amount Inv. Incl. VAT")
            {
                ApplicationArea = All;
            }
            field("Prepmt. Amt. Incl. VAT"; "Prepmt. Amt. Incl. VAT")
            {
                ApplicationArea = All;
            }
            field("Prepmt. VAT Amount Inv. (LCY)"; "Prepmt. VAT Amount Inv. (LCY)")
            {
                ApplicationArea = All;
            }
            field("Prepmt. VAT Base Amt."; "Prepmt. VAT Base Amt.")
            {
                ApplicationArea = All;
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