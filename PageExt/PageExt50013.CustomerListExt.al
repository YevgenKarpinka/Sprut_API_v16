pageextension 50013 "Customer List Ext." extends "Customer List"
{
    layout
    {
        // Add changes to page layout here
        addlast(Control1)
        {
            field("VAT Registration No."; "VAT Registration No.")
            {
                ApplicationArea = All;
            }
            field("TAX Registration No."; "TAX Registration No.")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        // Add changes to page actions here
        // addfirst("&Customer")
        // {
        //     action(DeleteAllFiltered)
        //     {
        //         ApplicationArea = All;
        //         CaptionML = ENU = 'DeleteAllFiltered',
        //                     RUS = 'DeleteAllFiltered';

        //         trigger OnAction()
        //         var
        //             Cust: Record Customer;
        //         begin
        //             CurrPage.SetSelectionFilter(Cust);
        //             if Confirm('Delete All?', true) then
        //                 Cust.DeleteAll();
        //             CurrPage.Update(false);
        //         end;
        //     }
        // }
    }

}