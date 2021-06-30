codeunit 50019 "Delete Entries From Logs"
{
    trigger OnRun()
    begin
        Execute();
    end;

    var
        taskModifyOrder: Record "Task Modify Order";
        taskPaymentSend: Record "Task Payment Send";
        integrationLog: Record "Integration Log";
        jobQueueLogEntry: Record "Job Queue Log Entry";

    local procedure Execute()
    begin
        taskModifyOrder.DeleteEntries(7);
        taskPaymentSend.DeleteEntries(7);
        integrationLog.DeleteEntries(31);
        jobQueueLogEntry.DeleteEntries(7);
    end;

    [EventSubscriber(ObjectType::Table, 474, 'OnBeforeDeleteEntries', '', false, false)]
    local procedure OnBeforeDeleteEntries(var SkipConfirm: Boolean)
    begin
        SkipConfirm := true;
    end;

}