pageextension 50000 "API Setup Ext" extends "API Setup"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
        addafter(IntegrateAPIs)
        {
            action(GetOauthToken)
            {
                ApplicationArea = All;
                CaptionML = ENU = 'Get Oauth Token', RUS = 'Get Oauth Token';
                ToolTipML = ENU = 'Get Oauth Token.',
                            RUS = 'Get Oauth Token.';
                Image = GetBinContent;

                trigger OnAction()
                var
                    TokenType: Text;
                    AccessToken: Text;
                    APIResult: Text;
                begin
                    if WebServiceMgt.GetOauthToken(TokenType, AccessToken, APIResult) then
                        Message(TokenTypeAccessToken, TokenType, AccessToken)
                    else
                        Message(APIResult);
                end;
            }
            action(GetProducts)
            {
                ApplicationArea = All;
                CaptionML = ENU = 'Get Products', RUS = 'Get Products';
                ToolTipML = ENU = 'Get Products.',
                            RUS = 'Get Products.';
                Image = GetBinContent;

                trigger OnAction()
                var
                    connectorCode: Label 'CRM';
                    entityType: Label 'products';
                    requestMethod: Label 'GET';
                    requestBody: Text;
                begin
                    WebServiceMgt.ConnectToCRM(connectorCode, entityType, requestMethod, requestBody);
                    Message(requestBody);
                end;
            }
            action(Get1CRoot)
            {
                ApplicationArea = All;
                CaptionML = ENU = 'Get 1CRoot', RUS = 'Get 1CRoot';
                ToolTipML = ENU = 'Get 1CRoot.',
                            RUS = 'Get 1CRoot.';
                Image = GetBinContent;

                trigger OnAction()
                begin
                    WebServiceMgt.Get1CRoot();
                end;
            }
            action(Get1CItems)
            {
                ApplicationArea = All;
                CaptionML = ENU = 'Get 1CItems', RUS = 'Get 1CItems';
                ToolTipML = ENU = 'Get 1CItems.',
                            RUS = 'Get 1CItems.';
                Image = GetBinContent;

                trigger OnAction()
                begin
                    WebServiceMgt.Get1CItems();
                end;
            }
        }
    }

    var
        WebServiceMgt: Codeunit "Web Service Mgt.";

        TokenTypeAccessToken: Label 'Token Type: %1\\AccessToken:\\%2';
}