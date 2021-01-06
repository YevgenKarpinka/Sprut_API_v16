tableextension 50006 "Customer Ext" extends Customer
{
    fields
    {
        // Add changes to table fields here
        field(50000; "TAX Registration No."; Text[20])
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'TAX Registration No.',
                        RUS = 'ИНН Sprut';
        }
        field(50001; "CRM ID"; Guid)
        {
            DataClassification = CustomerContent;
        }
    }
}