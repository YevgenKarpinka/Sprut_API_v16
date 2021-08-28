codeunit 50017 "Match Contragent"
{
    trigger OnRun()
    begin

    end;

    var
        GLSetup: Record "General Ledger Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";

    [EventSubscriber(ObjectType::Table, 4, 'OnAfterInitRoundingPrecision', '', false, false)]
    local procedure CurrencyOnAfterInitRoundingPrecision(var Currency: Record Currency; var GeneralLedgerSetup: Record "General Ledger Setup")
    begin
        if GeneralLedgerSetup."Enable VAT Order Round" then
            Currency."VAT Order Rounding Precision" := GeneralLedgerSetup."VAT Order Rounding Precision";
        Currency."Enable VAT Order Round" := GeneralLedgerSetup."Enable VAT Order Round";
    end;

    [EventSubscriber(ObjectType::Table, 37, 'OnUpdateVATAmountsOnBeforeCalcAmounts', '', false, false)]
    local procedure SalesLineOnAfterInitRoundingPrecision(TotalAmountInclVAT: Decimal; var IsHandled: Boolean; var SalesLine2: Record "Sales Line";
                        var SalesLine: Record "Sales Line"; var TotalAmount: Decimal; var TotalInvDiscAmount: Decimal; var TotalLineAmount: Decimal;
                        var TotalQuantityBase: Decimal; var TotalVATBaseAmount: Decimal)
    var
        Totals: array[4] of Decimal;
    begin
        GetGLSetup();
        SalesSetup.Get();
        GetSalesHeader(SalesLine);
        if not (Currency."Enable VAT Order Round" and SalesSetup."Allow VAT Rounding Precision") then exit;
        IsHandled := true;

        if SalesHeader."Prices Including VAT" then
            case SalesLine."VAT Calculation Type" of
                SalesLine."VAT Calculation Type"::"Normal VAT",
                SalesLine."VAT Calculation Type"::"Reverse Charge VAT":
                    begin
                        if not SalesSetup."Calc. VAT per Line" then
                            SalesLine.Amount :=
                              Round(
                                (TotalLineAmount - TotalInvDiscAmount + SalesLine.CalcLineAmount) / (1 + SalesLine."VAT %" / 100),
                                Currency."VAT Order Rounding Precision") -
                            TotalAmount
                        else
                            SalesLine.Amount :=
                              Round(
                                SalesLine.CalcLineAmount / (1 + SalesLine."VAT %" / 100), Currency."VAT Order Rounding Precision");
                        SalesLine."VAT Base Amount" :=
                          Round(
                            SalesLine.Amount * (1 - SalesHeader."VAT Base Discount %" / 100),
                            Currency."VAT Order Rounding Precision");
                        SalesLine."Amount Including VAT" :=
                          TotalLineAmount + SalesLine."Line Amount" -
                          Round(
                            (TotalAmount + SalesLine.Amount) * (SalesHeader."VAT Base Discount %" / 100) * SalesLine."VAT %" / 100,
                            Currency."Amount Rounding Precision", Currency.VATRoundingDirection) -
                          TotalAmountInclVAT - TotalInvDiscAmount - SalesLine."Inv. Discount Amount";
                    end;
                SalesLine."VAT Calculation Type"::"Full VAT":
                    begin
                        SalesLine.Amount := 0;
                        SalesLine."VAT Base Amount" := 0;
                    end;
                SalesLine."VAT Calculation Type"::"Sales Tax":
                    begin
                        SalesHeader.TestField("VAT Base Discount %", 0);
                        SalesLine.Amount :=
                          SalesTaxCalculate.ReverseCalculateTax(
                            SalesLine."Tax Area Code", SalesLine."Tax Group Code", SalesLine."Tax Liable", SalesHeader."Posting Date",
                            TotalAmountInclVAT + SalesLine."Amount Including VAT", TotalQuantityBase + SalesLine."Quantity (Base)",
                            SalesHeader."Currency Factor") -
                          TotalAmount;
                        UpdateVATPercent(SalesLine.Amount, SalesLine."Amount Including VAT" - SalesLine.Amount, SalesLine);
                        SalesLine.Amount := Round(SalesLine.Amount, Currency."VAT Order Rounding Precision");
                        SalesLine."VAT Base Amount" := SalesLine.Amount;
                    end;
            end
        else
            case SalesLine."VAT Calculation Type" of
                SalesLine."VAT Calculation Type"::"Normal VAT",
                SalesLine."VAT Calculation Type"::"Reverse Charge VAT":
                    begin
                        SalesLine.Amount := Round(SalesLine.CalcLineAmount, Currency."VAT Order Rounding Precision");
                        SalesLine."VAT Base Amount" :=
                          Round(SalesLine.Amount * (1 - SalesHeader."VAT Base Discount %" / 100), Currency."VAT Order Rounding Precision");
                        if not SalesSetup."Calc. VAT per Line" then
                            SalesLine."Amount Including VAT" :=
                              TotalAmount + SalesLine.Amount +
                              Round(
                                (TotalAmount + SalesLine.Amount) * (1 - SalesHeader."VAT Base Discount %" / 100) * SalesLine."VAT %" / 100,
                                Currency."Amount Rounding Precision", Currency.VATRoundingDirection) -
                              TotalAmountInclVAT
                        else
                            if TotalAmount + SalesLine.Amount = 0 then
                                SalesLine."Amount Including VAT" := 0
                            else
                                SalesLine."Amount Including VAT" :=
                                  SalesLine.Amount +
                                  Round(
                                    (TotalAmount + SalesLine.Amount) * (1 - SalesHeader."VAT Base Discount %" / 100) * SalesLine."VAT %" / 100 *
                                    SalesLine.Amount / (TotalAmount + SalesLine.Amount), Currency."Amount Rounding Precision");
                    end;
                SalesLine."VAT Calculation Type"::"Full VAT":
                    begin
                        SalesLine.Amount := 0;
                        SalesLine."VAT Base Amount" := 0;
                        SalesLine."Amount Including VAT" := SalesLine.CalcLineAmount;
                    end;
                SalesLine."VAT Calculation Type"::"Sales Tax":
                    begin
                        SalesLine.Amount := Round(SalesLine.CalcLineAmount, Currency."VAT Order Rounding Precision");
                        SalesLine."VAT Base Amount" := SalesLine.Amount;
                        SalesLine."Amount Including VAT" :=
                          TotalAmount + SalesLine.Amount +
                          Round(
                            SalesTaxCalculate.CalculateTax(
                              SalesLine."Tax Area Code", SalesLine."Tax Group Code", SalesLine."Tax Liable", SalesHeader."Posting Date",
                              TotalAmount + SalesLine.Amount, TotalQuantityBase + SalesLine."Quantity (Base)",
                              SalesHeader."Currency Factor"), Currency."Amount Rounding Precision") -
                          TotalAmountInclVAT;
                        UpdateVATPercent(SalesLine."VAT Base Amount", SalesLine."Amount Including VAT" - SalesLine."VAT Base Amount", SalesLine);
                    end;
            end;

        Totals[1] := Totals[1] + SalesLine.Amount;
        Totals[2] := Totals[2] + SalesLine."Amount Including VAT";
        SalesLine."Amount (LCY)" :=
          Round(
            CurrExchRate.ExchangeAmtFCYToLCY(
            SalesHeader."Posting Date", SalesHeader."Currency Code",
            Totals[1], SalesHeader."Currency Factor"), GLSetup."VAT Order Rounding Precision", GLSetupVATRoundingDirection()) - Totals[3];
        SalesLine."Amount Including VAT (LCY)" :=
          Round(
            CurrExchRate.ExchangeAmtFCYToLCY(
            SalesHeader."Posting Date", SalesHeader."Currency Code",
            Totals[2], SalesHeader."Currency Factor")) - Totals[4];
        Totals[3] := Totals[3] + SalesLine."Amount (LCY)";
        Totals[4] := Totals[4] + SalesLine."Amount Including VAT (LCY)";
    end;

    procedure GLSetupVATRoundingDirection(): Text[1]
    begin
        case GLSetup."VAT Rounding Type" of
            GLSetup."VAT Rounding Type"::Nearest:
                exit('=');
            GLSetup."VAT Rounding Type"::Up:
                exit('>');
            GLSetup."VAT Rounding Type"::Down:
                exit('<');
        end;
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetup.Get() then begin
            GLSetup.Init();
            GLSetup.Insert(true);
        end;
    end;

    local procedure UpdateVATPercent(BaseAmount: Decimal; VATAmount: Decimal; var SalesLine: Record "Sales Line")
    begin
        if BaseAmount <> 0 then
            SalesLine."VAT %" := Round(100 * VATAmount / BaseAmount, 0.00001)
        else
            SalesLine."VAT %" := 0;
    end;

    local procedure GetSalesHeader(SalesLine: Record "Sales Line")
    begin
        GetSalesHeader(SalesHeader, Currency, SalesLine);
    end;

    local procedure GetSalesHeader(var OutSalesHeader: Record "Sales Header"; var OutCurrency: Record Currency; SalesLine: Record "Sales Line")
    begin
        SalesLine.TestField("Document No.");
        if (SalesLine."Document Type" <> SalesHeader."Document Type") or (SalesLine."Document No." <> SalesHeader."No.") then begin
            SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
            if SalesHeader."Currency Code" = '' then
                Currency.InitRoundingPrecision
            else begin
                SalesHeader.TestField("Currency Factor");
                Currency.Get(SalesHeader."Currency Code");
                Currency.TestField("Amount Rounding Precision");
                if Currency."Enable VAT Order Round" then
                    Currency.TestField("VAT Order Rounding Precision");
            end;
        end;

        OutSalesHeader := SalesHeader;
        OutCurrency := Currency;
    end;

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

        if BankAccReconciliationLine."Description Extended" <> '' then
            GenJournalLine.Validate("Description Extended", BankAccReconciliationLine."Description Extended");
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