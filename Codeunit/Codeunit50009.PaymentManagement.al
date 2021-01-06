codeunit 50009 "Payment Management"
{
    trigger OnRun()
    begin

    end;

    var
        WebServiceMgt: Codeunit "Web Service Mgt.";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Payment Registration Mgt.", 'OnBeforeGenJnlLineInsert', '', false, false)]
    local procedure UpdateAgreementNo(var GenJournalLine: Record "Gen. Journal Line"; TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary)
    begin
        GenJournalLine."Agreement No." := TempPaymentRegistrationBuffer."Agreement No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Payment Registration Mgt.", 'OnBeforeGenJnlLineInsert', '', false, false)]
    local procedure OnBeforeGenJournalLineInsert(TempPaymentRegistrationBuffer: Record "Payment Registration Buffer"; var GenJournalLine: Record "Gen. Journal Line")
    var
        TaskPaymentSend: Record "Task Payment Send";
    begin
        TaskPaymentSend.Init();
        TaskPaymentSend."Invoice Entry No." := TempPaymentRegistrationBuffer."Ledger Entry No.";
        TaskPaymentSend."Invoice No." := TempPaymentRegistrationBuffer."Document No.";
        // 
        TaskPaymentSend."Payment No." := GenJournalLine."Document No.";
        TaskPaymentSend."Payment Amount" := TempPaymentRegistrationBuffer."Remaining Amount";
        TaskPaymentSend.Insert(true);
    end;



    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Payment Registration Mgt.", 'OnAfterPostPaymentRegistration', '', false, false)]
    local procedure OnAfterPostPaymentRegistration(TempPaymentRegistrationBuffer: Record "Payment Registration Buffer")
    var
        TaskPaymentSend: Record "Task Payment Send";
    begin
        TaskPaymentSend.SetCurrentKey(Status, "Work Status", "Invoice Entry No.", "Invoice No.", "Payment No.", "Payment Amount");
        TaskPaymentSend.SetRange("Invoice Entry No.", TempPaymentRegistrationBuffer."Ledger Entry No.");
        TaskPaymentSend.SetRange("Invoice No.", TempPaymentRegistrationBuffer."Document No.");
        TaskPaymentSend.SetRange("Payment Amount", TempPaymentRegistrationBuffer."Amount Received");
        // to do
        TaskPaymentSend."Payment Entry No." := 0;
        TaskPaymentSend.Modify(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CustEntry-Apply Posted Entries", 'OnBeforePostApplyCustLedgEntry', '', false, false)]
    local procedure OnBeforePostApplyCustLedgEntry(CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        if CustLedgerEntry."Document Type" <> CustLedgerEntry."Document Type"::Invoice then exit;
        InsertTaskPaymentSend(CustLedgerEntry."Entry No.", CustLedgerEntry."Document No.", CustLedgerEntry."Customer No.", CustLedgerEntry."Applies-to ID");
    end;

    local procedure InsertTaskPaymentSend(InvoiceEntryNo: Integer; InvoiceNo: Code[20]; CustomerNo: Code[20]; AppliesToID: Code[50])
    var
        locCLE: Record "Cust. Ledger Entry";
        TaskPaymentSend: Record "Task Payment Send";
    begin
        locCLE.SetCurrentKey("Customer No.", "Applies-to ID", "Document Type");
        locCLE.SetRange("Customer No.", CustomerNo);
        locCLE.SetRange("Applies-to ID", AppliestoID);
        locCLE.SetRange("Document Type", locCLE."Document Type"::Payment);
        if locCLE.FindSet(false, false) then
            repeat
                TaskPaymentSend.Init();
                TaskPaymentSend."Invoice Entry No." := InvoiceEntryNo;
                TaskPaymentSend."Invoice No." := InvoiceNo;
                TaskPaymentSend."Payment Entry No." := locCLE."Entry No.";
                TaskPaymentSend."Payment No." := locCLE."Document No.";
                TaskPaymentSend."Payment Amount" := Abs(locCLE."Amount to Apply");
                TaskPaymentSend.Insert(true);
            until locCLE.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, 226, 'OnAfterPostUnapplyCustLedgEntry', '', false, false)]
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

}