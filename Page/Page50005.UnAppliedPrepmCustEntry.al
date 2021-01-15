page 50005 "UnApplied Prepm. Cust. Entry"
{
    PageType = ListPart;
    // ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Cust. Ledger Entry";
    SourceTableView = where(Open = filter(true), Prepayment = filter(true));
    Editable = false;
    CaptionML = ENU = 'UnApplied Prepm. Cust. Entry',
                RUS = 'Непримененные операции предоплаты';

    layout
    {
        area(Content)
        {
            repeater(ItemsTransferSite)
            {
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = All;
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = All;
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = All;
                }
                field("Customer No."; "Customer No.")
                {
                    ApplicationArea = All;
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                }
                field("Agreement No."; "Agreement No.")
                {
                    ApplicationArea = All;
                }
                field(Amount; Amount)
                {
                    ApplicationArea = All;
                }
                field("Remaining Amount"; "Remaining Amount")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}