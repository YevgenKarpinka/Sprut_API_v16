codeunit 50003 "Caption Mgt."
{

    procedure SaveStreamToFile(_streamText: Text; ToFileName: Variant)
    var
        tmpTenantMedia: Record "Tenant Media";
        _inStream: inStream;
        _outStream: outStream;
    begin
        tmpTenantMedia.Content.CreateOutStream(_OutStream, TextEncoding::UTF8);
        _outStream.WriteText(_streamText);
        tmpTenantMedia.Content.CreateInStream(_inStream, TextEncoding::UTF8);
        DownloadFromStream(_inStream, 'Export', '', 'All Files (*.*)|*.*', ToFileName);
    end;

    procedure CheckModifyAllowed(): Boolean
    var
        CompIntegr: Record "Company Integration";
    begin
        CompIntegr.SetCurrentKey("Company Name");
        CompIntegr.SetRange("Company Name", CompanyName);
        if CompIntegr.FindFirst() then
            CompIntegr.TestField("Copy Items To", false);

        exit(true);
    end;

    procedure ErrorJobQueueEntries(): Integer
    var
        CompIntegr: Record "Company Integration";
        JobQueueEntry: Record "Job Queue Entry";
        TotalCountErrors: Integer;
    begin
        Clear(TotalCountErrors);
        ClearActivityEntries(Database::"Job Queue Entry");

        if CompIntegr.FindSet() then
            repeat
                if CompIntegr."Copy Items From" or CompIntegr."Copy Items To" then begin
                    if CompanyName <> CompIntegr."Company Name" then
                        JobQueueEntry.ChangeCompany(CompIntegr."Company Name");
                    JobQueueEntry.SetCurrentKey(Status);
                    JobQueueEntry.SetRange(Status, JobQueueEntry.Status::Error);
                    // TotalCountErrors += JobQueueEntry.Count;

                    if JobQueueEntry.FindSet() then
                        repeat
                            UpdateActivityEntries(CompIntegr."Company Name", Database::"Job Queue Entry",
                                Guid2Text(JobQueueEntry.ID), JobQueueEntry.Description, GetLastErrorTextFromJobQueueEntry(CompIntegr."Company Name", JobQueueEntry.ID),
                                JobQueueEntry."Earliest Start Date/Time");
                        until JobQueueEntry.Next() = 0;
                end;
            until CompIntegr.Next() = 0;
        exit(TotalCountErrors);
    end;

    local procedure GetLastErrorTextFromJobQueueEntry(_CompanyName: Text[30]; JobQueueEntryID: Guid): Text[2048]
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        // exit('');
        if CompanyName <> _CompanyName then
            JobQueueLogEntry.ChangeCompany(_CompanyName);

        JobQueueLogEntry.SetCurrentKey(ID);
        JobQueueLogEntry.SetRange(ID, JobQueueEntryID);
        JobQueueLogEntry.SetRange(Status, JobQueueLogEntry.Status::Error);
        if JobQueueLogEntry.FindLast() then
            exit(JobQueueLogEntry."Error Message");
        exit('');
    end;

    procedure ErrorModifyOrderEntries()
    var
        CompIntegr: Record "Company Integration";
        TaskModifyOrder: Record "Task Modify Order";
    begin
        ClearActivityEntries(Database::"Task Modify Order");

        if CompIntegr.FindSet() then
            repeat
                if CompIntegr."Copy Items From" or CompIntegr."Copy Items To" then begin
                    if CompanyName <> CompIntegr."Company Name" then
                        TaskModifyOrder.ChangeCompany(CompIntegr."Company Name");
                    TaskModifyOrder.SetCurrentKey("Work Status");
                    TaskModifyOrder.SetRange("Work Status", TaskModifyOrder."Work Status"::Error);

                    if TaskModifyOrder.FindSet() then
                        repeat
                            UpdateActivityEntries(CompIntegr."Company Name", Database::"Task Modify Order",
                                TaskModifyOrder."Order No.", '', TaskModifyOrder."Error Text", TaskModifyOrder."Modify Date Time");
                        until TaskModifyOrder.Next() = 0;
                end;
            until CompIntegr.Next() = 0;
    end;

    local procedure ClearActivityEntries(TableID: Integer)
    var
        ActivityEntries: Record "Activity Entries";
    begin
        ActivityEntries.SetRange("Table ID", TableID);
        if ActivityEntries.IsEmpty then exit;
        ActivityEntries.DeleteAll();
    end;

    local procedure UpdateActivityEntries(_CompanyName: Text[30]; _TableID: Integer; _No: Text[50];
                                            _Description: Text[250]; _ErrorText: Text[2048]; _LastDateTimeModify: DateTime)
    var
        ActivityEntries: Record "Activity Entries";
    begin
        if ActivityEntries.Get(_CompanyName, _TableID, _No) then exit;

        ActivityEntries.Init();
        ActivityEntries."Company Name" := _CompanyName;
        ActivityEntries."Table ID" := _TableID;
        ActivityEntries."No." := _No;
        ActivityEntries.Description := _Description;
        ActivityEntries."Error Text" := _ErrorText;
        ActivityEntries."Last Modify Date Time" := _LastDateTimeModify;
        ActivityEntries.Insert();
    end;

    procedure Guid2Text(_Guid: Text): Text
    begin
        exit(LowerCase(DelChr(_Guid, '<>', '{}')));
    end;
}