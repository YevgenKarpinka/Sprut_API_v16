pageextension 50028 "Customer Agreements Card Ext" extends "Customer Agreement Card"
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
            field("CRM ID"; "CRM ID")
            {
                ApplicationArea = All;
                ToolTipML = ENU = 'Specifies the CRM ID of the customer agreement.',
                            RUS = 'Указывает CRM ID договора клиента.';
            }
        }
    }
}