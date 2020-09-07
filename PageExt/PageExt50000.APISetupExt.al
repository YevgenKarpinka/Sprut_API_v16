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
        }
    }

    var
        WebServiceMgt: Codeunit "Web Service Mgt.";
}