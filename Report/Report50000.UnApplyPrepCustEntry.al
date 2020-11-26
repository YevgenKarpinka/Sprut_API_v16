report 50000 "UnApply Prep. Cust. Entry"
{
    CaptionML = ENU = 'UnApply Prep. Cust. Entry',
                RUS = 'Не примененные предоплаты клиентов';
    DefaultLayout = RDLC;
    RDLCLayout = 'UnApply Prep. Cust. Entry.rdl';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;

    dataset
    {
        dataitem("Sales Header"; "Sales Header")
        {
            dataitem(UnApplyPrepCustLedgEntry; "Cust. Ledger Entry")
            {
                RequestFilterFields = "Customer No.";
                DataItemLink = "Customer No." = field("Sell-to Customer No.");
                DataItemTableView = order(descending) where("Agreement No." = filter(<> ''), Open = filter(true), Prepayment = filter(true));

                column(Posting_Date; "Posting Date") { }
                column(Document_Type; "Document Type") { }
                column(Document_No_; "Document No.") { }
                column(Customer_No_; "Customer No.") { }
                column(Description; Description) { }
                column(Agreement_No_; "Agreement No.") { }
                column(Amount; Amount) { }
                column(Remaining_Amount; "Remaining Amount") { }

                trigger OnAfterGetRecord()
                begin
                    if filterOrderNo <> '' then
                        if not OrderNoExist() then
                            CurrReport.Skip();
                end;
            }
        }
    }

    requestpage
    {
        SaveValues = true;
        layout { }
        actions { }
    }

    labels { }

    trigger OnInitReport()
    begin

    end;

    trigger OnPreReport()
    begin
        if filterCustomerNo <> '' then
            UnApplyPrepCustLedgEntry.SetFilter("Customer No.", filterCustomerNo);
    end;

    var
        filterCustomerNo: Code[20];
        filterOrderNo: Code[20];

    procedure SetInit(newCustomerNo: Code[20]; newOrderNo: Code[20])
    begin
        filterCustomerNo := newCustomerNo;
        filterOrderNo := newOrderNo;
    end;

    local procedure OrderNoExist(): Boolean
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMHeader: Record "Sales Cr.Memo Header";
    begin
        case UnApplyPrepCustLedgEntry."Document Type" of
            UnApplyPrepCustLedgEntry."Document Type"::Invoice:
                begin
                    SalesInvHeader.SetCurrentKey("Prepayment Order No.");
                    SalesInvHeader.SetFilter("Prepayment Order No.", filterOrderNo);
                    if not SalesInvHeader.IsEmpty then
                        exit(true);
                end;

            UnApplyPrepCustLedgEntry."Document Type"::"Credit Memo":
                begin
                    SalesCrMHeader.SetCurrentKey("Prepayment Order No.");
                    SalesCrMHeader.SetFilter("Prepayment Order No.", filterOrderNo);
                    if not SalesCrMHeader.IsEmpty then
                        exit(true);
                end;
        end;
        exit(false);
    end;
}