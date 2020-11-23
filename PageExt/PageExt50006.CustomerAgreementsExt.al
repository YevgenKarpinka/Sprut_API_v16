pageextension 50006 "Customer Agreements Ext" extends "Customer Agreements"
{
    layout
    {
        // Add changes to page layout here
        addafter(Active)
        {
            field(Status; Status)
            {
                ApplicationArea = All;
                ToolTipML = ENU = 'Specifies the status of the customer agreement.',
                            RUS = 'Указывает статус договора клиента.';
            }
        }
    }
}