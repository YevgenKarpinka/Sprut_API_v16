pageextension 50002 "Sales & Receivables Setup Ext" extends "Sales & Receivables Setup"
{
    layout
    {
        // Add changes to page layout here
        addafter("Create Prepayment Invoice")
        {
            field("Allow Modifying"; Rec."Allow Modifying")
            {
                ApplicationArea = All;
                ToolTipML = ENU = 'Specifies recalculation amounts if you want to modify prepayment invoice.',
                            RUS = 'Пересчитывает суммы в строках при изменении счета на предоплату.';
            }
        }
    }
}