tableextension 50005 "Dtld. Cust. Ledg. Entry Ext" extends "Detailed Cust. Ledg. Entry"
{
    fields
    {
        // Add changes to table fields here
        field(50000; "CRM Invoice No."; Text[50])
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'CRM Invoice No.',
                        RUS = 'CRM Номер Счета';
        }
        field(50001; "CRM Payment Id"; Guid)
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'CRM Payment Id',
                        RUS = 'CRM Id платежа';
        }
    }
}