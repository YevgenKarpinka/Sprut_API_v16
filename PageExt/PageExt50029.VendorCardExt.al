pageextension 50029 "Vendor Card Ext." extends "Vendor Card"
{
    layout
    {
        // Add changes to page layout here
        addafter("VAT Registration No.")
        {
            field(Certificate; Certificate)
            {
                ApplicationArea = All;
                ToolTipML = ENU = 'Specifies the number of the Certificate.',
                            RUS = 'Указывает на номер Свидетельства.';
            }
        }
        addafter(Blocked)
        {
            field("Deduplicate No."; "Deduplicate No.")
            {
                ApplicationArea = All;
                ToolTipML = ENU = 'Specifies the Deduplicate No.',
                            RUS = 'Указывает на номер дедубликации.';
            }
        }
    }

}