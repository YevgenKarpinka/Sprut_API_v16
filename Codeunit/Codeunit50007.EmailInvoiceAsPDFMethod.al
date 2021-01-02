codeunit 50007 "Email Invoice As PDF Method"
{
    trigger OnRun();
    begin

    end;

    var
        TxtEmailSubject: TextConst RUS = '%1 - Не Примененные Документы - %2', ENU = '%1 - Не Примененные Документы - %2';
        TxtAttachmentName: TextConst RUS = 'НеПримененныеДокументы-%1.pdf', ENU = 'UnApplyDocuments-%1.pdf';
        TxtCouldNotSaveReport: TextConst RUS = 'Could not save report, Report Id %1.', ENU = 'Could not save report, Report Id %1.';
        errReportNotSavedToPDF: Label 'Report %1 not saved to PDF';
        msgReportSendedToUser: Label 'Report %1 sended to user';
        lblBody: Label 'Не примененные документы для заказа продажи %1';

    procedure UnApplyDocToAccounter(SalesOrderNo: Code[20]);
    var
        SalesHeader: Record "Sales Header";
    begin
        if SendEmailUnApplyDocNotAllowed() then exit;

        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("No.", SalesOrderNo);
        SalesHeader.FindFirst;

        EmailInvoiceAsPDF(SalesHeader);
        if GuiAllowed then
            Message(msgReportSendedToUser, 50000);
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

    procedure EmailInvoiceAsPDF(var SalesHeader: Record "Sales Header");
    begin
        DoEmailInvoiceAsPDF(SalesHeader);
    end;

    local procedure DoEmailInvoiceAsPDF(var SalesHeader: Record "Sales Header");
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

        SMTPMail.Send;
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

}