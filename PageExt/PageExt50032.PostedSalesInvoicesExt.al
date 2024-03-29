pageextension 50032 "Posted Sales Invoices Ext" extends "Posted Sales Invoices"
{
    layout
    {
        // Add changes to page layout here
        addafter(Corrective)
        {
            field("Invoice No. 1C"; "Invoice No. 1C")
            {
                ApplicationArea = All;
                Visible = false;
            }
        }
    }

    actions
    {
        // Add changes to page actions here
        addafter(Invoice)
        {
            group(SprutAdmin)
            {
                CaptionML = ENU = 'Sprut',
                            RUS = 'Спрут';

                action(ApplyInvoiceToCrMemo)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'Apply Invoices To CrMemo',
                                RUS = 'Применить инвойсы к кредит-нотам';
                    Image = ApplyEntries;

                    trigger OnAction()
                    var
                        PrepMgt: Codeunit "Prepayment Management";
                        SIH: Record "Sales Invoice Header";
                    begin
                        CurrPage.SetSelectionFilter(SIH);
                        SIH.FindSet();
                        repeat
                            PrepMgt.PostedPrepmtInvoiceApply(SIH."No.");
                        until SIH.Next() = 0;
                        Message('Apply Invoice To Cr-Memo is Ok!')
                    end;
                }
            }
        }
    }
}