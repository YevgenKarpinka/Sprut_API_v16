tableextension 50004 "Item Ext" extends Item
{
    fields
    {
        // Add changes to table fields here
        field(50000; "CRM Item Id"; Text[50])
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'CRM Item Id',
                        RUS = 'Id товара в CRM';
        }
    }

    var
        myInt: Integer;
}