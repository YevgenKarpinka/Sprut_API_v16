pageextension 50009 "User Setup Ext" extends "User Setup"
{
    layout
    {
        // Add changes to page layout here
        addafter("User ID")
        {
            field("Send Email UnApply Doc."; "Send Email UnApply Doc.")
            {
                ApplicationArea = All;
                ToolTipML = ENU = 'Specifies Send Email UnApplied Documents after modifying sales order',
                            RUS = 'Указывает что нужно отослать письмо с непримененными документами после изменения заказа продажи.';
            }
        }
    }
}