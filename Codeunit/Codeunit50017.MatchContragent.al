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
    var
        BankAcc: Record "Bank Account";
    begin
        BankAcc.Get(BankAccReconciliationLine."Bank Account No.");
        if BankAccReconciliationLine."Statement Amount" > 0 then begin
            GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Customer);
            if BankAcc."Bank BIC" = '380805' then
                GenJournalLine.Validate("Account No.", GetContragentByOKPO(GenJournalLine."Account Type"::Customer,
                                                        BankAccReconciliationLine."Recipient VAT Reg. No."))
            else
                GenJournalLine.Validate("Account No.", GetContragentByOKPO(GenJournalLine."Account Type"::Customer,
                                                        BankAccReconciliationLine."Sender VAT Reg. No."));
        end else begin
            GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Vendor);
            GenJournalLine.Validate("Account No.", GetContragentByOKPO(GenJournalLine."Account Type"::Vendor,
                                                    BankAccReconciliationLine."Recipient VAT Reg. No."))
        end;
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Payment);
    end;

    local procedure GetContragentByOKPO(AccountType: Enum "Gen. Journal Account Type"; OKPOCode: Text[20]): Code[20]
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
    begin
        case AccountType of
            AccountType::Customer:
                begin
                    Customer.SetCurrentKey("OKPO Code");
                    Customer.SetRange("OKPO Code", OKPOCode);
                    Customer.SetFilter(Blocked, '<>%1', Customer.Blocked::All);
                    if Customer.FindFirst() then
                        exit(Customer."No.");
                end;
            AccountType::Vendor:
                begin
                    Vendor.SetCurrentKey("OKPO Code");
                    Vendor.SetRange("OKPO Code", OKPOCode);
                    Vendor.SetFilter(Blocked, '<>%1', Vendor.Blocked::All);
                    if Vendor.FindFirst() then
                        exit(Vendor."No.");
                end;
        end;

        exit('');
    end;

    procedure GetCustomerCRMID(customerNo: Code[20]): Text
    var
        Customer: Record Customer;
    begin
        if Customer.Get(customerNo) then
            exit(LowerCase(DelChr(Customer."CRM ID", '<>', '{}')));
        exit('');
    end;

    procedure GetVATPercent(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]): Integer
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if VATPostingSetup.Get(VATBusPostingGroup, VATProdPostingGroup) then
            exit(VATPostingSetup."VAT %");
        exit(0);
    end;

    procedure GetCurrencyISONumericCode(CurrenceCode: Code[10]): Code[5]
    var
        Currency: Record Currency;
    begin
        if Currency.Get(CurrenceCode) then
            exit(Currency."ISO Numeric Code");
        exit('');
    end;

    procedure GetAgreementCRMID(customerNo: Code[20]; customerAgreementNo: Code[20]): Text
    var
        CustAgreement: Record "Customer Agreement";
    begin
        if CustAgreement.Get(customerNo, customerAgreementNo) then
            exit(LowerCase(DelChr(CustAgreement."CRM ID", '<>', '{}')));
        exit('');
    end;

    procedure GetBCIdFromCustomer(CustNo: Code[20]): Guid
    var
        Customer: Record Customer;
    begin
        if Customer.Get(CustNo) then;
        exit(Customer."BC Id");
    end;
}