pageextension 50022 "Posted Purch. Cr.M Subform Ext" extends "Posted Purch. Cr. Memo Subform"
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
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        MatchContragent: Codeunit "Match Contragent";
}