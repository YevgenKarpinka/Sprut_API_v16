codeunit 50019 "Delete Entries From Logs"
{
    trigger OnRun()
    begin
        Execute();
    end;

    local procedure Execute()
    begin
        taskModifyOrder.DeleteEntries(7);
        taskPaymentSend.DeleteEntries(7);
        integrationLog.DeleteEntries(7);
    end;

    var
        taskModifyOrder: Record "Task Modify Order";
        taskPaymentSend: Record "Task Payment Send";
        integrationLog: Record "Integration Log";
}