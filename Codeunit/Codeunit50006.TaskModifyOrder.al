codeunit 50006 "Task Modify Order"
{
    trigger OnRun()
    begin
        if GetFirstRecordForExecute() then
            Execute();
    end;

    var
        recTaskModifyOrder: Record "Task Modify Order";
        WebServicesMgt: Codeunit "Web Service Mgt.";
        PrepmMgt: Codeunit "Prepayment Management";
        SalesPostPrepm: Codeunit "Sales-Post Prepayments Sprut";
        PDFToEmail: Codeunit "Email Invoice As PDF Method";
        SpecificationResponseText: Text;
        InvoicesResponseText: Text;
        BCIdResponseText: Text;
        SpecEntityType: Label 'specification';
        InvEntityType: Label 'invoice';
        BCIdEntityType: Label 'bcid';
        POSTrequestMethod: Label 'POST';
        errTaskForModificationOrderNoAlreadyExist: Label 'task for modification order no. %1 already exist';
        errTaskForModificationOrderNoAlreadyInWork: Label 'task for modification order no. %1 already in work';

    local procedure Execute()
    var
        SalesHeader: Record "Sales Header";
    begin
        case recTaskModifyOrder.Status of
            recTaskModifyOrder.Status::OnModifyOrder:
                begin
                    UpdateWorkStatus(recTaskModifyOrder."Work Status"::InWork);

                    OnModifyOrder(recTaskModifyOrder."Order No.");

                    // modify task statuses to next level
                    ModifyTaskStatusToNextLevel(recTaskModifyOrder.Status::OnSendToCRM);
                    UpdateWorkStatus(recTaskModifyOrder."Work Status"::WaitingForWork);
                end;

            recTaskModifyOrder.Status::OnSendToCRM:
                begin
                    UpdateWorkStatus(recTaskModifyOrder."Work Status"::InWork);

                    WebServicesMgt.SetInvoicesLineIdToCRM(recTaskModifyOrder."Order No.", BCIdEntityType, POSTrequestMethod, BCIdResponseText);

                    // modify task status to next level
                    ModifyTaskStatusToNextLevel(recTaskModifyOrder.Status::OnSendToEmail);
                    UpdateWorkStatus(recTaskModifyOrder."Work Status"::WaitingForWork);
                end;
            recTaskModifyOrder.Status::OnSendToEmail:
                begin
                    UpdateWorkStatus(recTaskModifyOrder."Work Status"::InWork);

                    // WebServicesMgt.SendToEmail(recTaskModifyOrder."Order No.");
                    PDFToEmail.UnApplyDocToAccounter(recTaskModifyOrder."Order No.");
                    // https://community.dynamics.com/business/f/dynamics-365-business-central-forum/383532/smtp-mail-setup-with-mfa-not-working-with-o365
                    // https://robertostefanettinavblog.com/2020/06/15/business-central-send-email-with-multi-attachments/
                    // https://yzhums.com/1799/

                    // modify task status to next level
                    ModifyTaskStatusToNextLevel(recTaskModifyOrder.Status::Done);
                end;

            else
        end;
    end;

    procedure OnModifyOrder(SalesOrderNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        // analyze need full update sales order or not
        if WebServicesMgt.NeedFullUpdateSalesOrder(SalesOrderNo) then begin

            // unapply prepayments
            PrepmMgt.UnApplyPayments(SalesOrderNo);
            // Open Sales Order
            OpenSalesOrder(SalesHeader, SalesOrderNo);
            // create credit memo for prepayment invoice
            if SalesPostPrepm.CheckOpenPrepaymentLines(SalesHeader, 1) then
                SalesPostPrepm.PostPrepaymentCreditMemoSprut(SalesHeader);
            // Get Specification From CRM
            WebServicesMgt.GetSpecificationFromCRM(SalesOrderNo, SpecEntityType, POSTrequestMethod, SpecificationResponseText);
            // Open Sales Order
            OpenSalesOrder(SalesHeader, SalesOrderNo);
            // delete all sales lines
            PrepmMgt.OnDeleteSalesOrderLine(SalesOrderNo);
            // insert sales line
            PrepmMgt.InsertSalesLineFromCRM(SalesOrderNo, SpecificationResponseText);
            // Get Invoices From CRM
            WebServicesMgt.GetInvoicesFromCRM(SalesOrderNo, InvEntityType, POSTrequestMethod, InvoicesResponseText);
            // create prepayment invoice by amount
            PrepmMgt.CreatePrepaymentInvoicesFromCRM(SalesOrderNo, InvoicesResponseText);

        end;
    end;

    local procedure ModifyTaskStatusToNextLevel(NextTaskStatus: Enum TaskStatus)
    begin
        recTaskModifyOrder.Status := NextTaskStatus;
        if NextTaskStatus = NextTaskStatus::Done then
            recTaskModifyOrder."Work Status" := recTaskModifyOrder."Work Status"::Done;
        recTaskModifyOrder.Modify(true);
    end;

    local procedure OpenSalesOrder(var SalesHeader: Record "Sales Header"; SalesOrderNo: Code[20])
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesOrderNo);
        if SalesHeader.Status <> SalesHeader.Status::Open then begin
            SalesHeader.Status := SalesHeader.Status::Open;
            SalesHeader.Modify();
        end;
    end;

    local procedure UpdateWorkStatus(newWorkStatus: Enum WorkStatus)
    begin
        recTaskModifyOrder.LockTable();
        recTaskModifyOrder."Work Status" := newWorkStatus;
        recTaskModifyOrder.Modify();
        Commit();
    end;

    local procedure GetFirstRecordForExecute():
                                Boolean
    begin
        recTaskModifyOrder.SetCurrentKey(Status);
        recTaskModifyOrder.SetFilter(Status, '<>%1', recTaskModifyOrder.Status::Done);
        recTaskModifyOrder.SetRange("Work Status", recTaskModifyOrder."Work Status"::WaitingForWork);
        if recTaskModifyOrder.FindFirst() then
            exit(true);
        exit(false);
    end;

    procedure CreateTaskModifyOrder(SalesOrderNo: Code[20])
    begin
        recTaskModifyOrder.Reset();
        recTaskModifyOrder.SetCurrentKey(Status, "Work Status", "Order No.");
        recTaskModifyOrder.SetFilter(Status, '%1', recTaskModifyOrder.Status::OnModifyOrder);
        recTaskModifyOrder.SetRange("Order No.", SalesOrderNo);
        if not recTaskModifyOrder.IsEmpty then
            Error(errTaskForModificationOrderNoAlreadyExist, SalesOrderNo);

        recTaskModifyOrder.Reset();
        recTaskModifyOrder.SetCurrentKey(Status, "Work Status", "Order No.");
        recTaskModifyOrder.SetFilter("Work Status", '%1', recTaskModifyOrder."Work Status"::InWork);
        recTaskModifyOrder.SetRange("Order No.", SalesOrderNo);
        if not recTaskModifyOrder.IsEmpty then
            Error(errTaskForModificationOrderNoAlreadyInWork, SalesOrderNo);

        recTaskModifyOrder.Init();
        recTaskModifyOrder."Order No." := SalesOrderNo;
        recTaskModifyOrder.Insert(true);
    end;
}