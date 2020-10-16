codeunit 50001 "Prepayment Management"
{
    trigger OnRun()
    begin

    end;

    var
        Currency: Record Currency;
        SRSetup: Record "Sales & Receivables Setup";
        GLSetup: Record "General Ledger Setup";
        CannotUnapplyInReversalErr: TextConst ENU = 'You cannot unapply Cust. Ledger Entry No. %1 because the entry is part of a reversal.',
                                            RUS = 'Нельзя отменить операцию книги клиентов № %1, поскольку эта операция входит в состав сторнирования.';
        NoApplicationEntryErr: TextConst ENU = 'Cust. Ledger Entry No. %1 does not have an application entry.',
                                        RUS = 'У операции книги клиентов № %1 нет операции применения.';
        MustNotBeBeforeErr: TextConst ENU = 'The Posting Date entered must not be before the Posting Date on the Cust. Ledger Entry.',
                                    RUS = 'Введенная дата учета не должна предшествовать дате учета операции книги клиентов.';
        CannotUnapplyExchRateErr: TextConst ENU = 'You cannot unapply the entry with the posting date %1, because the exchange rate for the additional reporting currency has been changed.',
                                            RUS = 'Нельзя отменить операцию с датой учета %1, поскольку изменился курс дополнительной отчетной валюты.';
        UnapplyAllPostedAfterThisEntryErr: TextConst ENU = 'Before you can unapply this entry, you must first unapply all application entries in Cust. Ledger Entry No. %1 that were posted after this entry.',
                                                    RUS = 'Перед отменой этой операции необходимо отменить все операции применения в операции книги клиентов № %1, учтенные после этой операции.';
        LatestEntryMustBeAnApplicationErr: TextConst ENU = 'The latest Transaction No. must be an application in Cust. Ledger Entry No. %1.',
                                                    RUS = 'Номер последней транзакции должен соответствовать применению в операции книги клиентов № %1.';
        NotAllowedPostingDatesErr: TextConst ENU = 'Posting date is not within the range of allowed posting dates.',
                                            RUS = 'Дата учета вне пределов разрешенного диапазона дат учета.';
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        tempDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry" temporary;
        DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
        Cust: Record Customer;
        DocNo: Code[20];
        PostingDate: Date;
        CustLedgEntryNo: Integer;
        InitialVATTransactionNo: Integer;
        AllowAmtDiffUnapply: Boolean;
        AmtDiffManagement: Codeunit PrepmtDiffManagement;

    [EventSubscriber(ObjectType::Table, 37, 'OnBeforeUpdatePrepmtAmounts', '', false, false)]
    /// <summary> 
    /// Description for UpdatePrepaymentAmounts.
    /// </summary>
    /// <param name="SalesHeader">Parameter of type Record "Sales Header".</param>
    /// <param name="SalesLine">Parameter of type Record "Sales Line".</param>
    /// <param name="IsHandled">Parameter of type Boolean.</param>
    local procedure UpdatePrepaymentAmounts(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    var
        SalesLineUpdate: Record "Sales Line";
        CurrentAdjPrepAmount: Decimal;
        CurrentAdjPrepAmountIncVAT: Decimal;
        AdjPrepAmount: Decimal;
        AdjPrepAmountIncVAT: Decimal;
        Ratio: Decimal;
    begin
        GetSRSetup();
        if not SRSetup."Allow Modifying" then exit;

        if (SalesLine."Prepmt. Amt. Inv." = 0)
            or (SalesHeader."Document Type" <> SalesHeader."Document Type"::Order) then
            exit;

        SalesLine."Prepmt. Line Amount" := SalesLine."Line Amount" * SalesLine."Prepayment %" / 100;
        SalesLine.Modify();
        if (SalesLine."Prepmt. Amt. Inv." < SalesLine."Prepmt. Line Amount") then begin
            UpdatePrepmtAmountCurrLine(SalesHeader, SalesLine);
            exit;
        end;

        Currency.Initialize(SalesHeader."Currency Code");

        SalesLine."Prepmt. Line Amount" := ROUND(SalesLine."Line Amount" * SalesLine."Prepayment %" / 100, Currency."Amount Rounding Precision");
        CurrentAdjPrepAmount := SalesLine."Prepmt. Amt. Inv." - SalesLine."Prepmt. Line Amount";
        if SalesLine."Prepmt. Amount Inv. (LCY)" <> 0 then begin
            Ratio := SalesLine."Prepmt. Amount Inv. (LCY)" / SalesLine."Prepmt. Amt. Inv.";
        end else
            Ratio := 0;

        SalesLineUpdate.SetCurrentKey(Type, "Prepmt. Line Amount");
        SalesLineUpdate.SetRange("Document Type", SalesHeader."Document Type");
        SalesLineUpdate.SetRange("Document No.", SalesHeader."No.");
        SalesLineUpdate.SetFilter(Type, '<>%1', SalesLineUpdate.Type::" ");
        SalesLineUpdate.SetFilter("Prepmt. Line Amount", '<>0');
        SalesLineUpdate.LockTable();
        if SalesLineUpdate.FindSet() then
            repeat
                if SalesLineUpdate."Prepmt. Line Amount" > SalesLineUpdate."Prepmt. Amt. Inv." then begin
                    AdjPrepAmount := SalesLineUpdate."Prepmt. Line Amount" - SalesLineUpdate."Prepmt. Amt. Inv.";

                    if CurrentAdjPrepAmount > AdjPrepAmount then begin
                        SalesLine."Prepmt. Amt. Inv." -= AdjPrepAmount;
                        SalesLineUpdate."Prepmt. Amt. Inv." += AdjPrepAmount;
                        CurrentAdjPrepAmount -= AdjPrepAmount;
                    end else begin
                        SalesLine."Prepmt. Amt. Inv." -= CurrentAdjPrepAmount;
                        SalesLineUpdate."Prepmt. Amt. Inv." += CurrentAdjPrepAmount;
                        CurrentAdjPrepAmount := 0;
                    end;

                    if SalesHeader."Prices Including VAT" then begin
                        SalesLine."Prepmt. Amt. Incl. VAT" := SalesLine."Prepmt. Line Amount";
                        SalesLine."Prepmt. VAT Base Amt." := SalesLine."Prepmt. Line Amount";
                        SalesLine."Prepmt. Amount Inv. Incl. VAT" := SalesLine."Prepmt. Amt. Inv.";

                        SalesLineUpdate."Prepmt. Amt. Incl. VAT" := SalesLineUpdate."Prepmt. Line Amount";
                        SalesLineUpdate."Prepmt. VAT Base Amt." := SalesLineUpdate."Prepmt. Line Amount";
                        SalesLineUpdate."Prepmt. Amount Inv. Incl. VAT" := SalesLineUpdate."Prepmt. Amt. Inv.";
                    end else begin
                        SalesLine."Prepmt. Amt. Incl. VAT" := Round(SalesLine."Prepmt. Line Amount" + SalesLine."Prepmt. Line Amount" * SalesLine."VAT %" / 100, Currency."Amount Rounding Precision");
                        SalesLine."Prepmt. VAT Base Amt." := SalesLine."Prepmt. Line Amount";
                        SalesLine."Prepmt. Amount Inv. Incl. VAT" := Round(SalesLine."Prepmt. Amt. Inv." + SalesLine."Prepmt. Amt. Inv." * SalesLine."VAT %" / 100, Currency."Amount Rounding Precision");

                        SalesLineUpdate."Prepmt. Amt. Incl. VAT" := Round(SalesLineUpdate."Prepmt. Line Amount" + SalesLineUpdate."Prepmt. Line Amount" * SalesLineUpdate."VAT %" / 100, Currency."Amount Rounding Precision");
                        SalesLineUpdate."Prepmt. VAT Base Amt." := SalesLineUpdate."Prepmt. Line Amount";
                        SalesLineUpdate."Prepmt. Amount Inv. Incl. VAT" := Round(SalesLineUpdate."Prepmt. Amt. Inv." + SalesLineUpdate."Prepmt. Amt. Inv." * SalesLineUpdate."VAT %" / 100, Currency."Amount Rounding Precision");
                    end;

                    if Ratio <> 0 then begin
                        SalesLineUpdate."Prepmt. Amount Inv. (LCY)" :=
                            ROUND(SalesLineUpdate."Prepmt. Amt. Inv." * Ratio, Currency."Amount Rounding Precision");
                        SalesLineUpdate."Prepmt. VAT Amount Inv. (LCY)" :=
                            ROUND((SalesLineUpdate."Prepmt. Amount Inv. Incl. VAT" - SalesLineUpdate."Prepmt. Amt. Inv.") * Ratio, Currency."Amount Rounding Precision");

                        SalesLine."Prepmt. Amount Inv. (LCY)" :=
                            ROUND(SalesLine."Prepmt. Amt. Inv." * Ratio, Currency."Amount Rounding Precision");
                        SalesLine."Prepmt. VAT Amount Inv. (LCY)" :=
                            ROUND((SalesLine."Prepmt. Amount Inv. Incl. VAT" - SalesLine."Prepmt. Amt. Inv.") * Ratio, Currency."Amount Rounding Precision");
                    end;

                    SalesLineUpdate.Modify();
                    SalesLine.Modify();
                end;
            until (SalesLineUpdate.Next() = 0) or (CurrentAdjPrepAmount = 0);
    end;

    /// <summary> 
    /// Description for UpdatePrepmtAmountCurrLine.
    /// </summary>
    /// <param name="SalesHeader">Parameter of type Record "Sales Header".</param>
    /// <param name="SalesLine">Parameter of type Record "Sales Line".</param>
    local procedure UpdatePrepmtAmountCurrLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line");
    begin
        if SalesHeader."Prices Including VAT" then begin
            SalesLine."Prepmt. Amt. Incl. VAT" := SalesLine."Prepmt. Line Amount";
            SalesLine."Prepmt. VAT Base Amt." := SalesLine."Prepmt. Line Amount";
            // SalesLine."Prepmt. Amount Inv. Incl. VAT" := SalesLine."Prepmt. Amt. Inv.";
        end else begin
            // SalesLine."Line Amount" + SalesLine."Prepayment %" / 100
            SalesLine."Prepmt. Amt. Incl. VAT" := Round(SalesLine."Prepmt. Line Amount" + SalesLine."Prepmt. Line Amount" * SalesLine."VAT %" / 100, Currency."Amount Rounding Precision");
            SalesLine."Prepmt. VAT Base Amt." := SalesLine."Prepmt. Line Amount";
            // SalesLine."Prepmt. Amount Inv. Incl. VAT" := Round(SalesLine."Prepmt. Amt. Inv." + SalesLine."Prepmt. Amt. Inv." * SalesLine."VAT %" / 100, Currency."Amount Rounding Precision");
        end;
        SalesLine.Modify();
    end;

    /// <summary> 
    /// Description for GetSRSetup.
    /// </summary>
    local procedure GetSRSetup()
    begin
        IF not SRSetup.Get() then begin
            SRSetup.Init();
            SRSetup.Insert();
        end;
    end;

    /// <summary> 
    /// Description for GetLastPrepaymentInvoiceNo.
    /// </summary>
    /// <param name="PrepaymentOrderNo">Parameter of type Code[20].</param>
    /// <param name="DocumentNo">Parameter of type Code[20].</param>
    /// <param name="PostingDate">Parameter of type Date.</param>
    procedure GetLastPrepaymentInvoiceNo(PrepaymentOrderNo: Code[20]; var DocumentNo: Code[20]; var PostingDate: Date)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetCurrentKey("Prepayment Order No.");
        SalesInvoiceHeader.SetRange("Prepayment Order No.", PrepaymentOrderNo);
        if SalesInvoiceHeader.FindLast() then begin
            DocumentNo := SalesInvoiceHeader."No.";
            PostingDate := SalesInvoiceHeader."Posting Date";
            exit;
        end;
        DocumentNo := '';
        PostingDate := 0D;
    end;

    /// <summary> 
    /// Description for GetLastPrepaymentCreaditMemoNo.
    /// </summary>
    /// <param name="PrepaymentOrderNo">Parameter of type Code[20].</param>
    /// <param name="DocumentNo">Parameter of type Code[20].</param>
    /// <param name="PostingDate">Parameter of type Date.</param>
    procedure GetLastPrepaymentCreaditMemoNo(PrepaymentOrderNo: Code[20]; var DocumentNo: Code[20]; var PostingDate: Date)
    var
        SalesCreditMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCreditMemoHeader.SetCurrentKey("Prepayment Order No.");
        SalesCreditMemoHeader.SetRange("Prepayment Order No.", PrepaymentOrderNo);
        if SalesCreditMemoHeader.FindLast() then begin
            DocumentNo := SalesCreditMemoHeader."No.";
            PostingDate := SalesCreditMemoHeader."Posting Date";
            exit;
        end;
        DocumentNo := '';
        PostingDate := 0D;
    end;

    /// <summary> 
    /// Description for GetCustomerLedgerEntryNo.
    /// </summary>
    /// <param name="DocumentNo">Parameter of type Code[20].</param>
    /// <param name="PostingDate">Parameter of type Date.</param>
    /// <returns>Return variable "Integer".</returns>
    procedure GetCustomerLedgerEntryNo(DocumentNo: Code[20]; PostingDate: Date): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetCurrentKey("Document No.", "Posting Date");
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.SetRange("Posting Date", PostingDate);
        if CustLedgerEntry.FindFirst() then;
        exit(CustLedgerEntry."Entry No.");
    end;

    /// <summary> 
    /// Description for UnApplyCustLedgEntry.
    /// </summary>
    /// <param name="CustLedgEntryNo">Parameter of type Integer.</param>
    procedure UnApplyCustLedgEntry(CustLedgEntryNo: Integer)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        ApplicationEntryNo: Integer;
    begin
        CheckReversal(CustLedgEntryNo);
        ApplicationEntryNo := CustEntryApplyPostedEntries.FindLastApplEntry(CustLedgEntryNo);
        while ApplicationEntryNo <> 0 do begin
            DtldCustLedgEntry.GET(ApplicationEntryNo);
            UnApplyCustomer(DtldCustLedgEntry);
        end;
    end;

    /// <summary> 
    /// Description for CheckReversal.
    /// </summary>
    /// <param name="CustLedgEntryNo">Parameter of type Integer.</param>
    local procedure CheckReversal(CustLedgEntryNo: Integer)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.GET(CustLedgEntryNo);
        IF CustLedgEntry.Reversed THEN
            ERROR(CannotUnapplyInReversalErr, CustLedgEntryNo);
    end;

    /// <summary> 
    /// Description for UnApplyCustomer.
    /// </summary>
    /// <param name="DtldCustLedgEntry">Parameter of type Record "Detailed Cust. Ledg. Entry".</param>
    local procedure UnApplyCustomer(DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
        DtldCustLedgEntry.TESTFIELD("Entry Type", DtldCustLedgEntry."Entry Type"::Application);
        DtldCustLedgEntry.TESTFIELD(Unapplied, FALSE);
        SetDtldCustLedgEntry(DtldCustLedgEntry."Entry No.");
        // InsertEntries();
        // unapply last entry
        tempDtldCustLedgEntry.FindLast();
        PostUnApplyCustomer(DtldCustLedgEntry2, DocNo, PostingDate);
    end;

    /// <summary> 
    /// Description for PostUnApplyCustomer.
    /// </summary>
    /// <param name="DtldCustLedgEntry2">Parameter of type Record "Detailed Cust. Ledg. Entry".</param>
    /// <param name="DocNo">Parameter of type Code[20].</param>
    /// <param name="PostingDate">Parameter of type Date.</param>
    local procedure PostUnApplyCustomer(DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry"; DocNo: Code[20]; PostingDate: Date)
    begin
        PostUnApplyCustomerCommit(DtldCustLedgEntry2, DocNo, PostingDate, TRUE);
    end;

    /// <summary> 
    /// Description for PostUnApplyCustomerCommit.
    /// </summary>
    /// <param name="DtldCustLedgEntry2">Parameter of type Record "Detailed Cust. Ledg. Entry".</param>
    /// <param name="DocNo">Parameter of type Code[20].</param>
    /// <param name="PostingDate">Parameter of type Date.</param>
    /// <param name="CommitChanges">Parameter of type Boolean.</param>
    local procedure PostUnApplyCustomerCommit(DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry"; DocNo: Code[20]; PostingDate: Date; CommitChanges: Boolean)
    var
        GLEntry: Record "G/L Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlLine: Record "Gen. Journal Line";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DateComprReg: Record "Date Compr. Register";
        TempCustLedgerEntry: Record "Cust. Ledger Entry";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        LastTransactionNo: Integer;
        AddCurrChecked: Boolean;
        MaxPostingDate: Date;
        AdjustExchangeRates: Report "Adjust Exchange Rates";
    begin
        MaxPostingDate := 0D;
        GLEntry.LOCKTABLE;
        DtldCustLedgEntry.LOCKTABLE;
        CustLedgEntry.LOCKTABLE;
        CustLedgEntry.GET(DtldCustLedgEntry2."Cust. Ledger Entry No.");
        CheckPostingDate(PostingDate, MaxPostingDate);
        IF PostingDate < DtldCustLedgEntry2."Posting Date" THEN
            ERROR(MustNotBeBeforeErr);
        IF DtldCustLedgEntry2."Transaction No." = 0 THEN BEGIN
            DtldCustLedgEntry.SETCURRENTKEY("Application No.", "Customer No.", "Entry Type");
            DtldCustLedgEntry.SETRANGE("Application No.", DtldCustLedgEntry2."Application No.");
        END ELSE BEGIN
            DtldCustLedgEntry.SETCURRENTKEY("Transaction No.", "Customer No.", "Entry Type");
            DtldCustLedgEntry.SETRANGE("Transaction No.", DtldCustLedgEntry2."Transaction No.");
        END;
        DtldCustLedgEntry.SETRANGE("Customer No.", DtldCustLedgEntry2."Customer No.");
        DtldCustLedgEntry.SETFILTER("Entry Type", '<>%1', DtldCustLedgEntry."Entry Type"::"Initial Entry");
        DtldCustLedgEntry.SETRANGE(Unapplied, FALSE);
        IF DtldCustLedgEntry.FIND('-') THEN
            REPEAT
                IF NOT AddCurrChecked THEN BEGIN
                    CheckAdditionalCurrency(PostingDate, DtldCustLedgEntry."Posting Date");
                    AddCurrChecked := TRUE;
                END;
                CheckReversal(DtldCustLedgEntry."Cust. Ledger Entry No.");
                IF DtldCustLedgEntry."Transaction No." <> 0 THEN BEGIN
                    IF DtldCustLedgEntry."Entry Type" = DtldCustLedgEntry."Entry Type"::Application THEN BEGIN
                        LastTransactionNo :=
                          FindLastApplTransactionEntry(DtldCustLedgEntry."Cust. Ledger Entry No.");
                        IF (LastTransactionNo <> 0) AND (LastTransactionNo <> DtldCustLedgEntry."Transaction No.") THEN
                            ERROR(UnapplyAllPostedAfterThisEntryErr, DtldCustLedgEntry."Cust. Ledger Entry No.");
                    END;
                    LastTransactionNo := FindLastTransactionNo(DtldCustLedgEntry."Cust. Ledger Entry No.");
                    IF (LastTransactionNo <> 0) AND (LastTransactionNo <> DtldCustLedgEntry."Transaction No.") THEN
                        ERROR(LatestEntryMustBeAnApplicationErr, DtldCustLedgEntry."Cust. Ledger Entry No.");
                END;
            UNTIL DtldCustLedgEntry.NEXT = 0;

        DateComprReg.CheckMaxDateCompressed(MaxPostingDate, 0);

        SourceCodeSetup.GET;
        CustLedgEntry.GET(DtldCustLedgEntry2."Cust. Ledger Entry No.");
        MarkUnApplyPayment(CustLedgEntry);
        GenJnlLine."Document No." := DocNo;
        GenJnlLine."Posting Date" := PostingDate;
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer;
        GenJnlLine."Account No." := DtldCustLedgEntry2."Customer No.";
        GenJnlLine.Correction := TRUE;
        GenJnlLine.CopyCustLedgEntry(CustLedgEntry);
        GenJnlLine."Source Code" := SourceCodeSetup."Unapplied Sales Entry Appln.";
        GenJnlLine."Source Currency Code" := DtldCustLedgEntry2."Currency Code";
        GenJnlLine."System-Created Entry" := TRUE;
        GenJnlLine."Agreement No." := DtldCustLedgEntry2."Agreement No.";

        CollectAffectedLedgerEntries(TempCustLedgerEntry, DtldCustLedgEntry2);
        GenJnlPostLine.UnapplyCustLedgEntry(GenJnlLine, DtldCustLedgEntry2);
        AdjustExchangeRates.AdjustExchRateCust(GenJnlLine, TempCustLedgerEntry);

        IF GLSetup."Enable Russian Accounting" THEN BEGIN
            AmtDiffManagement.SetInitialVATTransactionNo(DtldCustLedgEntry2."Transaction No.");
            AmtDiffManagement.PrepmtDiffProcessing(TRUE, false);
        END;

        IF CommitChanges AND (NOT AllowAmtDiffUnapply) THEN
            COMMIT;
    end;

    /// <summary> 
    /// Description for CheckPostingDate.
    /// </summary>
    /// <param name="PostingDate">Parameter of type Date.</param>
    /// <param name="VAR MaxPostingDate">Parameter of type Date.</param>
    local procedure CheckPostingDate(PostingDate: Date; VAR MaxPostingDate: Date)
    var
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
    begin
        IF GenJnlCheckLine.DateNotAllowed(PostingDate) THEN
            ERROR(NotAllowedPostingDatesErr);

        IF PostingDate > MaxPostingDate THEN
            MaxPostingDate := PostingDate;
    end;

    /// <summary> 
    /// Description for SetDtldCustLedgEntry.
    /// </summary>
    /// <param name="EntryNo">Parameter of type Integer.</param>
    local procedure SetDtldCustLedgEntry(EntryNo: Integer)
    begin
        DtldCustLedgEntry2.GET(EntryNo);
        CustLedgEntryNo := DtldCustLedgEntry2."Cust. Ledger Entry No.";
        PostingDate := DtldCustLedgEntry2."Posting Date";
        DocNo := DtldCustLedgEntry2."Document No.";
        Cust.GET(DtldCustLedgEntry2."Customer No.");
    end;

    /// <summary> 
    /// Description for InsertEntries.
    /// </summary>
    local procedure InsertEntries()
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        IF DtldCustLedgEntry2."Transaction No." = 0 THEN BEGIN
            DtldCustLedgEntry.SETCURRENTKEY("Application No.", "Customer No.", "Entry Type");
            DtldCustLedgEntry.SETRANGE("Application No.", DtldCustLedgEntry2."Application No.");
        END ELSE BEGIN
            DtldCustLedgEntry.SETCURRENTKEY("Transaction No.", "Customer No.", "Entry Type");
            DtldCustLedgEntry.SETRANGE("Transaction No.", DtldCustLedgEntry2."Transaction No.");
        END;
        DtldCustLedgEntry.SETRANGE("Customer No.", DtldCustLedgEntry2."Customer No.");
        tempDtldCustLedgEntry.DELETEALL;
        IF DtldCustLedgEntry.FINDSET THEN
            REPEAT
                IF (DtldCustLedgEntry."Entry Type" <> DtldCustLedgEntry."Entry Type"::"Initial Entry") AND
                   NOT DtldCustLedgEntry.Unapplied
                THEN BEGIN
                    tempDtldCustLedgEntry := DtldCustLedgEntry;
                    tempDtldCustLedgEntry.INSERT;
                END;
            UNTIL DtldCustLedgEntry.NEXT = 0;
    end;

    /// <summary> 
    /// Description for CheckAdditionalCurrency.
    /// </summary>
    /// <param name="OldPostingDate">Parameter of type Date.</param>
    /// <param name="NewPostingDate">Parameter of type Date.</param>
    local procedure CheckAdditionalCurrency(OldPostingDate: Date; NewPostingDate: Date)
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        IF OldPostingDate = NewPostingDate THEN
            EXIT;
        GLSetup.GET;
        IF GLSetup."Additional Reporting Currency" <> '' THEN
            IF CurrExchRate.ExchangeRate(OldPostingDate, GLSetup."Additional Reporting Currency") <>
               CurrExchRate.ExchangeRate(NewPostingDate, GLSetup."Additional Reporting Currency")
            THEN
                ERROR(CannotUnapplyExchRateErr, NewPostingDate);
    end;

    /// <summary> 
    /// Description for FindLastApplTransactionEntry.
    /// </summary>
    /// <param name="CustLedgEntryNo">Parameter of type Integer.</param>
    /// <returns>Return variable "Integer".</returns>
    local procedure FindLastApplTransactionEntry(CustLedgEntryNo: Integer): Integer
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        LastTransactionNo: Integer;
    begin
        DtldCustLedgEntry.SETCURRENTKEY("Cust. Ledger Entry No.", "Entry Type");
        DtldCustLedgEntry.SETRANGE("Cust. Ledger Entry No.", CustLedgEntryNo);
        DtldCustLedgEntry.SETRANGE("Entry Type", DtldCustLedgEntry."Entry Type"::Application);
        LastTransactionNo := 0;
        IF DtldCustLedgEntry.FIND('-') THEN
            REPEAT
                IF NOT GLSetup."Enable Russian Accounting" OR
                   (GLSetup."Enable Russian Accounting" AND (NOT DtldCustLedgEntry."Prepmt. Diff."))
                THEN
                    IF (DtldCustLedgEntry."Transaction No." > LastTransactionNo) AND NOT DtldCustLedgEntry.Unapplied THEN
                        LastTransactionNo := DtldCustLedgEntry."Transaction No.";
            UNTIL DtldCustLedgEntry.NEXT = 0;
        EXIT(LastTransactionNo);
    end;

    /// <summary> 
    /// Description for FindLastTransactionNo.
    /// </summary>
    /// <param name="CustLedgEntryNo">Parameter of type Integer.</param>
    /// <returns>Return variable "Integer".</returns>
    local procedure FindLastTransactionNo(CustLedgEntryNo: Integer): Integer
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        LastTransactionNo: Integer;
    begin
        DtldCustLedgEntry.SETCURRENTKEY("Cust. Ledger Entry No.", "Entry Type");
        DtldCustLedgEntry.SETRANGE("Cust. Ledger Entry No.", CustLedgEntryNo);
        DtldCustLedgEntry.SETRANGE(Unapplied, FALSE);
        DtldCustLedgEntry.SETFILTER("Entry Type", '<>%1&<>%2', DtldCustLedgEntry."Entry Type"::"Unrealized Loss", DtldCustLedgEntry."Entry Type"::"Unrealized Gain");
        LastTransactionNo := 0;
        IF DtldCustLedgEntry.FINDSET THEN
            REPEAT
                IF LastTransactionNo < DtldCustLedgEntry."Transaction No." THEN
                    LastTransactionNo := DtldCustLedgEntry."Transaction No.";
            UNTIL DtldCustLedgEntry.NEXT = 0;
        EXIT(LastTransactionNo);
    end;

    /// <summary> 
    /// Description for CollectAffectedLedgerEntries.
    /// </summary>
    /// <param name="VAR TempCustLedgerEntry">Parameter of type Record "Cust. Ledger Entry" temporary.</param>
    /// <param name="DetailedCustLedgEntry2">Parameter of type Record "Detailed Cust. Ledg. Entry".</param>
    local procedure CollectAffectedLedgerEntries(VAR TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary; DetailedCustLedgEntry2: Record "Detailed Cust. Ledg. Entry")
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        TempCustLedgerEntry.DELETEALL;
        IF DetailedCustLedgEntry2."Transaction No." = 0 THEN BEGIN
            DetailedCustLedgEntry.SETCURRENTKEY("Application No.", "Customer No.", "Entry Type");
            DetailedCustLedgEntry.SETRANGE("Application No.", DetailedCustLedgEntry2."Application No.");
        END ELSE BEGIN
            DetailedCustLedgEntry.SETCURRENTKEY("Transaction No.", "Customer No.", "Entry Type");
            DetailedCustLedgEntry.SETRANGE("Transaction No.", DetailedCustLedgEntry2."Transaction No.");
        END;
        DetailedCustLedgEntry.SETRANGE("Customer No.", DetailedCustLedgEntry2."Customer No.");
        DetailedCustLedgEntry.SETRANGE(Unapplied, FALSE);
        DetailedCustLedgEntry.SETFILTER("Entry Type", '<>%1', DetailedCustLedgEntry."Entry Type"::"Initial Entry");
        IF DetailedCustLedgEntry.FINDSET THEN
            REPEAT
                TempCustLedgerEntry."Entry No." := DetailedCustLedgEntry."Cust. Ledger Entry No.";
                IF TempCustLedgerEntry.INSERT THEN;
            UNTIL DetailedCustLedgEntry.NEXT = 0;
    end;

    /// <summary> 
    /// Description for MarkUnApplyPayment.
    /// </summary>
    /// <param name="CustLedgEntry">Parameter of type Record "Cust. Ledger Entry".</param>
    local procedure MarkUnApplyPayment(CustLedgEntry: Record "Cust. Ledger Entry")
    var
        locCustLedgEntry: Record "Cust. Ledger Entry";
    begin
        if (CustLedgEntry."Document Type" in [CustLedgEntry."Document Type"::Payment, CustLedgEntry."Document Type"::Refund]) then
            if locCustLedgEntry.Get(CustLedgEntry."Entry No.") then begin
                locCustLedgEntry.Validate("Applies-to ID", UserId);
                locCustLedgEntry.Modify();
            end;
    end;

}