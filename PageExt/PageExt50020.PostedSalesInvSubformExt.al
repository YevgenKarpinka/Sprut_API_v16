pageextension 50020 "Posted Sales Inv Subform Ext" extends "Posted Sales Invoice Subform"
{
    layout
    {
        // Add changes to page layout here
        addbefore("Line Amount")
        {
            field("VATPercent"; MatchContragent.GetVATPercent("VAT Bus. Posting Group", "VAT Prod. Posting Group"))
            {
                Visible = false;
            }
            field("VAT Base Amount"; "VAT Base Amount")
            {
                Visible = false;
            }
            field("Amount Including VAT"; "Amount Including VAT")
            {
                Visible = false;
            }
            field("Description Extended"; "Description Extended")
            {
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