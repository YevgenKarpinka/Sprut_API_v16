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
                begin
                    WebServiceMgt.GetOauthToken(TokenType, AccessToken);
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
                    connectorCode: Code[20];
                    entityType: Text[20];
                    requestMethod: Code[20];
                begin
                    connectorCode := 'CRM';
                    entityType := 'products';
                    requestMethod := 'GET';
                    WebServiceMgt.ConnectToCRM(connectorCode, entityType, requestMethod);
                end;
            }
        }
    }

    var
        WebServiceMgt: Codeunit "Web Service Mgt.";
}