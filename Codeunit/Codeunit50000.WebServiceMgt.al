codeunit 50000 "Web Service Mgt."
{
    trigger OnRun()
    begin

    end;

    var
        EnvironmentBlocksErr: Label 'Environment blocks an outgoing HTTP request to ''%1''.', Comment = '%1 - url, e.g. https://microsoft.com';
        ConnectionErr: Label 'Connection to the remote service ''%1'' could not be established.', Comment = '%1 - url, e.g. https://microsoft.com';

    procedure ConnectToCRM(connectorCode: Code[20]; entityType: Text[20]; requestMethod: Code[20]): Boolean
    var
        tokenType: Text;
        accessToken: Text;
        webServiceHeader: Record "Web Service Header";
        webServiceLine: Record "Web Service Line";
    begin
        // with webServiceHeader do begin
        //     if not Get(connectorCode) then exit(false);
        GetOauthToken(
             // "Token URL", "Client Id", "Client Secret", Resource, "Request Body",
             tokenType, accessToken);
        // end;
        OnAPIProcess(entityType, requestMethod, tokenType, accessToken);
    end;

    local procedure OnAPIProcess(entityType: Text[20]; requestMethod: Code[20]; tokenType: Text; accessToken: Text)
    var
        // {{resource}}/api/data/v{{version}}/{{entityType}}
        webAPI_URL: Label '%1/api/data/v%2/%3';
        resource: Label 'https://org3baffe0c.api.crm4.dynamics.com';
        version: Label '9.1';
        Accept: Label 'application/json';
        HttpClient: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        RequestHeader: HttpHeaders;
        Content: HttpContent;
        TempBlob: Codeunit "Temp Blob";
        Outstr: OutStream;
        Instr: InStream;
        APIResult: Text;
        BaseURL: Text;
        Authorization: Text;
    begin
        // RequestMessage.GetHeaders(RequestHeader);
        // RequestHeader.Clear();

        // RequestMessage.Method(requestMethod);
        BaseURL := StrSubstNo(webAPI_URL, resource, version, entityType);
        // RequestMessage.SetRequestUri(BaseURL);

        // RequestHeader.Add('Accept', 'application/json');

        Authorization := StrSubstNo('%1 %2', tokenType, accessToken);
        // RequestHeader.Add('Authorization', Authorization);
        // HttpClient.Send(RequestMessage, ResponseMessage);
        // ResponseMessage.Content().ReadAs(APIResult);

        // if ResponseMessage.IsSuccessStatusCode() then begin
        //     Message(APIResult);
        // end else
        //     Error(APIResult);
        //  ******

        RequestMessage.Method := requestMethod;
        RequestMessage.SetRequestUri(BaseURL);
        RequestMessage.GetHeaders(RequestHeader);

        RequestHeader.Add('Accept', Accept);
        RequestHeader.Add('Authorization', Authorization);

        // Headers.Add('If-Match', SourceParameters."FSp ETag");
        // if SourceParameters."FSp RestMethod" = SourceParameters."FSp RestMethod"::POST then begin
        //     RequestMessage.Content.WriteFrom(Body2Request);
        //     RequestMessage.Content.GetHeaders(Headers);
        //     if SourceParameters."FSp ContentType" <> 0 then begin
        //         Headers.Remove('Content-Type');
        //         Headers.Add('Content-Type', Format(SourceParameters."FSp ContentType"));
        //     end;
        // end;

        HttpClient.Send(RequestMessage, ResponseMessage);
        ResponseMessage.Content.ReadAs(APIResult);
        Message(APIResult);
    end;

    procedure GetOauthToken(
        // TokenURL: Text[200]; ClientId: Text[50]; ClientSecret: Text[50]; Resource: Text[150]; RequestBody: Text[150];
        var TokenType: Text; var AccessToken: Text)
    var
        TokenURL: Label 'https://login.microsoftonline.com/common/oauth2/token';
        ClientId: Label 'a125243e-de60-41fb-b6f2-1795601fcea9';
        ClientSecret: Label 'A6-595SrEw0DPBT4-_1Uw-l3eL4ETar~-7';
        Resource: Label 'https://org3baffe0c.crm4.dynamics.com';
        RequestBody: Label 'grant_type=client_credentials&client_id=%1&client_secret=%2&resource=%3';
        HttpClient: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        RequestHeader: HttpHeaders;
        Content: HttpContent;
        TempBlob: Codeunit "Temp Blob";
        Outstr: OutStream;
        Instr: InStream;
        APIResult: Text;
        entityType: Label 'products';
        webAPI_URL: Label '%1/api/data/v%2/%3';
        version: Label '9.1';
        Accept: Label 'application/json';
        BaseURL: Text;
        Authorization: Text;
        ErrorMessage: Text;

    begin
        Content.GetHeaders(RequestHeader);
        RequestHeader.Clear();

        HttpClient.SetBaseAddress(TokenURL);
        RequestMessage.Method('POST');

        RequestHeader.Remove('Content-Type');
        // RequestHeader.Add('Content-Type', 'application/json');
        RequestHeader.Add('Content-Type', 'application/x-www-form-urlencoded');

        Clear(TempBlob);
        TempBlob.CreateOutStream(Outstr);
        Outstr.WriteText(StrSubstNo(RequestBody, ClientId, ClientSecret, Resource));
        TempBlob.CreateInStream(Instr);

        Content.WriteFrom(Instr);
        RequestMessage.Content(Content);
        HttpClient.Send(RequestMessage, ResponseMessage);
        ResponseMessage.Content().ReadAs(APIResult);

        if ResponseMessage.IsSuccessStatusCode() then //begin
            GetTokenFromResponse(APIResult, TokenType, AccessToken);
        // end else
        Error(APIResult);

        //  Get Products
        // **
        AccessToken := 'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6ImppYk5ia0ZTU2JteFBZck45Q0ZxUms0SzRndyIsImtpZCI6ImppYk5ia0ZTU2JteFBZck45Q0ZxUms0SzRndyJ9.eyJhdWQiOiJodHRwczovL29yZzNiYWZmZTBjLmNybTQuZHluYW1pY3MuY29tIiwiaXNzIjoiaHR0cHM6Ly9zdHMud2luZG93cy5uZXQvZGE3OWQ2ZmMtZmRkYi00N2FlLWJlYzMtNzVhOGQ5ZTFlMWJiLyIsImlhdCI6MTU5OTY1NTMwOCwibmJmIjoxNTk5NjU1MzA4LCJleHAiOjE1OTk2NTkyMDgsImFjciI6IjEiLCJhaW8iOiJBU1FBMi84UUFBQUFWb0N2eDQ1Zk45VWl1YVBIeDhqZS8yR1RBQnYwZ2M3VlBlN2pKYkJSMlEwPSIsImFtciI6WyJwd2QiXSwiYXBwaWQiOiJhMTI1MjQzZS1kZTYwLTQxZmItYjZmMi0xNzk1NjAxZmNlYTkiLCJhcHBpZGFjciI6IjAiLCJmYW1pbHlfbmFtZSI6ItCe0YXRgNCw0L3QvdGL0Lkg0YXQvtC70LTQuNC90LMgU3BydXQiLCJnaXZlbl9uYW1lIjoi0J7RhdGA0LDQvdC90YvQuSDRhdC-0LvQtNC40L3QsyBTcHJ1dCIsImlwYWRkciI6Ijc5LjExMC4xMzAuMjI4IiwibmFtZSI6ItCe0YXRgNCw0L3QvdGL0Lkg0YXQvtC70LTQuNC90LMgU3BydXQiLCJvaWQiOiI5NWVmMzRjZC1jZWQyLTRkMDMtYWQzZS02ZTQxMzUwYTM5OWYiLCJwdWlkIjoiMTAwMzIwMDA5RjUyMTg0MCIsInJoIjoiMC5BQUFBX05aNTJ0djlya2UtdzNXbzJlSGh1ejRrSmFGZzN2dEJ0dklYbFdBZnpxbElBQ0kuIiwic2NwIjoidXNlcl9pbXBlcnNvbmF0aW9uIiwic3ViIjoiTGlkdUNhalE2eERKd1JsRVd2a0FUWVI3T0wwQUJxUWdZWHpVSXRvZ0lpdyIsInRpZCI6ImRhNzlkNmZjLWZkZGItNDdhZS1iZWMzLTc1YThkOWUxZTFiYiIsInVuaXF1ZV9uYW1lIjoiYWRtaW5Ac3BydXQub25taWNyb3NvZnQuY29tIiwidXBuIjoiYWRtaW5Ac3BydXQub25taWNyb3NvZnQuY29tIiwidXRpIjoieE5KQi04anREMC1sQWFGVFhWNDlBQSIsInZlciI6IjEuMCJ9.IsoF--em89ENm_rR6S8x-B6pVL7CSSC0k8KNGEiYYkqy1zj7HhFXFowAttboE6q6eUc--Iy0a9diLlPA7yb8HP2W8bglZ3DkhJyF5NieM5RZqTGOwi0VxEXxmgyrXqX3vjEAC88km2gKYbS100iuOeRoT3SW7zolXdyNub3rNaASP4qxaBt5pV6_E2-zAYeEMxRiNhpzDq9XTBdWoVEfM-W_kEwVeB3kGMRBKxDFCCL_Evv_g6O_zV0hJ_p0bNDUKf0IxqiTHpIkBW1Z9-1k2pQ6feiq6aOPXx5VJJeb_iHVelKz2cK-FRKtRmIjde0n73VWbc5c_7zhyQGJWoBLvw';
        BaseURL := StrSubstNo(webAPI_URL, resource, version, entityType);
        Authorization := StrSubstNo('%1 %2', TokenType, AccessToken);
        // HttpClient.Clear();
        RequestMessage.GetHeaders(RequestHeader);
        RequestHeader.Clear();
        RequestHeader.Add('Accept', Accept);
        RequestHeader.Add('Authorization', Authorization);
        RequestMessage.Method('GET');
        RequestMessage.SetRequestUri(BaseURL);
        if not HttpClient.Send(RequestMessage, ResponseMessage) then
            if ResponseMessage.IsBlockedByEnvironment() then
                ErrorMessage := StrSubstNo(EnvironmentBlocksErr, RequestMessage.GetRequestUri())
            else
                ErrorMessage := StrSubstNo(ConnectionErr, RequestMessage.GetRequestUri());

        if ErrorMessage <> '' then
            Error(ErrorMessage);

        ResponseMessage.Content.ReadAs(APIResult);
        Message(APIResult);
    end;

    local procedure GetTokenFromResponse(APIResult: Text; var TokenType: Text; var AccessToken: Text)
    var
        jsonAPI: JsonObject;
    begin
        jsonAPI.ReadFrom(APIResult);
        TokenType := GetJSToken(jsonAPI, 'token_type').AsValue().AsText();
        AccessToken := GetJSToken(jsonAPI, 'access_token').AsValue().AsText();
    end;

    local procedure GetJSToken(_JSONObject: JsonObject; TokenKey: Text) _JSONToken: JsonToken
    begin
        if not _JSONObject.Get(TokenKey, _JSONToken) then
            Error('Could not find a token with key %1', TokenKey);
    end;

    local procedure SelectJSToken(_JSONObject: JsonObject; Path: Text) _JSONToken: JsonToken
    begin
        if not _JSONObject.SelectToken(Path, _JSONToken) then
            Error('Could not find a token with path %1', Path);
    end;

    local procedure InvokeSingleRequest(RequestJson: Text; var ResponseJson: Text; var HttpError: Text; AccessToken: Text) Result: Boolean
    var
        RequestJObject: JsonObject;
        HeaderJObject: JsonObject;
        JToken: JsonToken;

        Resource: Label 'https://org3baffe0c.crm4.dynamics.com/';
        entityType: Label 'products';
        webAPI_URL: Label '%1/api/data/v%2/%3';
        version: Label '9.1';
        BaseURL: Text;
    begin
        // with OAuth20Setup do begin
        //     TestField("Service URL");
        //     TestField("Access Token");

        if RequestJObject.ReadFrom(RequestJson) then;

        BaseURL := StrSubstNo(webAPI_URL, Resource, version, entityType);
        RequestJObject.Add('ServiceURL', BaseURL);
        HeaderJObject.Add('Authorization', StrSubstNo('Bearer %1', AccessToken));
        if RequestJObject.SelectToken('Header', JToken) then
            JToken.AsObject().Add('Authorization', StrSubstNo('Bearer %1', AccessToken))
        else
            RequestJObject.Add('Header', HeaderJObject);
        RequestJObject.WriteTo(RequestJson);

        // if "Latest Datetime" = 0DT then
        //     "Daily Count" := 0
        // else
        //     if "Latest Datetime" < CreateDateTime(Today(), 0T) then
        //         "Daily Count" := 0;
        // if ("Daily Limit" <= 0) or ("Daily Count" < "Daily Limit") or ("Latest Datetime" = 0DT) then begin
        Result := InvokeHttpJSONRequest(RequestJson, ResponseJson, HttpError);
        //     "Latest Datetime" := CurrentDateTime();
        //     "Daily Count" += 1;
        // end else begin
        //     Result := false;
        //     HttpError := LimitExceededTxt;
        //     SendTraceTag('00009YL', ActivityLogContextTxt, Verbosity::Normal, LimitExceededTxt, DataClassification::SystemMetadata);
        // end;
        // RequestJObject.Get('Method', JToken);
        // LogActivity(
        //     OAuth20Setup, Result, StrSubstNo(InvokeRequestTxt, JToken.AsValue().AsText()),
        //     HttpError, RequestJson, ResponseJson, false);
        // end;
    end;

    local procedure InvokeHttpJSONRequest(RequestJson: Text; var ResponseJson: Text; var HttpError: Text) Result: Boolean
    var
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        ErrorMessage: Text;
    begin
        ResponseJson := '';
        HttpError := '';

        Client.Clear();
        Client.Timeout(60000);
        InitHttpRequestContent(RequestMessage, RequestJson);
        InitHttpRequestMessage(RequestMessage, RequestJson);

        if not Client.Send(RequestMessage, ResponseMessage) then
            if ResponseMessage.IsBlockedByEnvironment() then
                ErrorMessage := StrSubstNo(EnvironmentBlocksErr, RequestMessage.GetRequestUri())
            else
                ErrorMessage := StrSubstNo(ConnectionErr, RequestMessage.GetRequestUri());

        if ErrorMessage <> '' then
            Error(ErrorMessage);

        exit(ProcessHttpResponseMessage(ResponseMessage, ResponseJson, HttpError));
    end;

    local procedure InitHttpRequestContent(var RequestMessage: HttpRequestMessage; RequestJson: Text)
    var
        ContentHeaders: HttpHeaders;
        JToken: JsonToken;
        ContentJToken: JsonToken;
        ContentJson: Text;
    begin
        if JToken.ReadFrom(RequestJson) then
            if JToken.SelectToken('Content', ContentJToken) then begin
                RequestMessage.Content().Clear();
                ContentJToken.WriteTo(ContentJson);
                RequestMessage.Content().WriteFrom(ContentJson);
                if JToken.SelectToken('Content-Type', JToken) then begin
                    RequestMessage.Content().GetHeaders(ContentHeaders);
                    ContentHeaders.Clear();
                    ContentHeaders.Add('Content-Type', JToken.AsValue().AsText());
                end;
            end;
    end;

    [NonDebuggable]
    local procedure InitHttpRequestMessage(var RequestMessage: HttpRequestMessage; RequestJson: Text)
    var
        RequestHeaders: HttpHeaders;
        JToken: JsonToken;
        JToken2: JsonToken;
        ServiceURL: Text;
        HeadersJson: Text;
    begin
        if JToken.ReadFrom(RequestJson) then begin
            RequestMessage.GetHeaders(RequestHeaders);
            RequestHeaders.Clear();
            if JToken.SelectToken('Accept', JToken2) then
                RequestHeaders.Add('Accept', JToken2.AsValue().AsText());
            if JToken.AsObject().Get('Header', JToken2) then begin
                JToken2.WriteTo(HeadersJson);
                if JToken2.ReadFrom(HeadersJson) then
                    foreach JToken2 in JToken2.AsObject().Values() do
                        RequestHeaders.Add(JToken2.Path(), JToken2.AsValue().AsText());
            end;

            if JToken.SelectToken('Method', JToken2) then
                RequestMessage.Method(JToken2.AsValue().AsText());

            if JToken.SelectToken('ServiceURL', JToken2) then begin
                ServiceURL := JToken2.AsValue().AsText();
                if JToken.SelectToken('URLRequestPath', JToken2) then
                    ServiceURL += JToken2.AsValue().AsText();
                RequestMessage.SetRequestUri(ServiceURL);
            end;
        end;
    end;

    local procedure ProcessHttpResponseMessage(var ResponseMessage: HttpResponseMessage; var ResponseJson: Text; var HttpError: Text) Result: Boolean
    var
        ResponseJObject: JsonObject;
        ContentJObject: JsonObject;
        JToken: JsonToken;
        ResponseText: Text;
        JsonResponse: Boolean;
        StatusCode: Integer;
        StatusReason: Text;
        StatusDetails: Text;
    begin
        Result := ResponseMessage.IsSuccessStatusCode();
        StatusCode := ResponseMessage.HttpStatusCode();
        StatusReason := ResponseMessage.ReasonPhrase();

        if ResponseMessage.Content().ReadAs(ResponseText) then
            JsonResponse := ContentJObject.ReadFrom(ResponseText);
        if JsonResponse then
            ResponseJObject.Add('Content', ContentJObject);

        if not Result then begin
            HttpError := StrSubstNo('HTTP error %1 (%2)', StatusCode, StatusReason);
            if JsonResponse then
                if ContentJObject.SelectToken('error_description', JToken) then begin
                    StatusDetails := JToken.AsValue().AsText();
                    HttpError += StrSubstNo('\%1', StatusDetails);
                end;
        end;

        SetHttpStatus(ResponseJObject, StatusCode, StatusReason, StatusDetails);
        ResponseJObject.WriteTo(ResponseJson);
    end;

    local procedure SetHttpStatus(var JObject: JsonObject; StatusCode: Integer; StatusReason: Text; StatusDetails: Text)
    var
        JObject2: JsonObject;
    begin
        JObject2.Add('code', StatusCode);
        JObject2.Add('reason', StatusReason);
        if StatusDetails <> '' then
            JObject2.Add('details', StatusDetails);
        JObject.Add('Status', JObject2);
    end;
}