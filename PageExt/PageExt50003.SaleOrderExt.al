pageextension 50003 "Sale Order Ext" extends "Sales Order"
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

                action(CRMTaskModificationSalerOrder)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'CRMTaskModificationSalerOrder',
                                RUS = 'CRMTaskModificationSalerOrder';
                    Image = MakeOrder;

                    trigger OnAction()
                    var
                        TaskModifyOrder: Codeunit "Task Modify Order";
                    begin
                        PrepaymentMgt.OnModifySalesOrderInTask("No.");
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
                        API_SalesInvoice: Page "APIV2 - Sales Invoice";
                    begin
                        invoiceID := 'INV-01942-D4F6G1';
                        prepaymentAmount := 2270;
                        crmId := '12b095da-4e2a-eb11-a813-000d3aba77ea';
                        API_SalesInvoice.SetInit(invoiceID, prepaymentAmount, crmId);
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
                        cmrAction.OnPostSalesOrder(Rec."No.", 'Test01', '00000000-0000-0000-0000-000000000000', 21.07);
                    end;
                }
            }
        }
    }

    var
        SalesPostPrepaymentsSprut: Codeunit "Sales-Post Prepayments Sprut";
        PrepaymentMgt: Codeunit "Prepayment Management";
        WebServicesMgt: Codeunit "Web Service Mgt.";
}