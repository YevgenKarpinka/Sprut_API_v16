tableextension 50003 "Sales Invoice Header Ext" extends "Sales Invoice Header"
{
    fields
    {
        // Add changes to table fields here
        field(50000; "CRM Invoice No."; Text[50])
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'CRM Invoice No.',
                        RUS = 'Номер инвойса в CRM';
        }
        field(50001; "Last Modified Date Time"; DateTime)
        {
            DataClassification = SystemMetadata;
            CaptionML = ENU = 'Last Modified Date Time',
                        RUS = 'Дата и время последнего изменения';
            Editable = false;
        }
    }
}