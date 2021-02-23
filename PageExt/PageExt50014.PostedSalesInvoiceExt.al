pageextension 50014 "Posted Sales Invoice Ext" extends "Posted Sales Invoice"
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