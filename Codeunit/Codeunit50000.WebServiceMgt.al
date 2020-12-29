codeunit 50000 "Web Service Mgt."
{
    trigger OnRun()
    begin

    end;

    var
        errHeaderAmountNotEqualSumsLinesAmount: Label 'Sales header amount %1 not equal sums sales lines amount %2';
        errSalesOrderAmountCanNotBeLessPrepaymentInvoicesAmount: Label 'Sales order amount %1 can not be less prepayment invoices amount %2';

    procedure ConnectToCRM(connectorCode: Code[20]; entityType: Text[20]; requestMethod: Code[20]; var Body: Text): Boolean
    var
        tokenType: Text;
        accessToken: Text;
        APIResult: Text;
        webServiceHeader: Record "Web Service Header";
        webServiceLine: Record "Web Service Line";
    begin
        if not GetOauthToken(tokenType, accessToken, APIResult) then begin
            Body := APIResult;
            exit(false);
        end;

        if not OnAPIProcess(entityType, requestMethod, tokenType, accessToken, Body) then
            exit(false);
        exit(true);
    end;

    procedure CreateProductInCRM(entityType: Text; requestMethod: Code[20]; tokenType: Text; accessToken: Text; var Body: Text): Boolean
    begin
        if not OnAPIProcess(entityType, requestMethod, tokenType, accessToken, Body) then
            exit(false);
        exit(true);
    end;

    procedure CreatePaymentInCRM(entityType: Text; requestMethod: Code[20]; tokenType: Text; accessToken: Text; var Body: Text): Boolean
    begin
        if not OnAPIProcess(entityType, requestMethod, tokenType, accessToken, Body) then
            exit(false);
        exit(true);
    end;

    procedure GetSpecificationFromCRM(SalesOrderNo: Code[20]; entityType: Text; requestMethod: Code[20]; var Body: Text): Boolean
    begin
        // for testing
        // SalesOrderNo := 'ПРЗК-20-00053';

        GetBodyFromSalesOrderNo(SalesOrderNo, Body);
        if not GetEntity(entityType, requestMethod, Body) then
            exit(false);
        exit(true);
    end;

    procedure GetInvoicesFromCRM(SalesOrderNo: Code[20]; entityType: Text; requestMethod: Code[20]; var Body: Text): Boolean
    begin
        // for testing
        // SalesOrderNo := 'ПРЗК-20-00053';

        GetBodyFromSalesOrderNo(SalesOrderNo, Body);
        if not GetEntity(entityType, requestMethod, Body) then
            exit(false);
        exit(true);
    end;

    local procedure GetBodyFromSalesOrderNo(SalesOrderNo: Code[20]; var Body: Text)
    var
        JSObjectBody: JsonObject;
    begin
        JSObjectBody.Add('document_no', SalesOrderNo);
        JSObjectBody.WriteTo(Body);
    end;

    procedure SetInvoicesLineIdToCRM(SalesOrderNo: Code[20]; entityType: Text; requestMethod: Code[20]; var Body: Text): Boolean
    begin
        // for testing
        // SalesOrderNo := 'ПРЗК-20-00053';

        SetBodyFromSalesOrderNo(SalesOrderNo, Body);
        if StrLen(Body) = 0 then exit(false);

        if not GetEntity(entityType, requestMethod, Body) then
            exit(false);
        exit(true);
    end;

    local procedure SetBodyFromSalesOrderNo(SalesOrderNo: Code[20]; var Body: Text)
    var
        locSalesLine: Record "Sales Line";
        JSObjectBody: JsonArray;
        JSObjectLine: JsonObject;
    begin
        locSalesLine.SetRange("Document Type", locSalesLine."Document Type"::Order);
        locSalesLine.SetRange("Document No.", SalesOrderNo);
        if locSalesLine.FindSet(false, false) then begin
            repeat
                Clear(JSObjectLine);
                JSObjectLine.Add('Line_No', locSalesLine."Line No.");
                JSObjectLine.Add('CRM_ID', locSalesLine."CRM ID");

                JSObjectBody.Add(JSObjectLine);
            until locSalesLine.Next() = 0;

            JSObjectLine.Add('Lines', JSObjectBody);
            JSObjectBody.WriteTo(Body);
        end;
    end;

    local procedure GetEntity(entityType: Text; requestMethod: Code[20]; var Body: Text): Boolean
    var
        webAPI_URL: Label 'https://sprutapi.azurewebsites.net/api/%1';
        ContentType: Label 'Content-Type';
        ContentTypeValue: Label 'application/json';
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        RequestHeader: HttpHeaders;
        BaseURL: Text;
        AuthorizationToken: Text;
    begin
        BaseURL := StrSubstNo(webAPI_URL, entityType);

        RequestMessage.Method := requestMethod;
        RequestMessage.SetRequestUri(BaseURL);
        RequestMessage.GetHeaders(RequestHeader);
        case requestMethod of
            'POST', 'PATCH':
                begin
                    RequestMessage.Content.WriteFrom(Body);
                    RequestMessage.Content.GetHeaders(RequestHeader);
                    RequestHeader.Remove(ContentType);
                    RequestHeader.Add(ContentType, ContentTypeValue);
                end;
        end;

        Client.Send(RequestMessage, ResponseMessage);
        ResponseMessage.Content.ReadAs(Body);
        exit(ResponseMessage.IsSuccessStatusCode);
    end;

    local procedure GetSpecificationAmount(ResponceToken: Text): Decimal
    var
        jsonRespToken: JsonObject;
    begin
        jsonRespToken.ReadFrom(ResponceToken);
        exit(Round(GetJSToken(jsonRespToken, 'order_amount').AsValue().AsDecimal(), 0.01));
    end;

    procedure GetSpecificationLinesArray(ResponceToken: Text): Text
    var
        jsonRespToken: JsonObject;
        jsonRespTokenLines: JsonArray;
        RespTokenLines: Text;
    begin
        jsonRespToken.ReadFrom(ResponceToken);
        jsonRespTokenLines := GetJSToken(jsonRespToken, 'lines').AsArray();
        jsonRespTokenLines.WriteTo(RespTokenLines);
        exit(RespTokenLines);
    end;

    local procedure GetPrepaymentInvoicesAmount(ResponceTokenLines: Text): Decimal
    var
        PrepmInvAmount: Decimal;
        jsonPrepmInv: JsonArray;
        PrepmInvToken: JsonToken;
    begin
        jsonPrepmInv.ReadFrom(ResponceTokenLines);
        foreach PrepmInvToken in jsonPrepmInv do
            PrepmInvAmount += GetJSToken(PrepmInvToken.AsObject(), 'totalamount').AsValue().AsDecimal();

        PrepmInvAmount := Round(PrepmInvAmount, 0.01);
        exit(PrepmInvAmount);
    end;

    local procedure GetSpecificationLinesAmount(ResponceTokenLines: Text): Decimal
    var
        SpecLineAmount: Decimal;
        jsonLines: JsonArray;
        LineToken: JsonToken;
    begin
        jsonLines.ReadFrom(ResponceTokenLines);
        foreach LineToken in jsonLines do
            SpecLineAmount += GetJSToken(LineToken.AsObject(), 'total_amount').AsValue().AsDecimal();

        SpecLineAmount := Round(SpecLineAmount, 0.01);
        exit(SpecLineAmount);
    end;

    local procedure CheckSpecificationAmount(ResponceToken: Text): Decimal
    var
        SpecAmount: Decimal;
        SpecLineAmount: Decimal;
        ResponceTokenLine: Text;
    begin
        SpecAmount := GetSpecificationAmount(ResponceToken);
        ResponceTokenLine := GetSpecificationLinesArray(ResponceToken);
        SpecLineAmount := GetSpecificationLinesAmount(ResponceTokenLine);

        if SpecAmount = SpecLineAmount then
            exit(SpecAmount);

        Error(errHeaderAmountNotEqualSumsLinesAmount, SpecAmount, SpecLineAmount);
    end;

    procedure GetSpecificationAndInvoice(SalesOrderNo: Code[20]; var SpecificationResponseText: Text; var InvoicesResponseText: Text): Boolean
    var
        connectorCode: Label 'CRM';
        SpecEntityType: Label 'specification';
        InvEntityType: Label 'invoice';
        POSTrequestMethod: Label 'POST';
        SpecAmount: Decimal;
        PrepmInvAmount: Decimal;
    begin
        GetSpecificationFromCRM(SalesOrderNo, SpecEntityType, POSTrequestMethod, SpecificationResponseText);
        GetInvoicesFromCRM(SalesOrderNo, InvEntityType, POSTrequestMethod, InvoicesResponseText);

        SpecAmount := CheckSpecificationAmount(SpecificationResponseText);
        PrepmInvAmount := GetPrepaymentInvoicesAmount(InvoicesResponseText);

        // check Specification Amount and Prepayment Amount
        if SpecAmount < PrepmInvAmount then
            Error(errSalesOrderAmountCanNotBeLessPrepaymentInvoicesAmount, SpecAmount, PrepmInvAmount);

        // check sales order for change need
        if SalesOrderChangeNeed(SalesOrderNo, SpecificationResponseText) then
            exit(true);

        // check prepayment invoices for change need
        if PrepaymentInvoicesChangeNeed(SalesOrderNo, InvoicesResponseText) then
            exit(true);

        exit(false);
    end;

    procedure NeedFullUpdateSalesOrder(SalesOrderNo: Code[20]): Boolean
    var
        SpecificationResponseText: Text;
        InvoicesResponseText: Text;
        connectorCode: Label 'CRM';
        SpecEntityType: Label 'specification';
        InvEntityType: Label 'invoice';
        POSTrequestMethod: Label 'POST';
        SpecAmount: Decimal;
        PrepmInvAmount: Decimal;
    begin
        GetSpecificationFromCRM(SalesOrderNo, SpecEntityType, POSTrequestMethod, SpecificationResponseText);
        GetInvoicesFromCRM(SalesOrderNo, InvEntityType, POSTrequestMethod, InvoicesResponseText);

        // check prepayment invoices for change need
        if PrepaymentInvoicesChangeNeed(SalesOrderNo, InvoicesResponseText) then
            exit(true);

        // check sales order for change need
        if SalesOrderFullChangesNeed(SalesOrderNo, SpecificationResponseText) then
            exit(true);

        exit(false);
    end;

    local procedure SalesOrderFullChangesNeed(SalesOrderNo: Code[20]; ResponceToken: Text): Boolean
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SpecAmount: Decimal;
        SpecLineAmount: Decimal;
        LineNo: Integer;
        ItemNo: Text[20];
        Qty: Decimal;
        UnitPrice: Decimal;
        ResponceTokenLine: Text;
        jsonLines: JsonArray;
        LineToken: JsonToken;
    begin
        SpecAmount := GetSpecificationAmount(ResponceToken);
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesOrderNo);
        SalesHeader.CalcFields("Amount Including VAT");

        if SpecAmount <> SalesHeader."Amount Including VAT" then
            exit(true);

        ResponceTokenLine := GetSpecificationLinesArray(ResponceToken);
        jsonLines.ReadFrom(ResponceTokenLine);
        foreach LineToken in jsonLines do begin
            if GetJSToken(LineToken.AsObject(), 'line_no').AsValue().IsNull then
                exit(true);

            LineNo := GetJSToken(LineToken.AsObject(), 'line_no').AsValue().AsInteger();
            ItemNo := GetJSToken(LineToken.AsObject(), 'no').AsValue().AsText();
            Qty := Round(GetJSToken(LineToken.AsObject(), 'quantity').AsValue().AsDecimal(), 0.00001);
            UnitPrice := Round(GetJSToken(LineToken.AsObject(), 'unit_price').AsValue().AsDecimal(), 0.01);
            SpecLineAmount := Round(GetJSToken(LineToken.AsObject(), 'total_amount').AsValue().AsDecimal(), 0.01);

            if not SalesLine.Get(SalesLine."Document Type"::Order, SalesOrderNo, LineNo) then exit(true);
            if SalesLine."No." <> ItemNo then exit(true);
            if SalesLine.Quantity < Qty then exit(true);
            if SalesLine."Unit Price" < UnitPrice then exit(true);
            if SalesLine."Line Amount" < SpecLineAmount then exit(true);
        end;

        foreach LineToken in jsonLines do begin
            LineNo := GetJSToken(LineToken.AsObject(), 'line_no').AsValue().AsInteger();
            ItemNo := GetJSToken(LineToken.AsObject(), 'no').AsValue().AsText();
            Qty := Round(GetJSToken(LineToken.AsObject(), 'quantity').AsValue().AsDecimal(), 0.00001);
            UnitPrice := Round(GetJSToken(LineToken.AsObject(), 'unit_price').AsValue().AsDecimal(), 0.01);
            SpecLineAmount := Round(GetJSToken(LineToken.AsObject(), 'total_amount').AsValue().AsDecimal(), 0.01);

            SalesLine.Get(SalesLine."Document Type"::Order, SalesOrderNo, LineNo);
            if SalesLine.Quantity <> Qty then
                SalesLine.Validate(Quantity, Qty);
            if SalesLine."Unit Price" <> UnitPrice then
                SalesLine.Validate("Unit Price", UnitPrice);
            if SalesLine."Line Amount" <> SpecLineAmount then
                SalesLine.Validate("Line Amount", SpecLineAmount);
            SalesLine.Modify(true);
        end;


        exit(false);
    end;

    local procedure SalesOrderChangeNeed(SalesOrderNo: Code[20]; ResponceToken: Text): Boolean
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SpecAmount: Decimal;
        SpecLineAmount: Decimal;
        LineNo: Integer;
        ItemNo: Text[20];
        Qty: Decimal;
        UnitPrice: Decimal;
        ResponceTokenLine: Text;
        jsonLines: JsonArray;
        LineToken: JsonToken;
    begin
        SpecAmount := GetSpecificationAmount(ResponceToken);
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesOrderNo);
        SalesHeader.CalcFields("Amount Including VAT");

        if SpecAmount <> SalesHeader."Amount Including VAT" then
            exit(true);

        ResponceTokenLine := GetSpecificationLinesArray(ResponceToken);
        jsonLines.ReadFrom(ResponceTokenLine);
        foreach LineToken in jsonLines do begin
            if GetJSToken(LineToken.AsObject(), 'line_no').AsValue().IsNull then
                exit(true);

            LineNo := GetJSToken(LineToken.AsObject(), 'line_no').AsValue().AsInteger();
            ItemNo := GetJSToken(LineToken.AsObject(), 'no').AsValue().AsText();
            Qty := Round(GetJSToken(LineToken.AsObject(), 'quantity').AsValue().AsDecimal(), 0.00001);
            UnitPrice := Round(GetJSToken(LineToken.AsObject(), 'unit_price').AsValue().AsDecimal(), 0.01);
            SpecLineAmount := Round(GetJSToken(LineToken.AsObject(), 'total_amount').AsValue().AsDecimal(), 0.01);

            if not SalesLine.Get(SalesLine."Document Type"::Order, SalesOrderNo, LineNo) then exit(true);
            if SalesLine."No." <> ItemNo then exit(true);
            if SalesLine.Quantity <> Qty then exit(true);
            if SalesLine."Unit Price" <> UnitPrice then exit(true);
            if SalesLine."Line Amount" <> SpecLineAmount then exit(true);
        end;

        exit(false);
    end;

    local procedure PrepaymentInvoicesChangeNeed(SalesOrderNo: Code[20]; ResponceTokenLines: Text): Boolean
    var
        SalesInvHeader: Record "Sales Invoice Header";
        invoiceID: Text[50];
        PrepmInvAmount: Decimal;
        bcPrepmInvAmount: Decimal;
        jsonPrepmInv: JsonArray;
        PrepmInvToken: JsonToken;
    begin
        SalesInvHeader.SetCurrentKey("CRM Invoice No.");
        jsonPrepmInv.ReadFrom(ResponceTokenLines);
        foreach PrepmInvToken in jsonPrepmInv do begin
            invoiceID := GetJSToken(PrepmInvToken.AsObject(), 'invoice_id').AsValue().AsText();
            PrepmInvAmount := Round(GetJSToken(PrepmInvToken.AsObject(), 'totalamount').AsValue().AsDecimal(), 0.01);

            SalesInvHeader.SetRange("CRM Invoice No.", invoiceID);
            if SalesInvHeader.FindSet() then
                repeat
                    SalesInvHeader.CalcFields("Amount Including VAT");
                    bcPrepmInvAmount += SalesInvHeader."Amount Including VAT";
                until SalesInvHeader.Next() = 0;

            if PrepmInvAmount <> bcPrepmInvAmount then
                exit(true);
        end;

        exit(false);
    end;

    local procedure OnAPIProcess(entityType: Text; requestMethod: Code[20]; tokenType: Text; accessToken: Text; var Body: Text): Boolean
    var
        // {{resource}}/api/data/v{{version}}/{{entityType}}
        webAPI_URL: Label '%1/api/data/v%2/%3';
        resource: Label 'https://org3baffe0c.crm4.dynamics.com';
        version: Label '9.1';
        Accept: Label 'Accept';
        Prefer: Label 'Prefer';
        Authorization: Label 'Authorization';
        AcceptValue: Label 'application/json';
        PreferValue: Label 'return=representation';
        ContentType: Label 'Content-Type';
        ContentTypeValue: Label 'application/json';
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        RequestHeader: HttpHeaders;
        BaseURL: Text;
        AuthorizationToken: Text;
    begin
        BaseURL := StrSubstNo(webAPI_URL, resource, version, entityType);
        AuthorizationToken := StrSubstNo('%1 %2', tokenType, accessToken);

        RequestMessage.Method := requestMethod;
        RequestMessage.SetRequestUri(BaseURL);
        RequestMessage.GetHeaders(RequestHeader);
        RequestHeader.Add(Authorization, AuthorizationToken);
        case requestMethod of
            'POST', 'PATCH':
                begin
                    RequestMessage.Content.WriteFrom(Body);
                    RequestMessage.Content.GetHeaders(RequestHeader);
                    RequestHeader.Remove(ContentType);
                    RequestHeader.Add(ContentType, ContentTypeValue);
                    RequestHeader.Add(Prefer, PreferValue);
                end;
        end;

        Client.Send(RequestMessage, ResponseMessage);
        ResponseMessage.Content.ReadAs(Body);
        exit(ResponseMessage.IsSuccessStatusCode);
    end;

    procedure GetOauthToken(var TokenType: Text; var AccessToken: Text; var APIResult: Text): Boolean
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

        if ResponseMessage.IsSuccessStatusCode() then begin
            GetTokenFromResponse(APIResult, TokenType, AccessToken);
            exit(true);
        end;
        exit(false);
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
    procedure GetJSToken(_JSONObject: JsonObject; TokenKey: Text) _JSONToken: JsonToken
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

    procedure jsonItemsToPost(ItemNo: Code[20]): JsonObject
    var
        locItems: Record Item;
        JSObjectLine: JsonObject;
        salesTypeCode: Label '799810002';
        defaultUoMScheduleId: Label '/uomschedules(422fde89-3e76-45f2-b9e6-9d59c8bbc311)';
        defaultUoMId: Label '/uoms(d91f3b4e-f4cc-4063-8f7a-8d365d5922ff)';
        quantityDecimal: Integer;
    begin
        quantitydecimal := 2;
        if locItems.Get(ItemNo) then begin
            JSObjectLine.Add('tct_salestypecode', salesTypeCode);
            JSObjectLine.Add('productnumber', locItems."No.");
            JSObjectLine.Add('name', locItems.Description);
            JSObjectLine.Add('defaultuomscheduleid@odata.bind', defaultUoMScheduleId);
            JSObjectLine.Add('defaultuomid@odata.bind', defaultUoMId);
            JSObjectLine.Add('quantitydecimal', quantityDecimal);
            JSObjectLine.Add('tct_bc_product_number', locItems."No.");
            JSObjectLine.Add('tct_bc_uomid', locItems."Sales Unit of Measure");
        end;
        exit(JSObjectLine);
    end;

    procedure jsonItemsToPatch(ItemNo: Code[20]): JsonObject
    var
        locItems: Record Item;
        JSObjectLine: JsonObject;
        salesTypeCode: Label '799810002';
        defaultUoMScheduleId: Label '/uomschedules(422fde89-3e76-45f2-b9e6-9d59c8bbc311)';
        defaultUoMId: Label '/uoms(d91f3b4e-f4cc-4063-8f7a-8d365d5922ff)';
        quantityDecimal: Integer;
    begin
        quantitydecimal := 2;
        if locItems.Get(ItemNo) then begin
            JSObjectLine.Add('tct_salestypecode', salesTypeCode);
            // JSObjectLine.Add('productnumber', locItems."No.");
            JSObjectLine.Add('name', locItems.Description);
            JSObjectLine.Add('defaultuomscheduleid@odata.bind', defaultUoMScheduleId);
            JSObjectLine.Add('defaultuomid@odata.bind', defaultUoMId);
            JSObjectLine.Add('quantitydecimal', quantityDecimal);
            JSObjectLine.Add('tct_bc_product_number', locItems."No.");
            JSObjectLine.Add('tct_bc_uomid', locItems."Sales Unit of Measure");
        end;
        exit(JSObjectLine);
    end;

    procedure jsonPaymentToPost(salesOrderId: Text[50]; invoiceId: Text[50]; payerDetails: Text[100]; paymentAmount: Decimal): JsonObject
    var
        JSObjectLine: JsonObject;
        lblSalesOrderId: Label '/salesorders(%1)';
        lblInvoiceId: Label '/invoices(%1)';
        lblTransactionCurrencyId: Label '/transactioncurrencies(d8b0ca73-7060-ea11-a811-000d3ab9be86)';
    begin
        salesOrderId := StrSubstNo(lblSalesOrderId, salesOrderId);
        invoiceId := StrSubstNo(lblInvoiceId, invoiceId);

        JSObjectLine.Add('tct_salesorderid@odata.bind', salesOrderId);
        JSObjectLine.Add('tct_payerdetails', payerDetails);
        JSObjectLine.Add('tct_amount', paymentAmount);
        JSObjectLine.Add('tct_invoiceid@odata.bind', invoiceId);
        JSObjectLine.Add('transactioncurrencyid@odata.bind', lblTransactionCurrencyId);

        exit(JSObjectLine);
    end;

    procedure jsonPaymentToPatch(): JsonObject
    var
        JSObjectLine: JsonObject;
    begin
        JSObjectLine.Add('statuscode', 0);
        exit(JSObjectLine);
    end;

    procedure AddCRMproductIdToItem(jsonText: Text)
    var
        locItem: Record Item;
        ItemToken: JsonToken;
        ItemToken2: JsonToken;
        ItemNo: Text[20];
        CRMproductId: Text[50];
    begin
        ItemToken.ReadFrom(jsonText);
        if ItemToken.AsObject().Get('tct_bc_product_number', ItemToken2) then begin
            ItemNo := GetJSToken(ItemToken.AsObject(), 'tct_bc_product_number').AsValue().AsText();
            CRMproductId := GetJSToken(ItemToken.AsObject(), 'productid').AsValue().AsText();
            if locItem.Get(ItemNo) then begin
                locItem."CRM Item Id" := CRMproductId;
                locItem.Modify();
            end;
        end;
    end;

    procedure AddCRMpaymentIdToPayment(jsonText: Text; crmInvoiceNo: Code[50])
    var
        locDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        PaymentToken: JsonToken;
        PaymentToken2: JsonToken;
        ItemNo: Text[20];
        CRMpaymentId: Text[50];
    begin
        PaymentToken.ReadFrom(jsonText);
        if PaymentToken.AsObject().Get('tct_paymentid', PaymentToken2) then begin
            CRMpaymentId := GetJSToken(PaymentToken.AsObject(), 'tct_paymentid').AsValue().AsText();

            locDtldCustLedgEntry.SetCurrentKey("CRM Invoice No.");
            locDtldCustLedgEntry.SetRange("CRM Invoice No.", crmInvoiceNo);
            locDtldCustLedgEntry.ModifyAll("CRM Payment Id", CRMpaymentId);
        end;
    end;

    procedure SendToEmail(SalesOrderNo: Code[20])
    var
        recUser: Record User;
        ToAddr: List of [Text];
        SalesHeader: Record "Sales Header";
        RecRef: RecordRef;
        text001: Label 'Email Sended';
        text002: Label 'Email address not present, go to User page and fill Contact Email field.';
        text003: Label 'User not identified';
    begin
        //read user email config
        recUser.Reset();
        recUser.SetFilter("User Security ID", UserSecurityId());
        if recUser.FindFirst() then begin

            //Send email after report building
            if recUser."Contact Email" <> '' then begin
                ToAddr.Add(recUser."Contact Email");   //contact email on User
                SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
                SalesHeader.SetRange("No.", SalesOrderNo);
                Clear(RecRef);
                RecRef.GetTable(SalesHeader);

                //send
                // ReportSendMail(ReportToSend: Integer; Recordr: RecordRef; ToAddr: List of [Text]; Subject: Text[100]; Body: Text[100]; AttachmentName: Text[100])
                if ReportSendMail(50000, RecRef, ToAddr, SalesHeader."No.", 'Sales Prepayment Invoices for Sales Order ' + SalesHeader."No.", SalesHeader."No." + '_' + SalesHeader."Sell-to Customer Name" + '_PrepmInv' + '.pdf') then
                    Message(text001);
            end
            else
                Message(text002);
        end
        else
            Message(text003);
    end;

    local procedure ReportSendMail(ReportToSend: Integer; Recordr: RecordRef; ToAddr: List of [Text]; Subject: Text[100]; Body: Text[100]; AttachmentName: Text[100]): Boolean
    var
        outStreamReport: OutStream;
        inStreamReport: InStream;
        Parameters: Text;
        tempBlob: Codeunit "Temp Blob";
        Base64EncodedString: Text;
        Mail: Codeunit "SMTP Mail";
        SmtpConf: Record "SMTP Mail Setup";
    begin
        //SMTP
        SmtpConf.Get();
        TempBlob.CreateOutStream(outStreamReport);
        TempBlob.CreateInStream(inStreamReport);

        //Print Report
        Report.SaveAs(ReportToSend, Parameters, ReportFormat::Pdf, outStreamReport, Recordr);

        //Create mail
        Clear(Mail);
        Mail.CreateMessage('Business Central Mailing System', SmtpConf."User ID", ToAddr, Subject, Body);
        Mail.AddAttachmentStream(inStreamReport, AttachmentName);

        //Send mail
        exit(Mail.Send());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Payment Registration Mgt.", 'OnBeforeGenJnlLineInsert', '', false, false)]
    local procedure OnBeforeGenJournalLineInsert(TempPaymentRegistrationBuffer: Record "Payment Registration Buffer"; var GenJournalLine: Record "Gen. Journal Line")
    var
        TaskPaymentSend: Record "Task Payment Send";
    begin
        TaskPaymentSend.Init();
        TaskPaymentSend."Invoice Entry No." := TempPaymentRegistrationBuffer."Ledger Entry No.";
        TaskPaymentSend."Invoice No." := TempPaymentRegistrationBuffer."Document No.";
        // 
        TaskPaymentSend."Payment No." := GenJournalLine."Document No.";
        TaskPaymentSend."Payment Amount" := Abs(GenJournalLine.Amount);
        TaskPaymentSend.Insert(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Payment Registration Mgt.", 'OnAfterPostPaymentRegistration', '', false, false)]
    local procedure OnAfterPostPaymentRegistration(TempPaymentRegistrationBuffer: Record "Payment Registration Buffer")
    var
        TaskPaymentSend: Record "Task Payment Send";
    begin
        TaskPaymentSend.SetCurrentKey(Status, "Work Status", "Invoice Entry No.", "Invoice No.", "Payment No.", "Payment Amount");
        TaskPaymentSend.SetRange("Invoice Entry No.", TempPaymentRegistrationBuffer."Ledger Entry No.");
        TaskPaymentSend.SetRange("Invoice No.", TempPaymentRegistrationBuffer."Document No.");
        TaskPaymentSend.SetRange("Payment Amount", TempPaymentRegistrationBuffer."Amount Received");
        // to do
        TaskPaymentSend."Payment Entry No." := 0;
        TaskPaymentSend.Modify(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CustEntry-Apply Posted Entries", 'OnBeforePostApplyCustLedgEntry', '', false, false)]
    local procedure OnBeforePostApplyCustLedgEntry(CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        if CustLedgerEntry."Document Type" <> CustLedgerEntry."Document Type"::Invoice then exit;
        InsertTaskPaymentSend(CustLedgerEntry."Entry No.", CustLedgerEntry."Document No.", CustLedgerEntry."Customer No.", CustLedgerEntry."Applies-to ID");
    end;

    local procedure InsertTaskPaymentSend(InvoiceEntryNo: Integer; InvoiceNo: Code[20]; CustomerNo: Code[20]; AppliestoID: Code[50])
    var
        locCLE: Record "Cust. Ledger Entry";
        TaskPaymentSend: Record "Task Payment Send";
    begin
        locCLE.SetCurrentKey("Customer No.", "Applies-to ID", "Document Type");
        locCLE.SetRange("Customer No.", CustomerNo);
        locCLE.SetRange("Applies-to ID", AppliestoID);
        locCLE.SetRange("Document Type", locCLE."Document Type"::Payment);
        if locCLE.FindSet(false, false) then
            repeat
                TaskPaymentSend.Init();
                TaskPaymentSend."Invoice Entry No." := InvoiceEntryNo;
                TaskPaymentSend."Invoice No." := InvoiceNo;
                TaskPaymentSend."Payment Entry No." := locCLE."Entry No.";
                TaskPaymentSend."Payment No." := locCLE."Document No.";
                TaskPaymentSend."Payment Amount" := Abs(locCLE."Amount to Apply");
                TaskPaymentSend.Insert(true);
            until locCLE.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, 226, 'OnAfterPostUnapplyCustLedgEntry', '', false, false)]
    local procedure OnAfterPostUnapplyCustLedgEntry(DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        SalesInvHeader: Record "Sales Invoice Header";
        CustAgreement: Record "Customer Agreement";
    begin
        if (DetailedCustLedgEntry."Entry Type" = DetailedCustLedgEntry."Entry Type"::Application)
        and (DetailedCustLedgEntry."Document Type" = DetailedCustLedgEntry."Document Type"::Payment)
        and (CustLedgerEntry."Document Type" = CustLedgerEntry."Document Type"::Invoice) then begin
            if SalesInvHeader.Get(CustLedgerEntry."Document No.")
            and (SalesInvHeader."CRM Invoice No." <> '') then begin
                if CustAgreement.Get(SalesInvHeader."Sell-to Customer No.", SalesInvHeader."Agreement No.")
                    and not IsNullGuid(CustAgreement."CRM ID") then
                    // sent to CRM payment with amount equal 0
                    SendPaymentToCRM(SalesInvHeader."CRM Header ID", '', 0, SalesInvHeader."CRM Invoice No.", SalesInvHeader."CRM ID", DetailedCustLedgEntry."CRM Payment Id");
            end;
        end;
    end;

    procedure SendPaymentToCRM(custAgreementId: Guid; PayerDetails: Text[100]; paymentAmount: Decimal; crmInvoiceNo: Text[50]; crmId: Guid; crmPaymentId: Guid)
    var
        _jsonErrorItemList: JsonArray;
        _jsonPayment: JsonObject;
        _jsonToken: JsonToken;
        _jsonText: Text;
        TotalCount: Integer;
        Counter: Integer;
        responseText: Text;
        connectorCode: Label 'CRM';
        entityType: Label 'tct_payments';
        POSTrequestMethod: Label 'POST';
        PATCHrequestMethod: Label 'PATCH';
        TokenType: Text;
        AccessToken: Text;
        APIResult: Text;
        requestMethod: Text[20];
        entityTypeValue: Text;
    begin

        // >> init for test
        custAgreementId := '446e2ca1-35a6-ea11-a812-000d3aba77ea';
        crmId := '93dd43f3-e5a3-ea11-a812-000d3abaae50';
        payerDetails := 'test payment from BC';
        paymentAmount := 155;
        // <<

        Counter := 0;
        TotalCount := 1;

        if not GetOauthToken(TokenType, AccessToken, APIResult) then begin
            // loging error APIResult
            _jsonPayment.ReadFrom(APIResult);
            _jsonErrorItemList.Add(_jsonPayment);
        end;

        if _jsonErrorItemList.Count = 0 then begin

            // Create JSON for CRM
            if IsNullGuid(crmPaymentId) then begin
                requestMethod := POSTrequestMethod;
                entityTypeValue := entityType;
                _jsonPayment := jsonPaymentToPost(custAgreementId, crmId, payerDetails, paymentAmount);
            end else begin
                requestMethod := PATCHrequestMethod;
                entityTypeValue := StrSubstNo('%1(%2)', entityType, crmPaymentId);
                _jsonPayment := jsonPaymentToPatch();
            end;

            _jsonPayment.WriteTo(_jsonText);
            Counter += 1;

            // try send to CRM
            if not CreatePaymentInCRM(entityTypeValue, requestMethod, TokenType, AccessToken, _jsonText) then begin
                _jsonErrorItemList.Add(_jsonPayment);
                _jsonPayment.ReadFrom(_jsonText);
                _jsonErrorItemList.Add(_jsonPayment);
            end else
                // add CRM product ID to Item
                AddCRMpaymentIdToPayment(_jsonText, crmInvoiceNo);
        end;
        if _jsonErrorItemList.Count > 0 then;
    end;
}