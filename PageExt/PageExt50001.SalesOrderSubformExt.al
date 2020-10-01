pageextension 50001 "Sales Order Subform Ext" extends "Sales Order Subform"
{
    layout
    {
        // Add changes to page layout here
        addafter("Prepayment %")
        {
            field("Prepmt. Amount Inv. (LCY)"; Rec."Prepmt. Amount Inv. (LCY)")
            {
                ApplicationArea = All;
            }
            field("Prepmt. Amount Inv. Incl. VAT"; Rec."Prepmt. Amount Inv. Incl. VAT")
            {
                ApplicationArea = All;
            }
            field("Prepmt. Amt. Incl. VAT"; Rec."Prepmt. Amt. Incl. VAT")
            {
                ApplicationArea = All;
            }
            field("Prepmt. VAT Amount Inv. (LCY)"; Rec."Prepmt. VAT Amount Inv. (LCY)")
            {
                ApplicationArea = All;
            }
            field("Prepmt. VAT Base Amt."; Rec."Prepmt. VAT Base Amt.")
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