codeunit 50012 "Task Payment To CRM"
{
    trigger OnRun()
    begin
        // if GetFirstRecordForExecute() then
        //     Execute();
        GetRecordForExecute();
    end;

    var
        recTaskPaymentSend: Record "Task Payment Send";
        PDFToEmail: Codeunit "Email Invoice As PDF Method";
        PaymentMgt: Codeunit "Payment Management";

    local procedure Execute()
    begin
        case recTaskPaymentSend.Status of
            recTaskPaymentSend.Status::OnPaymentSend:
                begin
                    if recTaskPaymentSend."Work Status" = recTaskPaymentSend."Work Status"::WaitingForWork then begin

                        UpdateWorkStatus(recTaskPaymentSend."Work Status"::InWork);

                        if not PaymentMgt.OnProcessPaymentSendToCRM(recTaskPaymentSend."Entry Type", recTaskPaymentSend."Invoice Entry No.",
                                                        recTaskPaymentSend."Payment Entry No.", recTaskPaymentSend."Payment Amount") then begin
                            if recTaskPaymentSend."Attempts Send" >= GetJobQueueMaxAttempts then begin
                                UpdateWorkStatus(recTaskPaymentSend."Work Status"::Error)
                            end else begin
                                IncTaskModifyOrderAttempt();
                                UpdateWorkStatus(recTaskPaymentSend."Work Status"::WaitingForWork);
                            end;
                            exit;
                        end;

                        // modify task statuses to next level
                        ModifyTaskStatusToNextLevel(recTaskPaymentSend.Status::Done);
                        exit;
                    end;

                    if recTaskPaymentSend."Work Status" = recTaskPaymentSend."Work Status"::Error then begin
                        UpdateWorkStatus(recTaskPaymentSend."Work Status"::InWork);

                        if not PDFToEmail.ErrorTasksPaymentSendToAdministrator() then begin
                            UpdateWorkStatus(recTaskPaymentSend."Work Status"::Error);
                            IncTaskModifyOrderAttempt();
                            exit;
                        end;

                        // modify task status to next level
                        ModifyTaskStatusToNextLevel(recTaskPaymentSend.Status::Error);
                        UpdateWorkStatus(recTaskPaymentSend."Work Status"::Done);
                    end;
                end;
        end;
    end;

    local procedure ModifyTaskStatusToNextLevel(NextTaskStatus: Enum TaskPaymentStatus)
    var
        locTaskPaymentSend: Record "Task Payment Send";
    begin
        locTaskPaymentSend.SetRange("Entry Type", recTaskPaymentSend."Entry Type");
        locTaskPaymentSend.SetRange("Invoice Entry No.", recTaskPaymentSend."Invoice Entry No.");
        locTaskPaymentSend.SetRange("Payment Entry No.", recTaskPaymentSend."Payment Entry No.");
        locTaskPaymentSend.SetRange("Payment Amount", recTaskPaymentSend."Payment Amount");
        locTaskPaymentSend.FindFirst();
        locTaskPaymentSend.Status := NextTaskStatus;
        if NextTaskStatus = NextTaskStatus::Done then
            locTaskPaymentSend."Work Status" := locTaskPaymentSend."Work Status"::Done
        else
            locTaskPaymentSend."Work Status" := locTaskPaymentSend."Work Status"::WaitingForWork;
        ResetTaskModifyOrderAttempt(locTaskPaymentSend);
        locTaskPaymentSend.Modify(true);
        Commit();
    end;

    local procedure UpdateWorkStatus(newWorkStatus: Enum WorkStatus)
    begin
        // recTaskPaymentSend.LockTable();
        recTaskPaymentSend.Validate("Work Status", newWorkStatus);
        recTaskPaymentSend.Modify(true);
        Commit();
    end;

    local procedure GetFirstRecordForExecute(): Boolean
    begin
        recTaskPaymentSend.Reset();
        recTaskPaymentSend.SetCurrentKey(Status, "Work Status", "Create Date Time");
        recTaskPaymentSend.SetFilter(Status, '%1', recTaskPaymentSend.Status::OnPaymentSend);
        recTaskPaymentSend.SetFilter("Work Status", '%1|%2', recTaskPaymentSend."Work Status"::WaitingForWork,
                                                             recTaskPaymentSend."Work Status"::Error);
        exit(recTaskPaymentSend.FindFirst());
    end;

    local procedure GetRecordForExecute()
    begin
        recTaskPaymentSend.Reset();
        recTaskPaymentSend.SetCurrentKey(Status, "Work Status");
        recTaskPaymentSend.SetFilter(Status, '%1', recTaskPaymentSend.Status::OnPaymentSend);
        recTaskPaymentSend.SetFilter("Work Status", '%1|%2', recTaskPaymentSend."Work Status"::WaitingForWork,
                                                             recTaskPaymentSend."Work Status"::Error);
        if recTaskPaymentSend.FindSet(true) then
            repeat
                repeat
                    Execute();
                until recTaskPaymentSend.Next() = 0;
            until not recTaskPaymentSend.FindSet(true);
    end;

    local procedure GetJobQueueMaxAttempts(): Integer
    var
        locJobQueueEntry: Record "Job Queue Entry";
    begin
        locJobQueueEntry.SetCurrentKey("Object Type to Run", "Object ID to Run");
        locJobQueueEntry.SetRange("Object Type to Run", locJobQueueEntry."Object Type to Run"::Codeunit);
        locJobQueueEntry.SetRange("Object ID to Run", Codeunit::"Task Payment To CRM");
        if locJobQueueEntry.FindFirst() then
            exit(locJobQueueEntry."Maximum No. of Attempts to Run");
    end;

    local procedure IncTaskModifyOrderAttempt()
    begin
        recTaskPaymentSend.Validate("Attempts Send", recTaskPaymentSend."Attempts Send" + 1);
        recTaskPaymentSend.Modify(true);
        Commit();
    end;

    local procedure ResetTaskModifyOrderAttempt(var TaskPaymentSend: Record "Task Payment Send")
    begin
        if TaskPaymentSend."Attempts Send" = 0 then exit;
        TaskPaymentSend."Attempts Send" := 0;
    end;
}