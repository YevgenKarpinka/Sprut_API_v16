codeunit 50013 "Task Deduplicate Customers"
{
    trigger OnRun()
    begin
        if RecordForExecuteIsExist() then
            Execute();
    end;

    var
        PDFToEmail: Codeunit "Email Invoice As PDF Method";
        blankGuid: Guid;

    local procedure Execute()
    begin
        PDFToEmail.DeeduplicateNotificationToAccounter();
    end;

    local procedure RecordForExecuteIsExist(): Boolean
    var
        Cust: Record Customer;
    begin
        Cust.SetCurrentKey("Deduplicate Id");
        Cust.SetFilter("Deduplicate Id", '<>%1', blankGuid);
        exit(not Cust.IsEmpty);
    end;
}