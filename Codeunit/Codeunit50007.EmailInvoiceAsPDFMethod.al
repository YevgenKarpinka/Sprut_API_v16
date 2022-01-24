codeunit 50007 "Email Invoice As PDF Method"
{
    trigger OnRun();
    begin

    end;

    var
        TxtEmailSubject: TextConst RUS = '%1 - Не Примененные Документы - %2', ENU = '%1 - UnApply Documents - %2';
        TxtEmailErrorTasksSubject: TextConst RUS = '%1 - Ошибка(и) в очереди задач модификации заказа!', ENU = '%1 - Error(s) in Tasks Modification Order!';
        TxtAttachmentName: TextConst RUS = 'НеПримененныеДокументы-%1.pdf', ENU = 'UnApplyDocuments-%1.pdf';
        TxtCouldNotSaveReport: TextConst RUS = 'Could not save report, Report Id %1.', ENU = 'Could not save report, Report Id %1.';
        errReportNotSavedToPDF: Label 'Report %1 not saved to PDF';
        msgReportSentToUser: Label 'Report %1 sent to user';
        msgEmailErrorTasksSentToUser: Label 'Email with error tasks sent to user';
        msgEmailDeduplicateNotificationToUser: Label 'Email with neduplicate notification sent to user';
        lblBody: Label 'Не примененные документы для заказа продажи %1';
        lblBodyErrorTasks: Label 'Ошибка(и) очереди задач модификации заказа продажи';
        lblBodyDeduplicateNotification: Label 'Список клиентов требующих дедубликацию:';

    procedure ErrorTasksModifyOrderToAdministrator(): Boolean
    begin
        if SendEmailErrorTasks() then exit;

        if not DoEmailErrorTasks() then
            exit(false);

        if GuiAllowed then
            Message(msgEmailErrorTasksSentToUser, 50006);

        exit(true);
    end;

    procedure ErrorTasksPaymentSendToAdministrator(): Boolean
    begin
        if SendEmailErrorTasks() then exit;

        if not DoEmailErrorTasksPaymentSend() then
            exit(false);

        if GuiAllowed then
            Message(msgEmailErrorTasksSentToUser, 50012);

        exit(true);
    end;

    local procedure DoEmailErrorTasks(): Boolean
    var
        SMTPMail: Codeunit "SMTP Mail";
        CompanyInformation: Record "Company Information";
        EmailSubject: Text;
        SmtpConf: Record "SMTP Mail Setup";
        ToAddr: List of [Text];
        Body: Text;
    begin
        //SMTP
        SmtpConf.Get();
        CompanyInformation.Get;

        GetToAdminAddresses(ToAddr);

        Body := GetBodyErrorTasksModifyOrder();
        if StrLen(Body) = 0 then exit(false);

        EmailSubject := StrSubstNo(TxtEmailErrorTasksSubject, CompanyInformation.Name);
        SMTPMail.CreateMessage(CompanyInformation.Name, SmtpConf."User ID", ToAddr, EmailSubject, Body);

        exit(SMTPMail.Send);
    end;

    local procedure DoEmailErrorTasksPaymentSend(): Boolean
    var
        SMTPMail: Codeunit "SMTP Mail";
        CompanyInformation: Record "Company Information";
        EmailSubject: Text;
        SmtpConf: Record "SMTP Mail Setup";
        ToAddr: List of [Text];
        Body: Text;
    begin
        //SMTP
        SmtpConf.Get();
        CompanyInformation.Get;

        GetToAdminAddresses(ToAddr);

        Body := GetBodyErrorTasksPaymentSend();
        if StrLen(Body) = 0 then exit(false);

        EmailSubject := StrSubstNo(TxtEmailErrorTasksSubject, CompanyInformation.Name);
        SMTPMail.CreateMessage(CompanyInformation.Name, SmtpConf."User ID", ToAddr, EmailSubject, Body);

        exit(SMTPMail.Send);
    end;

    local procedure GetBodyErrorTasksModifyOrder(): Text
    var
        locTaskModifyOrder: Record "Task Modify Order";
        locBody: Text;
        char13: Char;
        char10: Char;
    begin
        char13 := 13;
        char10 := 10;

        locTaskModifyOrder.SetCurrentKey("Work Status");
        locTaskModifyOrder.SetFilter("Work Status", '%1', locTaskModifyOrder."Work Status"::Error);
        if locTaskModifyOrder.IsEmpty then exit('');

        if locTaskModifyOrder.FindSet(false, false) then begin
            locBody := lblBodyErrorTasks;
            repeat
                locBody += Format(char13) + Format(char10);
                locBody += locTaskModifyOrder."Error Text" + ' ' +
                                Format(locTaskModifyOrder.Status) + ' ' +
                                locTaskModifyOrder."Order No." + ' ' +
                                Format(locTaskModifyOrder."Create Date Time") + ' ' +
                                Format(locTaskModifyOrder."Modify Date Time");
            until locTaskModifyOrder.Next() = 0;
        end;

        exit(locBody);
    end;

    local procedure GetBodyErrorTasksPaymentSend(): Text
    var
        locTaskPaymentSend: Record "Task Payment Send";
        locBody: Text;
        char13: Char;
        char10: Char;
    begin
        char13 := 13;
        char10 := 10;

        locTaskPaymentSend.SetCurrentKey("Work Status");
        locTaskPaymentSend.SetFilter("Work Status", '%1', locTaskPaymentSend."Work Status"::Error);
        if locTaskPaymentSend.IsEmpty then exit('');

        if locTaskPaymentSend.FindSet(false, false) then begin
            locBody := lblBodyErrorTasks;
            repeat
                locBody += Format(char13) + Format(char10);
                locBody += locTaskPaymentSend."Error Text" + ' ' +
                                Format(locTaskPaymentSend.Status) + ' ' +
                                locTaskPaymentSend."Invoice No." + ' ' +
                                locTaskPaymentSend."Payment No." + ' ' +
                                Format(locTaskPaymentSend."Payment Amount") + ' ' +
                                Format(locTaskPaymentSend."Create Date Time") + ' ' +
                                Format(locTaskPaymentSend."Modify Date Time");
            until locTaskPaymentSend.Next() = 0;
        end;

        exit(locBody);
    end;

    procedure UnApplyDocToAccounter(SalesOrderNo: Code[20]): Boolean
    var
        SalesHeader: Record "Sales Header";
    begin
        if SendEmailUnApplyDocNotAllowed() then exit(true);

        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("No.", SalesOrderNo);
        SalesHeader.FindFirst;

        if not EmailInvoiceAsPDF(SalesHeader) then
            exit(false);

        if GuiAllowed then
            Message(msgReportSentToUser, 50000);

        exit(true);
    end;

    local procedure SendEmailErrorTasks(): Boolean
    var
        CompIntegr: Record "Company Integration";
    begin
        CompIntegr.SetCurrentKey("Company Name", "Send Email UnApply Doc.");
        CompIntegr.SetRange("Company Name", CompanyName);
        CompIntegr.SetRange("Send Email Error Tasks", true);
        exit(CompIntegr.IsEmpty);
    end;

    local procedure SendEmailUnApplyDocNotAllowed(): Boolean
    var
        CompIntegr: Record "Company Integration";
    begin
        CompIntegr.SetCurrentKey("Company Name", "Send Email UnApply Doc.");
        CompIntegr.SetRange("Company Name", CompanyName);
        CompIntegr.SetRange("Send Email UnApply Doc.", true);
        exit(CompIntegr.IsEmpty);
    end;

    procedure EmailInvoiceAsPDF(var SalesHeader: Record "Sales Header"): Boolean
    begin
        exit(DoEmailInvoiceAsPDF(SalesHeader));
    end;

    local procedure DoEmailInvoiceAsPDF(var SalesHeader: Record "Sales Header"): Boolean
    var
        SMTPMail: Codeunit "SMTP Mail";
        TempBlob: Codeunit "Temp Blob";
        VarInStream: InStream;
        CompanyInformation: Record "Company Information";
        EmailSubject: Text;
        AttachmentName: Text;
        SmtpConf: Record "SMTP Mail Setup";
        // recUser: Record User;
        ToAddr: List of [Text];
        Body: Text;
        Base64EncodedString: Integer;
    begin
        //SMTP
        SmtpConf.Get();
        CompanyInformation.Get;

        GetToAddresses(ToAddr);

        Body := StrSubstNo(lblBody, SalesHeader."No.");
        EmailSubject := StrSubstNo(TxtEmailSubject, CompanyInformation.Name, SalesHeader."No.");
        AttachmentName := StrSubstNo(TxtAttachmentName, SalesHeader."No.");

        if not SaveDocumentAsPDFToStream(SalesHeader, TempBlob) then
            Error(errReportNotSavedToPDF, 50000);
        Base64EncodedString := TempBlob.Length();

        TempBlob.CreateInStream(VarInStream);
        SMTPMail.CreateMessage(CompanyInformation.Name, SmtpConf."User ID", ToAddr, EmailSubject, Body);
        SMTPMail.AddAttachmentStream(VarInStream, AttachmentName);

        exit(SMTPMail.Send);
    end;

    local procedure GetToAdminAddresses(var ToAddr: List of [Text])
    var
        recUserSetup: Record "User Setup";
        recUser: Record User;
    begin
        recUserSetup.SetCurrentKey("Send Email Error Tasks");
        recUserSetup.SetRange("Send Email Error Tasks", true);
        recUserSetup.FindSet(false, false);
        repeat
            if recUserSetup."E-Mail" = '' then begin
                recUser.SetFilter("User Security ID", UserSecurityId());
                recUser.FindFirst();
                recUser.TestField("Contact Email");
                ToAddr.Add(recUser."Contact Email");
            end else
                ToAddr.Add(recUserSetup."E-Mail");
        until recUserSetup.Next() = 0;
    end;

    local procedure GetToAddresses(var ToAddr: List of [Text])
    var
        recUserSetup: Record "User Setup";
        recUser: Record User;
    begin
        recUserSetup.SetCurrentKey("Send Email UnApply Doc.");
        recUserSetup.SetRange("Send Email UnApply Doc.", true);
        recUserSetup.FindSet(false, false);
        repeat
            if recUserSetup."E-Mail" = '' then begin
                recUser.SetFilter("User Security ID", UserSecurityId());
                recUser.FindFirst();
                recUser.TestField("Contact Email");
                ToAddr.Add(recUser."Contact Email");
            end else
                ToAddr.Add(recUserSetup."E-Mail");
        until recUserSetup.Next() = 0;
    end;

    local procedure SaveDocumentAsPDFToStream(DocumentVariant: Variant; var TempBlob: Codeunit "Temp Blob"): Boolean;
    var
        DataTypeMgt: Codeunit "Data Type Management";
        ReportID: Integer;
        VarOutStream: OutStream;
        DocumentRef: RecordRef;
    begin
        ReportID := 50000;
        DataTypeMgt.GetRecordRef(DocumentVariant, DocumentRef);

        TempBlob.CreateOutStream(VarOutStream);
        if Report.SaveAs(ReportID, '', ReportFormat::Pdf, VarOutStream, DocumentRef) then
            exit(true)
        else
            Error(TxtCouldNotSaveReport, ReportID);
    end;

    procedure DeeduplicateNotificationToAccounter(): Boolean
    begin
        if SendEmailUnApplyDocNotAllowed() then exit;

        if not DoEmailDeduplicateNotification() then
            exit(false);

        if GuiAllowed then
            Message(msgEmailErrorTasksSentToUser, 50013);

        exit(true);

    end;

    local procedure DoEmailDeduplicateNotification(): Boolean
    var
        SMTPMail: Codeunit "SMTP Mail";
        CompanyInformation: Record "Company Information";
        EmailSubject: Text;
        SmtpConf: Record "SMTP Mail Setup";
        ToAddr: List of [Text];
        Body: Text;
    begin
        //SMTP
        SmtpConf.Get();
        CompanyInformation.Get;

        GetToAdminAddresses(ToAddr);

        Body := GetBodyDeeduplicateNotification;
        if StrLen(Body) = 0 then exit(false);

        EmailSubject := StrSubstNo(TxtEmailErrorTasksSubject, CompanyInformation.Name);
        SMTPMail.CreateMessage(CompanyInformation.Name, SmtpConf."User ID", ToAddr, EmailSubject, Body);

        exit(SMTPMail.Send);
    end;

    local procedure GetBodyDeeduplicateNotification(): Text
    var
        Cust: Record Customer;
        locBody: Text;
        char13: Char;
        char10: Char;
    begin
        char13 := 13;
        char10 := 10;

        Cust.SetCurrentKey("Deduplicate Id");
        Cust.SetFilter("Deduplicate Id", '<>%1', '00000000-0000-0000-0000-000000000000');
        if Cust.IsEmpty then exit('');

        if Cust.FindSet(false, false) then begin
            locBody := lblBodyDeduplicateNotification;
            repeat
                locBody += Format(char13) + Format(char10);
                locBody += Cust."No." + ' ' +
                            Cust.Name + ' ' +
                            Cust."Full Name" + ' ' +
                            Cust."Deduplicate Id" + ' ' +
                            GetCustDeduplicateNo(Cust."Deduplicate Id") + ' ' +
                            GetCustDeduplicateName(Cust."Deduplicate Id");
            until Cust.Next() = 0;
        end;

        exit(locBody);
    end;

    local procedure GetCustDeduplicateNo(DeduplicateId: Guid): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.SetCurrentKey("CRM ID");
        Customer.SetRange("CRM ID", DeduplicateId);
        if Customer.FindFirst() then
            exit(Customer."No.");

        exit('');
    end;

    local procedure GetCustDeduplicateName(DeduplicateId: Guid): Text[100]
    var
        Customer: Record Customer;
    begin
        Customer.SetCurrentKey("CRM ID");
        Customer.SetRange("CRM ID", DeduplicateId);
        if Customer.FindFirst() then
            exit(Customer.Name);

        exit('');
    end;
}