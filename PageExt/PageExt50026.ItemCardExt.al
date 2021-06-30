pageextension 50026 "Item Card Ext." extends "Item Card"
{
    layout
    {
        // Add changes to page layout here
        addafter(Description)
        {
            field("Description Print"; "Description Print")
            {
                ApplicationArea = All;

            }
        }
        addlast(Item)
        {
            field("CRM Item Id"; "CRM Item Id")
            {
                ApplicationArea = All;
                Editable = AllowEdit;

            }
            field("1C Path"; "1C Path")
            {
                ApplicationArea = All;
                Editable = AllowEdit;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if UserSetup.Get(UserId) then
            AllowEdit := UserSetup."Admin. Holding";
    end;

    var
        UserSetup: Record "User Setup";
        AllowEdit: Boolean;
}