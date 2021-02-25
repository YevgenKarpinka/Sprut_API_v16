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
            field("CRM Invoice No."; "CRM Invoice No.")
            {
                Visible = false;
            }
            field("CRM ID"; "CRM ID")
            {
                Visible = false;
            }
            field("Prepayment Order No."; "Prepayment Order No.")
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

    // trigger OnAfterGetRecord()
    // begin
    //     if GetCustomerLedgerEntry() then

    //     end;
}