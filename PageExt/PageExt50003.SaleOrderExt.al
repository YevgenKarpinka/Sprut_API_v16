pageextension 50003 "Sale Order Ext" extends "Sales Order"
{
    layout
    {
        // Add changes to page layout here
        addafter(Status)
        {
            field("Last Modified Date Time"; "Last Modified Date Time")
            {
                ApplicationArea = All;
                ToolTipML = ENU = 'Specifies Last Modified Date Time.',
                            RUS = 'Указывает на последнюю дату и время модификации.';
            }
        }

    }

    actions
    {
        // Add changes to page actions here
        addafter("Prepa&yment")
        {
            group(Sprut)
            {
                CaptionML = ENU = 'Sprut',
                            RUS = 'Sprut';
                Image = Prepayment;

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
                action(UnApplyEntriesSprut)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'Unapply Entries Sprut',
                            RUS = 'Отменить применение операций';
                    Image = UnApply;

                    trigger OnAction()
                    begin
                        PrepaymentMgt.UnApplyPayments(Rec."No.");
                    end;
                }
            }
        }
    }

    var
        SalesPostPrepaymentsSprut: Codeunit "Sales-Post Prepayments Sprut";
        PrepaymentMgt: Codeunit "Prepayment Management";
}