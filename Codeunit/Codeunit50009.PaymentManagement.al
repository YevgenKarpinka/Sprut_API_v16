codeunit 50009 "Payment Management"
{
    trigger OnRun()
    begin

    end;

    var
        WebServiceMgt: Codeunit "Web Service Mgt.";
        OnUnApplyFlag: Boolean;
        UnApplyInvoiceEntryNo: Integer;
        UnApplyPaymentEntryNo: Integer;
        UnApplyPaymentAmount: Decimal;
        GLSetup: Record "General Ledger Setup";


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Payment Registration Mgt.", 'OnBeforeGenJnlLineInsert', '', false, false)]
    local procedure OnBeforeGenJnlLineInsert(var GenJournalLine: Record "Gen. Journal Line"; TempPaymentRegistrationBuffer: Record "Payment Registration Buffer")
    begin
        GenJournalLine."Agreement No." := TempPaymentRegistrationBuffer."Agreement No.";
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnBeforePostDtldCVLedgEntry', '', false, false)]
    local procedure OnBeforePostDtldCVLedgEntry(var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; Unapply: Boolean)
    begin
        if Unapply then exit;
        if DetailedCVLedgEntryBuffer."CV Ledger Entry No." = DetailedCVLedgEntryBuffer."Applied CV Ledger Entry No." then exit;

        if not (CheckUnAppliedEntryPaymentOrInvoice(DetailedCVLedgEntryBuffer."CV Ledger Entry No.")
        and CheckUnAppliedEntryPaymentOrInvoice(DetailedCVLedgEntryBuffer."Applied CV Ledger Entry No.")) then
            exit;

        if not (isInvoiceFromCRM(DetailedCVLedgEntryBuffer."CV Ledger Entry No.")
        and isInvoiceFromCRM(DetailedCVLedgEntryBuffer."Applied CV Ledger Entry No.")) then
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

        if not (isInvoiceFromCRM(OldDtldCustLedgEntry."Cust. Ledger Entry No.")
                and isInvoiceFromCRM(OldDtldCustLedgEntry."Applied Cust. Ledger Entry No.")) then
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

    local procedure isInvoiceFromCRM(EntryNo: Integer): Boolean
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if CustLedgEntry.Get(EntryNo)
        and (CustLedgEntry."Document Type" in [CustLedgEntry."Document Type"::Invoice]) then begin
            if SalesInvoiceHeader.Get(CustLedgEntry."Document No.")
            and not IsNullGuid(SalesInvoiceHeader."CRM ID") then
                exit(true);
        end else
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
        if IsNullGuid(GetAgreementIdByDocumentNo(InvoiceEntryNo)) then exit;

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
        if IsNullGuid(GetAgreementIdByDocumentNo(InvoiceEntryNo)) then exit;

        TaskPaymentSend.SetRange("Entry Type", TaskPaymentSend."Entry Type"::UnApply);
        TaskPaymentSend.SetRange("Invoice Entry No.", InvoiceEntryNo);
        TaskPaymentSend.SetRange("Payment Entry No.", PaymentEntryNo);
        TaskPaymentSend.SetRange("Payment Amount", PaymentAmount);
        if TaskPaymentSend.FindFirst() then begin
            TaskPaymentSend.Status := TaskPaymentSend.Status::OnPaymentSend;
            TaskPaymentSend."Work Status" := TaskPaymentSend."Work Status"::WaitingForWork;
            TaskPaymentSend."CRM Payment Id" := GetCRMPaymentId(InvoiceEntryNo, PaymentEntryNo, PaymentAmount);
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
            TaskPaymentSend."CRM Payment Id" := GetCRMPaymentId(InvoiceEntryNo, PaymentEntryNo, PaymentAmount);
            TaskPaymentSend.Insert(true);
        end;
    end;

    local procedure GetCRMPaymentId(InvoiceEntryNo: Integer; PaymentEntryNo: Integer; PaymentAmount: Decimal): Guid
    var
        TaskPaymentSend: Record "Task Payment Send";
    begin
        TaskPaymentSend.SetRange("Entry Type", TaskPaymentSend."Entry Type"::Apply);
        TaskPaymentSend.SetRange("Invoice Entry No.", InvoiceEntryNo);
        TaskPaymentSend.SetRange("Payment Entry No.", PaymentEntryNo);
        TaskPaymentSend.SetRange("Payment Amount", PaymentAmount);
        if TaskPaymentSend.FindLast() then;
        exit(TaskPaymentSend."CRM Payment Id");
    end;

    procedure OnProcessPaymentSendToCRM(EntryType: Enum EntryType; InvoiceEntryNo: Integer; PaymentEntryNo: Integer; PaymentAmount: Decimal): Boolean
    var
        recTaskPaymentSend: Record "Task Payment Send";
    begin
        recTaskPaymentSend.SetRange("Entry Type", EntryType);
        recTaskPaymentSend.SetRange("Invoice Entry No.", InvoiceEntryNo);
        recTaskPaymentSend.SetRange("Payment Entry No.", PaymentEntryNo);
        if not recTaskPaymentSend.FindFirst() then
            exit(false);

        case recTaskPaymentSend."Entry Type" of
            recTaskPaymentSend."Entry Type"::Apply:
                begin
                    exit(OnProcessApplyPaymentSendToCRM(recTaskPaymentSend));
                end;
            recTaskPaymentSend."Entry Type"::UnApply:
                begin
                    exit(OnProcessUnApplyPaymentSendToCRM(recTaskPaymentSend));
                end;
            else
                exit(false);
        end;

        exit(true);
    end;

    local procedure OnProcessApplyPaymentSendToCRM(recTaskPaymentSend: Record "Task Payment Send"): Boolean
    begin
        exit(SendPaymentToApplyPost(recTaskPaymentSend."CRM Payment Id", recTaskPaymentSend."Invoice Entry No.", recTaskPaymentSend."Payment Entry No.", recTaskPaymentSend."Payment Amount"));
    end;

    local procedure OnProcessUnApplyPaymentSendToCRM(recTaskPaymentSend: Record "Task Payment Send"): Boolean
    begin
        if IsNullGuid(recTaskPaymentSend."CRM Payment Id") then exit(false);
        exit(SendPaymentToUnApplyPatch(recTaskPaymentSend."CRM Payment Id"));
    end;

    local procedure SendPaymentToUnApplyPatch(CRMPaymentId: Text): Boolean
    var
        _jsonPayment: JsonObject;
        _jsonText: Text;
        entityType: Label 'tct_payments';
        PATCHrequestMethod: Label 'PATCH';
        TokenType: Text;
        AccessToken: Text;
        APIResult: Text;
        requestMethod: Text[20];
        entityTypeValue: Text;
    begin
        if not WebServiceMgt.GetOauthToken(TokenType, AccessToken, APIResult) then
            exit(false);

        // Create JSON for CRM
        if IsNullGuid(CRMPaymentId) then begin
            exit(false);
        end else begin
            requestMethod := PATCHrequestMethod;
            entityTypeValue := StrSubstNo('%1(%2)', entityType, LowerCase(DelChr(CRMPaymentId, '<>', '{}')));
            _jsonPayment := WebServiceMgt.jsonUnApplyPaymentToPatch();
        end;

        _jsonPayment.WriteTo(_jsonText);
        // try send to CRM
        exit(WebServiceMgt.CreatePaymentInCRM(entityTypeValue, requestMethod, TokenType, AccessToken, _jsonText));
    end;

    local procedure SendPaymentToApplyPost(CRMPaymentId: Text; InvoiceEntryNo: Integer; PaymentEntryNo: Integer; PaymentAmount: Decimal): Boolean
    var
        _jsonPayment: JsonObject;
        _jsonText: Text;
        connectorCode: Label 'CRM';
        entityType: Label 'tct_payments';
        POSTrequestMethod: Label 'POST';
        PATCHrequestMethod: Label 'PATCH';
        TokenType: Text;
        AccessToken: Text;
        APIResult: Text;
        requestMethod: Text[20];
        entityTypeValue: Text;
        payerDetails: Text[100];
        custAgreementId: Guid;
        crmId: Guid;
    begin
        custAgreementId := GetAgreementIdByDocumentNo(InvoiceEntryNo);
        // if IsNullGuid(custAgreementId) then exit(false);
        crmId := GetCRMInvoiceIdByDocumentNo(InvoiceEntryNo);
        // if IsNullGuid(crmId) then exit(false);
        payerDetails := '';

        if not WebServiceMgt.GetOauthToken(TokenType, AccessToken, APIResult) then
            exit(false);

        // Create JSON for CRM
        if IsNullGuid(CRMPaymentId) then begin
            requestMethod := POSTrequestMethod;
            entityTypeValue := entityType;
            _jsonPayment := WebServiceMgt.jsonPaymentToPost(custAgreementId, crmId, payerDetails, paymentAmount);
        end else begin
            requestMethod := PATCHrequestMethod;
            entityTypeValue := StrSubstNo('%1(%2)', entityType, LowerCase(DelChr(CRMPaymentId, '<>', '{}')));
            _jsonPayment := WebServiceMgt.jsonApplyPaymentToPatch();
        end;

        _jsonPayment.WriteTo(_jsonText);
        // try send to CRM
        if not WebServiceMgt.CreatePaymentInCRM(entityTypeValue, requestMethod, TokenType, AccessToken, _jsonText) then
            exit(false)
        else
            // add CRM product ID to Item
            exit(WebServiceMgt.AddCRMpaymentIdToPayment(_jsonText, InvoiceEntryNo, PaymentEntryNo, PaymentAmount));
    end;

    local procedure GetAgreementIdByDocumentNo(InvoiceEntryNo: Integer): Guid
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        SalesInvHeader: Record "Sales Invoice Header";
        CustAgreement: Record "Customer Agreement";
    begin
        if CustLedgEntry.Get(InvoiceEntryNo)
        and SalesInvHeader.Get(CustLedgEntry."Document No.")
        and CustAgreement.Get(SalesInvHeader."Sell-to Customer No.", SalesInvHeader."Agreement No.")
        and not CustAgreement."Init 1C" then
            exit(CustAgreement."CRM ID");
    end;

    local procedure GetCRMInvoiceIdByDocumentNo(InvoiceEntryNo: Integer): Guid
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        SalesInvHeader: Record "Sales Invoice Header";
        CustAgreement: Record "Customer Agreement";
    begin
        if CustLedgEntry.Get(InvoiceEntryNo) and SalesInvHeader.Get(CustLedgEntry."Document No.") then;
        exit(SalesInvHeader."CRM ID");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnApplyCustLedgEntryOnBeforePrepareTempCustLedgEntry', '', false, false)]
    local procedure CustApply(var NewCVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    begin
        GetGLSetup();
        if GLSetup."Enable Russian Accounting" and GLSetup."Disable Check Cust. Prep."
        and NewCVLedgerEntryBuffer.Prepayment then
            NewCVLedgerEntryBuffer.Prepayment := false;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnPrepareTempVendLedgEntryOnBeforeExit', '', false, false)]
    local procedure VendApply(var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    begin
        GetGLSetup();
        if GLSetup."Enable Russian Accounting" and GLSetup."Disable Check Vend. Prep."
        and CVLedgerEntryBuffer.Prepayment then
            CVLedgerEntryBuffer.Prepayment := false;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnBeforePostApply', '', false, false)]
    local procedure PostApply(GenJnlLine: Record "Gen. Journal Line"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var NewCVLedgEntryBuf2: Record "CV Ledger Entry Buffer")
    begin
        GetGLSetup();
        if GLSetup."Enable Russian Accounting" then
            case GenJnlLine."Account Type" of
                GenJnlLine."Account Type"::Customer:
                    begin
                        if GLSetup."Disable Check Cust. Prep."
                                and (NewCVLedgEntryBuf.Prepayment <> NewCVLedgEntryBuf2.Prepayment) then
                            NewCVLedgEntryBuf.Prepayment := NewCVLedgEntryBuf2.Prepayment;
                    end;
                GenJnlLine."Account Type"::Vendor:
                    begin
                        if GLSetup."Disable Check Vend. Prep."
                                and (NewCVLedgEntryBuf.Prepayment <> NewCVLedgEntryBuf2.Prepayment) then
                            NewCVLedgEntryBuf.Prepayment := NewCVLedgEntryBuf2.Prepayment;
                    end;
            end;
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetup.Get() then begin
            GLSetup.Init;
            GLSetup.Insert();
        end;
    end;

    [EventSubscriber(ObjectType::Table, 81, 'OnBeforeCheckIfPostingDateIsEarlier', '', false, false)]
    local procedure OnBeforeCheckIfPostingDateIsEarlier(var IsHandled: Boolean)
    begin
        GetGLSetup();
        if GLSetup."Disable Check Cust. Prep." then
            IsHandled := true;
    end;
}