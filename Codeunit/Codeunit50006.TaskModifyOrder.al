codeunit 50006 "Task Modify Order"
{
    trigger OnRun()
    begin
        if GetFirstRecordForExecute() then
            Execute();
    end;

    var
        ModificationOrder: Codeunit "Modification Order";
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
        errTaskForModificationOrderNoAlreadyInWork: Label 'task for modification order no. %1 already in work';

    local procedure Execute()
    var
        SalesHeader: Record "Sales Header";
    begin
        case recTaskModifyOrder.Status of
            recTaskModifyOrder.Status::OnModifyOrder:
                begin
                    UpdateWorkStatus(recTaskModifyOrder."Work Status"::InWork);

                    // OnModifyOrder(recTaskModifyOrder."Order No.");

                    SalesHeader.Get(SalesHeader."Document Type"::Order, recTaskModifyOrder."Order No.");
                    if not Codeunit.Run(Codeunit::"Modification Order", SalesHeader) then begin
                        if recTaskModifyOrder."Attempts Send" > GetJobQueueMaxAttempts then
                            UpdateWorkStatus(recTaskModifyOrder."Work Status"::Error)
                        else
                            IncTaskModifyOrderAttempt;
                        exit;
                    end;

                    // modify task statuses to next level
                    ModifyTaskStatusToNextLevel(recTaskModifyOrder.Status::OnSendToCRM);
                    // UpdateWorkStatus(recTaskModifyOrder."Work Status"::WaitingForWork);
                end;

            recTaskModifyOrder.Status::OnSendToCRM:
                begin
                    UpdateWorkStatus(recTaskModifyOrder."Work Status"::InWork);

                    if not WebServicesMgt.SetInvoicesLineIdToCRM(recTaskModifyOrder."Order No.", BCIdEntityType, POSTrequestMethod, BCIdResponseText) then begin
                        if recTaskModifyOrder."Attempts Send" > GetJobQueueMaxAttempts then
                            UpdateWorkStatus(recTaskModifyOrder."Work Status"::Error)
                        else
                            IncTaskModifyOrderAttempt;
                        exit;
                    end;

                    // modify task status to next level
                    ModifyTaskStatusToNextLevel(recTaskModifyOrder.Status::OnSendToEmail);
                    // UpdateWorkStatus(recTaskModifyOrder."Work Status"::WaitingForWork);
                end;
            recTaskModifyOrder.Status::OnSendToEmail:
                begin
                    UpdateWorkStatus(recTaskModifyOrder."Work Status"::InWork);

                    if not PDFToEmail.UnApplyDocToAccounter(recTaskModifyOrder."Order No.") then begin
                        if recTaskModifyOrder."Attempts Send" > GetJobQueueMaxAttempts then
                            UpdateWorkStatus(recTaskModifyOrder."Work Status"::Error)
                        else
                            IncTaskModifyOrderAttempt;
                        exit;
                    end;

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
            recTaskModifyOrder."Work Status" := recTaskModifyOrder."Work Status"::Done
        else
            recTaskModifyOrder."Work Status" := recTaskModifyOrder."Work Status"::WaitingForWork;

        ResetTaskModifyOrderAttempt();

        recTaskModifyOrder.Modify(true);
        Commit();
    end;

    local procedure UpdateWorkStatus(newWorkStatus: Enum WorkStatus)
    begin
        recTaskModifyOrder.LockTable();
        recTaskModifyOrder.Validate("Work Status", newWorkStatus);
        recTaskModifyOrder.Modify(true);
        Commit();
    end;

    local procedure GetFirstRecordForExecute(): Boolean
    begin
        recTaskModifyOrder.Reset();
        recTaskModifyOrder.SetCurrentKey(Status, "Work Status");
        recTaskModifyOrder.SetFilter(Status, '<>%1', recTaskModifyOrder.Status::Done);
        recTaskModifyOrder.SetRange("Work Status", recTaskModifyOrder."Work Status"::WaitingForWork);
        exit(recTaskModifyOrder.FindFirst());
    end;

    procedure CreateTaskModifyOrder(SalesOrderNo: Code[20])
    begin
        recTaskModifyOrder.Reset();
        recTaskModifyOrder.SetCurrentKey(Status, "Work Status", "Order No.");
        recTaskModifyOrder.SetRange("Order No.", SalesOrderNo);
        recTaskModifyOrder.SetFilter(Status, '<>%1', recTaskModifyOrder.Status::Done);
        if recTaskModifyOrder.FindFirst() then begin
            if recTaskModifyOrder."Work Status" = recTaskModifyOrder."Work Status"::InWork then
                Error(errTaskForModificationOrderNoAlreadyInWork, SalesOrderNo);
            recTaskModifyOrder.Status := recTaskModifyOrder.Status::OnModifyOrder;
            recTaskModifyOrder.Modify(true);
            exit;
        end;

        recTaskModifyOrder.Init();
        recTaskModifyOrder."Order No." := SalesOrderNo;
        recTaskModifyOrder.Insert(true);
    end;

    local procedure GetJobQueueMaxAttempts(): Integer
    var
        locJobQueueEntry: Record "Job Queue Entry";
    begin
        locJobQueueEntry.SetCurrentKey("Object Type to Run", "Object ID to Run");
        locJobQueueEntry.SetRange("Object Type to Run", locJobQueueEntry."Object Type to Run"::Codeunit);
        locJobQueueEntry.SetRange("Object ID to Run", Codeunit::"Task Modify Order");
        if locJobQueueEntry.FindFirst() then
            exit(locJobQueueEntry."Maximum No. of Attempts to Run");
    end;

    local procedure IncTaskModifyOrderAttempt()
    begin
        recTaskModifyOrder."Attempts Send" += 1;
        recTaskModifyOrder.Modify(true);
        Commit();
    end;

    local procedure ResetTaskModifyOrderAttempt()
    begin
        if recTaskModifyOrder."Attempts Send" = 0 then exit;

        recTaskModifyOrder."Attempts Send" := 0;
    end;
}