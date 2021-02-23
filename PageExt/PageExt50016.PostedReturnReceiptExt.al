pageextension 50016 "Posted Return Receipt Ext" extends "Posted Return Receipt"
{
    layout
    {
        // Add changes to page layout here
        addbefore("Sell-to Customer Name")
        {
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