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

    procedure CheckModifyAllowed();
    var
        CompIntegr: Record "Company Integration";
    begin
        CompIntegr.SetCurrentKey("Company Name", "Copy Items To");
        CompIntegr.SetRange("Company Name", CompanyName);
        CompIntegr.FindFirst();
        CompIntegr.TestField("Copy Items To", false);
        CompIntegr.TestField("Copy Items From", true);
    end;
}