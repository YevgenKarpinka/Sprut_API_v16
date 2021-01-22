codeunit 50014 "Transfer Order Mgt."
{
    trigger OnRun()
    begin

    end;

    procedure CreateTransferOrderFromSalesOrder(SalesLine: Record "Sales Line";
                                                TransferFromCode: Code[20];
                                                TransferToCode: Code[20])
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        LineNo: Integer;
    begin
        TransferHeader.Init();
        TransferHeader.Validate("Direct Transfer", true);
        TransferHeader.Validate("Transfer-from Code", TransferFromCode);
        TransferHeader.Validate("Transfer-to Code", TransferToCode);
        TransferHeader.Validate("Order No.", SalesLine."Document No.");
        TransferHeader.Insert(true);

        SalesLine.FindSet(false, false);
        repeat
            if LineNo = 0 then LineNo += 10000;
            TransferLine.Init();
            TransferLine.Validate("Document No.", TransferHeader."No.");
            TransferLine.Validate("Line No.", LineNo);
            TransferLine.Validate("Item No.", SalesLine."No.");
            TransferLine.Validate("Unit of Measure Code", SalesLine."Unit of Measure Code");
            TransferLine.Validate(Quantity, SalesLine.Quantity);
            TransferLine.Insert(true);
        until SalesLine.Next() = 0;
    end;
}