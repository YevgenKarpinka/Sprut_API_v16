codeunit 50018 "Integration 1C"
{
    trigger OnRun()
    begin

    end;

    var
        IntegrationLog: Record "Integration Log";
        WebServiceMgt: Codeunit "Web Service Mgt.";

    procedure GetBankIdFrom1C()
    var
        entityType: Label 'Catalog_Банки';
        requestMethod: Label 'GET';
        Body: Text;
        filterValue: Text;
    begin
        ConnectTo1C(entityType, requestMethod, Body, filterValue);
    end;

    procedure GetUoMIdFrom1C()
    var
        entityType: Label 'Catalog_КлассификаторЕдиницИзмерения';
        requestMethod: Label 'GET';
        Body: Text;
        filterValue: Text;
        lblSystemCode: Label '1C';
        lblName: Label 'UnitOfMeasure';
        UnitOfMeasure: Record "Unit of Measure";
        tempUnitOfMeasure: Record "Unit of Measure" temporary;
        IntegrationEntity: Record "Integration Entity";
        ResponceTokenLine: Text;
        jsonLines: JsonArray;
        LineToken: JsonToken;
    begin
        // create UoMs list for getting id from 1C
        if UnitOfMeasure.FindSet(false, false) then
            repeat
                if not IntegrationEntity.Get(lblSystemCode, Database::"Unit of Measure", UnitOfMeasure.Code, '', '') then begin
                    tempUnitOfMeasure := UnitOfMeasure;
                    tempUnitOfMeasure.Insert();
                end;
            until UnitOfMeasure.Next() = 0;

        // link between BC and 1C by Code and Description

        if tempUnitOfMeasure.FindSet(false, false) then
            repeat
                // create request body

                // get body from 1C
                ConnectTo1C(entityType, requestMethod, Body, filterValue);
                jsonLines.ReadFrom(Body);
                if jsonLines.Count = 0 then begin
                    // create Unit of Measure
                end else begin
                    // add id from 1C to integration entity
                    AddIDToIntegrationEntity(lblSystemCode, Database::"Unit of Measure", UnitOfMeasure.Code, '', '');
                end;


            until tempUnitOfMeasure.Next() = 0;


    end;

    local procedure AddIDToIntegrationEntity(SystemCode: Code[20]; tableID: Integer; Code1: Code[20]; Code2: Code[20]; entityID: Guid);
    var
        IntegrationEntity: Record "Integration Entity";
    begin
        IntegrationEntity.Init();

        IntegrationEntity.Insert();
    end;

    procedure GetItemsIdFrom1C()
    var
        entityType: Label 'Catalog_Номенклатура';
        requestMethod: Label 'GET';
        Body: Text;
        filterValue: Text;
    begin
        ConnectTo1C(entityType, requestMethod, Body, filterValue);
    end;

    procedure Get1CRoot()
    var
        entityType: Text;
        requestMethod: Label 'GET';
        Body: Text;
        filterValue: Text;
    begin
        ConnectTo1C(entityType, requestMethod, Body, filterValue);
    end;

    procedure ConnectTo1C(entityType: Text; requestMethod: Code[20]; var Body: Text; filterValue: Text): Boolean
    var
        Base64Convert: Codeunit "Base64 Convert";
        ClientId: Label 'Марина Кващук';
        ClientSecret: Label '888';
        ResourceTest: Label 'http://20.67.250.23/conf/odata/standard.odata';
        ResourceProd: Label 'http://20.67.250.23/conf/odata/standard.odata';
        HttpClient: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        RequestHeader: HttpHeaders;
        webAPI_URL: Label '%1/%2?%3';
        Accept: Label 'application/json';
        ParameterAuthorization: Label 'Authorization';
        Authorization: Text;
        MethodGET: Label 'GET';
        MethodPOST: Label 'POST';
        ContentType: Label 'Content-Type';
        ContentTypeFormUrlencoded: Label 'application/x-www-form-urlencoded';
        ParameterFormat: Label '$format';
        ParameterFormatValue: Label 'json';
        API_URL: Text;
        APIResult: Text;
        Basic: Label 'Basic %1';
        ClientIdSecretBase64: Label '%1:%2';
        ParameterBody: Label '%1=%2%3';
    begin
        if WebServiceMgt.GetResourceProductionNotAllowed() then
            API_URL := StrSubstNo(webAPI_URL, ResourceTest, entityType,
                            StrSubstNo(ParameterBody, ParameterFormat, ParameterFormatValue, filterValue))
        else
            API_URL := StrSubstNo(webAPI_URL, ResourceProd, entityType,
                            StrSubstNo(ParameterBody, ParameterFormat, ParameterFormatValue, filterValue));

        RequestMessage.Method := requestMethod;
        RequestMessage.SetRequestUri(API_URL);
        RequestMessage.GetHeaders(RequestHeader);
        Authorization := StrSubstNo(Basic,
                Base64Convert.ToBase64(StrSubstNo(ClientIdSecretBase64, ClientId, ClientSecret)));
        RequestHeader.Add(ParameterAuthorization, Authorization);

        if requestMethod = 'POST' then begin
            RequestMessage.Content.WriteFrom(Body);
            RequestMessage.Content.GetHeaders(RequestHeader);
            RequestHeader.Remove(ContentType);
            RequestHeader.Add(ContentType, Accept);
        end;

        HttpClient.Send(RequestMessage, ResponseMessage);
        ResponseMessage.Content().ReadAs(APIResult);

        // Insert Operation to Log
        IntegrationLog.InsertOperationToLog('STANDART_1C_API', requestMethod, API_URL, '', Body, APIResult, ResponseMessage.IsSuccessStatusCode());

        // for testing
        Message(APIResult);

        // response body
        Body := APIResult;

        exit(ResponseMessage.IsSuccessStatusCode);
    end;
}