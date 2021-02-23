pageextension 50015 "Posted Sales Credit Memo Ext" extends "Posted Sales Credit Memo"
{
    layout
    {
        // Add changes to page layout here
        addbefore("Sell-to Customer Name")
        {
            field("Sell-to Customer No."; "Sell-to Customer No.")
            {
                Visible = false;
            }
            field("Customer CRM ID"; MatchContragent.GetCustomerCRMID("Sell-to Customer No."))
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