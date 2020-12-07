codeunit 50001 "Prepayment Management"
{
    trigger OnRun()
    begin

    end;

    var
        Currency: Record Currency;
        Cust: Record Customer;
        DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
        GLSetup: Record "General Ledger Setup";
        SRSetup: Record "Sales & Receivables Setup";
        AmtDiffManagement: Codeunit PrepmtDiffManagement;
        SalesPostPrepaymentsSprut: Codeunit "Sales-Post Prepayments Sprut";
        WebServicesMgt: Codeunit "Web Service Mgt.";
        TaskModifyOrder: Codeunit "Task Modify Order";
        AllowAmtDiffUnapply: Boolean;
        CustLedgEntryNo: Integer;
        FirstInsertLineNo: Integer;
        UnapplyAllPostedAfterThisEntryErr: TextConst ENU = 'Before you can unapply this entry, you must first unapply all application entries in Cust. Ledger Entry No. %1 that were posted after this entry.',
                                                    RUS = 'Перед отменой этой операции необходимо отменить все операции применения в операции книги клиентов № %1, учтенные после этой операции.';
        NoApplicationEntryErr: TextConst ENU = 'Cust. Ledger Entry No. %1 does not have an application entry.',
                                        RUS = 'У операции книги клиентов № %1 нет операции применения.';
        NotAllowedPostingDatesErr: TextConst ENU = 'Posting date is not within the range of allowed posting dates.',
                                            RUS = 'Дата учета вне пределов разрешенного диапазона дат учета.';
        LatestEntryMustBeAnApplicationErr: TextConst ENU = 'The latest Transaction No. must be an application in Cust. Ledger Entry No. %1.',
                                                    RUS = 'Номер последней транзакции должен соответствовать применению в операции книги клиентов № %1.';
        MustNotBeBeforeErr: TextConst ENU = 'The Posting Date entered must not be before the Posting Date on the Cust. Ledger Entry.',
                                    RUS = 'Введенная дата учета не должна предшествовать дате учета операции книги клиентов.';
        errTotalAmountLessPrepaymentAmount: TextConst ENU = 'Total order amount less prepayment invoice amount.',
                                                    RUS = 'Сумма заказа меньше суммы счета на предоплату.';
        CannotUnapplyInReversalErr: TextConst ENU = 'You cannot unapply Cust. Ledger Entry No. %1 because the entry is part of a reversal.',
                                            RUS = 'Нельзя отменить операцию книги клиентов № %1, поскольку эта операция входит в состав сторнирования.';
        CannotUnapplyExchRateErr: TextConst ENU = 'You cannot unapply the entry with the posting date %1, because the exchange rate for the additional reporting currency has been changed.',
                                            RUS = 'Нельзя отменить операцию с датой учета %1, поскольку изменился курс дополнительной отчетной валюты.';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Payment Registration Mgt.", 'OnBeforeGenJnlLineInsert', '', false, false)]
    local procedure UpdateAgreementNo(var GenJournalLine: Record "Gen. Journal Line"; TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary)
    begin
        GenJournalLine."Agreement No." := TempPaymentRegistrationBuffer."Agreement No.";
    end;

    procedure OnDeleteSalesOrderLine(SalesOrderNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesOrderNo);
        SalesLine.DeleteAll(true);
    end;

    local procedure OpenSalesOrder(var SalesHeader: Record "Sales Header"; SalesOrderNo: Code[20])
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesOrderNo);
        if SalesHeader.Status <> SalesHeader.Status::Open then begin
            SalesHeader.Status := SalesHeader.Status::Open;
            SalesHeader.Modify();
        end;
    end;

    procedure OnModifySalesOrderInTask(SalesOrderNo: Code[20])
    var
        SpecificationResponseText: Text;
        InvoicesResponseText: Text;
    begin
        // Check Specification Amount
        // check modification sales order need
        if WebServicesMgt.GetSpecificationAndInvoice(SalesOrderNo, SpecificationResponseText, InvoicesResponseText) then
            // Create Task Modify Order
            TaskModifyOrder.CreateTaskModifyOrder(SalesOrderNo);
    end;

    procedure OnModifySalesOrderOneLine(SalesOrderNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SpecificationResponseText: Text;
        InvoicesResponseText: Text;
    begin
        // Check Specification Amount
        WebServicesMgt.GetSpecificationAndInvoice(SalesOrderNo, SpecificationResponseText, InvoicesResponseText);

        // unapply prepayments
        UnApplyPayments(SalesOrderNo);

        // Open Sales Order
        OpenSalesOrder(SalesHeader, SalesOrderNo);

        // create credit memo for prepayment invoice
        if SalesPostPrepaymentsSprut.CheckOpenPrepaymentLines(SalesHeader, 1) then
            SalesPostPrepaymentsSprut.PostPrepaymentCreditMemoSprut(SalesHeader);

        // Open Sales Order
        OpenSalesOrder(SalesHeader, SalesOrderNo);

        // delete all sales lines
        OnDeleteSalesOrderLine(SalesOrderNo);

        // insert sales line
        InsertSalesLineFromCRM(SalesOrderNo, SpecificationResponseText);

        // create prepayment invoice by amount
        CreatePrepaymentInvoicesFromCRM(SalesOrderNo, InvoicesResponseText);
    end;

    local procedure ModifySalesLine(var SalesLine: Record "Sales Line"; Qty: Decimal; UnitPrice: Decimal; LineAmount: Decimal)
    begin
        SalesLine.Validate(Quantity, Qty);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate("Line Amount", LineAmount);
        SalesLine.Modify(true);
    end;

    procedure InsertSalesLineFromCRM(SalesOrderNo: Code[20]; responseText: Text)
    var
        ItemNo: Code[20];
        Qty: Decimal;
        UnitPrice: Decimal;
        LineAmount: Decimal;
        ResponceTokenLine: Text;
        jsonLines: JsonArray;
        LineToken: JsonToken;
        crmLineID: Guid;
    begin
        //  to do
        // post to CRM for getting json with sales lines
        ResponceTokenLine := WebServicesMgt.GetSpecificationLinesArray(responseText);

        // loop for insert sales lines
        jsonLines.ReadFrom(ResponceTokenLine);
        foreach LineToken in jsonLines do begin
            ItemNo := WebServicesMgt.GetJSToken(LineToken.AsObject(), 'no').AsValue().AsText();
            Qty := Round(WebServicesMgt.GetJSToken(LineToken.AsObject(), 'quantity').AsValue().AsDecimal(), 0.01);
            UnitPrice := Round(WebServicesMgt.GetJSToken(LineToken.AsObject(), 'unit_price').AsValue().AsDecimal(), 0.01);
            LineAmount := Round(WebServicesMgt.GetJSToken(LineToken.AsObject(), 'total_amount').AsValue().AsDecimal(), 0.01);
            crmLineID := WebServicesMgt.GetJSToken(LineToken.AsObject(), 'crm_line_id').AsValue().AsText();
            InsertNewSalesLine(SalesOrderNo, ItemNo, Qty, UnitPrice, LineAmount, crmLineID);
        end;
    end;

    procedure CreatePrepaymentInvoicesFromCRM(SalesOrderNo: Code[20]; responseText: Text);
    var
        invoiceID: Text[50];
        API_SalesInvoice: Page "APIV2 - Sales Invoice";
        PrepmInvAmount: Decimal;
        jsonPrepmInv: JsonArray;
        PrepmInvToken: JsonToken;
    begin
        // loop for create prepayment invoices
        jsonPrepmInv.ReadFrom(responseText);
        foreach PrepmInvToken in jsonPrepmInv do begin
            invoiceID := WebServicesMgt.GetJSToken(PrepmInvToken.AsObject(), 'invoice_id').AsValue().AsText();
            PrepmInvAmount := Round(WebServicesMgt.GetJSToken(PrepmInvToken.AsObject(), 'totalamount').AsValue().AsDecimal(), 0.01);
            API_SalesInvoice.SetInit(invoiceID, PrepmInvAmount);
            API_SalesInvoice.CreatePrepaymentInvoice(SalesOrderNo);
        end;
    end;

    local procedure GetSalesOrderLastLineNo(SalesOrderNo: Code[20]): Integer
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesOrderNo);
        if SalesLine.FindLast() then
            exit(SalesLine."Line No." + 10000);
        exit(10000);
    end;

    local procedure InsertNewSalesLine(SalesOrderNo: Code[20]; ItemNo: Code[20]; Qty: Decimal; UnitPrice: Decimal; LineAmount: Decimal; crmLineID: Guid)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Init();
        SalesLine."Document Type" := SalesLine."Document Type"::Order;
        SalesLine."Document No." := SalesOrderNo;
        SalesLine."Line No." := GetSalesOrderLastLineNo(SalesOrderNo);
        SalesLine.Insert(true);

        SalesLine.Type := SalesLine.Type::Item;
        SalesLine.Validate("No.", ItemNo);
        SalesLine.Validate(Quantity, Qty);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate("Line Amount", LineAmount);
        Evaluate(SalesLine."CRM ID", crmLineID);
        SalesLine.Validate("CRM ID");
        SalesLine.Modify(true);
    end;

    // for test
    // [EventSubscriber(ObjectType::Table, 37, 'OnBeforeUpdatePrepmtAmounts', '', false, false)]
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

    procedure GetPrepaymentInvoices(PrepaymentOrderNo: Code[20]; var tempSalesInvoiceHeader: Record "Sales Invoice Header" temporary)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetCurrentKey("Prepayment Order No.");
        SalesInvoiceHeader.SetRange("Prepayment Order No.", PrepaymentOrderNo);
        if SalesInvoiceHeader.FindSet() then
            repeat
                tempSalesInvoiceHeader := SalesInvoiceHeader;
                tempSalesInvoiceHeader.Insert();
            until SalesInvoiceHeader.Next() = 0;
    end;

    procedure GetLastPrepaymentCreditMemoNo(PrepaymentOrderNo: Code[20]; var DocumentNo: Code[20]; var PostingDate: Date)
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

    procedure UnApplyPayments(SalesOrderNo: Code[20])
    var
        tempSalesInvoiceHeader: Record "Sales Invoice Header" temporary;
    begin
        GetPrepaymentInvoices(SalesOrderNo, tempSalesInvoiceHeader);
        if tempSalesInvoiceHeader.FindLast() then
            repeat
                UnApplyCustLedgEntry(GetCustomerLedgerEntryNo(tempSalesInvoiceHeader."No.", tempSalesInvoiceHeader."Posting Date"));
            until tempSalesInvoiceHeader.Next() = 0;
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
    begin
        CheckReversal(CustLedgEntryNo);
        FindApplEntries(CustLedgEntryNo);
    end;

    procedure FindApplEntries(CustLedgEntryNo: Integer): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
        tempDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry" temporary;
    begin
        DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type");
        DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntryNo);
        DtldCustLedgEntry.SetRange("Entry Type", DtldCustLedgEntry."Entry Type"::Application);
        DtldCustLedgEntry.SetRange(Unapplied, false);
        if DtldCustLedgEntry.FindSet() then
            repeat
                if DtldCustLedgEntry."Cust. Ledger Entry No." = DtldCustLedgEntry."Applied Cust. Ledger Entry No." then begin
                    DtldCustLedgEntry2.Init();
                    DtldCustLedgEntry2.SetCurrentKey("Applied Cust. Ledger Entry No.", "Entry Type");
                    DtldCustLedgEntry2.SetRange("Applied Cust. Ledger Entry No.", DtldCustLedgEntry."Applied Cust. Ledger Entry No.");
                    DtldCustLedgEntry2.SetRange("Entry Type", DtldCustLedgEntry2."Entry Type"::Application);
                    DtldCustLedgEntry2.SetRange(Unapplied, false);
                    if DtldCustLedgEntry2.FindSet(false, false) then
                        repeat
                            if DtldCustLedgEntry2."Cust. Ledger Entry No." <> DtldCustLedgEntry2."Applied Cust. Ledger Entry No." then begin
                                tempDtldCustLedgEntry := DtldCustLedgEntry2;
                                tempDtldCustLedgEntry."Applied Cust. Ledger Entry No." := DtldCustLedgEntry2."Cust. Ledger Entry No.";
                                tempDtldCustLedgEntry.Insert();
                            end;
                        until DtldCustLedgEntry2.Next() = 0;
                end else begin
                    tempDtldCustLedgEntry := DtldCustLedgEntry;
                    tempDtldCustLedgEntry.Insert();
                end;
            until DtldCustLedgEntry.Next() = 0;

        tempDtldCustLedgEntry.SetCurrentKey("Entry No.");
        if tempDtldCustLedgEntry.FindLast() then
            repeat
                if CustLedgerEntry.Get(tempDtldCustLedgEntry."Applied Cust. Ledger Entry No.") then
                    if CustLedgerEntry."Document Type" = CustLedgerEntry."Document Type"::Payment then begin
                        if DtldCustLedgEntry.Get(tempDtldCustLedgEntry."Entry No.")
                        and not DtldCustLedgEntry.Unapplied then
                            UnApplyCustomer(tempDtldCustLedgEntry."Entry No.");
                    end;

            until tempDtldCustLedgEntry.Next(-1) = 0;
    end;

    local procedure CheckReversal(CustLedgEntryNo: Integer)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.GET(CustLedgEntryNo);
        IF CustLedgEntry.Reversed THEN
            ERROR(CannotUnapplyInReversalErr, CustLedgEntryNo);
    end;

    local procedure UnApplyCustomer(ApplicationEntryNo: Integer)
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DtldCustLedgEntry.GET(ApplicationEntryNo);
        SetDtldCustLedgEntry(DtldCustLedgEntry."Entry No.");
        PostUnApplyCustomer(DtldCustLedgEntry2, DtldCustLedgEntry2."Document No.", DtldCustLedgEntry2."Posting Date");
    end;

    local procedure PostUnApplyCustomer(DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry"; DocNo: Code[20]; PostingDate: Date)
    begin
        PostUnApplyCustomerCommit(DtldCustLedgEntry2, DocNo, PostingDate, TRUE);
        // for testing commit false
        // PostUnApplyCustomerCommit(DtldCustLedgEntry2, DocNo, PostingDate, false);
    end;

    local procedure PostUnApplyCustomerCommit(DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry"; DocNo: Code[20]; PostingDate: Date; CommitChanges: Boolean)
    var
        GLEntry: Record "G/L Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlLine: Record "Gen. Journal Line";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DateComprReg: Record "Date Compr. Register";
        TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        LastTransactionNo: Integer;
        AddCurrChecked: Boolean;
        MaxPostingDate: Date;
        AdjustExchangeRates: Report "Adjust Exchange Rates";
    begin
        MaxPostingDate := 0D;
        GLEntry.LockTable();
        DtldCustLedgEntry.LockTable();
        CustLedgEntry.LockTable();
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
            Commit();
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

    local procedure SetDtldCustLedgEntry(EntryNo: Integer)
    begin
        DtldCustLedgEntry2.GET(EntryNo);
        CustLedgEntryNo := DtldCustLedgEntry2."Cust. Ledger Entry No.";
        Cust.GET(DtldCustLedgEntry2."Customer No.");
    end;

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