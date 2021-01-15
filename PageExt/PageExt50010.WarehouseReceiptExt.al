pageextension 50010 "Warehouse Receipt Ext." extends "Warehouse Receipt"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
        addbefore("Post Receipt")
        {
            action(sprutPostReceipt)
            {
                ApplicationArea = All;
                CaptionML = ENU = 'sprut Post Receipt',
                            RUS = 'sprut Post Receipt';
                Visible = false;

                trigger OnAction()
                begin
                    CurrPage.WhseReceiptLines.PAGE.WhsePostRcptYesNo;
                end;
            }
        }
    }

    var
        myInt: Integer;
}