page 50014 "Create Direct Transfer"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Tasks;
    SourceTable = "Sales Line";

    CaptionML = ENU = 'Create Direct Transfer',
                RUS = 'Создание прямого перемещения';

    layout
    {
        area(Content)
        {
            group(SelectLocation)
            {
                CaptionML = ENU = 'SelectLocation',
                            RUS = 'Выбор складов';

                field(TransferFromCode; TransferFromCode)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'Transfer-from Code',
                                RUS = 'Код склада-источника';
                    TableRelation = Location where("Use As In-Transit" = filter(false));
                }
                field(TransferToCode; TransferToCode)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'Transfer-to Code',
                                RUS = 'Код склада-назначения';
                    TableRelation = Location where("Use As In-Transit" = filter(false));
                }
                field(DirectTransfer; DirectTransfer)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'DirectTransfer',
                                RUS = 'Прямое перемещение';
                }
            }
            repeater(SelectItemsForTransfer)
            {
                CaptionML = ENU = 'Select Items For Transfer',
                            RUS = 'Выберите строки для перемещения';
                Editable = false;

                field("No."; "No.")
                {
                    ApplicationArea = All;

                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = All;

                }
                field("Unit of Measure Code"; "Unit of Measure Code")
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
            group(TransferOrder)
            {
                action(CreateTransferOrder)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'Create',
                                RUS = 'Создать';

                    trigger OnAction()
                    begin
                        // glSalesLine := Rec;
                        CurrPage.SetSelectionFilter(glSalesLine);
                        glSalesLine.FindSet();
                        TransferOrderMgt.CreateTransferOrderFromSalesOrder(glSalesLine, TransferFromCode, TransferToCode, DirectTransfer);
                    end;
                }
            }
        }
    }

    var
        glSalesLine: Record "Sales Line";
        TransferOrderMgt: Codeunit "Transfer Order Mgt.";
        TransferFromCode: Code[20];
        TransferToCode: Code[20];
        DirectTransfer: Boolean;
}