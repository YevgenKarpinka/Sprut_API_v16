codeunit 50005 "CRM Action API"
{
    var
        msgSalesOrderGetIsOk: Label 'the processed from %1 sales order %2 is ok';
        errUndefinedSourceType: Label 'undefined "sourceType" %1';
        OrderId: Text[50];



    procedure OnAfterChangedSalesOrder(sourceType: Text[50]; salesOrderId: Text[50]): Text
    var
        SalesHeader: Record "Sales Header";
    begin
        OrderId := salesOrderId;
        case sourceType of
            'Specification', 'Invoice':
                begin

                end;
            else
                Error(errUndefinedSourceType, sourceType);
        end;

        if StrLen(salesOrderId) > 20 then begin
            SalesHeader.SetRange(SystemId, salesOrderId);
            SalesHeader.FindFirst();
        end else
            SalesHeader.Get(SalesHeader."Document Type"::Order, salesOrderId);

        exit(StrSubstNo(msgSalesOrderGetIsOk, sourceType, SalesHeader."No."));
        // exit(GetJsonSalesOrderLines(SalesHeader."No."));
    end;

    local procedure GetJsonSalesOrderLines(SalesOrderNo: Code[20]): Text
    var
        SalesLines: Record "Sales Line";
        jsonSalesLine: JsonObject;
        jsonSalesLines: JsonArray;
        txtSalesLines: Text;
    begin
        SalesLines.SetRange("Document Type", SalesLines."Document Type"::Order);
        SalesLines.SetRange("Document No.", SalesOrderNo);
        SalesLines.SetRange(Type, SalesLines.Type::Item);
        SalesLines.SetFilter(Quantity, '<>%1', 0);
        if SalesLines.FindSet(false, false) then
            repeat
                Clear(jsonSalesLine);

                jsonSalesLine.Add('document_no', OrderId);
                jsonSalesLine.Add('line_no', SalesLines.SystemId);
                jsonSalesLine.Add('no', SalesLines."No.");
                jsonSalesLine.Add('quantity', SalesLines.Quantity);
                jsonSalesLine.Add('unit_price', SalesLines."Unit Price");

                jsonSalesLines.Add(jsonSalesLine);
            until SalesLines.Next() = 0;

        jsonSalesLines.WriteTo(txtSalesLines);
        exit(txtSalesLines);
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

