pageextension 50008 "Accountant Role Center Ext" extends "Accountant Role Center"
{
    layout
    {
        // Add changes to page layout here
        addafter(Control103)
        {
            part(UnAppliedPrepCustEntryes; "UnApplied Prepm. Cust. Entry")
            {
                ApplicationArea = All;
            }
            part(CustomersDeduplicateList; "Customers Deduplicate List")
            {
                ApplicationArea = All;
            }
        }

        modify(Control103)
        {
            Visible = true;
        }
        modify(Control106)
        {
            Visible = true;
        }
        modify(Control100)
        {
            Visible = false;
        }
        modify(Control10)
        {
            Visible = false;
        }
        modify(Control122)
        {
            Visible = false;
        }
        modify(Control108)
        {
            Visible = false;
        }
    }
}