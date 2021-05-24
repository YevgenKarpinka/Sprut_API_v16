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
    }
}