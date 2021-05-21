tableextension 50001 "Sales & Receivables Setup Ext" extends "Sales & Receivables Setup"
{
    fields
    {
        // Add changes to table fields here
        field(50000; "Allow Grey Agreement"; Boolean)
        {

            CaptionML = ENU = 'Allow Grey Agreement',
                        RUS = 'Разрешить серый договор';
        }
    }
}