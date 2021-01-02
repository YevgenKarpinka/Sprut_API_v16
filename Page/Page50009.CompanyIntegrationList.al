page 50009 "Company Integration List"
{
    CaptionML = ENU = 'Company Integration List',
                RUS = 'Список компаний интеграции';
    // InsertAllowed = false;
    SourceTable = "Company Integration";
    DataCaptionFields = "Company Name";
    ApplicationArea = All;
    PageType = List;
    UsageCategory = History;
    Editable = true;


    layout
    {
        area(Content)
        {
            repeater(RepeaterName)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Company Name"; "Company Name")
                {
                    ApplicationArea = All;

                }
                field("Copy Items"; "Copy Items")
                {
                    ApplicationArea = All;

                }
                field("Environment Production"; "Environment Production")
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
            group(CopyItems)
            {
                CaptionML = ENU = 'Copy Items',
                            RUS = 'Копировать товары';
                action(SetSelectionForCopy)
                {
                    ApplicationArea = Warehouse;
                    CaptionML = ENU = 'Set Selection For Copy',
                                RUS = 'Выбрать для копирования';
                    // ToolTipML = ENU = 'Register package document to the next stage of processing. You must unregister the document before you can make changes to it.',
                    //             RUS = 'Зарегистрировать документов упаковки на следующий этап обработки. Необходимо отменить регистрацию документа, чтобы в него можно было вносить изменения.';
                    Image = CopyItem;

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(CompIntegr);
                        CompIntegr.ModifyAll("Copy Items", true);
                        CurrPage.Update(false);
                    end;
                }
                action(SetUnSelectionForCopy)
                {
                    ApplicationArea = Warehouse;
                    CaptionML = ENU = 'Set UnSelection For Copy',
                                RUS = 'Снять признак копирования';
                    // ToolTipML = ENU = 'Register package document to the next stage of processing. You must unregister the document before you can make changes to it.',
                    //             RUS = 'Зарегистрировать документов упаковки на следующий этап обработки. Необходимо отменить регистрацию документа, чтобы в него можно было вносить изменения.';
                    Image = CopyItem;

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(CompIntegr);
                        CompIntegr.ModifyAll("Copy Items", false);
                        CurrPage.Update(false);
                    end;
                }
            }
            group(EnvironmentProduction)
            {
                action(SetSelectionEnvironment)
                {
                    ApplicationArea = Warehouse;
                    CaptionML = ENU = 'Set Selection Production',
                                RUS = 'Установить признак производства';
                    // ToolTipML = ENU = 'Register package document to the next stage of processing. You must unregister the document before you can make changes to it.',
                    //             RUS = 'Зарегистрировать документов упаковки на следующий этап обработки. Необходимо отменить регистрацию документа, чтобы в него можно было вносить изменения.';
                    Image = Production;

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(CompIntegr);
                        CompIntegr.ModifyAll("Environment Production", true);
                        CurrPage.Update(false);
                    end;
                }
                action(SetUnSelectionEnvironment)
                {
                    ApplicationArea = Warehouse;
                    CaptionML = ENU = 'Set UnSelection Production',
                                RUS = 'Снять признак производства';
                    // ToolTipML = ENU = 'Register package document to the next stage of processing. You must unregister the document before you can make changes to it.',
                    //             RUS = 'Зарегистрировать документов упаковки на следующий этап обработки. Необходимо отменить регистрацию документа, чтобы в него можно было вносить изменения.';
                    Image = Production;

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(CompIntegr);
                        CompIntegr.ModifyAll("Environment Production", false);
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }
    var
        CompIntegr: Record "Company Integration";
}