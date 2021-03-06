pageextension 50028 "Customer Agreements Card Ext" extends "Customer Agreement Card"
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
                // Editable = AllowGreyAgreement;

            }
            field(Status; Status)
            {
                ApplicationArea = All;
                ToolTipML = ENU = 'Specifies the status of the customer agreement.',
                            RUS = 'Указывает статус договора клиента.';
            }
            field(Print; Print)
            {
                ApplicationArea = All;
                ToolTipML = ENU = 'Specifies the print of the customer agreement.',
                            RUS = 'Указывает печатать ли договор клиента.';
            }
            field("CRM ID"; "CRM ID")
            {
                ApplicationArea = All;
                ToolTipML = ENU = 'Specifies the CRM ID of the customer agreement.',
                            RUS = 'Указывает CRM ID договора клиента.';
            }
            field("Additional Date"; "Additional Date")
            {
                ApplicationArea = All;
                ToolTipML = ENU = 'Specifies the Additional Date of the customer agreement.',
                            RUS = 'Указывает дату дополнения к договору клиента.';
            }
            field("BC Id"; "BC Id")
            {
                ApplicationArea = All;
                ToolTipML = ENU = 'Specifies the BC ID of the customer agreement.',
                            RUS = 'Указывает БЦ ID договора клиента.';
            }
        }
    }

    trigger OnOpenPage()
    begin
        SRSetup.Get();
        AllowGreyAgreement := SRSetup."Allow Grey Agreement";
    end;

    var
        SRSetup: Record "Sales & Receivables Setup";
        AllowGreyAgreement: Boolean;


}