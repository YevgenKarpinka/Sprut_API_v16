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

    procedure OnCreatePrepaymentInvoice(orderNo: Code[20]; invoiceId: Text[50];
                                        crmId: Guid; prepaymentAmount: Decimal): Text
    var
        salesInvoice: Page "APIV2 - Sales Invoice";
    begin
        CheckCRM_Id(crmId);
        if invoiceId = '' then
            Error(errBlankInvoiceId);
        if prepaymentAmount <= 0 then
            ERROR(errBlankPrepaymentAmount);

        salesInvoice.SetInit(invoiceId, prepaymentAmount, crmId);
        salesInvoice.CreatePrepaymentInvoice(orderNo);
        exit(CreateJsonPrpmtSalesInvoice(orderNo, invoiceId, crmId, prepaymentAmount));
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

    procedure OnPostSalesOrder(salesOrderId: Text[50]; crmInvoiceId: Text[50]; crmId: Guid; crmInvoiceAmount: Decimal): Text
    var
        SalesHeader: Record "Sales Header";
        Location: Record Location;
        ReleaseSalesDoc: Codeunit "Release Sales Document";
    begin
        CheckCRMInvoiceAmount(salesOrderId, crmInvoiceAmount);
        CheckCRM_Id(crmId);

        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("No.", salesOrderId);
        SalesHeader.FindFirst();
        if SalesHeader.TestStatusIsNotReleased() then
            ReleaseSalesDoc.PerformManualRelease(SalesHeader);
        SalesHeader."CRM Invoice No." := crmInvoiceId;
        SalesHeader."CRM ID" := crmId;
        SalesHeader.Modify();
        if Location.RequireShipment(SalesHeader."Location Code") then begin
            recWhseShipmentLine.SetCurrentKey("Source Document", "Source No.");
            recWhseShipmentLine.SetRange("Source Document", recWhseShipmentLine."Source Document"::"Sales Order");
            recWhseShipmentLine.SetRange("Source No.", salesOrderId);
            recWhseShipmentLine.FindFirst();

            WhsePostShipment.SetPostingSettings(true);
            WhsePostShipment.SetPrint(false);
            WhsePostShipment.RUN(recWhseShipmentLine);
        end else begin
            SalesHeader.Invoice := true;
            SalesHeader.Ship := true;
            CODEUNIT.RUN(CODEUNIT::"Sales-Post", SalesHeader);
        end;

        exit(StrSubstNo(msgSalesOrderGetIsOk, '', salesOrderId));
    end;

    local procedure CheckCRM_Id(crmId: Guid)
    begin
        if IsNullGuid(crmId) then
            Error(errCRM_IdNotAllowed, crmId);
    end;

    local procedure CheckCRMInvoiceAmount(salesOrderId: Text[50]; crmInvoiceAmount: Decimal)
    var
        SalesLine: Record "Sales Line";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        OrderAmount: Decimal;
        InvAmount: Decimal;
        CrMemoAmount: Decimal;
        errOrderAmountInvAmountCrMemoAmount: Label 'Order Amount %1 Inv Amount %2 CrMemo Amount %3';
    begin
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

    local procedure CreateJsonPrpmtSalesInvoice(orderNo: Code[20]; invoiceId: Text[50]; crmId: Text[50]; prepaymentAmount: Decimal): Text
    var
        SalesInvHeader: Record "Sales Invoice Header";
        jsonSalesInvHeader: JsonObject;
        txtSalesInvHeader: Text;
    begin
        SalesInvHeader.SetCurrentKey("Prepayment Order No.", "CRM Invoice No.", "CRM ID");
        SalesInvHeader.SetRange("Prepayment Order No.", orderNo);
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

