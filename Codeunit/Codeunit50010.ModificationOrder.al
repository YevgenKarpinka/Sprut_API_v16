codeunit 50010 "Modification Order"
{
    TableNo = "Sales Header";

    trigger OnRun()
    begin
        OnModifyOrder(Rec."No.");
    end;

    var
        WebServicesMgt: Codeunit "Web Service Mgt.";
        PrepmMgt: Codeunit "Prepayment Management";
        SalesPostPrepm: Codeunit "Sales-Post Prepayments Sprut";
        SpecificationResponseText: Text;
        InvoicesResponseText: Text;
        SpecEntityType: Label 'specification';
        InvEntityType: Label 'invoice';
        POSTrequestMethod: Label 'POST';

    procedure OnDeleteSalesOrder(SalesOrderNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        // Open Sales Order
        OpenSalesOrder(SalesHeader, SalesOrderNo);

        // create credit memo for prepayment invoice
        if SalesPostPrepm.CheckOpenPrepaymentLines(SalesHeader, 1) then
            SalesPostPrepm.PostPrepaymentCreditMemoSprut(SalesHeader);

        // Open Sales Order
        OpenSalesOrder(SalesHeader, SalesOrderNo);

        OnDeleteSalesHeader(SalesHeader);
    end;

    procedure OnDeleteSalesHeader(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Delete(true);
    end;

    procedure OnModifyOrder(SalesOrderNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        // analyze need full update sales order or not
        if WebServicesMgt.NeedFullUpdateSalesOrder(SalesOrderNo) then begin
            // unapply prepayments
            PrepmMgt.UnApplyPayments(SalesOrderNo);

            // Open Sales Order
            OpenSalesOrder(SalesHeader, SalesOrderNo);

            // create credit memo for prepayment invoice
            if SalesPostPrepm.CheckOpenPrepaymentLines(SalesHeader, 1) then
                SalesPostPrepm.PostPrepaymentCreditMemoSprut(SalesHeader);

            // Applying Prepayment Entries
            PrepmMgt.CustPrepmtApply(SalesOrderNo);

            // Get Specification From Task
            SpecificationResponseText := GetSpecificationFromTask(SalesOrderNo);

            // Open Sales Order
            OpenSalesOrder(SalesHeader, SalesOrderNo);

            // delete all sales lines
            PrepmMgt.OnDeleteSalesOrderLine(SalesOrderNo);

            // Update sales header location
            PrepmMgt.UpdateSalesHeaderLocation(SalesHeader, SpecificationResponseText);

            // insert sales line
            PrepmMgt.InsertSalesLineFromCRM(SalesOrderNo, SpecificationResponseText);

            // Get Invoices From Task
            InvoicesResponseText := GetInvoicesFromTask(SalesOrderNo);

            // create prepayment invoice by amount
            PrepmMgt.CreatePrepaymentInvoicesFromCRM(SalesOrderNo, InvoicesResponseText);
        end else
            // create Added prepayment invoice by amount
            if WebServicesMgt.NeedCreatePrepmtInvoice(SalesOrderNo) then begin
                // Get Invoices From Task
                InvoicesResponseText := GetInvoicesFromTask(SalesOrderNo);
                // create Added prepayment invoice by amount
                PrepmMgt.AddedPrepaymentInvoicesFromCRM(SalesOrderNo, InvoicesResponseText);
            end;
    end;

    local procedure OpenSalesOrder(var SalesHeader: Record "Sales Header"; SalesOrderNo: Code[20])
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesOrderNo);
        if SalesHeader.Status <> SalesHeader.Status::Open then begin
            SalesHeader.Status := SalesHeader.Status::Open;
            SalesHeader.Modify();
        end;
    end;

    procedure GetSpecificationFromTask(SalesOrderNo: Code[20]): Text
    var
        TaskModifyOrder: Record "Task Modify Order";
    begin
        TaskModifyOrder.SetCurrentKey(Status, "Order No.", "Work Status");
        TaskModifyOrder.SetRange(Status, TaskModifyOrder.Status::OnModifyOrder);
        TaskModifyOrder.SetRange("Order No.", SalesOrderNo);
        TaskModifyOrder.SetRange("Work Status", TaskModifyOrder."Work Status"::InWork);
        TaskModifyOrder.FindFirst();
        exit(TaskModifyOrder.GetCRMSpecification());
    end;

    procedure GetInvoicesFromTask(SalesOrderNo: Code[20]): Text
    var
        TaskModifyOrder: Record "Task Modify Order";
    begin
        TaskModifyOrder.SetCurrentKey(Status, "Order No.", "Work Status");
        TaskModifyOrder.SetRange(Status, TaskModifyOrder.Status::OnModifyOrder);
        TaskModifyOrder.SetRange("Order No.", SalesOrderNo);
        TaskModifyOrder.SetRange("Work Status", TaskModifyOrder."Work Status"::InWork);
        TaskModifyOrder.FindFirst();
        exit(TaskModifyOrder.GetCRMInvoices());
    end;
}