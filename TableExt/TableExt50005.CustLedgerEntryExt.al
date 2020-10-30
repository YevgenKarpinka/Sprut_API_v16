tableextension 50005 "Cust. Ledger Entry Ext" extends "Cust. Ledger Entry"
{
    fields
    {
        // Add changes to table fields here
        field(50000; "CRM Payment Id"; Text[50])
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'CRM Payment Id',
                        RUS = 'Id платежа в CRM';
        }

    }
}