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
                Visible = false;
            }
            field("Prepmt. Amount Inv. Incl. VAT"; Rec."Prepmt. Amount Inv. Incl. VAT")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("Prepmt. Amt. Incl. VAT"; Rec."Prepmt. Amt. Incl. VAT")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("Prepmt. VAT Amount Inv. (LCY)"; Rec."Prepmt. VAT Amount Inv. (LCY)")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("Prepmt. VAT Base Amt."; Rec."Prepmt. VAT Base Amt.")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("CRM ID"; "CRM ID")
            {
                ApplicationArea = All;
                Visible = false;
            }
        }
        addbefore("Line Amount")
        {
            field("VATPercent"; MatchContragent.GetVATPercent("VAT Bus. Posting Group", "VAT Prod. Posting Group"))
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("VAT Base Amount"; "VAT Base Amount")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("Amount Including VAT"; "Amount Including VAT")
            {
                ApplicationArea = All;
                Visible = false;
            }
        }
    }
    actions
    {
        // Add changes to page actions here
    }

    var
        MatchContragent: Codeunit "Match Contragent";
}