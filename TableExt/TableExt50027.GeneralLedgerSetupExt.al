tableextension 50027 "General Ledger Setup Ext" extends "General Ledger Setup"
{
    fields
    {
        // Add changes to table fields here
        field(50000; "VAT Order Rounding Precision"; Decimal)
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'VAT Order Rounding Precision',
                        RUS = 'Точность округления НДС заказа';
            DecimalPlaces = 2 : 5;
        }
        field(50001; "Enable VAT Order Round"; Boolean)
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'Enable VAT Order Round',
                        RUS = 'Включить округления НДС заказа';
        }
        field(50002; "Disable Check Cust. Prep."; Boolean)
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'Disable Check Date Apply Customer Prepayment',
                        RUS = 'Выключить проверку даты применения предоплаты клиента';
        }
        field(50003; "Disable Check Vend. Prep."; Boolean)
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'Disable Check Date Apply Vendor Prepayment',
                        RUS = 'Выключить проверку даты применения предоплаты постащику';
        }
    }
}