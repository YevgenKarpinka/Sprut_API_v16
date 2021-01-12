pageextension 50005 "Customer Card Ext" extends "Customer Card"
{
    layout
    {
        // Add changes to page layout here
        addafter("VAT Registration No.")
        {
            field("TAX Registration No."; "TAX Registration No.")
            {
                ApplicationArea = All;
                ToolTipML = ENU = 'Specifies the display name of the tax registration number.',
                            RUS = 'Указывает отображаемое имя регистрационного номера налогоплательщика.';
            }
            field(Certificate; Certificate)
            {
                ApplicationArea = All;
                ToolTipML = ENU = 'Specifies the display name of the Certificate.',
                            RUS = 'Указывает отображаемое имя Свидетельства.';
            }
            field("1C Path"; "1C Path")
            {
                ApplicationArea = All;
                ToolTipML = ENU = 'Specifies the display name of the 1C Path.',
                            RUS = 'Указывает на 1C Путь.';
            }
            field("CRM ID"; "CRM ID")
            {
                ApplicationArea = All;
                ToolTipML = ENU = 'Specifies the display name of the CRM Id.',
                            RUS = 'Указывает на CRM Id.';
            }
            field("Deduplicate Id"; "Deduplicate Id")
            {
                ApplicationArea = All;
                ToolTipML = ENU = 'Specifies the display name of the Deduplicate Id.',
                            RUS = 'Указывает на Дедубликат ИД.';
            }
        }
    }
}