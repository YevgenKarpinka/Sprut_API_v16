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
        field(50001; "Allow VAT Rounding Precision"; Boolean)
        {

            CaptionML = ENU = 'Allow VAT Rounding Precision',
                        RUS = 'Разрешить точность округления НДС';
        }
        field(50002; "VAT Rounding Precision"; Decimal)
        {

            CaptionML = ENU = 'VAT Rounding Precision',
                        RUS = 'Точность округления НДС';
            InitValue = 0.001;
            DecimalPlaces = 2 : 5;
            MinValue = 0;
        }
    }
}