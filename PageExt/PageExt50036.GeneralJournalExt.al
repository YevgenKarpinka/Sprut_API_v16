pageextension 50036 "General Journal Ext" extends "General Journal"
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