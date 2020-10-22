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
                end;
            }
        }
    }

    var
        WebServiceMgt: Codeunit "Web Service Mgt.";

        TokenTypeAccessToken: Label 'Token Type: %1\\AccessToken:\\%2';
}