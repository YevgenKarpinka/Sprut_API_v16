page 50014 "Create Transfer"
{
    PageType = Worksheet;
    ApplicationArea = Basic, Suite;
    UsageCategory = Tasks;
    SourceTable = "Sales Line";
    DeleteAllowed = false;

    CaptionML = ENU = 'Create Direct Transfer',
                RUS = 'Создание прямого перемещения';

    layout
    {
        area(Content)
        {
            field(TransferFromCode; TransferFromCode)
            {
                ApplicationArea = All;
                CaptionML = ENU = 'Transfer-from Code',
                            RUS = 'Код склада-источника';
                TableRelation = Location where("Use As In-Transit" = const(false));
                Lookup = true;

                trigger OnValidate()
                begin
                    CurrPage.Update(false);
                end;
            }
            field(TransferToCode; TransferToCode)
            {
                ApplicationArea = All;
                CaptionML = ENU = 'Transfer-to Code',
                            RUS = 'Код склада-назначения';
                TableRelation = Location where("Use As In-Transit" = const(false));
                Lookup = true;

                trigger OnValidate()
                begin
                    CurrPage.Update(false);
                end;
            }
            field(DirectTransfer; DirectTransfer)
            {
                ApplicationArea = All;
                CaptionML = ENU = 'DirectTransfer',
                            RUS = 'Прямое перемещение';

                trigger OnValidate()
                begin
                    CurrPage.Update(false);
                end;
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
                field(Description; Description)
                {
                    ApplicationArea = All;

                }
                field("Location Code"; "Location Code")
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
            action(CreateTransferOrder)
            {
                ApplicationArea = All;
                CaptionML = ENU = 'Create Transfer Order',
                            RUS = 'Создать перемещение';

                trigger OnAction()
                begin
                    CurrPage.SetSelectionFilter(glSalesLine);
                    glSalesLine.FindSet();
                    TransferOrderMgt.CreateTransferOrderFromSalesOrder(glSalesLine, glTransferHeader, TransferFromCode, TransferToCode, DirectTransfer);
                    if Confirm(cnfOpenCreatedTransfer, true, glTransferHeader."No.") then
                        if DirectTransfer then
                            Page.Run(Page::"Direct Transfer", glTransferHeader)
                        else
                            Page.Run(Page::"Transfer Order", glTransferHeader);
                end;
            }
        }
    }

    var
        glSalesLine: Record "Sales Line";
        glTransferHeader: Record "Transfer Header";
        TransferOrderMgt: Codeunit "Transfer Order Mgt.";
        TransferFromCode: Code[20];
        TransferToCode: Code[20];
        DirectTransfer: Boolean;
        cnfOpenCreatedTransfer: TextConst ENU = 'Open Created Transfer Order %1?',
                                            RUS = 'Открыть созданное перемещение %1?';
}