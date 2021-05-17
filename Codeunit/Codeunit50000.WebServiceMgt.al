codeunit 50000 "Web Service Mgt."
{
    trigger OnRun()
    begin

    end;

    var
        IntegrationLog: Record "Integration Log";
        errHeaderAmountNotEqualSumsLinesAmount: Label 'Sales header amount %1 not equal sums sales lines amount %2';
        errSalesOrderAmountCanNotBeLessPrepaymentInvoicesAmount: Label 'Sales order amount %1 can not be less prepayment invoices amount %2';
        errReportNotSavedToPDF: Label 'Report %1 not saved to PDF';
        errWrong_CRM_Id: Label 'Wrong CRM Id %1';
        WebServiceMgt: Codeunit "Web Service Mgt.";
        ModificationOrder: Codeunit "Modification Order";
        PrepmtMgt: Codeunit "Prepayment Management";
        errDescriptionCannotBeEmpty: Label '''description'' cannot be empty';


    procedure ConnectToCRM(connectorCode: Code[20]; entityType: Text[20]; requestMethod: Code[20]; var Body: Text): Boolean
    var
        tokenType: Text;
        accessToken: Text;
        APIResult: Text;
        webServiceHeader: Record "Web Service Header";
        webServiceLine: Record "Web Service Line";
    begin
        // if not GetOauthToken(tokenType, accessToken, APIResult) then begin
        //     Body := APIResult;
        //     Error(Body);
        // end;

        GetOauthToken(tokenType, accessToken, APIResult);
        OnAPIProcess(entityType, requestMethod, tokenType, accessToken, Body);
        exit(true);
    end;

    procedure CreateProductInCRM(entityType: Text; requestMethod: Code[20]; tokenType: Text; accessToken: Text; var Body: Text): Boolean
    begin
        if OnAPIProcess(entityType, requestMethod, tokenType, accessToken, Body) then
            exit(true);
    end;

    procedure CreatePaymentInCRM(entityType: Text; requestMethod: Code[20]; tokenType: Text; accessToken: Text; var Body: Text): Boolean
    begin
        if OnAPIProcess(entityType, requestMethod, tokenType, accessToken, Body) then
            exit(true);
    end;

    procedure GetSpecificationFromCRM(SalesOrderNo: Code[20]; entityType: Text; requestMethod: Code[20]; var Body: Text): Boolean
    begin
        GetBodyFromSalesOrderNo(SalesOrderNo, Body);
        if GetEntity(entityType, requestMethod, Body) then
            exit(true);
    end;

    procedure GetInvoicesFromCRM(SalesOrderNo: Code[20]; entityType: Text; requestMethod: Code[20]; var Body: Text): Boolean
    begin
        GetBodyFromSalesOrderNo(SalesOrderNo, Body);
        if GetEntity(entityType, requestMethod, Body) then
            exit(true);
    end;

    local procedure GetBodyFromSalesOrderNo(SalesOrderNo: Code[20]; var Body: Text)
    var
        JSObjectBody: JsonObject;
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesOrderNo);
        JSObjectBody.Add('document_no', SalesOrderNo);
        JSObjectBody.Add('crm_id', LowerCase(DelChr(SalesHeader."CRM Header ID", '<>', '{}')));
        JSObjectBody.WriteTo(Body);
    end;

    procedure SetInvoicesLineIdToCRM(SalesOrderNo: Code[20]; entityType: Text; requestMethod: Code[20]; var Body: Text): Boolean
    var
        JSObjectLine: JsonObject;
    begin
        // for testing
        // SalesOrderNo := 'ПРЗК-20-00053';

        SetBodyFromSalesOrderNo(SalesOrderNo, Body);
        SetBodyFromPostedInvoices(SalesOrderNo, Body);
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
                JSObjectLine.Add('Line_No', Format(locSalesLine."Line No."));
                JSObjectLine.Add('CRM_ID', LowerCase(DelChr(locSalesLine."CRM ID", '<>', '{}')));

                JSObjectBody.Add(JSObjectLine);
            until locSalesLine.Next() = 0;

            Clear(JSObjectLine);
            JSObjectLine.Add('Lines', JSObjectBody);
            JSObjectLine.WriteTo(Body);
        end;
    end;

    local procedure SetBodyFromPostedInvoices(SalesOrderNo: Code[20]; var Body: Text)
    var
        locSalesInvHeader: Record "Sales Invoice Header";
        JSObjectBody: JsonArray;
        JSObjectLine: JsonObject;
    begin
        locSalesInvHeader.SetCurrentKey("Prepayment Order No.");
        locSalesInvHeader.SetRange("Prepayment Order No.", SalesOrderNo);
        locSalesInvHeader.SetFilter("CRM Invoice No.", '<>%1', '');
        if locSalesInvHeader.FindSet(false, false) then begin
            repeat
                Clear(JSObjectLine);
                JSObjectLine.Add('number', locSalesInvHeader."No.");
                JSObjectLine.Add('postedInvoiceNo', locSalesInvHeader."CRM Invoice No.");

                JSObjectBody.Add(JSObjectLine);
            until locSalesInvHeader.Next() = 0;

            Clear(JSObjectLine);
            if StrLen(Body) <> 0 then
                JSObjectLine.ReadFrom(Body);
            JSObjectLine.Add('PostedInvoices', JSObjectBody);
            JSObjectLine.WriteTo(Body);
        end;
    end;

    local procedure GetEntity(entityType: Text; requestMethod: Code[20]; var Body: Text): Boolean
    var
        webAPI_URL: Label 'https://sprutapi.azurewebsites.net/api/%1';
        ContentType: Label 'Content-Type';
        ContentTypeValue: Label 'application/json';
        EnvironmentType: Label 'Environment';
        EnvironmentTypeValue: Label 'Production';
        CompanyNameType: Label 'CompanyName';
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        RequestBody: Text;
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
                    if not GetResourceProductionNotAllowed() then
                        RequestHeader.Add(EnvironmentType, EnvironmentTypeValue);
                end;
        end;

        Client.Send(RequestMessage, ResponseMessage);
        RequestBody := Body;
        ResponseMessage.Content.ReadAs(Body);

        // Insert Operation to Log
        IntegrationLog.InsertOperationToLog('CUSTOM_CRM_API', requestMethod, BaseURL, '', RequestBody, Body, ResponseMessage.IsSuccessStatusCode());
        if ResponseMessage.IsSuccessStatusCode then
            exit(ResponseMessage.IsSuccessStatusCode);

        Error(Body);
    end;

    local procedure GetSpecificationAmount(ResponceToken: Text): Decimal
    var
        jsonRespToken: JsonObject;
    begin
        jsonRespToken.ReadFrom(ResponceToken);
        exit(Round(GetJSToken(jsonRespToken, 'order_amount').AsValue().AsDecimal(), 0.01));
    end;

    procedure GetSpecificationLocationCode(ResponceToken: Text): Code[20]
    var
        jsonRespToken: JsonObject;
    begin
        jsonRespToken.ReadFrom(ResponceToken);
        exit(GetJSToken(jsonRespToken, 'location_code').AsValue().AsText());
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
        foreach PrepmInvToken in jsonPrepmInv do begin
            CheckPrepmtInvoiceToken(PrepmInvToken);
            PrepmInvAmount += GetJSToken(PrepmInvToken.AsObject(), 'totalamount').AsValue().AsDecimal();
        end;

        PrepmInvAmount := Round(PrepmInvAmount, 0.01);
        exit(PrepmInvAmount);
    end;

    local procedure CheckPrepmtInvoiceToken(LineToken: JsonToken)
    var
        document_no: Text[20];
        invoice_id: Text[30];
        prepayment_percent: Decimal;
        crm_id: Guid;
    begin
        document_no := GetJSToken(LineToken.AsObject(), 'document_no').AsValue().AsText();
        invoice_id := GetJSToken(LineToken.AsObject(), 'invoice_id').AsValue().AsText();
        prepayment_percent := GetJSToken(LineToken.AsObject(), 'prepayment_percent').AsValue().AsDecimal();
        crm_id := GetJSToken(LineToken.AsObject(), 'crm_id').AsValue().AsText();
        if IsNullGuid(crm_id) then
            Error(errWrong_CRM_Id, crm_id);
    end;

    local procedure GetSpecificationLinesAmount(ResponceTokenLines: Text): Decimal
    var
        SpecLineAmount: Decimal;
        jsonLines: JsonArray;
        LineToken: JsonToken;
    begin
        jsonLines.ReadFrom(ResponceTokenLines);
        foreach LineToken in jsonLines do begin
            CheckSalesLineToken(LineToken);
            SpecLineAmount += GetJSToken(LineToken.AsObject(), 'total_amount').AsValue().AsDecimal();
        end;

        SpecLineAmount := Round(SpecLineAmount, 0.01);
        exit(SpecLineAmount);
    end;

    local procedure CheckSalesLineToken(LineToken: JsonToken)
    var
        ItemNo: Code[20];
        Qty: Decimal;
        UnitPrice: Decimal;
        LineAmount: Decimal;
        crmLineID: Guid;
    begin
        ItemNo := GetJSToken(LineToken.AsObject(), 'no').AsValue().AsText();
        Qty := GetJSToken(LineToken.AsObject(), 'quantity').AsValue().AsDecimal();
        UnitPrice := GetJSToken(LineToken.AsObject(), 'unit_price').AsValue().AsDecimal();
        LineAmount := GetJSToken(LineToken.AsObject(), 'total_amount').AsValue().AsDecimal();
        crmLineID := GetJSToken(LineToken.AsObject(), 'CRM_ID').AsValue().AsText();
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
        if PrepaymentInvoicesChangesNeed(SalesOrderNo, InvoicesResponseText) then
            exit(true);

        // update sales line
        // to do

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
        // GetSpecificationFromCRM(SalesOrderNo, SpecEntityType, POSTrequestMethod, SpecificationResponseText);
        SpecificationResponseText := ModificationOrder.GetSpecificationFromTask(SalesOrderNo);

        // check sales order for change need
        if SalesOrderFullChangesNeed(SalesOrderNo, SpecificationResponseText) then
            exit(true);

        // GetInvoicesFromCRM(SalesOrderNo, InvEntityType, POSTrequestMethod, InvoicesResponseText);
        InvoicesResponseText := ModificationOrder.GetInvoicesFromTask(SalesOrderNo);

        // check prepayment invoices for change need
        if PrepaymentInvoicesChangesNeed(SalesOrderNo, InvoicesResponseText) then
            exit(true);

        exit(false);
    end;

    procedure NeedCreatePrepmtInvoice(SalesOrderNo: Code[20]): Boolean
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
        // GetInvoicesFromCRM(SalesOrderNo, InvEntityType, POSTrequestMethod, InvoicesResponseText);
        InvoicesResponseText := ModificationOrder.GetInvoicesFromTask(SalesOrderNo);
        // check prepayment invoices for change need
        if PrepaymentInvoicesAddedNeed(SalesOrderNo, InvoicesResponseText) then
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
        crmLineId: Guid;
        ResponceTokenLine: Text;
        jsonLines: JsonArray;
        LineToken: JsonToken;
        LocationCode: Code[20];
        countSL: Integer;
        modifiedSL: Boolean;
        statusSH: Enum "Sales Document Status";
        Description: Text[100];
    begin
        SpecAmount := GetSpecificationAmount(ResponceToken);

        ResponceTokenLine := GetSpecificationLinesArray(ResponceToken);
        jsonLines.ReadFrom(ResponceTokenLine);

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesOrderNo);
        if SalesLine.FindSet(false, false) then
            repeat
                SalesLine.Mark(true);
            until SalesLine.Next() = 0;

        foreach LineToken in jsonLines do begin
            if not GetJSToken(LineToken.AsObject(), 'line_no').AsValue().IsNull then begin
                // exit(true);
                LineNo := GetJSToken(LineToken.AsObject(), 'line_no').AsValue().AsInteger();
                ItemNo := GetJSToken(LineToken.AsObject(), 'no').AsValue().AsText();

                Description := GetJSToken(LineToken.AsObject(), 'description').AsValue().AsText();
                if Description = '' then Error(errDescriptionCannotBeEmpty);

                Qty := Round(GetJSToken(LineToken.AsObject(), 'quantity').AsValue().AsDecimal(), 0.00001);
                UnitPrice := Round(GetJSToken(LineToken.AsObject(), 'unit_price').AsValue().AsDecimal(), 0.01);
                SpecLineAmount := Round(GetJSToken(LineToken.AsObject(), 'total_amount').AsValue().AsDecimal(), 0.01);
                crmLineId := GetJSToken(LineToken.AsObject(), 'CRM_ID').AsValue().AsText();

                if SalesLine.Get(SalesLine."Document Type"::Order, SalesOrderNo, LineNo) then begin
                    if SalesLine."No." <> ItemNo then exit(true);
                    if SalesLine.Description <> Description then exit(true);
                    if SalesLine.Quantity > Qty then exit(true);
                    if SalesLine."Unit Price" > UnitPrice then exit(true);
                    // if SalesLine."Line Amount" > SpecLineAmount then exit(true);
                    if SalesLine."Prepmt. Amt. Inv." > SpecLineAmount then exit(true);
                    if (LowerCase(DelChr(SalesLine."CRM ID", '<>', '{}')) <> crmLineId) and not IsNullGuid(crmLineId) then begin
                        SalesLine.Validate("CRM ID", crmLineId);
                        SalesLine.Modify();
                    end;
                    SalesLine.Mark(false);
                end;
            end;
        end;

        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesOrderNo);
        if SalesHeader.Status <> SalesHeader.Status::Open then begin
            statusSH := SalesHeader.Status;
            SalesHeader.Status := SalesHeader.Status::Open;
            SalesHeader.Modify();
        end;

        SalesLine.MarkedOnly(true);
        if SalesLine.FindSet(false, false) then
            repeat
                if SalesLine."Prepmt. Amt. Inv." <> 0 then exit(true);
            until SalesLine.Next() = 0;
        SalesLine.DeleteAll(true);

        LocationCode := WebServiceMgt.GetSpecificationLocationCode(ResponceToken);
        ChangeSalesOrderLocationCode(SalesHeader, LocationCode);

        // update sales line
        foreach LineToken in jsonLines do begin
            if not GetJSToken(LineToken.AsObject(), 'line_no').AsValue().IsNull then
                LineNo := GetJSToken(LineToken.AsObject(), 'line_no').AsValue().AsInteger()
            else
                LineNo := 0;
            ItemNo := GetJSToken(LineToken.AsObject(), 'no').AsValue().AsText();
            Description := GetJSToken(LineToken.AsObject(), 'description').AsValue().AsText();
            Qty := Round(GetJSToken(LineToken.AsObject(), 'quantity').AsValue().AsDecimal(), 0.00001);
            UnitPrice := Round(GetJSToken(LineToken.AsObject(), 'unit_price').AsValue().AsDecimal(), 0.01);
            SpecLineAmount := Round(GetJSToken(LineToken.AsObject(), 'total_amount').AsValue().AsDecimal(), 0.01);
            crmLineId := GetJSToken(LineToken.AsObject(), 'CRM_ID').AsValue().AsText();

            if SalesLine.Get(SalesLine."Document Type"::Order, SalesOrderNo, LineNo) then begin

                modifiedSL := false;
                if SalesLine.Description <> Description then begin
                    SalesLine.Validate(Description, Description);
                    modifiedSL := true;
                end;
                if SalesLine.Quantity <> Qty then begin
                    SalesLine.Validate(Quantity, Qty);
                    modifiedSL := true;
                end;
                if SalesLine."Unit Price" <> UnitPrice then begin
                    SalesLine.Validate("Unit Price", UnitPrice);
                    modifiedSL := true;
                end;
                if SalesLine."Line Amount" <> SpecLineAmount then begin
                    SalesLine.Validate("Line Amount", SpecLineAmount);
                    modifiedSL := true;
                end;
                if (LowerCase(DelChr(SalesLine."CRM ID", '<>', '{}')) <> crmLineId)
                and not IsNullGuid(crmLineId) then begin
                    SalesLine.Validate("CRM ID", crmLineId);
                    modifiedSL := true;
                end;
                if modifiedSL then
                    SalesLine.Modify(true);
            end else begin
                PrepmtMgt.InsertNewSalesLine(SalesOrderNo, ItemNo, Description, Qty, UnitPrice, SpecLineAmount, crmLineID);
            end;
        end;

        if statusSH <> statusSH::Open then begin
            SalesHeader.Status := statusSH;
            SalesHeader.Modify(true);
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
        LocationCode: Code[20];
        Location: Record Location;
        Description: Text[100];
    begin
        SpecAmount := GetSpecificationAmount(ResponceToken);
        LocationCode := GetSpecificationLocationCode(ResponceToken);
        if LocationCode <> '' then
            Location.Get(LocationCode);
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesOrderNo);
        if (LocationCode <> '') and (SalesHeader."Location Code" <> LocationCode) then
            exit(true);

        SalesHeader.CalcFields("Amount Including VAT");
        if SalesHeader."Amount Including VAT" <> SpecAmount then
            exit(true);

        ResponceTokenLine := GetSpecificationLinesArray(ResponceToken);
        jsonLines.ReadFrom(ResponceTokenLine);
        foreach LineToken in jsonLines do begin
            if GetJSToken(LineToken.AsObject(), 'line_no').AsValue().IsNull then
                exit(true);

            LineNo := GetJSToken(LineToken.AsObject(), 'line_no').AsValue().AsInteger();
            ItemNo := GetJSToken(LineToken.AsObject(), 'no').AsValue().AsText();

            Description := GetJSToken(LineToken.AsObject(), 'description').AsValue().AsText();
            if Description = '' then Error(errDescriptionCannotBeEmpty);

            Qty := Round(GetJSToken(LineToken.AsObject(), 'quantity').AsValue().AsDecimal(), 0.00001);
            UnitPrice := Round(GetJSToken(LineToken.AsObject(), 'unit_price').AsValue().AsDecimal(), 0.01);
            SpecLineAmount := Round(GetJSToken(LineToken.AsObject(), 'total_amount').AsValue().AsDecimal(), 0.01);

            if not SalesLine.Get(SalesLine."Document Type"::Order, SalesOrderNo, LineNo) then exit(true);
            if SalesLine."No." <> ItemNo then exit(true);
            if SalesLine.Description <> Description then exit(true);
            if SalesLine.Quantity <> Qty then exit(true);
            if SalesLine."Unit Price" <> UnitPrice then exit(true);
            if SalesLine."Line Amount" <> SpecLineAmount then exit(true);
        end;

        exit(false);
    end;

    local procedure PrepaymentInvoicesAddedNeed(SalesOrderNo: Code[20]; ResponceTokenLines: Text): Boolean
    var
        SalesInvHeader: Record "Sales Invoice Header";
        invoiceID: Text[50];
        PrepmInvAmount: Decimal;
        bcPrepmInvAmount: Decimal;
        jsonPrepmInv: JsonArray;
        PrepmInvToken: JsonToken;
        CountInvoiceCRM: Integer;
        CountSalesInv: Integer;
    begin
        jsonPrepmInv.ReadFrom(ResponceTokenLines);
        CountInvoiceCRM := jsonPrepmInv.Count;

        SalesInvHeader.SetCurrentKey("Prepayment Order No.", "CRM Invoice No.");
        SalesInvHeader.SetRange("Prepayment Order No.", SalesOrderNo);
        SalesInvHeader.SetFilter("CRM Invoice No.", '<>%1', '');
        CountSalesInv := SalesInvHeader.Count;
        if CountInvoiceCRM > CountSalesInv then exit(true);

        exit(false);
    end;

    local procedure PrepaymentInvoicesChangesNeed(SalesOrderNo: Code[20]; ResponceTokenLines: Text): Boolean
    var
        SalesInvHeader: Record "Sales Invoice Header";
        invoiceID: Text[50];
        PrepmInvAmount: Decimal;
        bcPrepmInvAmount: Decimal;
        jsonPrepmInv: JsonArray;
        PrepmInvToken: JsonToken;
        CountInvoiceCRM: Integer;
        CountSalesInv: Integer;
    begin
        SalesInvHeader.SetCurrentKey("CRM Invoice No.");
        jsonPrepmInv.ReadFrom(ResponceTokenLines);
        foreach PrepmInvToken in jsonPrepmInv do begin
            invoiceID := GetJSToken(PrepmInvToken.AsObject(), 'invoice_id').AsValue().AsText();
            PrepmInvAmount := Round(GetJSToken(PrepmInvToken.AsObject(), 'totalamount').AsValue().AsDecimal(), 0.01);

            SalesInvHeader.SetRange("CRM Invoice No.", invoiceID);
            bcPrepmInvAmount := 0;
            if SalesInvHeader.FindSet(false, false) then begin
                repeat
                    SalesInvHeader.CalcFields("Amount Including VAT");
                    bcPrepmInvAmount += SalesInvHeader."Amount Including VAT";
                until SalesInvHeader.Next() = 0;
                if PrepmInvAmount <> bcPrepmInvAmount then
                    exit(true);
            end;

            if PrepmInvAmount < bcPrepmInvAmount then
                exit(true);
        end;

        // if crm invoice will be delete
        SalesInvHeader.Reset();
        SalesInvHeader.SetCurrentKey("Prepayment Order No.", "CRM Invoice No.");
        SalesInvHeader.SetRange("Prepayment Order No.", SalesOrderNo);
        SalesInvHeader.SetFilter("CRM Invoice No.", '<>%1', '');
        CountSalesInv := SalesInvHeader.Count;
        CountInvoiceCRM := jsonPrepmInv.Count;
        if CountInvoiceCRM < CountSalesInv then exit(true);

        exit(false);
    end;

    local procedure OnAPIProcess(entityType: Text; requestMethod: Code[20]; tokenType: Text; accessToken: Text; var Body: Text): Boolean
    var
        // {{resource}}/api/data/v{{version}}/{{entityType}}
        webAPI_URL: Label '%1/api/data/v%2/%3';
        resourceTest: Label 'https://org3baffe0c.crm4.dynamics.com';
        resourceProd: Label 'https://sprut.crm4.dynamics.com';
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
        RequestBody: Text;
        ResponseMessage: HttpResponseMessage;
        RequestHeader: HttpHeaders;
        BaseURL: Text;
        AuthorizationToken: Text;
    begin
        if GetResourceProductionNotAllowed() then
            BaseURL := StrSubstNo(webAPI_URL, resourceTest, version, entityType)
        else
            BaseURL := StrSubstNo(webAPI_URL, resourceProd, version, entityType);
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
        RequestBody := Body;
        ResponseMessage.Content.ReadAs(Body);

        // Insert Operation to Log
        IntegrationLog.InsertOperationToLog('STANDART_CRM_API', requestMethod, BaseURL, '', RequestBody, Body, ResponseMessage.IsSuccessStatusCode());
        if ResponseMessage.IsSuccessStatusCode then
            exit(ResponseMessage.IsSuccessStatusCode);

        Error(Body);
    end;

    procedure GetOauthToken(var TokenType: Text; var AccessToken: Text; var APIResult: Text): Boolean
    var
        TokenURL: Label 'https://login.microsoftonline.com/da79d6fc-fddb-47ae-bec3-75a8d9e1e1bb/oauth2/token';
        ClientId: Label 'a125243e-de60-41fb-b6f2-1795601fcea9';
        ClientSecret: Label 'A6-595SrEw0DPBT4-_1Uw-l3eL4ETar~-7';
        ResourceTest: Label 'https://org3baffe0c.crm4.dynamics.com';
        ResourceProd: Label 'https://sprut.crm4.dynamics.com';
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
        // BaseURL: Text;
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
        if GetResourceProductionNotAllowed() then
            Outstr.WriteText(StrSubstNo(RequestBody, ClientId, ClientSecret, ResourceTest))
        else
            Outstr.WriteText(StrSubstNo(RequestBody, ClientId, ClientSecret, ResourceProd));
        TempBlob.CreateInStream(Instr);

        Content.WriteFrom(Instr);
        RequestMessage.Content(Content);
        HttpClient.Send(RequestMessage, ResponseMessage);
        ResponseMessage.Content().ReadAs(APIResult);

        // Insert Operation to Log
        IntegrationLog.InsertOperationToLog('GETAUTH_CRM_API', MethodPOST, TokenURL, Authorization, RequestBody, APIResult, ResponseMessage.IsSuccessStatusCode());

        if ResponseMessage.IsSuccessStatusCode() then begin
            GetTokenFromResponse(APIResult, TokenType, AccessToken);
            exit(true);
        end;

        Error(APIResult);
    end;

    procedure GetResourceProductionNotAllowed(): Boolean
    var
        CompIntegr: Record "Company Integration";
    begin
        CompIntegr.SetCurrentKey("Company Name", "Environment Production");
        CompIntegr.SetRange("Company Name", CompanyName);
        CompIntegr.SetRange("Environment Production", true);
        exit(CompIntegr.IsEmpty);
    end;

    local procedure GetTokenFromResponse(APIResult: Text; var TokenType: Text; var AccessToken: Text)
    var
        jsonAPI: JsonObject;
    begin
        jsonAPI.ReadFrom(APIResult);
        TokenType := GetJSToken(jsonAPI, 'token_type').AsValue().AsText();
        AccessToken := GetJSToken(jsonAPI, 'access_token').AsValue().AsText();
    end;

    procedure GetJSToken(_JSONObject: JsonObject; TokenKey: Text) _JSONToken: JsonToken
    begin
        if not _JSONObject.Get(TokenKey, _JSONToken) then
            Error('Could not find a token with key %1', TokenKey);
    end;

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
            // JSObjectLine.Add('tct_salestypecode', salesTypeCode);
            JSObjectLine.Add('productnumber', locItems."No.");
            JSObjectLine.Add('name', locItems.Description);
            JSObjectLine.Add('defaultuomscheduleid@odata.bind', defaultUoMScheduleId);
            JSObjectLine.Add('defaultuomid@odata.bind', defaultUoMId);
            JSObjectLine.Add('quantitydecimal', quantityDecimal);
            JSObjectLine.Add('tct_bc_product_number', locItems."No.");
            JSObjectLine.Add('tct_bc_uomid', locItems."Sales Unit of Measure");
            JSObjectLine.Add('statecode', GetStateCode(locItems."No."));
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
            // JSObjectLine.Add('tct_salestypecode', salesTypeCode);
            JSObjectLine.Add('name', locItems.Description);
            JSObjectLine.Add('defaultuomscheduleid@odata.bind', defaultUoMScheduleId);
            // JSObjectLine.Add('defaultuomid@odata.bind', defaultUoMId);
            JSObjectLine.Add('quantitydecimal', quantityDecimal);
            JSObjectLine.Add('tct_bc_product_number', locItems."No.");
            JSObjectLine.Add('tct_bc_uomid', locItems."Sales Unit of Measure");
            JSObjectLine.Add('statecode', GetStateCode(locItems."No."));
        end;
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

    procedure jsonPaymentToPost(salesOrderId: Text[100]; invoiceId: Text[100]; payerDetails: Text[100]; paymentAmount: Decimal): JsonObject
    var
        JSObjectLine: JsonObject;
        lblSalesOrderId: Label '/salesorders(%1)';
        lblInvoiceId: Label '/invoices(%1)';
        lblTransactionCurrencyId: Label '/transactioncurrencies(d8b0ca73-7060-ea11-a811-000d3ab9be86)';
    begin
        salesOrderId := StrSubstNo(lblSalesOrderId, LowerCase(DelChr(salesOrderId, '<>', '{}')));
        invoiceId := StrSubstNo(lblInvoiceId, LowerCase(DelChr(invoiceId, '<>', '{}')));

        JSObjectLine.Add('tct_salesorderid@odata.bind', salesOrderId);
        JSObjectLine.Add('tct_payerdetails', payerDetails);
        JSObjectLine.Add('tct_amount', paymentAmount);
        JSObjectLine.Add('tct_invoiceid@odata.bind', invoiceId);
        JSObjectLine.Add('transactioncurrencyid@odata.bind', lblTransactionCurrencyId);

        exit(JSObjectLine);
    end;

    procedure jsonApplyPaymentToPatch(): JsonObject
    var
        JSObjectLine: JsonObject;
    begin
        JSObjectLine.Add('statecode', 0);
        exit(JSObjectLine);
    end;

    procedure jsonUnApplyPaymentToPatch(): JsonObject
    var
        JSObjectLine: JsonObject;
    begin
        JSObjectLine.Add('statecode', 1);
        exit(JSObjectLine);
    end;

    procedure AddCRMpaymentIdToPayment(jsonText: Text; InvoiceEntryNo: Integer; PaymentEntryNo: Integer; PaymentAmount: Decimal): Boolean
    var
        locTaskPaymentSend: Record "Task Payment Send";
        PaymentToken: JsonToken;
        PaymentToken2: JsonToken;
        CRMpaymentId: Text[50];
    begin
        PaymentToken.ReadFrom(jsonText);
        if PaymentToken.AsObject().Get('tct_paymentid', PaymentToken2) then begin
            CRMpaymentId := GetJSToken(PaymentToken.AsObject(), 'tct_paymentid').AsValue().AsText();

            locTaskPaymentSend.SetRange("Invoice Entry No.", InvoiceEntryNo);
            locTaskPaymentSend.SetRange("Payment Entry No.", PaymentEntryNo);
            locTaskPaymentSend.SetRange("Payment Amount", PaymentAmount);
            if locTaskPaymentSend.FindSet(true) then
                repeat
                    locTaskPaymentSend."CRM Payment Id" := CRMpaymentId;
                    locTaskPaymentSend.Modify();
                until locTaskPaymentSend.Next() = 0;
        end else
            exit(false);

        exit(true);
    end;

    local procedure GetDocumentNoByEntryNoCustLedgEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]): Code[20]
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        case DocumentType of
            DocumentType::Invoice:
                begin
                    CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
                end;
            DocumentType::Payment:
                begin
                    CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Payment);

                end;
        end;
        CustLedgEntry.SetRange("Document No.", DocumentNo);
        if CustLedgEntry.FindFirst() then
            exit(CustLedgEntry."Document No.");
        exit('');
    end;

    local procedure GetStateCode(ItemNo: Code[20]): Integer
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        if Item.Blocked or Item."Sales Blocked" then
            exit(1);
        exit(0);
    end;

    procedure ChangeSalesOrderLocationCode(var SalesHeader: Record "Sales Header"; LocationCode: Code[20])
    var
        Location: Record Location;
        SalesLine: Record "Sales Line";
        newSalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        if not Location.Get(LocationCode) then exit;
        // SalesHeader.Get(SalesHeader."Document Type"::Order, SalesOrderNo);
        if Location.Code = SalesHeader."Location Code" then exit;

        SalesHeader."Location Code" := Location.Code;
        SalesHeader.Modify(true);

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter("Location Code", '<>%1', Location.Code);
        if SalesLine.FindSet(false, false) then
            repeat
                if Item.Get(SalesLine."No.")
                and Item.IsInventoriableType() then begin
                    newSalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
                    newSalesLine."Location Code" := LocationCode;
                    newSalesLine.Modify();
                end;
            until SalesLine.Next() = 0;
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
                _jsonPayment := jsonApplyPaymentToPatch();
            end;

            _jsonPayment.WriteTo(_jsonText);
            Counter += 1;

            // try send to CRM
            if not CreatePaymentInCRM(entityTypeValue, requestMethod, TokenType, AccessToken, _jsonText) then begin
                _jsonErrorItemList.Add(_jsonPayment);
                _jsonPayment.ReadFrom(_jsonText);
                _jsonErrorItemList.Add(_jsonPayment);
            end;// else
                // add CRM product ID to Item
                // AddCRMpaymentIdToPayment(_jsonText, crmInvoiceNo);
        end;
        if _jsonErrorItemList.Count > 0 then;
    end;

}