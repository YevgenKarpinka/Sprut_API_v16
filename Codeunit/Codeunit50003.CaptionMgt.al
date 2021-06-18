codeunit 50003 "Caption Mgt."
{

    trigger OnRun()
    var
        myInt: Integer;
    begin

    end;

    var
        blankGuid: Guid;
        descriptionSalesHeader: TextConst ENU = '%1, %2',
                                            RUS = '%1, %2';
        errorSalesHeader: TextConst ENU = 'Posting Date %1, Due Date %2, Amount Incl. VAT %3, CRM No. %4, CRM ID %5',
                                            RUS = 'Дата учета %1, Срок выполнения %2, Сумма с НДС %3, Номер CRM %4, CRM ID %5';

    procedure SaveStreamToFile(_streamText: Text;
        ToFileName: Variant)
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

    procedure OpenSalesOrder()
    var
        CompIntegr: Record "Company Integration";
        SalesHeader: Record "Sales Header";
    begin
        ClearActivityEntries(Database::"Sales Header");

        if CompIntegr.FindSet() then
            repeat
                if CompIntegr."Copy Items From" or CompIntegr."Copy Items To" then begin
                    // if CompanyName <> CompIntegr."Company Name" then
                    SalesHeader.ChangeCompany(CompIntegr."Company Name");
                    SalesHeader.SetCurrentKey(Status, "CRM Header ID");
                    SalesHeader.SetRange(Status, SalesHeader.Status::Open);
                    SalesHeader.SetFilter("CRM Header ID", '<>%1', blankGuid);
                    if SalesHeader.FindSet() then
                        repeat
                            UpdateActivityEntries(CompIntegr."Company Name", Database::"Sales Header",
                                SalesHeader."No.", GetDescriptionFromSalesHeader(CompIntegr."Company Name", SalesHeader."No."),
                                GetErrorTextFromSalesHeader(CompIntegr."Company Name", SalesHeader."No."),
                                SalesHeader."Last Modified Date Time");
                        until SalesHeader.Next() = 0;
                end;
            until CompIntegr.Next() = 0;
    end;

    local procedure GetDescriptionFromSalesHeader(_CompanyName: Text[30]; SalesHeaderNo: Code[20]): Text[2048]
    var
        SalesHeader: Record "Sales Header";
    begin
        // if CompanyName <> _CompanyName then
        SalesHeader.ChangeCompany(_CompanyName);

        if SalesHeader.Get(SalesHeader."Document Type"::Order, SalesHeaderNo) then
            exit(StrSubstNo(descriptionSalesHeader, SalesHeader."Sell-to Customer No.", SalesHeader."Sell-to Customer Name"));

        exit('');
    end;

    local procedure GetErrorTextFromSalesHeader(_CompanyName: Text[30]; SalesHeaderNo: Code[20]): Text[2048]
    var
        SalesHeader: Record "Sales Header";
    begin
        // if CompanyName <> _CompanyName then
        SalesHeader.ChangeCompany(_CompanyName);

        if SalesHeader.Get(SalesHeader."Document Type"::Order, SalesHeaderNo) then begin
            SalesHeader.CalcFields("Amount Including VAT");
            exit(StrSubstNo(errorSalesHeader, SalesHeader."Posting Date", SalesHeader."Due Date",
                    SalesHeader."Amount Including VAT", SalesHeader."External Document No.", SalesHeader."CRM Header ID"));
        end;

        exit('');
    end;
}