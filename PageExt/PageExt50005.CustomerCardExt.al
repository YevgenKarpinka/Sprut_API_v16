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
        }
    }
}