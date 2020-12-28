tableextension 50004 "Item Ext" extends Item
{
    fields
    {
        // Add changes to table fields here
        field(50000; "CRM Item Id"; Guid)
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'CRM Item Id',
                        RUS = 'Id товара в CRM';
            Editable = false;
        }
        field(50001; "1C Path"; Text[30])
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = '1C Path',
                        RUS = '1C Путь';
            Editable = false;
        }
    }
}