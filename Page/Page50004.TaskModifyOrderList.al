page 50004 "Task Modify Order List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Task Modify Order";
    // Editable = false;
    SourceTableView = order(descending) where(Status = filter(<> Done));
    CaptionML = ENU = 'Task Modify Order List',
                RUS = 'Список задач модификации заказа';

    layout
    {
        area(Content)
        {
            repeater(ItemsTransferSite)
            {
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = All;
                }
                field(Status; Status)
                {
                    ApplicationArea = All;
                }
                field("Work Status"; "Work Status")
                {
                    ApplicationArea = All;
                }
                field("Order No."; "Order No.")
                {
                    ApplicationArea = All;
                }
                field("Attempts Send"; "Attempts Send")
                {
                    ApplicationArea = All;
                }
                field("Create User Name"; "Create User Name")
                {
                    ApplicationArea = All;
                }
                field("Create Date Time"; "Create Date Time")
                {
                    ApplicationArea = All;
                }
                field("Modify User Name"; "Modify User Name")
                {
                    ApplicationArea = All;
                }
                field("Modify Date Time"; "Modify Date Time")
                {
                    ApplicationArea = All;
                }
                field("Error Text"; "Error Text")
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
            group(UpdateWorkStatus)
            {
                CaptionML = ENU = 'UpdateWorkStatus',
                            RUS = 'Обновить статус работы';
                action(UpdateToWaitingForWork)
                {
                    ApplicationArea = Warehouse;
                    CaptionML = ENU = 'Update To WaitingForWork',
                                RUS = 'Обновить в ожидание очереди';
                    // ToolTipML = ENU = 'Register package document to the next stage of processing. You must unregister the document before you can make changes to it.',
                    //             RUS = 'Зарегистрировать документов упаковки на следующий этап обработки. Необходимо отменить регистрацию документа, чтобы в него можно было вносить изменения.';
                    Image = UpdateDescription;

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(recTaskModifyOrder);
                        recTaskModifyOrder.ModifyAll("Work Status", "Work Status"::WaitingForWork, true);
                        CurrPage.Update(false);
                    end;
                }
                action(UpdateToDone)
                {
                    ApplicationArea = Warehouse;
                    CaptionML = ENU = 'Update To Done',
                                RUS = 'Обновить в закончить';
                    Image = UpdateDescription;

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(recTaskModifyOrder);
                        recTaskModifyOrder.ModifyAll(Status, Status::Done, true);
                        recTaskModifyOrder.ModifyAll("Work Status", "Work Status"::Done, true);
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    var
        recTaskModifyOrder: Record "Task Modify Order";
}