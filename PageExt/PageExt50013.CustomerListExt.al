pageextension 50013 "Customer List Ext." extends "Customer List"
{
    layout
    {
        // Add changes to page layout here
        addafter(Name)
        {
            field("Init 1C"; "Init 1C")
            {
                ApplicationArea = All;
                ToolTipML = ENU = 'Specifies transfer to 1C of the customer.',
                            RUS = 'Указывает передавать ли клиента в 1С.';
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

}