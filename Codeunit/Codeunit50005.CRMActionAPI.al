codeunit 50005 "CRM Action API"
{
    var
        PrepaymentMgt: Codeunit "Prepayment Management";
        recWhseShipmentLine: Record "Warehouse Shipment Line";
        WhsePostShipment: Codeunit "Whse.-Post Shipment";
        msgSalesOrderGetIsOk: Label 'the processed from %1 sales order %2 is ok';
        errUndefinedSourceType: Label 'undefined "sourceType" %1';
        errCRMInvoiceAmountMustBeEqualBCInvoiceAmount: Label 'CRM invoice amount %1 must be equal BC invoice amount %2';
        errCRM_IdNotAllowed: Label 'CRM Id is Null not allowed %1';
        errBlankPrepaymentAmount: Label 'The blank "prepaymentAmount" is not allowed.', Locked = true;
        errBlankInvoiceId: Label 'The blank "invoiceId" is not allowed.', Locked = true;
        errPrepaymentPercentCannotBeLessOrEqual: Label 'The "prepaymentPercent" cannot be less or equal %1.', Locked = true;
        errCRM_IDisNullNotAllowed: Label 'The blank "crmId" is not allowed.', Locked = true;
        msgInvoiceUpdated: Label 'Invoice %1 updated.', Locked = true;

    procedure OnCreatePrepaymentInvoice(orderNo: Code[20]; invoiceId: Text[50]; crmId: Guid;
                                        prepaymentAmount: Decimal; invoiceNo1C: Text[50];
                                        postingDate: Date; dueDate: Date): Text
    var
        salesInvoice: Page "APIV2 - Sales Invoice";
    begin
        CheckCRM_Id(crmId, prepaymentAmount);
        if invoiceId = '' then
            Error(errBlankInvoiceId);
        if prepaymentAmount <= 0 then
            ERROR(errBlankPrepaymentAmount);

        salesInvoice.SetInit(invoiceId, prepaymentAmount, crmId, invoiceNo1C, postingDate, dueDate);
        salesInvoice.CreatePrepaymentInvoice(orderNo);
        exit(CreateJsonPrpmtSalesInvoice(orderNo, invoiceId, crmId, prepaymentAmount, true));
    end;

    procedure OnAfterChangedSalesOrder(sourceType: Text[50]; salesOrderId: Text[50]; crm_id: Guid): Text
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Order, salesOrderId);
        SalesHeader.TestField("CRM Header ID", crm_id);

        case sourceType of
            'Specification', 'Invoice':
                begin
                    // PrepaymentMgt.OnModifySalesOrderOneLine(SalesHeader."No.");
                    PrepaymentMgt.OnModifySalesOrderInTask(SalesHeader."No.");
                end;
            else
                Error(errUndefinedSourceType, sourceType);
        end;

        exit(StrSubstNo(msgSalesOrderGetIsOk, sourceType, SalesHeader."No."));
        // exit(GetJsonSalesOrderLines(SalesHeader."No."));
    end;

    procedure OnPostSalesOrder(salesOrderId: Text[20]; crmInvoiceId: Text[50]; crmId: Guid;
                                crmInvoiceAmount: Decimal; invoiceNo1C: Text[50];
                                postingDate: Date; dueDate: Date;
                                shippingNo: Text[20]; shipmentDate: Text[10]): Text
    var
        SalesHeader: Record "Sales Header";
    begin
        CheckCRMInvoiceAmount(salesOrderId, crmInvoiceAmount);
        CheckCRM_Id(crmId, crmInvoiceAmount);
        UpdateSalesOrder(SalesHeader, salesOrderId, crmInvoiceId, crmId,
                                crmInvoiceAmount, invoiceNo1C,
                                postingDate, dueDate,
                                shippingNo, shipmentDate);
        PostSalesOrder(SalesHeader);

        exit(CreateJsonPrpmtSalesInvoice(SalesHeader."No.", SalesHeader."CRM Invoice No.",
                                            SalesHeader."CRM ID", crmInvoiceAmount, false));
        // exit(StrSubstNo(msgSalesOrderGetIsOk, '', salesOrderId));
    end;

    local procedure PostSalesOrder(var SalesHeader: Record "Sales Header")
    var
        Location: Record Location;
    begin
        if Location.RequireShipment(SalesHeader."Location Code") then begin
            recWhseShipmentLine.SetCurrentKey("Source Document", "Source No.");
            recWhseShipmentLine.SetRange("Source Document", recWhseShipmentLine."Source Document"::"Sales Order");
            recWhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
            recWhseShipmentLine.FindFirst();

            WhsePostShipment.SetPostingSettings(true);
            WhsePostShipment.SetPrint(false);
            WhsePostShipment.RUN(recWhseShipmentLine);
        end else begin
            SalesHeader.Invoice := true;
            SalesHeader.Ship := true;
            CODEUNIT.RUN(CODEUNIT::"Sales-Post", SalesHeader);
        end;
    end;

    local procedure UpdateSalesOrder(var SalesHeader: Record "Sales Header"; salesOrderId: Text[20];
                                    crmInvoiceId: Text[50]; crmId: Guid;
                                    crmInvoiceAmount: Decimal; invoiceNo1C: Text[50];
                                    postingDate: Date; dueDate: Date;
                                    shippingNo: Text[20]; shipmentDate: Text[10])
    var
        ReleaseSalesDoc: Codeunit "Release Sales Document";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("No.", salesOrderId);
        SalesHeader.FindFirst();
        if SalesHeader.Status <> SalesHeader.Status::Open then
            ReleaseSalesDoc.Reopen(SalesHeader);

        if crmInvoiceId <> '' then
            SalesHeader."CRM Invoice No." := crmInvoiceId
        else
            if SalesHeader."External Document No." <> '' then
                SalesHeader."CRM Invoice No." := SalesHeader."External Document No.";

        if not IsNullGuid(crmId) then
            SalesHeader."CRM ID" := crmId
        else
            if not IsNullGuid(SalesHeader."CRM Header ID") then
                SalesHeader."CRM ID" := SalesHeader."CRM Header ID";

        if invoiceNo1C <> '' then
            SalesHeader."Invoice No. 1C" := invoiceNo1C;

        SalesHeader."Document Date" := postingDate;
        SalesHeader."Posting Date" := postingDate;
        SalesHeader."Due Date" := dueDate;
        if shippingNo <> '' then
            SalesHeader."Shipping No." := shippingNo;
        if Evaluate(SalesHeader."Shipment Date", shipmentDate) then
            if SalesHeader."Shipment Date" < CalcDate('<-CM >', Today) then
                SalesHeader.Validate("Shipment Date", Today)
            else
                SalesHeader.Validate("Shipment Date");
        SalesHeader.Modify();

        if SalesHeader.TestStatusIsNotReleased() then
            ReleaseSalesDoc.PerformManualRelease(SalesHeader);
    end;

    local procedure CheckCRM_Id(crmId: Guid; crmInvoiceAmount: Decimal)
    begin
        if (crmInvoiceAmount <> 0) and IsNullGuid(crmId) then
            Error(errCRM_IdNotAllowed, crmId);
    end;

    local procedure CheckCRMInvoiceAmount(salesOrderId: Text[50]; crmInvoiceAmount: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        OrderAmount: Decimal;
        InvAmount: Decimal;
        CrMemoAmount: Decimal;
        errOrderAmountInvAmountCrMemoAmount: Label 'Order Amount %1 Inv Amount %2 CrMemo Amount %3';
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Order, salesOrderId);

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", salesOrderId);
        SalesLine.CalcSums("Amount Including VAT");
        OrderAmount += SalesLine."Amount Including VAT";

        SalesInvHeader.SetCurrentKey("Prepayment Order No.");
        SalesInvHeader.SetRange("Prepayment Order No.", salesOrderId);
        if SalesInvHeader.FindSet() then
            repeat
                SalesInvHeader.CalcFields("Amount Including VAT");
                InvAmount += SalesInvHeader."Amount Including VAT";
            until SalesInvHeader.Next() = 0;

        SalesCrMemoHeader.SetCurrentKey("Prepayment Order No.");
        SalesCrMemoHeader.SetRange("Prepayment Order No.", salesOrderId);
        if SalesCrMemoHeader.FindSet() then
            repeat
                SalesCrMemoHeader.CalcFields("Amount Including VAT");
                CrMemoAmount += SalesCrMemoHeader."Amount Including VAT";
            until SalesCrMemoHeader.Next() = 0;


        // Error(errOrderAmountInvAmountCrMemoAmount, OrderAmount, InvAmount, CrMemoAmount);
        if OrderAmount - InvAmount + CrMemoAmount <> crmInvoiceAmount then
            Error(errCRMInvoiceAmountMustBeEqualBCInvoiceAmount, crmInvoiceAmount, OrderAmount - InvAmount + CrMemoAmount);
    end;

    local procedure GetJsonSalesOrderLines(SalesOrderNo: Code[20]): Text
    var
        SalesLines: Record "Sales Line";
        jsonSalesLine: JsonObject;
        jsonSalesLines: JsonArray;
        txtSalesLines: Text;
    begin
        SalesLines.SetCurrentKey(Type, Quantity);
        SalesLines.SetRange("Document Type", SalesLines."Document Type"::Order);
        SalesLines.SetRange("Document No.", SalesOrderNo);
        SalesLines.SetRange(Type, SalesLines.Type::Item);
        SalesLines.SetFilter(Quantity, '<>%1', 0);
        if SalesLines.FindSet() then
            repeat
                Clear(jsonSalesLine);

                jsonSalesLine.Add('document_no', SalesLines."Document No.");
                jsonSalesLine.Add('line_no', SalesLines.SystemId);
                jsonSalesLine.Add('no', SalesLines."No.");
                jsonSalesLine.Add('quantity', SalesLines.Quantity);
                jsonSalesLine.Add('unit_price', SalesLines."Unit Price");

                jsonSalesLines.Add(jsonSalesLine);
            until SalesLines.Next() = 0;

        jsonSalesLines.WriteTo(txtSalesLines);
        exit(txtSalesLines);
    end;

    local procedure CreateJsonPrpmtSalesInvoice(orderNo: Code[20]; invoiceId: Text[50]; crmId: Text[50]; prepaymentAmount: Decimal; prepaymentInvoice: Boolean): Text
    var
        SalesInvHeader: Record "Sales Invoice Header";
        jsonSalesInvHeader: JsonObject;
        txtSalesInvHeader: Text;
    begin
        if prepaymentInvoice then begin
            SalesInvHeader.SetCurrentKey("Prepayment Order No.", "CRM Invoice No.", "CRM ID");
            SalesInvHeader.SetRange("Prepayment Order No.", orderNo);
        end else begin
            SalesInvHeader.SetCurrentKey("Order No.", "CRM Invoice No.", "CRM ID");
            SalesInvHeader.SetRange("Order No.", orderNo);
        end;
        SalesInvHeader.SetRange("CRM Invoice No.", invoiceId);
        SalesInvHeader.SetRange("CRM ID", crmId);
        if SalesInvHeader.FindLast() then begin
            jsonSalesInvHeader.Add('orderNo', orderNo);
            jsonSalesInvHeader.Add('postedInvoiceNo', SalesInvHeader."No.");
            jsonSalesInvHeader.Add('invoiceId', invoiceId);
            jsonSalesInvHeader.Add('crmId', LowerCase(DelChr(crmId, '<>', '{}')));
            jsonSalesInvHeader.Add('prepaymentAmount', prepaymentAmount);
        end;

        jsonSalesInvHeader.WriteTo(txtSalesInvHeader);
        exit(txtSalesInvHeader);
    end;

    procedure OnUpdatePostedInvoiceInvoiceNo1C(postedInvoiceNo: Code[20]; invoiceNo1C: Text[50]): Text
    var
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        if SalesInvHeader.Get(postedInvoiceNo) then begin
            SalesInvHeader."Invoice No. 1C" := invoiceNo1C;
            SalesInvHeader.Modify();
        end;
        exit(StrSubstNo(msgInvoiceUpdated, postedInvoiceNo));
    end;
}

enum 50000 CRMSourceType
{
    Extensible = true;

    value(0; Invoice)
    {
        CaptionML = ENU = 'Invoice',
                    RUS = 'Счет';
    }
    value(1; Specification)
    {
        CaptionML = ENU = 'Specification',
                    RUS = 'Спецификация';
    }
}

