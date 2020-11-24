codeunit 50006 "Task Modify Order"
{
    trigger OnRun()
    begin
        GetFirstRecordForExecute();
        Execute();
    end;

    var
        recTaskModifyOrder: Record "Task Modify Order";
        WebServicesMgt: Codeunit "Web Service Mgt.";
        PrepmMgt: Codeunit "Prepayment Management";
        SalesPostPrepm: Codeunit "Sales-Post Prepayments Sprut";
        SpecificationResponseText: Text;
        InvoicesResponseText: Text;
        SpecEntityType: Label 'specification';
        InvEntityType: Label 'invoice';
        POSTrequestMethod: Label 'POST';

    local procedure Execute()
    var
        SalesHeader: Record "Sales Header";
    begin
        case recTaskModifyOrder.Status of
            recTaskModifyOrder.Status::OnUnApplyPayments:
                begin
                    // unapply prepayments
                    PrepmMgt.UnApplyPayments(recTaskModifyOrder."Order No.");
                    // Open Sales Order
                    OpenSalesOrder(SalesHeader, recTaskModifyOrder."Order No.");
                    // create credit memo for prepayment invoice
                    if SalesPostPrepm.CheckOpenPrepaymentLines(SalesHeader, 1) then
                        SalesPostPrepm.PostPrepaymentCreditMemoSprut(SalesHeader);
                    // modify task status to next level
                    ModifyTaskStatusToNextLevel(recTaskModifyOrder.Status::OnModifyOrder);
                end;

            recTaskModifyOrder.Status::OnModifyOrder:
                begin
                    WebServicesMgt.GetSpecificationFromCRM(recTaskModifyOrder."Order No.", SpecEntityType, POSTrequestMethod, SpecificationResponseText);
                    // Open Sales Order
                    OpenSalesOrder(SalesHeader, recTaskModifyOrder."Order No.");
                    // delete all sales lines
                    PrepmMgt.OnDeleteSalesOrderLine(recTaskModifyOrder."Order No.");
                    // insert sales line
                    PrepmMgt.InsertSalesLineFromCRM(recTaskModifyOrder."Order No.", SpecificationResponseText);
                    // modify task status to next level
                    ModifyTaskStatusToNextLevel(recTaskModifyOrder.Status::OnCreateInvoices);
                end;

            recTaskModifyOrder.Status::OnCreateInvoices:
                begin
                    WebServicesMgt.GetInvoicesFromCRM(recTaskModifyOrder."Order No.", InvEntityType, POSTrequestMethod, InvoicesResponseText);
                    // create prepayment invoice by amount
                    PrepmMgt.CreatePrepaymentInvoicesFromCRM(recTaskModifyOrder."Order No.", InvoicesResponseText);
                    // modify task status to next level
                    ModifyTaskStatusToNextLevel(recTaskModifyOrder.Status::OnSendToCRM);
                end;

            recTaskModifyOrder.Status::OnSendToCRM:
                begin


                    // modify task status to next level
                    ModifyTaskStatusToNextLevel(recTaskModifyOrder.Status::OnSendToEmail);
                end;
            recTaskModifyOrder.Status::OnSendToEmail:
                begin


                    // modify task status to next level
                    ModifyTaskStatusToNextLevel(recTaskModifyOrder.Status::Done);
                end;

            else
        end;
    end;

    local procedure ModifyTaskStatusToNextLevel(NextTaskStatus: Enum TaskStatus)
    begin
        recTaskModifyOrder.Status := NextTaskStatus;
        recTaskModifyOrder.Modify(true);
    end;

    local procedure OpenSalesOrder(var SalesHeader: Record "Sales Header"; SalesOrderNo: Code[20])
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesOrderNo);
        if SalesHeader.Status <> SalesHeader.Status::Open then begin
            SalesHeader.Status := SalesHeader.Status::Open;
            SalesHeader.Modify();
        end;
    end;

    local procedure GetFirstRecordForExecute()
    begin
        recTaskModifyOrder.SetCurrentKey(Status);
        recTaskModifyOrder.SetFilter(Status, '<>%1', recTaskModifyOrder.Status::Done);
        recTaskModifyOrder.FindFirst();
    end;
}