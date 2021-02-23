pageextension 50021 "Posted Purch. Inv Subform Ext" extends "Posted Purch. Invoice Subform"
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