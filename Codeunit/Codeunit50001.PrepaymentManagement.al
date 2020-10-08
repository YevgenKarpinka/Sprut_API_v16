codeunit 50001 "Prepayment Management"
{
    trigger OnRun()
    begin

    end;

    var
        Currency: Record Currency;
        SRSetup: Record "Sales & Receivables Setup";
        CannotUnapplyInReversalErr: TextConst ENU = 'You cannot unapply Cust. Ledger Entry No. %1 because the entry is part of a reversal.',
                                            RUS = 'Нельзя отменить операцию книги клиентов № %1, поскольку эта операция входит в состав сторнирования.';
        NoApplicationEntryErr: TextConst ENU = 'Cust. Ledger Entry No. %1 does not have an application entry.',
                                        RUS = 'У операции книги клиентов № %1 нет операции применения.';
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        tempDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry" temporary;
        DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
        Cust: Record Customer;
        DocNo: Code[20];
        PostingDate: Date;
        CustLedgEntryNo: Integer;

    [EventSubscriber(ObjectType::Table, 37, 'OnBeforeUpdatePrepmtAmounts', '', false, false)]
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

    local procedure GetSRSetup()
    begin
        IF not SRSetup.Get() then begin
            SRSetup.Init();
            SRSetup.Insert();
        end;
    end;

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

    local procedure CheckReversal(CustLedgEntryNo: Integer)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.GET(CustLedgEntryNo);
        IF CustLedgEntry.Reversed THEN
            ERROR(CannotUnapplyInReversalErr, CustLedgEntryNo);
    end;

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

    local procedure PostUnApplyCustomer(DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry"; DocNo: Code[20]; PostingDate: Date)
    begin
        PostUnApplyCustomerCommit(DtldCustLedgEntry2, DocNo, PostingDate, TRUE);
    end;

    local procedure PostUnApplyCustomerCommit(DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry"; DocNo: Code[20]; PostingDate: Date; CommitChanges: Boolean)
    var
        GLEntry: Record "G/L Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlLine: Record "Gen. Journal Line";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DateComprReg: Record "Date Compr. Register";
        TempCustLedgerEntry: Record "Cust. Ledger Entry";
        AdjustExchangeRates: Report "Adjust Exchange Rates";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        LastTransactionNo: Integer;
        AddCurrChecked: Boolean;
        MaxPostingDate: Date;
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

        WITH DtldCustLedgEntry2 DO BEGIN
            SourceCodeSetup.GET;
            CustLedgEntry.GET("Cust. Ledger Entry No.");
            GenJnlLine."Document No." := DocNo;
            GenJnlLine."Posting Date" := PostingDate;
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer;
            GenJnlLine."Account No." := "Customer No.";
            GenJnlLine.Correction := TRUE;
            GenJnlLine.CopyCustLedgEntry(CustLedgEntry);
            GenJnlLine."Source Code" := SourceCodeSetup."Unapplied Sales Entry Appln.";
            GenJnlLine."Source Currency Code" := "Currency Code";
            GenJnlLine."System-Created Entry" := TRUE;
            GenJnlLine."Agreement No." := "Agreement No.";
            // Window.OPEN(UnapplyingMsg);

            CollectAffectedLedgerEntries(TempCustLedgerEntry, DtldCustLedgEntry2);
            GenJnlPostLine.UnapplyCustLedgEntry(GenJnlLine, DtldCustLedgEntry2);
            AdjustExchangeRates.AdjustExchRateCust(GenJnlLine, TempCustLedgerEntry);

            IF GLSetup."Enable Russian Accounting" THEN BEGIN
                AmtDiffManagement.SetInitialVATTransactionNo("Transaction No.");
                AmtDiffManagement.PrepmtDiffProcessing(TRUE, PreviewMode);
            END;

            IF PreviewMode THEN
                GenJnlPostPreview.ThrowError;

            IF CommitChanges AND (NOT AllowAmtDiffUnapply) THEN
                COMMIT;
            // Window.CLOSE;
        END;
    end;

    local procedure CheckPostingDate(PostingDate: Date; VAR MaxPostingDate: Date)
    var
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
    begin
        IF GenJnlCheckLine.DateNotAllowed(PostingDate) THEN
            ERROR(NotAllowedPostingDatesErr);

        IF PostingDate > MaxPostingDate THEN
            MaxPostingDate := PostingDate;
    end;

    local procedure SetDtldCustLedgEntry(EntryNo: Integer)
    begin
        DtldCustLedgEntry2.GET(EntryNo);
        CustLedgEntryNo := DtldCustLedgEntry2."Cust. Ledger Entry No.";
        PostingDate := DtldCustLedgEntry2."Posting Date";
        DocNo := DtldCustLedgEntry2."Document No.";
        Cust.GET(DtldCustLedgEntry2."Customer No.");
    end;

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
}