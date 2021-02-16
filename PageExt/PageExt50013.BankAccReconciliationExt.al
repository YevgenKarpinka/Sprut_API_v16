pageextension 50013 "Bank Acc. Reconciliation Ext" extends "Bank Acc. Reconciliation"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
        addafter("Transfer to General Journal")
        {
            action(MatchContragentTransferToGeneralJournal)
            {
                ApplicationArea = Basic, Suite;
                CaptionML = ENU = 'Match contragent and transfer to General Journal',
                            RUS = 'Определить контрагента и переместить в финансовый журнал';
                Ellipsis = true;
                Image = TransferToGeneralJournal;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTipML = ENU = 'Match contragent and transfer the lines from the current window to the general journal.',
                            RUS = 'Определение контрагента и перемещение строк из текущего окна в финансовый журнал.';

                trigger OnAction()
                begin
                    // Match contragent
                    MatchContragent.SetBankAccRecon(Rec);

                    // Transfer to General Journal
                    TransferToGLJnl.SetBankAccRecon(Rec);
                    TransferToGLJnl.Run;
                end;
            }
        }
    }

    var
        TransferToGLJnl: Report "Trans. Bank Rec. to Gen. Jnl.";
        MatchContragent: Codeunit "Match Contragent";
}