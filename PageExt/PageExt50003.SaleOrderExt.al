pageextension 50003 "Sale Order Ext" extends "Sales Order"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
        addafter(PostPrepaymentInvoice)
        {
            action(PostPrepaymentInvoiceSprut)
            {
                ApplicationArea = All;
                CaptionML = ENU = 'Post Prepayment Invoice Sprut',
                            RUS = 'Учет счета на предоплату';
                Image = PrepaymentPost;

                trigger OnAction()
                begin
                    SalesPostPrepaymentsSprut.PostPrepaymentInvoiceSprut(Rec);
                end;
            }
        }
        addafter(PostPrepaymentCreditMemo)
        {
            action(PostPrepaymentCreditMemoSprut)
            {
                ApplicationArea = All;
                CaptionML = ENU = 'Post Prepayment Credit Memo Sprut',
                            RUS = 'Учет кредит ноты на предоплату';
                Image = PrepaymentPost;

                trigger OnAction()
                begin
                    SalesPostPrepaymentsSprut.PostPrepaymentCreditMemoSprut(Rec);
                end;
            }
        }
        addafter(PostPrepaymentCreditMemo)
        {
            action(UnApplyEntriesSprut)
            {
                ApplicationArea = All;
                CaptionML = ENU = 'Unapply Entries Sprut',
                            RUS = 'Отменить применение операций';
                Image = UnApply;

                trigger OnAction()
                var
                    DocumentNo: Code[20];
                    PostingDate: Date;
                begin
                    PrepaymentMgt.GetLastPrepaymentInvoiceNo(Rec."No.", DocumentNo, PostingDate);
                    PrepaymentMgt.UnApplyCustLedgEntry(PrepaymentMgt.GetCustomerLedgerEntryNo(DocumentNo, PostingDate));

                end;
            }
        }
    }

    var
        SalesPostPrepaymentsSprut: Codeunit "Sales-Post Prepayments Sprut";
        PrepaymentMgt: Codeunit "Prepayment Management";
}