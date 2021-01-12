codeunit 50009 "Payment Management"
{
    trigger OnRun()
    begin

    end;

    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"Payment Registration Mgt.", 'OnBeforeGenJnlLineInsert', '', false, false)]
    // local procedure OnBeforeGenJournalLineInsert(var GenJournalLine: Record "Gen. Journal Line"; TempPaymentRegistrationBuffer: Record "Payment Registration Buffer")
    // begin
    //     GenJournalLine."Agreement No." := TempPaymentRegistrationBuffer."Agreement No.";

    //     if GenJournalLine."Applies-to ID" = '' then
    //         CreateApplyTaskForSendingToCRM(TempPaymentRegistrationBuffer."Ledger Entry No.", TempPaymentRegistrationBuffer."Pmt. Discount Date",
    //                                        TempPaymentRegistrationBuffer."Document No.", 0, GenJournalLine."Posting Date",
    //                                        GenJournalLine."Document No.", TempPaymentRegistrationBuffer."Amount Received")
    //     else
    //         InsertTaskPaymentFromRegistrationLump(GenJournalLine."Posting Date", GenJournalLine."Applies-to ID", GenJournalLine."Account No.");
    // end;

    local procedure InsertTaskPaymentFromRegistrationLump(PostingDate: Date; CustEntryApplID: Code[20]; CustomerNo: Code[20])
    var
        AppliedCustLedgEntry: Record "Cust. Ledger Entry";
    begin
        AppliedCustLedgEntry.SetCurrentKey("Customer No.", Open, Positive);
        AppliedCustLedgEntry.SetRange("Customer No.", CustomerNo);
        AppliedCustLedgEntry.SetRange(Open, true);
        AppliedCustLedgEntry.SetRange("Applies-to ID", CustEntryApplID);
        AppliedCustLedgEntry.SetRange("Document Type", AppliedCustLedgEntry."Document Type"::Invoice);
        AppliedCustLedgEntry.LockTable();
        if AppliedCustLedgEntry.FindSet(false, false) then begin
            repeat
                CreateApplyTaskForSendingToCRM(AppliedCustLedgEntry."Entry No.", AppliedCustLedgEntry."Posting Date",
                                               AppliedCustLedgEntry."Document No.", 0, PostingDate,
                                               AppliedCustLedgEntry."Applies-to ID", AppliedCustLedgEntry."Amount to Apply");
            until AppliedCustLedgEntry.Next() = 0;
        end;
    end;

    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"Payment Registration Mgt.", 'OnAfterPostPaymentRegistration', '', false, false)]
    // local procedure OnAfterPostPaymentRegistration()
    // var
    //     TaskPaymentSend: Record "Task Payment Send";
    //     UpdateTaskPaymentSend: Record "Task Payment Send";
    //     CustLedgEntry: Record "Cust. Ledger Entry";
    // begin
    //     TaskPaymentSend.SetCurrentKey("Payment Entry No.");
    //     TaskPaymentSend.SetRange("Payment Entry No.", 0);
    //     if TaskPaymentSend.FindSet(false, true) then
    //         repeat
    //             CustLedgEntry.SetCurrentKey("Document Type", "Posting Date", "Document No.");
    //             CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Payment);
    //             CustLedgEntry.SetRange("Posting Date", TaskPaymentSend."Payment Date");
    //             CustLedgEntry.SetRange("Document No.", TaskPaymentSend."Payment No.");
    //             if CustLedgEntry.FindFirst() then begin
    //                 UpdateTaskPaymentSend.SetRange("Payment Date", TaskPaymentSend."Payment Date");
    //                 UpdateTaskPaymentSend.SetRange("Payment No.", TaskPaymentSend."Payment No.");
    //                 UpdateTaskPaymentSend.ModifyAll("Payment Entry No.", CustLedgEntry."Entry No.", true);
    //             end;
    //         until TaskPaymentSend.Next() = 0;
    // end;

    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"CustEntry-Apply Posted Entries", 'OnBeforePostApplyCustLedgEntry', '', false, false)]
    // local procedure OnBeforePostApplyCustLedgEntry(CustLedgerEntry: Record "Cust. Ledger Entry")
    // begin
    //     if CustLedgerEntry."Document Type" <> CustLedgerEntry."Document Type"::Invoice then exit;
    //     InsertTaskPaymentSendFromCustEntryApply(CustLedgerEntry."Entry No.", CustLedgerEntry."Posting Date",
    //                                             CustLedgerEntry."Document No.", CustLedgerEntry."Customer No.",
    //                                             CustLedgerEntry."Applies-to ID");
    // end;

    local procedure InsertTaskPaymentSendFromCustEntryApply(InvoiceEntryNo: Integer; InvoiceDate: Date; InvoiceNo: Code[20]; CustomerNo: Code[20]; AppliesToID: Code[50])
    var
        locCustLedgEntry: Record "Cust. Ledger Entry";
        TaskPaymentSend: Record "Task Payment Send";
    begin
        locCustLedgEntry.SetCurrentKey("Customer No.", "Applies-to ID", "Document Type");
        locCustLedgEntry.SetRange("Customer No.", CustomerNo);
        locCustLedgEntry.SetRange("Applies-to ID", AppliestoID);
        locCustLedgEntry.SetRange("Document Type", locCustLedgEntry."Document Type"::Payment);
        if locCustLedgEntry.FindSet(false, false) then
            repeat
                CreateApplyTaskForSendingToCRM(InvoiceEntryNo, InvoiceDate, InvoiceNo,
                        locCustLedgEntry."Entry No.", locCustLedgEntry."Posting Date",
                        locCustLedgEntry."Document No.", Abs(locCustLedgEntry."Amount to Apply"));
            until locCustLedgEntry.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnBeforePostDtldCVLedgEntry', '', false, false)]
    local procedure OnBeforePostDtldCVLedgEntry(var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer")
    begin
        if DetailedCVLedgEntryBuffer."CV Ledger Entry No." = DetailedCVLedgEntryBuffer."Applied CV Ledger Entry No." then exit;

        if not (CheckUnAppliedEntryPaymentOrInvoice(DetailedCVLedgEntryBuffer."CV Ledger Entry No.")
        and CheckUnAppliedEntryPaymentOrInvoice(DetailedCVLedgEntryBuffer."Applied CV Ledger Entry No.")) then
            exit;

        if isPayment(DetailedCVLedgEntryBuffer."Applied CV Ledger Entry No.") then
            // create task for sending to CRM
            CreateApplyTaskForSendingToCRM(DetailedCVLedgEntryBuffer."CV Ledger Entry No.", GetCustLedgEntrtyPostingDate(DetailedCVLedgEntryBuffer."CV Ledger Entry No."), GetCustLedgEntrtyDocumentNo(DetailedCVLedgEntryBuffer."CV Ledger Entry No."),
                                           DetailedCVLedgEntryBuffer."Applied CV Ledger Entry No.", GetCustLedgEntrtyPostingDate(DetailedCVLedgEntryBuffer."Applied CV Ledger Entry No."), GetCustLedgEntrtyDocumentNo(DetailedCVLedgEntryBuffer."Applied CV Ledger Entry No."),
                                           Abs(DetailedCVLedgEntryBuffer.Amount))
        else
            CreateApplyTaskForSendingToCRM(DetailedCVLedgEntryBuffer."Applied CV Ledger Entry No.", GetCustLedgEntrtyPostingDate(DetailedCVLedgEntryBuffer."Applied CV Ledger Entry No."), GetCustLedgEntrtyDocumentNo(DetailedCVLedgEntryBuffer."Applied CV Ledger Entry No."),
                                           DetailedCVLedgEntryBuffer."CV Ledger Entry No.", GetCustLedgEntrtyPostingDate(DetailedCVLedgEntryBuffer."CV Ledger Entry No."), GetCustLedgEntrtyDocumentNo(DetailedCVLedgEntryBuffer."CV Ledger Entry No."),
                                           Abs(DetailedCVLedgEntryBuffer.Amount));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnBeforeInsertDtldCustLedgEntryUnapply', '', false, false)]
    local procedure OnBeforeInsertDtldCustLedgEntryUnapply(OldDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
        if OldDtldCustLedgEntry."Cust. Ledger Entry No." = OldDtldCustLedgEntry."Applied Cust. Ledger Entry No." then exit;

        if not (CheckUnAppliedEntryPaymentOrInvoice(OldDtldCustLedgEntry."Cust. Ledger Entry No.")
        and CheckUnAppliedEntryPaymentOrInvoice(OldDtldCustLedgEntry."Applied Cust. Ledger Entry No.")) then
            exit;

        if isPayment(OldDtldCustLedgEntry."Applied Cust. Ledger Entry No.") then
            // create task for sending to CRM
            CreateUnApplyTaskForSendingToCRM(OldDtldCustLedgEntry."Cust. Ledger Entry No.", GetCustLedgEntrtyPostingDate(OldDtldCustLedgEntry."Cust. Ledger Entry No."), GetCustLedgEntrtyDocumentNo(OldDtldCustLedgEntry."Cust. Ledger Entry No."),
                                             OldDtldCustLedgEntry."Applied Cust. Ledger Entry No.", GetCustLedgEntrtyPostingDate(OldDtldCustLedgEntry."Applied Cust. Ledger Entry No."), GetCustLedgEntrtyDocumentNo(OldDtldCustLedgEntry."Applied Cust. Ledger Entry No."),
                                             Abs(OldDtldCustLedgEntry.Amount))
        else
            CreateUnApplyTaskForSendingToCRM(OldDtldCustLedgEntry."Applied Cust. Ledger Entry No.", GetCustLedgEntrtyPostingDate(OldDtldCustLedgEntry."Applied Cust. Ledger Entry No."), GetCustLedgEntrtyDocumentNo(OldDtldCustLedgEntry."Applied Cust. Ledger Entry No."),
                                             OldDtldCustLedgEntry."Cust. Ledger Entry No.", GetCustLedgEntrtyPostingDate(OldDtldCustLedgEntry."Cust. Ledger Entry No."), GetCustLedgEntrtyDocumentNo(OldDtldCustLedgEntry."Cust. Ledger Entry No."),
                                             Abs(OldDtldCustLedgEntry.Amount));
    end;

    local procedure CheckUnAppliedEntryPaymentOrInvoice(EntryNo: Integer): Boolean
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        if CustLedgEntry.Get(EntryNo)
        and (CustLedgEntry."Document Type" in [CustLedgEntry."Document Type"::Invoice, CustLedgEntry."Document Type"::Payment]) then
            exit(true);
        exit(false);
    end;

    local procedure isPayment(EntryNo: Integer): Boolean
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        if CustLedgEntry.Get(EntryNo)
        and (CustLedgEntry."Document Type" in [CustLedgEntry."Document Type"::Payment]) then
            exit(true);
        exit(false);
    end;

    local procedure GetCustLedgEntrtyPostingDate(EntryNo: Integer): Date
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        if CustLedgEntry.Get(EntryNo) then;
        exit(CustLedgEntry."Posting Date");
    end;

    local procedure GetCustLedgEntrtyDocumentNo(EntryNo: Integer): Code[20]
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        if CustLedgEntry.Get(EntryNo) then;
        exit(CustLedgEntry."Document No.");
    end;

    local procedure CreateApplyTaskForSendingToCRM(InvoiceEntryNo: Integer; InvoiceDate: Date; InvoiceNo: Code[20];
                                                   PaymentEntryNo: Integer; PaymentDate: Date; PaymentNo: Code[20];
                                                   PaymentAmount: Decimal);
    var
        TaskPaymentSend: Record "Task Payment Send";
    begin
        // TaskPaymentSend.SetCurrentKey("Invoice Entry No.", "Payment Entry No.");
        TaskPaymentSend.SetRange("Entry Type", TaskPaymentSend."Entry Type"::Apply);
        TaskPaymentSend.SetRange("Invoice Entry No.", InvoiceEntryNo);
        TaskPaymentSend.SetRange("Payment Entry No.", PaymentEntryNo);
        TaskPaymentSend.SetRange("Payment Amount", PaymentAmount);
        if TaskPaymentSend.FindFirst() then begin
            TaskPaymentSend.Status := TaskPaymentSend.Status::OnPaymentSend;
            TaskPaymentSend."Work Status" := TaskPaymentSend."Work Status"::WaitingForWork;
            TaskPaymentSend.Modify(true);
        end else begin
            TaskPaymentSend.Init();
            TaskPaymentSend."Invoice Entry No." := InvoiceEntryNo;
            TaskPaymentSend."Invoice Date" := InvoiceDate;
            TaskPaymentSend."Invoice No." := InvoiceNo;
            TaskPaymentSend."Payment Entry No." := PaymentEntryNo;
            TaskPaymentSend."Payment Date" := PaymentDate;
            TaskPaymentSend."Payment No." := PaymentNo;
            TaskPaymentSend."Payment Amount" := PaymentAmount;
            TaskPaymentSend.Insert(true);
        end;
    end;

    local procedure CreateUnApplyTaskForSendingToCRM(InvoiceEntryNo: Integer; InvoiceDate: Date; InvoiceNo: Code[20];
                                                     PaymentEntryNo: Integer; PaymentDate: Date; PaymentNo: Code[20];
                                                     PaymentAmount: Decimal)
    var
        TaskPaymentSend: Record "Task Payment Send";
    begin
        // TaskPaymentSend.SetCurrentKey("Invoice Entry No.", "Payment Entry No.");
        TaskPaymentSend.SetRange("Entry Type", TaskPaymentSend."Entry Type"::UnApply);
        TaskPaymentSend.SetRange("Invoice Entry No.", InvoiceEntryNo);
        TaskPaymentSend.SetRange("Payment Entry No.", PaymentEntryNo);
        TaskPaymentSend.SetRange("Payment Amount", PaymentAmount);
        if TaskPaymentSend.FindFirst() then begin
            TaskPaymentSend.Status := TaskPaymentSend.Status::OnPaymentSend;
            TaskPaymentSend."Work Status" := TaskPaymentSend."Work Status"::WaitingForWork;
            TaskPaymentSend."CRM Payment Id" := GetCRMPaymentId(InvoiceNo, PaymentNo, PaymentAmount);
            TaskPaymentSend.Modify(true);
        end else begin
            TaskPaymentSend.Init();
            TaskPaymentSend."Entry Type" := TaskPaymentSend."Entry Type"::UnApply;
            TaskPaymentSend."Invoice Entry No." := InvoiceEntryNo;
            TaskPaymentSend."Invoice Date" := InvoiceDate;
            TaskPaymentSend."Invoice No." := InvoiceNo;
            TaskPaymentSend."Payment Entry No." := PaymentEntryNo;
            TaskPaymentSend."Payment Date" := PaymentDate;
            TaskPaymentSend."Payment No." := PaymentNo;
            TaskPaymentSend."Payment Amount" := PaymentAmount;
            TaskPaymentSend."CRM Payment Id" := GetCRMPaymentId(InvoiceNo, PaymentNo, PaymentAmount);
            TaskPaymentSend.Insert(true);
        end;
    end;

    local procedure GetCRMPaymentId(InvoiceNo: Code[20]; PaymentNo: Code[20]; PaymentAmount: Decimal): Guid
    var
        TaskPaymentSend: Record "Task Payment Send";
    begin
        TaskPaymentSend.SetRange("Entry Type", TaskPaymentSend."Entry Type"::Apply);
        TaskPaymentSend.SetRange("Invoice No.", InvoiceNo);
        TaskPaymentSend.SetRange("Payment No.", PaymentNo);
        TaskPaymentSend.SetRange("Payment Amount", PaymentAmount);
        if TaskPaymentSend.FindLast() then;
        exit(TaskPaymentSend."CRM Payment Id");
    end;
}