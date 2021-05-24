pageextension 50006 "Customer Agreements Ext" extends "Customer Agreements"
{
    layout
    {
        // Add changes to page layout here
        addafter(Active)
        {
            field("Init 1C"; "Init 1C")
            {
                ApplicationArea = All;
                ToolTipML = ENU = 'Specifies transfer to 1C of the customer agreement.',
                            RUS = 'Указывает передавать ли договор клиента в 1С.';
            }
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