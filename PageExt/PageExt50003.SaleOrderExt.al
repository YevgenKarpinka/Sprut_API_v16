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
                        API_SalesInvoice: Page "APIV2 - Sales Invoice";
                    begin
                        invoiceID := 'INV-01942-D4F6G1';
                        prepaymentAmount := 2270;
                        API_SalesInvoice.SetInit(invoiceID, prepaymentAmount);
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
                        PrepaymentMgt.OnModifySalesOrder(Rec."No.");
                        Message(msgSalesOrderModified, Rec."No.");
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