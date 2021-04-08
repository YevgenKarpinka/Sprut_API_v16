page 50007 "Integration Log Card"
{
    CaptionML = ENU = 'Integration Log Card', RUS = 'Карточка интеграции';
    SourceTable = "Integration Log";
    PageType = Card;
    RefreshOnActivate = true;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Editable = false;

                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTipML = ENU = 'Specifies the operation integration number.',
                                RUS = 'Определяет номер операции интеграции.';
                }
                field("Operation Date"; "Operation Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTipML = ENU = 'Specifies the operation integration date and time.',
                                RUS = 'Определяет дату и время операции интеграции.';
                }
                field("Source Operation"; "Source Operation")
                {
                    ApplicationArea = Warehouse;
                    ToolTipML = ENU = 'Specifies the source integration code.',
                                RUS = 'Определяет код источника интеграции.';
                }
                field(Success; Success)
                {
                    ApplicationArea = Warehouse;
                    ToolTipML = ENU = 'Specifies the status the operation integration.',
                                RUS = 'Определяет статус операции интеграции.';
                }
                field(Autorization; Autorization)
                {
                    ApplicationArea = Warehouse;
                    ToolTipML = ENU = 'Specifies the Autorization the operation integration.',
                                RUS = 'Определяет авторизацию операции интеграции.';
                }
                field(URL; URL)
                {
                    ApplicationArea = Warehouse;
                    ToolTipML = ENU = 'Specifies the URL the operation integration.',
                                RUS = 'Определяет URL операции интеграции.';
                }
                group(groupRequest)
                {
                    Caption = 'Request';
                    field(Request; _Request)
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        MultiLine = true;
                        ShowCaption = false;
                        ToolTipML = ENU = 'Specifies the request integration.',
                                    RUS = 'Определяет запрос интеграции.';

                        trigger OnValidate()
                        begin
                            SetRequest(_Request);
                        end;
                    }
                }
                group(groupResponse)
                {
                    Caption = 'Response';
                    field(Response; _Response)
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        MultiLine = true;
                        ShowCaption = false;
                        ToolTipML = ENU = 'Specifies the response integration.',
                                    RUS = 'Определяет ответ интеграции.';

                        trigger OnValidate()
                        begin
                            SetResponse(_Response);
                        end;
                    }
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        _Request := GetRequest();
        _Response := GetResponse();
    end;

    var
        _Request: Text;
        _Response: Text;
}