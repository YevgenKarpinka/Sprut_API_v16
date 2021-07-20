pageextension 50002 "Sales & Receivables Setup Ext" extends "Sales & Receivables Setup"
{
    layout
    {
        // Add changes to page layout here
        addafter("Copy Line Descr. to G/L Entry")
        {
            field("Allow Grey Agreement"; "Allow Grey Agreement")
            {
                ApplicationArea = All;
                ToolTipML = ENU = 'Specifies Allow Grey Agreements.',
                            RUS = 'Разрешает создание серых договоров.';
            }
        }
        addafter("Discount Decimal Points")
        {
            field("Allow VAT Rounding Precision"; "Allow VAT Rounding Precision")
            {
                ApplicationArea = All;
                ToolTipML = ENU = 'Specifies Allow VAT Rounding Precision in Sales Documents.',
                            RUS = 'Разрешает специальное округление НДС в документах продажи.';
            }
            field("VAT Rounding Precision"; "VAT Rounding Precision")
            {
                ApplicationArea = All;
                ToolTipML = ENU = 'Specifies VAT Rounding Precision in Sales Documents.',
                            RUS = 'Определяет специальное округление НДС в документах продажи.';
            }
        }
    }
}