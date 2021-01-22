page 50014 "Create Direct Transfer"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Tasks;
    SourceTable = "Sales Line";
    Editable = false;
    CaptionML = ENU = 'Create Direct Transfer',
                RUS = 'Создание прямого перемещения';

    layout
    {
        area(Content)
        {
            group(SelectLocation)
            {
                field(TransferFromCode; TransferFromCode)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'Transfer-from Code',
                                RUS = 'Код склада-источника';
                    TableRelation = Location.Code;
                }
                field(TransferToCode; TransferToCode)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'Transfer-to Code',
                                RUS = 'Код склада-назначения';
                    TableRelation = Location.Code;
                }
            }
            repeater(SelectItemsForTransfer)
            {
                CaptionML = ENU = 'Select Items For Transfer',
                            RUS = 'Выберите строки для перемещения';

                field("No."; "No.")
                {
                    ApplicationArea = All;

                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = All;

                }
                field("Unit of Measure"; "Unit of Measure")
                {
                    ApplicationArea = All;

                }
                field("Unit Price"; "Unit Price")
                {
                    ApplicationArea = All;

                }
                field("Line Amount"; "Line Amount")
                {
                    ApplicationArea = All;

                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Select)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    CurrPage.SetSelectionFilter(glSalesLine);
                    TransferOrderMgt.CreateTransferOrderFromSalesOrder(glSalesLine, TransferFromCode, TransferToCode);
                end;
            }
            action(SelectAll)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    CurrPage.SetSelectionFilter(glSalesLine);
                    TransferOrderMgt.CreateTransferOrderFromSalesOrder(glSalesLine, TransferFromCode, TransferToCode);
                end;
            }
            action(UnSelectAll)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    CurrPage.SetSelectionFilter(glSalesLine);
                    TransferOrderMgt.CreateTransferOrderFromSalesOrder(glSalesLine, TransferFromCode, TransferToCode);
                end;
            }
        }
    }

    var
        glSalesLine: Record "Sales Line";
        TransferOrderMgt: Codeunit "Transfer Order Mgt.";
        TransferFromCode: Code[20];
        TransferToCode: Code[20];
}