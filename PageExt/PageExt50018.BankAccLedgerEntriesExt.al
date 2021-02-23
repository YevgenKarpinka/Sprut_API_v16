pageextension 50018 "Bank Acc. Ledger Entries Ext" extends "Bank Account Ledger Entries"
{
    layout
    {
        // Add changes to page layout here
        addbefore("Bal. Account No.")
        {
            field("Customer CRM ID"; MatchContragent.GetCustomerCRMID("Bal. Account No."))
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