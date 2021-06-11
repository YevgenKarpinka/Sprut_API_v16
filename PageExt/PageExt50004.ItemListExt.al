pageextension 50004 "Item List Ext." extends "Item List"
{
    layout
    {
        // Add changes to page layout here
        addlast(Control1)
        {
            field("CRM Item Id"; "CRM Item Id")
            {
                ApplicationArea = All;
                ToolTipML = ENU = 'Specifies CRM Item Id.',
                            RUS = 'Соответствует ID товара в CRM.';
            }
            field("1C Path"; "1C Path")
            {
                ApplicationArea = All;
                ToolTipML = ENU = 'Specifies 1C Path.',
                            RUS = 'Определяет путь в 1C.';
            }
        }
        addafter("Last Date Modified")
        {
            field("Last DateTime Modified"; "Last DateTime Modified")
            {
                ApplicationArea = All;
                // Visible = false;
            }
        }
    }

    actions
    {
        // Add changes to page actions here
        addfirst(PeriodicActivities)
        {
            group(groupCRM)
            {
                CaptionML = ENU = 'CRM', RUS = 'CRM';
                Image = SuggestCustomerPayments;
                Visible = CRMEnable;

                action(OnCopyAllItems)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'On Copy All Items', RUS = 'Запуск копирования всех товаров';
                    Image = CopyItem;
                    // Visible = UserId = 'ekar';

                    trigger OnAction()
                    var
                        CopyItems: Codeunit "Copy Items to All Companies";
                        msgOk: Label 'Все товары скопированы во все компании';
                    begin
                        CopyItems.CopyAllItemsToClone();
                        // CopyItems.Run();
                        // Message(msgOk);
                    end;
                }
                action(OnCopyItems)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'On Copy Items', RUS = 'Запуск копирования товаров';
                    Image = CopyItem;

                    trigger OnAction()
                    var
                        // CopyItems: Codeunit "Copy Items to All Companies";
                        msgOk: Label 'Товары скопированы во все компании';
                    begin
                        // CopyItems.Run();
                        Codeunit.Run(Codeunit::"Copy Items to All Companies");
                        Message(msgOk);
                    end;
                }

                action(Send)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'Send Item', RUS = 'Отправить товар';
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
                        entityType: Label 'products';
                        msgEntityType: Label 'Товары';
                        POSTrequestMethod: Label 'POST';
                        PATCHrequestMethod: Label 'PATCH';
                        TokenType: Text;
                        AccessToken: Text;
                        APIResult: Text;
                        requestMethod: Text[20];
                        entityTypeValue: Text;
                        CopyItem: Codeunit "Copy Items to All Companies";
                    begin
                        CurrPage.SetSelectionFilter(_Item);

                        Counter := 0;
                        _Item.SetFilter(Description, '<>%1', '');
                        TotalCount := _Item.Count;
                        ConfigProgressBarRecord.Init(TotalCount, Counter, STRSUBSTNO(ApplyingURLMsg, _Item.TableCaption));

                        if not WebServiceMgt.GetOauthToken(TokenType, AccessToken, APIResult) then begin
                            // loging error APIResult
                            _jsonItem.ReadFrom(APIResult);
                            _jsonErrorItemList.Add(_jsonItem);
                        end;

                        if _jsonErrorItemList.Count = 0 then
                            if _Item.FindSet(false, false) then
                                repeat
                                    if CopyItem.CheckItemFieldsFilled(_Item) then begin
                                        // Create JSON for CRM
                                        if not IsNullGuid(_Item."CRM Item Id") then begin
                                            requestMethod := PATCHrequestMethod;
                                            _jsonItem := WebServiceMgt.jsonItemsToPatch(_Item."No.");
                                            entityTypeValue := StrSubstNo('%1(%2)', entityType, LowerCase(DelChr(_Item."CRM Item Id", '<>', '{}')));
                                        end else begin
                                            requestMethod := POSTrequestMethod;
                                            _jsonItem := WebServiceMgt.jsonItemsToPost(_Item."No.");
                                            entityTypeValue := entityType;
                                        end;

                                        _jsonItem.WriteTo(_jsonText);
                                        Counter += 1;

                                        ConfigProgressBarRecord.Update(STRSUBSTNO(RecordsXofYMsg, Counter, TotalCount));

                                        IsSuccessStatusCode := true;
                                        // try send to CRM
                                        if not WebServiceMgt.CreateProductInCRM(entityTypeValue, requestMethod, TokenType, AccessToken, _jsonText) then begin
                                            _jsonErrorItemList.Add(_jsonItem);
                                            _jsonItem.ReadFrom(_jsonText);
                                            _jsonItem.Add('entityTypeValue', entityTypeValue);
                                            _jsonErrorItemList.Add(_jsonItem);
                                        end else
                                            // add CRM product ID to Item
                                            WebServiceMgt.AddCRMproductIdToItem(_jsonText);
                                    end else
                                        CopyItem.GetErrorFillingItem(_Item);
                                until _Item.Next() = 0;
                        ConfigProgressBarRecord.Close;
                        if _jsonErrorItemList.Count > 0 then begin
                            _jsonErrorItemList.WriteTo(_jsonText);
                            CaptionMgt.SaveStreamToFile(_jsonText, 'errorItemList.txt');
                            Message(msgSentWithError, msgEntityType);
                        end else
                            Message(msgSentOk, msgEntityType);
                    end;
                }
                action(SendAll)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'Send All', RUS = 'Отправить все';
                    Image = SuggestVendorPayments;

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
                        entityType: Label 'products';
                        msgEntityType: Label 'Товары';
                        POSTrequestMethod: Label 'POST';
                        PATCHrequestMethod: Label 'PATCH';
                        TokenType: Text;
                        AccessToken: Text;
                        APIResult: Text;
                        requestMethod: Text[20];
                        entityTypeValue: Text;
                    begin
                        // CurrPage.SetSelectionFilter(_Item);

                        if not Confirm(cnfUpdateExistingItems, false) then begin
                            _Item.SetCurrentKey("CRM Item Id");
                            _Item.SetFilter("CRM Item Id", '=%1', '00000000-0000-0000-0000-000000000000');
                        end;

                        Counter := 0;
                        TotalCount := _Item.Count;
                        ConfigProgressBarRecord.Init(TotalCount, Counter, STRSUBSTNO(ApplyingURLMsg, _Item.TableCaption));

                        if not WebServiceMgt.GetOauthToken(TokenType, AccessToken, APIResult) then begin
                            // loging error APIResult
                            _jsonItem.ReadFrom(APIResult);
                            _jsonErrorItemList.Add(_jsonItem);
                        end;

                        if _jsonErrorItemList.Count = 0 then
                            if _Item.FindSet(false, false) then
                                repeat
                                    // Create JSON for CRM
                                    if not IsNullGuid(_Item."CRM Item Id") then begin
                                        requestMethod := PATCHrequestMethod;
                                        _jsonItem := WebServiceMgt.jsonItemsToPatch(_Item."No.");
                                        entityTypeValue := StrSubstNo('%1(%2)', entityType, _Item."CRM Item Id");
                                    end else begin
                                        requestMethod := POSTrequestMethod;
                                        _jsonItem := WebServiceMgt.jsonItemsToPost(_Item."No.");
                                        entityTypeValue := entityType;
                                    end;

                                    _jsonItem.WriteTo(_jsonText);
                                    Counter += 1;

                                    ConfigProgressBarRecord.Update(STRSUBSTNO(RecordsXofYMsg, Counter, TotalCount));

                                    IsSuccessStatusCode := true;
                                    // try send to CRM
                                    if not WebServiceMgt.CreateProductInCRM(entityTypeValue, requestMethod, TokenType, AccessToken, _jsonText) then begin
                                        _jsonErrorItemList.Add(_jsonItem);
                                        _jsonItem.ReadFrom(_jsonText);
                                        _jsonErrorItemList.Add(_jsonItem);
                                    end else
                                        // add CRM product ID to Item
                                        WebServiceMgt.AddCRMproductIdToItem(_jsonText);
                                until _Item.Next() = 0;
                        ConfigProgressBarRecord.Close;
                        if _jsonErrorItemList.Count > 0 then begin
                            _jsonErrorItemList.WriteTo(_jsonText);
                            CaptionMgt.SaveStreamToFile(_jsonText, 'errorItemList.txt');
                            Message(msgSentWithError, entityType);
                        end else
                            Message(msgSentOk, entityType);
                    end;
                }
                action(Send2File)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'Send to File', RUS = 'Отправить в файл';
                    Image = SuggestField;

                    trigger OnAction()
                    var
                        _Item: Record Item;
                        _jsonItemList: JsonArray;
                        _jsonItem: JsonObject;
                        _jsonToken: JsonToken;
                        _jsonText: Text;
                        TotalCount: Integer;
                        Counter: Integer;
                    begin
                        CurrPage.SetSelectionFilter(_Item);

                        Counter := 0;
                        TotalCount := _Item.Count;
                        ConfigProgressBarRecord.Init(TotalCount, Counter, STRSUBSTNO(ApplyingURLMsg, _Item.TableCaption));

                        if _Item.FindSet(false, false) then
                            repeat
                                // Create JSON for CRM
                                _jsonItem := WebServiceMgt.jsonItemsToPost(_Item."No.");
                                _jsonItemList.Add(_jsonItem);

                                ConfigProgressBarRecord.Update(STRSUBSTNO(RecordsXofYMsg, Counter, TotalCount));
                                Counter += 1;
                            until _Item.Next() = 0;
                        ConfigProgressBarRecord.Close;
                        _jsonItemList.WriteTo(_jsonText);
                        CaptionMgt.SaveStreamToFile(_jsonText, 'selectedItemList.txt');
                    end;
                }
                action(SendAll2File)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'Send All to File', RUS = 'Отправить все в файл';
                    Image = SuggestFinancialCharge;

                    trigger OnAction()
                    var
                        _Item: Record Item;
                        _jsonItemList: JsonArray;
                        _jsonItem: JsonObject;
                        _jsonToken: JsonToken;
                        _jsonText: Text;
                        TotalCount: Integer;
                        Counter: Integer;
                    begin
                        _Item.SetCurrentKey("CRM Item Id");
                        _Item.SetFilter("CRM Item Id", '=%1', '');

                        Counter := 0;
                        TotalCount := _Item.Count;
                        ConfigProgressBarRecord.Init(TotalCount, Counter, STRSUBSTNO(ApplyingURLMsg, _Item.TableCaption));

                        if _Item.FindSet(false, false) then
                            repeat
                                // Create JSON for CRM
                                _jsonItem := WebServiceMgt.jsonItemsToPost(_Item."No.");
                                _jsonItemList.Add(_jsonItem);

                                ConfigProgressBarRecord.Update(STRSUBSTNO(RecordsXofYMsg, Counter, TotalCount));
                                Counter += 1;
                            until _Item.Next() = 0;
                        ConfigProgressBarRecord.Close;
                        _jsonItemList.WriteTo(_jsonText);
                        CaptionMgt.SaveStreamToFile(_jsonText, 'allItemList.txt');
                    end;
                }
                action(SendTestPayment)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'Send Test Payment', RUS = 'Отправить тестовую оплату';
                    Image = SuggestCustomerPayments;

                    trigger OnAction()
                    var
                        _jsonErrorItemList: JsonArray;
                        _jsonPayment: JsonObject;
                        _jsonToken: JsonToken;
                        _jsonText: Text;
                        TotalCount: Integer;
                        Counter: Integer;
                        responseText: Text;
                        connectorCode: Label 'CRM';
                        entityType: Label 'tct_payments';
                        POSTrequestMethod: Label 'POST';
                        TokenType: Text;
                        AccessToken: Text;
                        APIResult: Text;
                        requestMethod: Text[20];
                        entityTypeValue: Text;
                        // >> for test payment
                        salesOrderId: Text[50];
                        invoiceId: Text[50];
                        payerDetails: Text[100];
                        paymentAmount: Decimal;
                    // <<
                    begin

                        // >> init for test
                        salesOrderId := '446e2ca1-35a6-ea11-a812-000d3aba77ea';
                        invoiceId := '93dd43f3-e5a3-ea11-a812-000d3abaae50';
                        payerDetails := 'test payment from BC';
                        paymentAmount := 155;
                        // <<

                        Counter := 0;
                        // TotalCount := _Item.Count;
                        TotalCount := 1;
                        ConfigProgressBarRecord.Init(TotalCount, Counter, StrSubstNo(ApplyingURLMsg, 'Payment'));

                        if not WebServiceMgt.GetOauthToken(TokenType, AccessToken, APIResult) then begin
                            // loging error APIResult
                            _jsonPayment.ReadFrom(APIResult);
                            _jsonErrorItemList.Add(_jsonPayment);
                        end;

                        if _jsonErrorItemList.Count = 0 then begin
                            // Create JSON for CRM
                            requestMethod := POSTrequestMethod;
                            _jsonPayment := WebServiceMgt.jsonPaymentToPost(salesOrderId, invoiceId, payerDetails, paymentAmount);
                            entityTypeValue := entityType;

                            _jsonPayment.WriteTo(_jsonText);
                            Counter += 1;

                            ConfigProgressBarRecord.Update(STRSUBSTNO(RecordsXofYMsg, Counter, TotalCount));

                            IsSuccessStatusCode := true;
                            // try send to CRM
                            if not WebServiceMgt.CreatePaymentInCRM(entityTypeValue, requestMethod, TokenType, AccessToken, _jsonText) then begin
                                _jsonErrorItemList.Add(_jsonPayment);
                                _jsonPayment.ReadFrom(_jsonText);
                                _jsonErrorItemList.Add(_jsonPayment);
                            end else
                                // add CRM product ID to Item
                                WebServiceMgt.AddCRMproductIdToItem(_jsonText);
                        end;
                        ConfigProgressBarRecord.Close;
                        if _jsonErrorItemList.Count > 0 then begin
                            _jsonErrorItemList.WriteTo(_jsonText);
                            CaptionMgt.SaveStreamToFile(_jsonText, 'errorItemList.txt');
                            Message(msgSentWithError, entityType);
                        end else
                            Message(msgSentOk, entityType);
                    end;
                }
                action(OnTaskPaymentSend)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'On Task Payment Send', RUS = 'Запуск очереди отправки платежей';
                    Image = SuggestCustomerPayments;

                    trigger OnAction()
                    begin
                        if Codeunit.Run(Codeunit::"Task Payment To CRM") then
                            Message(msgSentOk, 'payment')
                        else
                            Message(msgSentWithError, 'payment');
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if UserSetup.Get(UserId) then
            CRMEnable := UserSetup."Admin. Holding";
    end;

    var
        UserSetup: Record "User Setup";
        WebServiceMgt: Codeunit "Web Service Mgt.";
        RecordsXofYMsg: TextConst ENU = 'Records: %1 of %2',
                                RUS = 'Запись: %1 из %2';
        ApplyingURLMsg: TextConst ENU = 'Sending Table %1',
                                RUS = 'Пересылается таблица %1';
        msgSentOk: TextConst ENU = 'Sent %1 in CRM is Ok!',
                            RUS = 'Отправлено %1 в CRM!';
        msgSentWithError: TextConst ENU = 'Sent %1 in CRM with Errors!',
                                    RUS = 'Отправлено %1 в CRM с ошибками!';
        cnfUpdateExistingItems: TextConst ENU = 'Update existing CRM products?',
                                RUS = 'Обновлять существующие в CRM товары?';
        ConfigProgressBarRecord: Codeunit "Config Progress Bar";
        CaptionMgt: Codeunit "Caption Mgt.";
        IsSuccessStatusCode: Boolean;
        CRMEnable: Boolean;
}