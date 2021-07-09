pageextension 50034 "Posted Sales Shpt. Subform Ext" extends "Posted Sales Shpt. Subform"
{
    layout
    {
        // Add changes to page layout here
        addbefore("Appl.-to Item Entry")
        {
            field("Description Extended"; "Description Extended")
            {
                Visible = false;
            }
        }
    }

}