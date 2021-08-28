pageextension 50039 "Posted Sales Credit Memos Ext" extends "Posted Sales Credit Memos"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
        addafter(Send)
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
                        SCrMH: Record "Sales Cr.Memo Header";
                    begin
                        CurrPage.SetSelectionFilter(SCrMH);
                        SCrMH.FindSet();
                        repeat
                            PrepMgt.PostedPrepmtCrMApply(SCrMH."No.");
                        until SCrMH.Next() = 0;
                        Message('Apply Invoice To Cr-Memo is Ok!')
                    end;
                }
            }
        }
    }
}