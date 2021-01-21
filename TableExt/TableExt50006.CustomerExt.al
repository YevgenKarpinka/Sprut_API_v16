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
            CaptionML = ENU = 'CRM ID',
                        RUS = 'CRM ID';
            Editable = false;
        }
        field(50002; "1C Path"; Text[30])
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = '1C Path',
                        RUS = '1C Путь';
            Editable = false;
        }
        field(50003; "Certificate"; Text[20])
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'Certificate',
                        RUS = 'Свидетельство';
        }
        field(50004; "Deduplicate Id"; Guid)
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'Deduplicate Id',
                        RUS = 'Дедубликат ИД';
            Editable = false;
        }
        field(50005; Status; Text[20])
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'Status CRM',
                        RUS = 'Статус CRM';
            Editable = false;
        }
    }
}