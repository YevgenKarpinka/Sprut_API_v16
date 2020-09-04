codeunit 50000 "Web Service Mgt."
{
    trigger OnRun()
    begin

    end;

    procedure GetOauthToken()
    var
        TokenURL: Label 'https://login.microsoftonline.com/common/oauth2/';
        ClientId: Label 'a125243e-de60-41fb-b6f2-1795601fcea9';
        ClientSecret: Label 'Ct705dZ8-D2P-S0d_~n9n-CtFUkjI68.f7';
        Resource: Label 'https://org3baffe0c.crm4.dynamics.com';
        RequestBody: Label 'grant_type=implicit&client_id=%1&client_secret=%2&resource=%3';
        HttpClient: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        RequestHeader: HttpHeaders;
        Content: HttpContent;
        TempBlob: Codeunit "Temp Blob";
        Outstr: OutStream;
        Instr: InStream;
        APIResult: Text;
    begin

        Content.GetHeaders(RequestHeader);
        RequestHeader.Clear();

        HttpClient.SetBaseAddress(TokenURL);
        RequestMessage.Method('POST');
        RequestHeader.Remove('Content-Type');
        RequestHeader.Add('Content-Type', 'application/x-www-form-urlencoded');

        Clear(TempBlob);
        TempBlob.CreateOutStream(Outstr);
        Outstr.WriteText(StrSubstNo(RequestBody, ClientId, ClientSecret, Resource));
        TempBlob.CreateInStream(Instr);

        Content.WriteFrom(Instr);
        RequestMessage.Content(Content);
        HttpClient.Send(RequestMessage, ResponseMessage);

        if ResponseMessage.IsSuccessStatusCode() then begin
            ResponseMessage.Content().ReadAs(APIResult);
            Message(APIResult);
        end;

    end;
}