pageextension 50003 "Sale Order Card Ext" extends "Sales Order"
{
    layout
    {
        // Add changes to page layout here
        addafter(Status)
        {
            field("Last Modified Date Time"; "Last Modified Date Time")
            {
                ApplicationArea = All;
                ToolTipML = ENU = 'Specifies Last Modified Date Time.',
                            RUS = 'Указывает на последнюю дату и время модификации.';
            }
            field("CRM ID"; "CRM ID")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("CRM Header ID"; "CRM Header ID")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("CRM Source Type"; "CRM Source Type")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("Customer BC Id"; MatchContragent.GetBCIdFromCustomer("Sell-to Customer No."))
            {
                Visible = false;
            }
            field("Customer CRM ID"; MatchContragent.GetCustomerCRMID("Sell-to Customer No."))
            {
                Visible = false;
            }
            field("Currency ISO Code"; MatchContragent.GetCurrencyISONumericCode("Currency Code"))
            {
                Visible = false;
            }
            field(Amount; Amount)
            {
                Visible = false;
            }
            field("Amount Including VAT"; "Amount Including VAT")
            {
                Visible = false;
            }
        }
        addafter(SalesLines)
        {
            part(SalesLinesExt; "Sales Order Subform Ext")
            {
                ApplicationArea = Basic, Suite;
                // Editable = DynamicEditable;
                // Enabled = "Sell-to Customer No." <> '';
                Visible = false;
                SubPageLink = "Document No." = FIELD("No.");
                // UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        // Add changes to page actions here
        addafter("Prepa&yment")
        {
            group(Sprut)
            {
                CaptionML = ENU = 'Sprut',
                            RUS = 'Sprut';
                Image = Prepayment;
                // Visible = UserId = 'YEKAR';

                action(ApplyInvoiceToCrMemo)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'ApplyInvoiceToCrMemo',
                                RUS = 'ApplyInvoiceToCrMemo';
                    Image = ApplyEntries;

                    trigger OnAction()
                    var
                        PrepMgt: Codeunit "Prepayment Management";
                        SH: Record "Sales Header";
                    begin
                        CurrPage.SetSelectionFilter(SH);
                        SH.FindSet();
                        repeat
                            PrepMgt.CustPrepmtApply(SH."No.");
                        until SH.Next() = 0;
                        Message('Apply Invoice To Cr-Memo is Ok!')
                    end;
                }
                action(OnModifySalesOrderFromOrder)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'OnModifySalesOrderFromOrder',
                                RUS = 'OnModifySalesOrderFromOrder';
                    Image = MakeOrder;

                    trigger OnAction()
                    var
                        SalesHeader: Record "Sales Header";
                    begin
                        CurrPage.SetSelectionFilter(SalesHeader);
                        SalesHeader.FindSet();
                        repeat
                            CRMAction.OnAfterChangedSalesOrder('Invoice', SalesHeader."No.", SalesHeader."CRM Header ID");
                        until SalesHeader.Next() = 0;
                        Message('Task Modify Order Ok!')
                    end;
                }
                action(OnModifySalesOrderInTask)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'OnModifySalesOrderInTask',
                                RUS = 'OnModifySalesOrderInTask';
                    Image = MakeOrder;

                    trigger OnAction()
                    var
                        SalesHeader: Record "Sales Header";
                    begin
                        CurrPage.SetSelectionFilter(SalesHeader);
                        SalesHeader.FindSet();
                        repeat
                            PrepaymentMgt.OnModifySalesOrderInTask(SalesHeader."No.")
                        until SalesHeader.Next() = 0;
                        Message('Task Modify Order Ok!')
                    end;
                }
                action(OnTaskModificationSalerOrder)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'OnTaskModificationSalerOrder',
                                RUS = 'OnTaskModificationSalerOrder';
                    Image = MakeOrder;

                    trigger OnAction()
                    var
                        TaskModifyOrder: Codeunit "Task Modify Order";
                    begin
                        if Codeunit.Run(Codeunit::"Task Modify Order") then
                            Message('Task Modify Order Ok!')
                        else
                            Error(GetLastErrorText);
                    end;
                }

                // >>
                action(OnModifyOrder)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'OnModifyOrder',
                                RUS = 'OnModifyOrder';
                    Image = MakeOrder;

                    trigger OnAction()
                    var
                        TaskModifyOrder: Codeunit "Task Modify Order";
                    begin
                        Codeunit.Run(Codeunit::"Modification Order", Rec);
                        // if Codeunit.Run(Codeunit::"Modification Order", Rec) then
                        Message('Sales Order Modified Ok!')
                        //     else
                        //         Error(GetLastErrorText);
                    end;
                }

                action(OnSendToCRM)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'OnSendToCRM',
                                RUS = 'OnSendToCRM';
                    Image = SendConfirmation;

                    trigger OnAction()
                    var
                        BCIdResponseText: Text;
                        BCIdEntityType: Label 'bcid';
                        POSTrequestMethod: Label 'POST';
                    begin
                        if not WebServicesMgt.SetInvoicesLineIdToCRM(Rec."No.", BCIdEntityType, POSTrequestMethod, BCIdResponseText) then
                            Error(BCIdResponseText);
                        Message('Line Id Updated Ok!');
                    end;
                }

                // <<
                action(OnSendToEmail)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'OnSendToEmail',
                                RUS = 'OnSendToEmail';
                    Image = SendEmailPDF;

                    trigger OnAction()
                    var
                        PDFToEmail: Codeunit "Email Invoice As PDF Method";
                    begin
                        // WebServicesMgt.SendToEmail(Rec."No.");
                        PDFToEmail.UnApplyDocToAccounter(Rec."No.");
                        Message('UnApply Doc Sended Mail To Accounter!');
                    end;
                }

                action(PostPrepaymentInvoiceSprut)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'Post Prepayment Invoice Sprut',
                            RUS = 'Учет счета на предоплату';
                    Image = PrepaymentInvoice;

                    trigger OnAction()
                    begin
                        SalesPostPrepaymentsSprut.PostPrepaymentInvoiceSprut(Rec);
                    end;
                }
                action(PostPrepaymentCreditMemoSprut)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'Post Prepayment Credit Memo Sprut',
                            RUS = 'Учет кредит ноты на предоплату';
                    Image = PrepaymentCreditMemo;

                    trigger OnAction()
                    begin
                        SalesPostPrepaymentsSprut.PostPrepaymentCreditMemoSprut(Rec);
                    end;
                }
                action(UnApplyEntriesSprut)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'Unapply Entries Sprut',
                            RUS = 'Отменить применение операций';
                    Image = UnApply;

                    trigger OnAction()
                    begin
                        PrepaymentMgt.UnApplyPayments(Rec."No.");
                    end;
                }
                action(CreatePrepaymentInvoiceByAmount)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'Create Prepayment Invoice By Amount',
                            RUS = 'Создание счета на предоплату по сумме';
                    Image = PrepaymentInvoice;

                    trigger OnAction()
                    var
                        invoiceID: Text[50];
                        prepaymentAmount: Decimal;
                        crmId: Guid;
                        invoiceNo1C: Text[50];
                        API_SalesInvoice: Page "APIV2 - Sales Invoice";
                        postingDate: Date;
                        dueDate: Date;
                    begin
                        invoiceID := 'INV-01942-D4F6G1';
                        prepaymentAmount := 75;
                        crmId := '12b095da-4e2a-eb11-a813-000d3aba77ea';
                        invoiceNo1C := 'Test1C';
                        API_SalesInvoice.SetInit(invoiceID, prepaymentAmount, crmId, invoiceNo1C, postingDate, dueDate);
                        API_SalesInvoice.CreatePrepaymentInvoice("No.");
                    end;
                }
                action(GetSpecification)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'Get Specification',
                                RUS = 'Получить спецификацию';
                    Image = ShowInventoryPeriods;

                    trigger OnAction()
                    var
                        _Item: Record Item;
                        _jsonErrorItemList: JsonArray;
                        _jsonItem: JsonObject;
                        _jsonToken: JsonToken;
                        _jsonText: Text;
                        TotalCount: Integer;
                        Counter: Integer;
                        responseText: Text;
                        connectorCode: Label 'CRM';
                        entityType: Label 'specification';
                        POSTrequestMethod: Label 'POST';
                        SalesOrderNo: Text;
                    begin
                        SalesOrderNo := 'ПРЗК-20-00053';
                        WebServicesMgt.GetSpecificationFromCRM(SalesOrderNo, entityType, POSTrequestMethod, responseText);
                        Message(responseText);
                    end;
                }
                action(GetPrepInvoices)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'Get Prep.Invoices',
                                RUS = 'Получить счета на предоплату';
                    Image = ShowInventoryPeriods;

                    trigger OnAction()
                    var
                        _Item: Record Item;
                        _jsonErrorItemList: JsonArray;
                        _jsonItem: JsonObject;
                        _jsonToken: JsonToken;
                        _jsonText: Text;
                        TotalCount: Integer;
                        Counter: Integer;
                        responseText: Text;
                        connectorCode: Label 'CRM';
                        entityType: Label 'invoice';
                        POSTrequestMethod: Label 'POST';
                        SalesOrderNo: Text;
                    begin
                        SalesOrderNo := 'ПРЗК-20-00047';
                        WebServicesMgt.GetInvoicesFromCRM(SalesOrderNo, entityType, POSTrequestMethod, responseText);
                        Message(responseText);
                    end;
                }
                action(ModifySalesOrder)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'Modify Sales Order',
                                RUS = 'Изменить заказ продажи';
                    Image = ShowInventoryPeriods;

                    trigger OnAction()
                    var
                        msgSalesOrderModified: Label 'Sales Order %1 Modified';
                    begin
                        // PrepaymentMgt.OnModifySalesOrderOneLine(Rec."No.");
                        PrepaymentMgt.OnModifySalesOrderInTask(Rec."No.");
                        Message(msgSalesOrderModified, Rec."No.");
                    end;
                }
                action(ReportUnApppliedEntry)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'Report UnAppplied Entries',
                                RUS = 'Отчет непримененных операций';
                    Image = ShowInventoryPeriods;

                    trigger OnAction()
                    var
                        _SalesHeader: Record "Sales Header";
                    begin
                        CurrPage.SetSelectionFilter(_SalesHeader);
                        Report.Run(Report::"UnApply Prep. Cust. Entry", true, true, _SalesHeader);
                    end;
                }
                action(OnPostSalesOrder)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'On Post Sales Order',
                                RUS = 'On Post Sales Order';
                    Image = ShowInventoryPeriods;

                    trigger OnAction()
                    var
                        cmrAction: Codeunit "CRM Action API";
                    begin
                        cmrAction.OnPostSalesOrder("No.", 'Test01', '00000000-0000-1111-1111-000000000000', 0, '1CTest', 20210518D, 20210528D, '', '');
                    end;
                }
            }
        }
        addafter("Create &Warehouse Shipment")
        {
            action(CreateTransferOrder)
            {
                ApplicationArea = All;
                CaptionML = ENU = 'Create Transfer Order',
                            RUS = 'Создать перемещение';
                Image = TransferOrder;

                trigger OnAction()
                var
                    locSalesLine: Record "Sales Line";
                    tempSalesLine: Record "Sales Line" temporary;
                    locItem: Record Item;
                begin
                    locSalesLine.SetRange("Document Type", locSalesLine."Document Type"::Order);
                    locSalesLine.SetRange("Document No.", "No.");
                    if locSalesLine.FindSet() then
                        repeat
                            if locItem.Get(locSalesLine."No.")
                            and (locItem.Type in [locItem.Type::Inventory]) then begin
                                tempSalesLine := locSalesLine;
                                tempSalesLine.Insert();
                            end;
                        until locSalesLine.Next() = 0;

                    Page.Run(Page::"Create Transfer", tempSalesLine);
                end;
            }
        }
    }

    var
        CRMAction: Codeunit "CRM Action API";
        SalesPostPrepaymentsSprut: Codeunit "Sales-Post Prepayments Sprut";
        PrepaymentMgt: Codeunit "Prepayment Management";
        WebServicesMgt: Codeunit "Web Service Mgt.";
        MatchContragent: Codeunit "Match Contragent";
}