page 50009 "Company Integration List"
{
    CaptionML = ENU = 'Companies Integration List',
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
                field(Prefix; Prefix)
                {
                    ApplicationArea = All;
                }
                field("Copy Items From"; "Copy Items From")
                {
                    ApplicationArea = All;
                }
                field("Copy Items To"; "Copy Items To")
                {
                    ApplicationArea = All;
                }
                field("Environment Production"; "Environment Production")
                {
                    ApplicationArea = All;
                }
                field("Send Email UnApply Doc."; "Send Email UnApply Doc.")
                {
                    ApplicationArea = All;
                }
                field("Send Email Error Tasks"; "Send Email Error Tasks")
                {
                    ApplicationArea = All;
                }
                field("Integration With 1C"; "Integration With 1C")
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
            group(CopyItemsFrom)
            {
                CaptionML = ENU = 'Copy Items From',
                            RUS = 'Копировать товары с';
                action(SetSelectionForCopyFrom)
                {
                    ApplicationArea = Warehouse;
                    CaptionML = ENU = 'Set Selection For Copy From',
                                RUS = 'Выбрать для копирования с';
                    // ToolTipML = ENU = 'Register package document to the next stage of processing. You must unregister the document before you can make changes to it.',
                    //             RUS = 'Зарегистрировать документов упаковки на следующий этап обработки. Необходимо отменить регистрацию документа, чтобы в него можно было вносить изменения.';
                    Image = CopyItem;

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(CompIntegr);
                        CompIntegr.ModifyAll("Copy Items From", true, true);
                        CompIntegr.ModifyAll("Copy Items To", false, true);
                        CurrPage.Update(false);
                    end;
                }
                action(SetUnSelectionForCopyFrom)
                {
                    ApplicationArea = Warehouse;
                    CaptionML = ENU = 'Set UnSelection For Copy From',
                                RUS = 'Снять признак копирования с';
                    Image = CopyItem;

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(CompIntegr);
                        CompIntegr.ModifyAll("Copy Items From", false, true);
                        CurrPage.Update(false);
                    end;
                }
            }
            group(CopyItemsTo)
            {
                CaptionML = ENU = 'Copy Items To',
                            RUS = 'Копировать товары в';
                action(SetSelectionForCopyTo)
                {
                    ApplicationArea = Warehouse;
                    CaptionML = ENU = 'Set Selection For Copy To',
                                RUS = 'Выбрать для копирования в';
                    Image = CopyItem;

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(CompIntegr);
                        CompIntegr.ModifyAll("Copy Items To", true, true);
                        CompIntegr.ModifyAll("Copy Items From", false, true);
                        CurrPage.Update(false);
                    end;
                }
                action(SetUnSelectionForCopyTo)
                {
                    ApplicationArea = Warehouse;
                    CaptionML = ENU = 'Set UnSelection For Copy To',
                                RUS = 'Снять признак копирования в';
                    Image = CopyItem;

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(CompIntegr);
                        CompIntegr.ModifyAll("Copy Items To", false, true);
                        CurrPage.Update(false);
                    end;
                }
            }
            group(EnvironmentProduction)
            {
                CaptionML = ENU = 'Environment Production',
                            RUS = 'Произв. среда';
                action(SetSelectionEnvironment)
                {
                    ApplicationArea = Warehouse;
                    CaptionML = ENU = 'Set Selection Production',
                                RUS = 'Установить признак производства';
                    Image = Production;

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(CompIntegr);
                        CompIntegr.ModifyAll("Environment Production", true, true);
                        CurrPage.Update(false);
                    end;
                }
                action(SetUnSelectionEnvironment)
                {
                    ApplicationArea = Warehouse;
                    CaptionML = ENU = 'Set UnSelection Production',
                                RUS = 'Снять признак производства';
                    Image = Production;

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(CompIntegr);
                        CompIntegr.ModifyAll("Environment Production", false, true);
                        CurrPage.Update(false);
                    end;
                }
            }
            group(SendEmailUnApplyDoc)
            {
                CaptionML = ENU = 'Send Email UnApply Doc',
                            RUS = 'Отсылать почной неприм. док.';
                action(SetSelectionSendEmail)
                {
                    ApplicationArea = Warehouse;
                    CaptionML = ENU = 'Set Selection Send Email',
                                RUS = 'Установить отсылку почты';
                    Image = Production;

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(CompIntegr);
                        CompIntegr.ModifyAll("Send Email UnApply Doc.", true, true);
                        CurrPage.Update(false);
                    end;
                }
                action(SetUnSelectionSendEmail)
                {
                    ApplicationArea = Warehouse;
                    CaptionML = ENU = 'Set UnSelection Send Email',
                                RUS = 'Отменить отсылку почты';
                    Image = Production;

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(CompIntegr);
                        CompIntegr.ModifyAll("Send Email UnApply Doc.", false, true);
                        CurrPage.Update(false);
                    end;
                }
            }
            group(SendEmailErrorTasks)
            {
                CaptionML = ENU = 'Send Email Error Tasks',
                            RUS = 'Отсылать почной ошибки задач';
                action(SetSelectionSendEmailErrTask)
                {
                    ApplicationArea = Warehouse;
                    CaptionML = ENU = 'Set Selection Send Email',
                                RUS = 'Установить отсылку почты';
                    Image = Production;

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(CompIntegr);
                        CompIntegr.ModifyAll("Send Email Error Tasks", true, true);
                        CurrPage.Update(false);
                    end;
                }
                action(SetUnSelectionSendEmailErrTask)
                {
                    ApplicationArea = Warehouse;
                    CaptionML = ENU = 'Set UnSelection Send Email',
                                RUS = 'Отменить отсылку почты';
                    Image = Production;

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(CompIntegr);
                        CompIntegr.ModifyAll("Send Email Error Tasks", false, true);
                        CurrPage.Update(false);
                    end;
                }
            }
            group(IntegrationWith1C)
            {
                CaptionML = ENU = 'Integration With 1C',
                            RUS = 'Интеграция с 1С';
                action(SetSelectionIntegrationWith1C)
                {
                    ApplicationArea = Warehouse;
                    CaptionML = ENU = 'Set Selection Integration',
                                RUS = 'Установить интеграцию';
                    Image = Production;

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(CompIntegr);
                        CompIntegr.ModifyAll("Integration With 1C", true, true);
                        CurrPage.Update(false);
                    end;
                }
                action(SetUnSelectionIntegrationWith1C)
                {
                    ApplicationArea = Warehouse;
                    CaptionML = ENU = 'Set UnSelection Integration',
                                RUS = 'Отменить интеграцию';
                    Image = Production;

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(CompIntegr);
                        CompIntegr.ModifyAll("Integration With 1C", false, true);
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }
    var
        CompIntegr: Record "Company Integration";
}