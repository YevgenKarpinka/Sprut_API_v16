codeunit 50000 "Web Service Mgt."
{
    trigger OnRun()
    begin

    end;

    var
        EnvironmentBlocksErr: Label 'Environment blocks an outgoing HTTP request to ''%1''.',
            Comment = '%1 - url, e.g. https://microsoft.com';
        ConnectionErr: Label 'Connection to the remote service ''%1'' could not be established.',
            Comment = '%1 - url, e.g. https://microsoft.com';

    /// <summary> 
    /// Description for ConnectToCRM.
    /// </summary>
    /// <param name="connectorCode">Parameter of type Code[20].</param>
    /// <param name="entityType">Parameter of type Text[20].</param>
    /// <param name="requestMethod">Parameter of type Code[20].</param>
    /// <returns>Return variable "Boolean".</returns>
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

    /// <summary> 
    /// Description for OnAPIProcess.
    /// </summary>
    /// <param name="entityType">Parameter of type Text[20].</param>
    /// <param name="requestMethod">Parameter of type Code[20].</param>
    /// <param name="tokenType">Parameter of type Text.</param>
    /// <param name="accessToken">Parameter of type Text.</param>
    local procedure OnAPIProcess(entityType: Text[20]; requestMethod: Code[20]; tokenType: Text; accessToken: Text)
    var
        // {{resource}}/api/data/v{{version}}/{{entityType}}
        webAPI_URL: Label '%1/api/data/v%2/%3';
        resource: Label 'https://org3baffe0c.crm4.dynamics.com';
        version: Label '9.1';
        Accept: Label 'Accept';
        Authorization: Label 'Authorization';
        AcceptJSON: Label 'application/json';
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
        AuthorizationToken: Text;
    begin
        BaseURL := StrSubstNo(webAPI_URL, resource, version, entityType);
        AuthorizationToken := StrSubstNo('%1 %2', tokenType, accessToken);

        RequestMessage.GetHeaders(RequestHeader);
        RequestHeader.Clear();

        RequestHeader.Add(Accept, AcceptJSON);
        RequestHeader.Add(Authorization, AuthorizationToken);

        RequestMessage.Method := requestMethod;
        RequestMessage.SetRequestUri(BaseURL);

        HttpClient.Send(RequestMessage, ResponseMessage);
        ResponseMessage.Content.ReadAs(APIResult);
        Message(APIResult);
    end;

    procedure GetOauthToken(
        // TokenURL: Text[200]; ClientId: Text[50]; ClientSecret: Text[50]; Resource: Text[150]; RequestBody: Text[150];
        var TokenType: Text; var AccessToken: Text)
    var
        TokenURL: Label 'https://login.microsoftonline.com/da79d6fc-fddb-47ae-bec3-75a8d9e1e1bb/oauth2/token';
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
        MethodPOST: Label 'POST';
        ContentType: Label 'Content-Type';
        ContentTypeFormUrlencoded: Label 'application/x-www-form-urlencoded';
    begin
        Content.GetHeaders(RequestHeader);
        RequestHeader.Clear();

        HttpClient.SetBaseAddress(TokenURL);
        RequestMessage.Method(MethodPOST);

        RequestHeader.Remove(ContentType);
        RequestHeader.Add(ContentType, ContentTypeFormUrlencoded);

        Clear(TempBlob);
        TempBlob.CreateOutStream(Outstr);
        Outstr.WriteText(StrSubstNo(RequestBody, ClientId, ClientSecret, Resource));
        TempBlob.CreateInStream(Instr);

        Content.WriteFrom(Instr);
        RequestMessage.Content(Content);
        HttpClient.Send(RequestMessage, ResponseMessage);
        ResponseMessage.Content().ReadAs(APIResult);

        if ResponseMessage.IsSuccessStatusCode() then //begin
            GetTokenFromResponse(APIResult, TokenType, AccessToken)
        // end
        else
            Error(APIResult);
    end;

    /// <summary> 
    /// Description for GetTokenFromResponse.
    /// </summary>
    /// <param name="APIResult">Parameter of type Text.</param>
    /// <param name="TokenType">Parameter of type Text.</param>
    /// <param name="AccessToken">Parameter of type Text.</param>
    local procedure GetTokenFromResponse(APIResult: Text; var TokenType: Text; var AccessToken: Text)
    var
        jsonAPI: JsonObject;
    begin
        jsonAPI.ReadFrom(APIResult);
        TokenType := GetJSToken(jsonAPI, 'token_type').AsValue().AsText();
        AccessToken := GetJSToken(jsonAPI, 'access_token').AsValue().AsText();
    end;

    /// <summary> 
    /// Description for GetJSToken.
    /// </summary>
    /// <param name="_JSONObject">Parameter of type JsonObject.</param>
    /// <param name="TokenKey">Parameter of type Text.</param>
    local procedure GetJSToken(_JSONObject: JsonObject; TokenKey: Text) _JSONToken: JsonToken
    begin
        if not _JSONObject.Get(TokenKey, _JSONToken) then
            Error('Could not find a token with key %1', TokenKey);
    end;

    /// <summary> 
    /// Description for SelectJSToken.
    /// </summary>
    /// <param name="_JSONObject">Parameter of type JsonObject.</param>
    /// <param name="Path">Parameter of type Text.</param>
    local procedure SelectJSToken(_JSONObject: JsonObject; Path: Text) _JSONToken: JsonToken
    begin
        if not _JSONObject.SelectToken(Path, _JSONToken) then
            Error('Could not find a token with path %1', Path);
    end;

    /// <summary> 
    /// Description for InvokeSingleRequest.
    /// </summary>
    /// <param name="RequestJson">Parameter of type Text.</param>
    /// <param name="ResponseJson">Parameter of type Text.</param>
    /// <param name="HttpError">Parameter of type Text.</param>
    /// <param name="AccessToken">Parameter of type Text.</param>
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

    /// <summary> 
    /// Description for InvokeHttpJSONRequest.
    /// </summary>
    /// <param name="RequestJson">Parameter of type Text.</param>
    /// <param name="ResponseJson">Parameter of type Text.</param>
    /// <param name="HttpError">Parameter of type Text.</param>
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

    /// <summary> 
    /// Description for InitHttpRequestContent.
    /// </summary>
    /// <param name="RequestMessage">Parameter of type HttpRequestMessage.</param>
    /// <param name="RequestJson">Parameter of type Text.</param>
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
    /// <summary> 
    /// Description for InitHttpRequestMessage.
    /// </summary>
    /// <param name="RequestMessage">Parameter of type HttpRequestMessage.</param>
    /// <param name="RequestJson">Parameter of type Text.</param>
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

    /// <summary> 
    /// Description for ProcessHttpResponseMessage.
    /// </summary>
    /// <param name="ResponseMessage">Parameter of type HttpResponseMessage.</param>
    /// <param name="ResponseJson">Parameter of type Text.</param>
    /// <param name="HttpError">Parameter of type Text.</param>
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

    /// <summary> 
    /// Description for SetHttpStatus.
    /// </summary>
    /// <param name="JObject">Parameter of type JsonObject.</param>
    /// <param name="StatusCode">Parameter of type Integer.</param>
    /// <param name="StatusReason">Parameter of type Text.</param>
    /// <param name="StatusDetails">Parameter of type Text.</param>
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

    procedure jsonItems(ItemNo: Code[20]): JsonArray
    var
        locItems: Record Item;
        JSObjectLine: JsonObject;
        JSObjectArray: JsonArray;
        salesTypeCode: Label '799810002';
        defaultUoMScheduleId: Label '/uomschedules(422fde89-3e76-45f2-b9e6-9d59c8bbc311)';
        defaultUoMId: Label '/uoms(d91f3b4e-f4cc-4063-8f7a-8d365d5922ff)';
        quantityDecimal: Integer;
    begin
        quantitydecimal := 2;

        if locItems.FindSet(false, false) then
            repeat
                Clear(JSObjectLine);

                JSObjectLine.Add('tct_salestypecode', salesTypeCode);
                JSObjectLine.Add('productnumber', locItems."No.");
                JSObjectLine.Add('name', locItems.Description);
                JSObjectLine.Add('defaultuomscheduleid@odata.bind', defaultUoMScheduleId);
                JSObjectLine.Add('defaultuomid@odata.bind', defaultUoMId);
                JSObjectLine.Add('quantitydecimal', quantityDecimal);
                JSObjectLine.Add('tct_bc_product_number', locItems."No.");
                JSObjectLine.Add('tct_bc_UoMId', locItems."Sales Unit of Measure");

                JSObjectArray.Add(JSObjectLine);
            until locItems.Next() = 0;
        exit(JSObjectArray);
    end;
}