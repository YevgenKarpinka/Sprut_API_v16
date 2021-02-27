codeunit 50018 "Integration 1C"
{
    trigger OnRun()
    begin

    end;

    var
        IntegrationLog: Record "Integration Log";
        WebServiceMgt: Codeunit "Web Service Mgt.";

    procedure GetBankIdFrom1C(): Boolean
    var
        entityType: Label 'Catalog_Банки';
        requestMethodGET: Label 'GET';
        requestMethodPOST: Label 'POST';
        Body: Text;
        filterValue: Text;
        lblSystemCode: Label '1C';
        lblName: Label 'Bank';
        BankDirectory: Record "Bank Directory";
        tempBankDirectory: Record "Bank Directory" temporary;
        IntegrationEntity: Record "Integration Entity";
        ResponceTokenLine: Text;
        jsonLines: JsonArray;
        jsonBody: JsonObject;
        LineToken: JsonToken;
        codeBIC: Code[10];
        codeBIC1C: Text[10];
        tempcodeBIC1C: Text[10];
    begin
        // create UoMs list for getting id from 1C
        if BankDirectory.FindSet(false, false) then
            repeat
                if not IntegrationEntity.Get(lblSystemCode, Database::"Bank Directory", BankDirectory.BIC, '', CompanyName) then begin
                    tempBankDirectory := BankDirectory;
                    tempBankDirectory.Insert();
                end;
            until BankDirectory.Next() = 0;

        // link between 1C МФО and BIC in BC
        if tempBankDirectory.Count = 0 then exit(true);

        // get body from 1C
        if not ConnectTo1C(entityType, requestMethodGET, Body, filterValue) then exit(false);
        jsonBody.ReadFrom(Body);
        jsonLines := WebServiceMgt.GetJSToken(jsonBody, 'value').AsArray();
        foreach LineToken in jsonLines do begin
            codeBIC := DelChr(WebServiceMgt.GetJSToken(LineToken.AsObject(), 'Code').AsValue().AsText(), '<>', ' ');
            if tempBankDirectory.Get(codeBIC) then begin
                AddIDToIntegrationEntity(lblSystemCode, Database::"Bank Directory", tempBankDirectory.BIC, '',
                                WebServiceMgt.GetJSToken(LineToken.AsObject(), 'Ref_Key').AsValue().AsText());
                tempBankDirectory.Delete();
            end;
        end;

        // create entity in 1C
        Clear(jsonBody);
        Clear(jsonLines);
        if tempBankDirectory.FindSet(false, false) then
            repeat
                // create request body
                CreateRequestBodyToBank(tempBankDirectory.BIC, jsonBody);

                // get body from 1C
                jsonBody.WriteTo(Body);
                if not ConnectTo1C(entityType, requestMethodPOST, Body, filterValue) then exit(false);
                jsonBody.ReadFrom(Body);
                AddIDToIntegrationEntity(lblSystemCode, Database::"Bank Directory", tempBankDirectory.BIC, '',
                                WebServiceMgt.GetJSToken(jsonBody, 'Ref_Key').AsValue().AsText());
            until tempBankDirectory.Next() = 0;

        exit(true);
    end;

    local procedure CreateRequestBodyToBank(BankDirectoryBIC: Code[10]; var Body: JsonObject)
    var
        BankDirectory: Record "Bank Directory";
    begin
        BankDirectory.Get(BankDirectoryBIC);
        Clear(Body);
        Body.Add('Code', BankDirectory.BIC);
        Body.Add('Description', BankDirectory."Short Name");
        if BankDirectory."Area Name" <> '' then
            Body.Add('Город', BankDirectory."Area Name");
        if BankDirectory.Address <> '' then
            Body.Add('Адрес', BankDirectory.Address);
        if BankDirectory.Telephone <> '' then
            Body.Add('Телефоны', BankDirectory.Telephone);
        if BankDirectory.OKPO <> '' then
            Body.Add('КодПоЕДРПОУ', BankDirectory.OKPO);
    end;

    procedure GetUoMIdFrom1C(): Boolean
    var
        entityType: Label 'Catalog_КлассификаторЕдиницИзмерения';
        requestMethodGET: Label 'GET';
        requestMethodPOST: Label 'POST';
        Body: Text;
        filterValue: Text;
        lblSystemCode: Label '1C';
        lblName: Label 'UnitOfMeasure';
        UnitOfMeasure: Record "Unit of Measure";
        tempUnitOfMeasure: Record "Unit of Measure" temporary;
        IntegrationEntity: Record "Integration Entity";
        ResponceTokenLine: Text;
        jsonLines: JsonArray;
        jsonBody: JsonObject;
        LineToken: JsonToken;
        codeUoM: Code[10];
        codeUoM1C: Text[10];
        tempCodeUoM1C: Text[10];
    begin
        // create UoMs list for getting id from 1C
        if UnitOfMeasure.FindSet(false, false) then
            repeat
                if not IntegrationEntity.Get(lblSystemCode, Database::"Unit of Measure", UnitOfMeasure.Code, '', CompanyName) then begin
                    tempUnitOfMeasure := UnitOfMeasure;
                    tempUnitOfMeasure.Insert();
                end;
            until UnitOfMeasure.Next() = 0;

        // link between BC and 1C by Code and Description
        if tempUnitOfMeasure.Count = 0 then exit(true);

        // get body from 1C
        if not ConnectTo1C(entityType, requestMethodGET, Body, filterValue) then exit(false);
        jsonBody.ReadFrom(Body);
        jsonLines := WebServiceMgt.GetJSToken(jsonBody, 'value').AsArray();
        foreach LineToken in jsonLines do begin
            codeUoM := DelChr(WebServiceMgt.GetJSToken(LineToken.AsObject(), 'Description').AsValue().AsText(), '<>', ' ');
            if tempUnitOfMeasure.Get(codeUoM) then begin
                AddIDToIntegrationEntity(lblSystemCode, Database::"Unit of Measure", tempUnitOfMeasure.Code, '',
                                WebServiceMgt.GetJSToken(LineToken.AsObject(), 'Ref_Key').AsValue().AsText());
                tempUnitOfMeasure.Delete();
            end;
            tempCodeUoM1C := DelChr(WebServiceMgt.GetJSToken(LineToken.AsObject(), 'Code').AsValue().AsText(), '<>', ' ');
            GetMaximumCode(codeUoM1C, tempCodeUoM1C);
        end;

        // create entity in 1C
        Clear(jsonBody);
        Clear(jsonLines);
        if tempUnitOfMeasure.FindSet(false, false) then
            repeat
                // create request body
                GetNextCode(codeUoM1C);
                CreateRequestBodyToUoM(tempUnitOfMeasure.Code, jsonBody, codeUoM1C);

                // get body from 1C
                jsonBody.WriteTo(Body);
                if not ConnectTo1C(entityType, requestMethodPOST, Body, filterValue) then exit(false);
                jsonBody.ReadFrom(Body);
                AddIDToIntegrationEntity(lblSystemCode, Database::"Unit of Measure", tempUnitOfMeasure.Code, '',
                                WebServiceMgt.GetJSToken(jsonBody, 'Ref_Key').AsValue().AsText());
            until tempUnitOfMeasure.Next() = 0;

        exit(true);
    end;

    local procedure GetMaximumCode(var codeUoM1C: Text[10]; tempCodeUoM1C: Text[10])
    begin
        if tempCodeUoM1C > codeUoM1C then
            codeUoM1C := tempCodeUoM1C;
    end;

    local procedure GetNextCode(var codeUoM1C: Text[10])
    begin
        if codeUoM1C = '' then
            codeUoM1C := '000000';
        codeUoM1C := IncStr(codeUoM1C);
    end;

    local procedure CreateRequestBodyToUoM(UnitOfMeasureCode: Code[10]; var Body: JsonObject; codeUoM1C: Text[10])
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        UnitOfMeasure.Get(UnitOfMeasureCode);
        Clear(Body);
        Body.Add('Code', codeUoM1C);
        Body.Add('Description', LowerCase(UnitOfMeasureCode));
        Body.Add('НаименованиеПолное', UnitOfMeasure.Description);
    end;

    local procedure AddIDToIntegrationEntity(SystemCode: Code[20]; tableID: Integer; Code1: Code[20]; Code2: Code[20]; entityID: Guid);
    var
        IntegrationEntity: Record "Integration Entity";
    begin
        IntegrationEntity.Init();
        IntegrationEntity."System Code" := SystemCode;
        IntegrationEntity."Table ID" := tableID;
        IntegrationEntity."Code 1" := Code1;
        IntegrationEntity."Code 2" := Code2;
        IntegrationEntity."Entity Id" := entityID;
        IntegrationEntity.Insert(true);
    end;

    procedure GetItemsIdFrom1C(): Boolean
    var
        entityType: Label 'Catalog_Номенклатура';
        requestMethodGET: Label 'GET';
        requestMethodPOST: Label 'POST';
        Body: Text;
        filterValue: Text;
        lblSystemCode: Label '1C';
        lblName: Label 'Iten';
        Item: Record Item;
        tempItem: Record Item temporary;
        IntegrationEntity: Record "Integration Entity";
        ResponceTokenLine: Text;
        jsonLines: JsonArray;
        jsonBody: JsonObject;
        LineToken: JsonToken;
        ItemNo: Code[20];
    begin
        // create UoMs list for getting id from 1C
        if Item.FindSet(false, false) then
            repeat
                if not IntegrationEntity.Get(lblSystemCode, Database::Item, Item."No.", '', CompanyName) then begin
                    tempItem := Item;
                    tempItem.Insert();
                end;
            until Item.Next() = 0;

        // link between 1C МФО and BIC in BC
        if tempItem.Count = 0 then exit(true);

        // get body from 1C
        // if not ConnectTo1C(entityType, requestMethodGET, Body, filterValue) then exit(false);
        // jsonBody.ReadFrom(Body);
        // jsonLines := WebServiceMgt.GetJSToken(jsonBody, 'value').AsArray();
        // foreach LineToken in jsonLines do begin
        //     ItemNo := DelChr(WebServiceMgt.GetJSToken(LineToken.AsObject(), 'Code').AsValue().AsText(), '<>', ' ');
        //     if tempItem.Get(ItemNo) then begin
        //         AddIDToIntegrationEntity(lblSystemCode, Database::Item, tempItem."No.", '',
        //                         WebServiceMgt.GetJSToken(LineToken.AsObject(), 'Ref_Key').AsValue().AsText());
        //         tempItem.Delete();
        //     end;
        // end;

        // create entity in 1C
        // Clear(jsonBody);
        // Clear(jsonLines);
        if tempItem.FindSet(false, false) then
            repeat
                // create request body
                CreateRequestBodyToItems(tempItem."No.", jsonBody);

                // get body from 1C
                jsonBody.WriteTo(Body);
                if not ConnectTo1C(entityType, requestMethodPOST, Body, filterValue) then exit(false);
                jsonBody.ReadFrom(Body);
                AddIDToIntegrationEntity(lblSystemCode, Database::Item, tempItem."No.", '',
                                WebServiceMgt.GetJSToken(jsonBody, 'Ref_Key').AsValue().AsText());
            until tempItem.Next() = 0;

        exit(true);
    end;

    local procedure CreateRequestBodyToItems(ItemNo: Code[20]; var Body: JsonObject)
    var
        Items: Record Item;
    begin
        Items.Get(ItemNo);
        Clear(Body);
        Body.Add('Code', ItemNo);
        Body.Add('Description', Items.Description);
        Body.Add('СтавкаНДС', Items."VAT Prod. Posting Group");
        Body.Add('БазоваяЕдиницаИзмерения_Key', GetItemUoMIdFromIntegrEntity(Items."Base Unit of Measure"));
        Body.Add('ЕдиницыИзмерения', GetJsonItemUoM(ItemNo));
    end;

    local procedure GetJsonItemUoM(ItemNo: Code[20]): JsonArray
    var
        ItemUoM: Record "Item Unit of Measure";
        jsonUoMLine: JsonObject;
        jsonUoMs: JsonArray;
        LineNo: Integer;
    begin
        ItemUoM.SetCurrentKey("Item No.");
        ItemUoM.SetRange("Item No.", ItemNo);
        if ItemUoM.FindSet(false, false) then begin
            Clear(jsonUoMs);
            LineNo := 0;
            repeat
                LineNo += 1;
                Clear(jsonUoMLine);
                jsonUoMLine.Add('LineNumber', LineNo);
                jsonUoMLine.Add('ЕдиницаИзмерения_Key', GetItemUoMIdFromIntegrEntity(ItemUoM.Code));
                jsonUoMLine.Add('Коэффициент', ItemUoM."Qty. per Unit of Measure");
                jsonUoMs.Add(jsonUoMLine);
            until ItemUoM.Next() = 0;
        end;
    end;

    local procedure GetItemUoMIdFromIntegrEntity(ItemUoMCode: Code[10]): Text
    var
        IntegrEntity: Record "Integration Entity";
        lblSystemCode: Label '1C';
    begin
        if IntegrEntity.Get(lblSystemCode, Database::"Unit of Measure", ItemUoMCode, '', CompanyName) then begin
            exit(LowerCase(DelChr(IntegrEntity."Entity Id", '<>', '{}')));
        end;

        // create UoM in 1C
        GetUoMIdFrom1C();
        IntegrEntity.Get(lblSystemCode, Database::"Unit of Measure", ItemUoMCode, '', CompanyName);
        exit(LowerCase(DelChr(IntegrEntity."Entity Id", '<>', '{}')));
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
        // Message(APIResult);

        // response body
        Body := APIResult;

        exit(ResponseMessage.IsSuccessStatusCode);
    end;
}