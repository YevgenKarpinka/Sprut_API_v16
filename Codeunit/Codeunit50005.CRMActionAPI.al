codeunit 50005 "CRM Action API"
{
    var
        msgSalesOrderGetIsOk: Label 'the processed from %1 sales order %2 is ok';
        errUndefinedSourceType: Label 'undefined "sourceType" %1';

    procedure OnAfterChangedSalesOrder(sourceType: Text; salesOrderId: Text): Text
    var
        SalesHeader: Record "Sales Header";
    begin
        case sourceType of
            'Invoice':
                begin

                end;

            'Specification':
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

