codeunit 50014 "Transfer Order Mgt."
{
    trigger OnRun()
    begin

    end;

    procedure CreateTransferOrderFromSalesOrder(var SalesLine: Record "Sales Line";
                                                var TransferHeader: Record "Transfer Header";
                                                TransferFromCode: Code[20];
                                                TransferToCode: Code[20];
                                                DirectTransfer: Boolean)
    var
        TransferLine: Record "Transfer Line";
        LineNo: Integer;
    begin
        TransferHeader.Init();
        TransferHeader.Insert(true);
        TransferHeader.Validate("Direct Transfer", DirectTransfer);
        TransferHeader.Validate("Transfer-from Code", TransferFromCode);
        TransferHeader.Validate("Transfer-to Code", TransferToCode);
        TransferHeader.Validate("Order No.", SalesLine."Document No.");
        TransferHeader.Modify(true);

        SalesLine.FindSet(false, false);
        repeat
            TransferLine.Init();
            TransferLine.Validate("Document No.", TransferHeader."No.");
            TransferLine.Validate("Line No.", LineNo + 10000);
            TransferLine.Validate("Item No.", SalesLine."No.");
            TransferLine.Validate("Unit of Measure Code", SalesLine."Unit of Measure Code");
            TransferLine.Validate(Quantity, SalesLine.Quantity);
            TransferLine.Insert(true);
        until SalesLine.Next() = 0;
    end;
}