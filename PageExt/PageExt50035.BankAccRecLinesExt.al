pageextension 50035 "Bank Acc. Rec. Lines Ext" extends "Bank Acc. Reconciliation Lines"
{
    layout
    {
        // Add changes to page layout here
        addbefore(Description)
        {
            field("Description Extended"; "Description Extended")
            {
                ApplicationArea = All;
            }
        }
        modify(Description)
        {
            Visible = false;
        }
    }

}