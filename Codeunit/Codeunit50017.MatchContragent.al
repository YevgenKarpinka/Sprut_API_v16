codeunit 50017 "Match Contragent"
{
    trigger OnRun()
    begin

    end;

    var
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        BankAccRecon: Record "Bank Acc. Reconciliation";

    [EventSubscriber(ObjectType::Report, 1497, 'OnBeforeGenJnlLineInsert', '', false, false)]
    procedure OnBeforeGenJnlLineInsert(var GenJournalLine: Record "Gen. Journal Line"; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
        if BankAccReconciliationLine."Statement Amount" > 0 then begin
            GenJournalLine."Account Type" := GenJournalLine."Account Type"::Customer;
            GenJournalLine."Account No." := GetContragentByVATRegNo(GenJournalLine."Account Type"::Customer,
                                                    BankAccReconciliationLine."Recipient VAT Reg. No.");
        end else begin
            GenJournalLine."Account Type" := GenJournalLine."Account Type"::Vendor;
            GenJournalLine."Account No." := GetContragentByVATRegNo(GenJournalLine."Account Type"::Vendor,
                                                    BankAccReconciliationLine."Sender VAT Reg. No.");
        end;
        GenJournalLine."Document Type" := GenJournalLine."Document Type"::Payment;
    end;

    local procedure GetContragentByVATRegNo(AccountType: Enum "Gen. Journal Account Type"; VATRegNo: Text[20]): Code[20]
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
    begin
        case AccountType of
            AccountType::Customer:
                begin
                    Customer.SetCurrentKey("VAT Registration No.");
                    Customer.SetRange("VAT Registration No.", VATRegNo);
                    if Customer.FindFirst() then
                        exit(Customer."No.");
                end;
            AccountType::Vendor:
                begin
                    Vendor.SetCurrentKey("VAT Registration No.");
                    Vendor.SetRange("VAT Registration No.", VATRegNo);
                    if Vendor.FindFirst() then
                        exit(Vendor."No.");
                end;
        end;

        exit('');
    end;
}