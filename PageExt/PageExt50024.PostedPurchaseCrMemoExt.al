pageextension 50024 "Posted Purchase Cr.Memo Ext" extends "Posted Purchase Credit Memo"
{
    layout
    {
        // Add changes to page layout here
        addbefore("Buy-from Vendor Name")
        {
            field("Buy-from Vendor No."; "Buy-from Vendor No.")
            {
                Visible = false;
            }
            // field("Customer CRM ID"; MatchContragent.GetCustomerCRMID("Sell-to Customer No."))
            // {
            //     Visible = false;
            // }
            field("Currency ISO Code"; MatchContragent.GetCurrencyISONumericCode("Currency Code"))
            {
                Visible = false;
            }
            field(Amount; Amount)
            {
                Visible = false;
            }
            field("Amount Including VAT"; "Amount Including VAT")
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