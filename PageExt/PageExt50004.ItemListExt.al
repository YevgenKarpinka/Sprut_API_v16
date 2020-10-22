pageextension 50004 "Item List Ext." extends "Item List"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
        addfirst(PeriodicActivities)
        {
            group(eCommerce)
            {
                CaptionML = ENU = 'CRM', RUS = 'CRM';
                Image = SuggestCustomerPayments;

                action(Send)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'Send Item', RUS = 'Отправить товар';
                    Image = ShowInventoryPeriods;

                    trigger OnAction()
                    var
                        _Item: Record Item;
                        _jsonItemList: JsonArray;
                        _jsonErrorItemList: JsonArray;
                        _jsonItem: JsonObject;
                        _jsonToken: JsonToken;
                        _jsonText: Text;
                        TotalCount: Integer;
                        Counter: Integer;
                        responseText: Text;
                        connectorCode: Label 'CRM';
                        entityType: Label 'products';
                        requestMethod: Label 'POST';
                    begin
                        CurrPage.SetSelectionFilter(_Item);

                        Counter := 0;
                        TotalCount := _Item.Count;
                        ConfigProgressBarRecord.Init(TotalCount, Counter, STRSUBSTNO(ApplyingURLMsg, _Item.TableCaption));

                        if _Item.FindSet(false, false) then
                            repeat
                                // Create JSON for CRM
                                _jsonItem := WebServiceMgt.jsonItems(_Item."No.");
                                Counter += 1;
                                if _jsonItem.Get('productnumber', _jsonToken) then begin
                                    _jsonItemList.Add(_jsonItem);

                                    ConfigProgressBarRecord.Update(STRSUBSTNO(RecordsXofYMsg, Counter, TotalCount));

                                    if ((Counter mod 50) = 0) or (Counter = TotalCount) then begin
                                        _jsonItemList.WriteTo(_jsonText);

                                        IsSuccessStatusCode := true;
                                        // try send to CRM
                                        if not WebServiceMgt.ConnectToCRM(connectorCode, entityType, requestMethod, _jsonText) then begin
                                            _jsonErrorItemList.Add(_jsonItem);
                                            _jsonItem.ReadFrom(_jsonText);
                                            _jsonErrorItemList.Add(_jsonItem);
                                        end;
                                        // add CRM product ID to Item
                                        WebServiceMgt.AddCRMproductIdToItem(_jsonText);
                                        Clear(_jsonItemList);
                                    end;
                                end;
                            until _Item.Next() = 0;
                        ConfigProgressBarRecord.Close;
                        if _jsonErrorItemList.Count > 0 then begin
                            _jsonErrorItemList.WriteTo(_jsonText);
                            CaptionMgt.SaveStreamToFile(_jsonText, 'errorItemList.txt');
                            Message(msgSentWithError);
                        end else
                            Message(msgSentOk);
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
                        _ItemModify: Record Item;
                        _jsonItemList: JsonArray;
                        _jsonErrorItemList: JsonArray;
                        _jsonItem: JsonObject;
                        _jsonToken: JsonToken;
                        _jsonText: Text;
                        TotalCount: Integer;
                        Counter: Integer;
                        responseText: Text;
                        connectorCode: Label 'CRM';
                        entityType: Label 'products';
                        requestMethod: Label 'POST';
                    begin
                        _Item.SetCurrentKey("CRM Item Id");
                        _Item.SetFilter("CRM Item Id", '=%1', '');

                        Counter := 0;
                        TotalCount := _Item.Count;
                        ConfigProgressBarRecord.Init(TotalCount, Counter, STRSUBSTNO(ApplyingURLMsg, _Item.TableCaption));

                        if _Item.FindSet(false, false) then
                            repeat
                                // Create JSON for CRM
                                _jsonItem := WebServiceMgt.jsonItems(_Item."No.");
                                Counter += 1;

                                if _jsonItem.Get('productnumber', _jsonToken) then begin
                                    _jsonItemList.Add(_jsonItem);

                                    ConfigProgressBarRecord.Update(STRSUBSTNO(RecordsXofYMsg, Counter, TotalCount));

                                    if ((Counter mod 50) = 0) or (Counter = TotalCount) then begin
                                        _jsonItemList.WriteTo(_jsonText);

                                        IsSuccessStatusCode := true;
                                        if not WebServiceMgt.ConnectToCRM(connectorCode, entityType, requestMethod, _jsonText) then begin
                                            _jsonErrorItemList.Add(_jsonItem);
                                            _jsonItem.ReadFrom(_jsonText);
                                            _jsonErrorItemList.Add(_jsonItem);
                                        end;
                                        // add CRM product ID to Item
                                        WebServiceMgt.AddCRMproductIdToItem(_jsonText);
                                        Clear(_jsonItemList);
                                        Commit();
                                    end;

                                end;
                            until _Item.Next() = 0;
                        ConfigProgressBarRecord.Close;
                        if _jsonErrorItemList.Count > 0 then begin
                            _jsonErrorItemList.WriteTo(_jsonText);
                            CaptionMgt.SaveStreamToFile(_jsonText, 'errorItemList.txt');
                            Message(msgSentWithError);
                        end else
                            Message(msgSentOk);
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
                                _jsonItem := WebServiceMgt.jsonItems(_Item."No.");
                                if _jsonItem.Get('productnumber', _jsonToken) then
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
                        Counter := 0;
                        TotalCount := _Item.Count;
                        ConfigProgressBarRecord.Init(TotalCount, Counter, STRSUBSTNO(ApplyingURLMsg, _Item.TableCaption));

                        if _Item.FindSet(false, false) then
                            repeat
                                // Create JSON for CRM
                                _jsonItem := WebServiceMgt.jsonItems(_Item."No.");
                                if _jsonItem.Get('productnumber', _jsonToken) then
                                    _jsonItemList.Add(_jsonItem);

                                ConfigProgressBarRecord.Update(STRSUBSTNO(RecordsXofYMsg, Counter, TotalCount));
                                Counter += 1;
                            until _Item.Next() = 0;
                        ConfigProgressBarRecord.Close;
                        _jsonItemList.WriteTo(_jsonText);
                        CaptionMgt.SaveStreamToFile(_jsonText, 'allItemList.txt');
                    end;
                }
            }
        }
    }

    var
        WebServiceMgt: Codeunit "Web Service Mgt.";
        RecordsXofYMsg: TextConst ENU = 'Records: %1 of %2', RUS = 'Запись: %1 из %2';
        ApplyingURLMsg: TextConst ENU = 'Sending Table %1', RUS = 'Пересылается таблица %1';
        msgSentOk: TextConst ENU = 'Sent into eShop is Ok!', RUS = 'Отправлено в eShop!';
        msgSentWithError: TextConst ENU = 'Sent into eShop with Errors!', RUS = 'Отправлено в eShop с ошибками!';
        ConfigProgressBarRecord: Codeunit "Config Progress Bar";
        CaptionMgt: Codeunit "Caption Mgt.";
        IsSuccessStatusCode: Boolean;
}