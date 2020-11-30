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
        SpecificationResponseText: Text;
        InvoicesResponseText: Text;
        SpecEntityType: Label 'specification';
        InvEntityType: Label 'invoice';
        POSTrequestMethod: Label 'POST';

    local procedure Execute()
    var
        SalesHeader: Record "Sales Header";
    begin
        case recTaskModifyOrder.Status of
            recTaskModifyOrder.Status::OnModifyOrder:
                begin
                    UpdateWorkStatus(recTaskModifyOrder."Work Status"::InWork);

                    // analyze need full update sales order or not
                    if WebServicesMgt.NeedFullUpdateSalesOrder(recTaskModifyOrder."Order No.") then begin

                        // unapply prepayments
                        PrepmMgt.UnApplyPayments(recTaskModifyOrder."Order No.");
                        // Open Sales Order
                        OpenSalesOrder(SalesHeader, recTaskModifyOrder."Order No.");
                        // create credit memo for prepayment invoice
                        if SalesPostPrepm.CheckOpenPrepaymentLines(SalesHeader, 1) then
                            SalesPostPrepm.PostPrepaymentCreditMemoSprut(SalesHeader);
                        // Get Specification From CRM
                        WebServicesMgt.GetSpecificationFromCRM(recTaskModifyOrder."Order No.", SpecEntityType, POSTrequestMethod, SpecificationResponseText);
                        // Open Sales Order
                        OpenSalesOrder(SalesHeader, recTaskModifyOrder."Order No.");
                        // delete all sales lines
                        PrepmMgt.OnDeleteSalesOrderLine(recTaskModifyOrder."Order No.");
                        // insert sales line
                        PrepmMgt.InsertSalesLineFromCRM(recTaskModifyOrder."Order No.", SpecificationResponseText);
                        // Get Invoices From CRM
                        WebServicesMgt.GetInvoicesFromCRM(recTaskModifyOrder."Order No.", InvEntityType, POSTrequestMethod, InvoicesResponseText);
                        // create prepayment invoice by amount
                        PrepmMgt.CreatePrepaymentInvoicesFromCRM(recTaskModifyOrder."Order No.", InvoicesResponseText);

                    end;

                    // modify task statuses to next level
                    ModifyTaskStatusToNextLevel(recTaskModifyOrder.Status::OnSendToCRM);
                    UpdateWorkStatus(recTaskModifyOrder."Work Status"::WaitingForWork);
                end;

            recTaskModifyOrder.Status::OnSendToCRM:
                begin
                    UpdateWorkStatus(recTaskModifyOrder."Work Status"::InWork);

                    // modify task status to next level
                    ModifyTaskStatusToNextLevel(recTaskModifyOrder.Status::OnSendToEmail);
                    UpdateWorkStatus(recTaskModifyOrder."Work Status"::WaitingForWork);
                end;
            recTaskModifyOrder.Status::OnSendToEmail:
                begin
                    UpdateWorkStatus(recTaskModifyOrder."Work Status"::InWork);

                    // https://robertostefanettinavblog.com/2020/06/15/business-central-send-email-with-multi-attachments/
                    // https://yzhums.com/1799/


                    // modify task status to next level
                    ModifyTaskStatusToNextLevel(recTaskModifyOrder.Status::Done);
                end;

            else
        end;
    end;

    local procedure ModifyTaskStatusToNextLevel(NextTaskStatus: Enum TaskStatus)
    begin
        recTaskModifyOrder.Status := NextTaskStatus;
        if NextTaskStatus = NextTaskStatus::Done then
            recTaskModifyOrder."Work Status" := recTaskModifyOrder."Work Status"::Done;
        recTaskModifyOrder.Modify(true);
    end;

    local procedure OpenSalesOrder(var SalesHeader:
                                           Record "Sales Header";
    SalesOrderNo:
        Code[20])
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
        recTaskModifyOrder.Init();
        recTaskModifyOrder."Order No." := SalesOrderNo;
        recTaskModifyOrder.Insert(true);
    end;
}