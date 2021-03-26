tableextension 50021 "Vendor Ext" extends Vendor
{
    fields
    {
        // Add changes to table fields here
        field(50000; "Certificate"; Text[20])
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'Certificate',
                        RUS = 'Свидетельство';
        }

    }
}