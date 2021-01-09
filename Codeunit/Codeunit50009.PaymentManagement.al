codeunit 50009 "Payment Management"
{
    trigger OnRun()
    begin

    end;

    var
    // WebServiceMgt: Codeunit "Web Service Mgt.";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Payment Registration Mgt.", 'OnBeforeGenJnlLineInsert', '', false, false)]
    local procedure UpdateAgreementNo(var GenJournalLine: Record "Gen. Journal Line"; TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary)
    begin
        GenJournalLine."Agreement No." := TempPaymentRegistrationBuffer."Agreement No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Payment Registration Mgt.", 'OnBeforeGenJnlLineInsert', '', false, false)]
    local procedure OnBeforeGenJournalLineInsert(TempPaymentRegistrationBuffer: Record "Payment Registration Buffer"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        if GenJournalLine."Applies-to ID" = '' then
            InsertTaskPaymentFromPaymentRegistration(TempPaymentRegistrationBuffer, GenJournalLine)
        else
            InsertTaskPaymentFromRegistrationLump(GenJournalLine."Posting Date", GenJournalLine."Applies-to ID", GenJournalLine."Account No.");
    end;

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
                InsertTaskPaymentSendFromAppliedCustLedgEntry(AppliedCustLedgEntry."Entry No.", AppliedCustLedgEntry."Posting Date",
                                                            AppliedCustLedgEntry."Document No.", PostingDate, AppliedCustLedgEntry."Applies-to ID",
                                                            AppliedCustLedgEntry."Amount to Apply");
            until AppliedCustLedgEntry.Next() = 0;
        end;
    end;

    local procedure InsertTaskPaymentSendFromAppliedCustLedgEntry(InvoiceEntryNo: Integer; InvoiceDate: Date; InvoiceNo: Code[20]; PostingDate: Date; AppliesToID: Code[50]; AmountToApply: Decimal)
    var
        TaskPaymentSend: Record "Task Payment Send";
    begin
        TaskPaymentSend.Init();
        TaskPaymentSend."Invoice Entry No." := InvoiceEntryNo;
        TaskPaymentSend."Invoice Date" := InvoiceDate;
        TaskPaymentSend."Invoice No." := InvoiceNo;
        TaskPaymentSend."Payment Date" := PostingDate;
        TaskPaymentSend."Payment No." := AppliesToID;
        TaskPaymentSend."Payment Amount" := Abs(AmountToApply);
        TaskPaymentSend.Insert(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Payment Registration Mgt.", 'OnAfterPostPaymentRegistration', '', false, false)]
    local procedure OnAfterPostPaymentRegistration(TempPaymentRegistrationBuffer: Record "Payment Registration Buffer")
    var
        TaskPaymentSend: Record "Task Payment Send";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        TempPaymentRegistrationBuffer.SetCurrentKey("Payment Made", "Document Type");
        TempPaymentRegistrationBuffer.SetRange("Payment Made", true);
        TempPaymentRegistrationBuffer.SetRange("Document Type", TempPaymentRegistrationBuffer."Document Type"::Invoice);
        if TempPaymentRegistrationBuffer.FindSet(false, false) then
            repeat
                TaskPaymentSend.SetCurrentKey("Entry Type", "Invoice Entry No.", "Invoice Date", "Invoice No.");
                TaskPaymentSend.SetRange("Entry Type", TaskPaymentSend."Entry Type"::Apply);
                TaskPaymentSend.SetRange("Work Status", TaskPaymentSend."Work Status"::WaitingForWork);
                TaskPaymentSend.SetRange("Invoice Entry No.", TempPaymentRegistrationBuffer."Ledger Entry No.");
                TaskPaymentSend.SetRange("Invoice Date", TempPaymentRegistrationBuffer."Posting Date");
                TaskPaymentSend.SetRange("Invoice No.", TempPaymentRegistrationBuffer."Document No.");
                if TaskPaymentSend.FindSet(false, true) then begin
                    CustLedgEntry.SetCurrentKey("Posting Date", "Document No.");
                    CustLedgEntry.SetRange("Posting Date", TempPaymentRegistrationBuffer."Date Received");
                    CustLedgEntry.SetRange("Document No.", TaskPaymentSend."Payment No.");
                    if CustLedgEntry.FindFirst() then
                        repeat
                            if TaskPaymentSend."Payment Entry No." = 0 then begin
                                TaskPaymentSend."Payment Entry No." := CustLedgEntry."Entry No.";
                                TaskPaymentSend.Modify(true);
                            end;
                        until TaskPaymentSend.Next() = 0;
                end;
            until TempPaymentRegistrationBuffer.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CustEntry-Apply Posted Entries", 'OnBeforePostApplyCustLedgEntry', '', false, false)]
    local procedure OnBeforePostApplyCustLedgEntry(CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        if CustLedgerEntry."Document Type" <> CustLedgerEntry."Document Type"::Invoice then exit;
        InsertTaskPaymentSendFromCustEntryApply(CustLedgerEntry."Entry No.", CustLedgerEntry."Posting Date", CustLedgerEntry."Document No.", CustLedgerEntry."Customer No.", CustLedgerEntry."Applies-to ID");
    end;

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
                TaskPaymentSend.Init();
                TaskPaymentSend."Invoice Entry No." := InvoiceEntryNo;
                TaskPaymentSend."Invoice Date" := InvoiceDate;
                TaskPaymentSend."Invoice No." := InvoiceNo;
                TaskPaymentSend."Payment Entry No." := locCustLedgEntry."Entry No.";
                TaskPaymentSend."Payment Date" := locCustLedgEntry."Posting Date";
                TaskPaymentSend."Payment No." := locCustLedgEntry."Document No.";
                TaskPaymentSend."Payment Amount" := Abs(locCustLedgEntry."Amount to Apply");
                TaskPaymentSend.Insert(true);
            until locCustLedgEntry.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CustEntry-Apply Posted Entries", 'OnAfterPostUnapplyCustLedgEntry', '', false, false)]
    local procedure OnAfterPostUnapplyCustLedgEntry(DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        SalesInvHeader: Record "Sales Invoice Header";
        CustAgreement: Record "Customer Agreement";
    begin
        if (DetailedCustLedgEntry."Entry Type" = DetailedCustLedgEntry."Entry Type"::Application)
        and (DetailedCustLedgEntry."Document Type" = DetailedCustLedgEntry."Document Type"::Payment)
        and (CustLedgerEntry."Document Type" = CustLedgerEntry."Document Type"::Invoice) then begin
            if SalesInvHeader.Get(CustLedgerEntry."Document No.")
            and (SalesInvHeader."CRM Invoice No." <> '') then begin
                // if CustAgreement.Get(SalesInvHeader."Sell-to Customer No.", SalesInvHeader."Agreement No.")
                //     and not IsNullGuid(CustAgreement."CRM ID") then
                // sent to CRM payment with amount equal 0
                //    WebServiceMgt.SendPaymentToCRM(SalesInvHeader."CRM Header ID", '', 0, SalesInvHeader."CRM Invoice No.", SalesInvHeader."CRM ID", DetailedCustLedgEntry."CRM Payment Id");
            end;
        end;
    end;

    local procedure InsertTaskPaymentFromPaymentRegistration(TempPaymentRegistrationBuffer: Record "Payment Registration Buffer"; GenJournalLine: Record "Gen. Journal Line");
    var
        TaskPaymentSend: Record "Task Payment Send";
    begin
        TaskPaymentSend.Init();
        TaskPaymentSend."Invoice Entry No." := TempPaymentRegistrationBuffer."Ledger Entry No.";
        TaskPaymentSend."Invoice Date" := TempPaymentRegistrationBuffer."Posting Date";
        TaskPaymentSend."Invoice No." := TempPaymentRegistrationBuffer."Document No.";
        TaskPaymentSend."Payment Date" := GenJournalLine."Posting Date";
        TaskPaymentSend."Payment No." := GenJournalLine."Document No.";
        TaskPaymentSend."Payment Amount" := TempPaymentRegistrationBuffer."Amount Received";
        TaskPaymentSend.Insert(true);
    end;

}