codeunit 50011 "Notification Task Error"
{
    trigger OnRun()
    begin
        if GetFirstRecordForExecute() then
            Execute();
    end;

    var
        recTaskModifyOrder: Record "Task Modify Order";
        PDFToEmail: Codeunit "Email Invoice As PDF Method";

    local procedure Execute()
    begin
        case recTaskModifyOrder."Work Status" of
            recTaskModifyOrder."Work Status"::Error:
                begin
                    UpdateWorkStatus(recTaskModifyOrder."Work Status"::InWork);

                    PDFToEmail.ErrorTasksToAdministrator();

                    UpdateWorkStatus(recTaskModifyOrder."Work Status"::Done);
                end;
            else
        end;
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
        recTaskModifyOrder.SetFilter("Work Status", '%1', recTaskModifyOrder."Work Status"::Error);
        exit(recTaskModifyOrder.FindLast());
    end;

}