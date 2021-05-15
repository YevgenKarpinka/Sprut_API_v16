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
                    Integration1C.Get1CRoot();
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
                    Integration1C.GetItemsIdFrom1C();
                end;
            }
            action(GetUoMIdFrom1C)
            {
                ApplicationArea = All;
                CaptionML = ENU = 'Get UoM Id From 1C', RUS = 'Get UoM Id From 1C';
                ToolTipML = ENU = 'Get UoM Id From 1C',
                            RUS = 'Get UoM Id From 1C';
                Image = TeamSales;

                trigger OnAction()
                begin
                    if Integration1C.GetUoMIdFrom1C() then
                        Message('Ok!')
                    else
                        Message('Error!');
                end;
            }

            action(GetItemsIdFrom1C)
            {
                ApplicationArea = All;
                CaptionML = ENU = 'Get Items Id From 1C', RUS = 'Get Items Id From 1C';
                ToolTipML = ENU = 'Get Items Id From 1C',
                            RUS = 'Get Items Id From 1C';
                Image = TeamSales;

                trigger OnAction()
                begin
                    if Integration1C.GetItemsIdFrom1C() then
                        Message('Ok!')
                    else
                        Message('Error!');
                end;
            }
            action(GetBankIdFrom1C)
            {
                ApplicationArea = All;
                CaptionML = ENU = 'Get Bank Id From 1C', RUS = 'Get Bank Id From 1C';
                ToolTipML = ENU = 'Get Bank Id From 1C',
                            RUS = 'Get Bank Id From 1C';
                Image = TeamSales;

                trigger OnAction()
                begin
                    if Integration1C.GetBankDirectoryIdFrom1C(CompanyName) then
                        Message('Ok!')
                    else
                        Message('Error!');
                end;
            }
            action(GetCurrencyIdFrom1C)
            {
                ApplicationArea = All;
                CaptionML = ENU = 'Get Currency Id From 1C', RUS = 'Get Currency Id From 1C';
                ToolTipML = ENU = 'Get Currency Id From 1C',
                            RUS = 'Get Currency Id From 1C';
                Image = TeamSales;

                trigger OnAction()
                begin
                    if Integration1C.GetCurrencyIdFrom1C(CompanyName) then
                        Message('Ok!')
                    else
                        Message('Error!');
                end;
            }
            action(GetCompanyIdFrom1C)
            {
                ApplicationArea = All;
                CaptionML = ENU = 'Get Company Id From 1C', RUS = 'Get Company Id From 1C';
                ToolTipML = ENU = 'Get Company Id From 1C',
                            RUS = 'Get Company Id From 1C';
                Image = TeamSales;

                trigger OnAction()
                begin
                    if Integration1C.GetCompanyIdFrom1C() then
                        Message('Ok!')
                    else
                        Message('Error!');
                end;
            }
            action(GetCustomerIdFrom1C)
            {
                ApplicationArea = All;
                CaptionML = ENU = 'Get Customer Id From 1C', RUS = 'Get Customer Id From 1C';
                ToolTipML = ENU = 'Get Customer Id From 1C',
                            RUS = 'Get Customer Id From 1C';
                Image = TeamSales;

                trigger OnAction()
                begin
                    if Integration1C.GetCustomerIdFrom1C(CompanyName) then
                        Message('Ok!')
                    else
                        Message('Error!');
                end;
            }
            action(GetVendorIdFrom1C)
            {
                ApplicationArea = All;
                CaptionML = ENU = 'Get Vendor Id From 1C', RUS = 'Get Vendor Id From 1C';
                ToolTipML = ENU = 'Get Vendor Id From 1C',
                            RUS = 'Get Vendor Id From 1C';
                Image = TeamSales;

                trigger OnAction()
                begin
                    if Integration1C.GetVendorIdFrom1C() then
                        Message('Ok!')
                    else
                        Message('Error!');
                end;
            }
            action(GetCustomerBankAccIdFrom1C)
            {
                ApplicationArea = All;
                CaptionML = ENU = 'Get CustomerBankAcc Id From 1C', RUS = 'Get CustomerBankAcc Id From 1C';
                ToolTipML = ENU = 'Get CustomerBankAcc Id From 1C',
                            RUS = 'Get CustomerBankAcc Id From 1C';
                Image = TeamSales;

                trigger OnAction()
                begin
                    if Integration1C.GetCustomerBankAccountIdFrom1C(CustBankAcc, CompanyName) then
                        Message('Ok!')
                    else
                        Message('Error!');
                end;
            }
            action(GetVendorBankAccIdFrom1C)
            {
                ApplicationArea = All;
                CaptionML = ENU = 'Get VendorBankAcc Id From 1C', RUS = 'Get VendorBankAcc Id From 1C';
                ToolTipML = ENU = 'Get VendorBankAcc Id From 1C',
                            RUS = 'Get VendorBankAcc Id From 1C';
                Image = TeamSales;

                trigger OnAction()
                begin
                    if Integration1C.GetVendorBankAccountIdFrom1C(VendBankAcc) then
                        Message('Ok!')
                    else
                        Message('Error!');
                end;
            }
            action(GetCustomerAgreementIdFrom1C)
            {
                ApplicationArea = All;
                CaptionML = ENU = 'Get CustomerAgreement Id From 1C', RUS = 'Get CustomerAgreement Id From 1C';
                ToolTipML = ENU = 'Get CustomerAgreement Id From 1C',
                            RUS = 'Get CustomerAgreement Id From 1C';
                Image = TeamSales;

                trigger OnAction()
                begin
                    if Integration1C.GetCustomerAgreementIdFrom1C(CustAgreement, CompanyName) then
                        Message('Ok!')
                    else
                        Message('Error!');
                end;
            }
            action(GetAllIdFrom1C)
            {
                ApplicationArea = All;
                CaptionML = ENU = 'Get All Id From 1C', RUS = 'Get All Id From 1C';
                ToolTipML = ENU = 'Get All Id From 1C',
                            RUS = 'Get All Id From 1C';
                Image = TeamSales;

                trigger OnAction()
                begin
                    if Integration1C.Run() then
                        Message('Ok!')
                    else
                        Message('Error!');
                end;
            }
        }
    }

    var
        WebServiceMgt: Codeunit "Web Service Mgt.";
        Integration1C: Codeunit "Integration 1C";
        TokenTypeAccessToken: Label 'Token Type: %1\\AccessToken:\\%2';
        CustBankAcc: Record "Customer Bank Account";
        VendBankAcc: Record "Vendor Bank Account";
        CustAgreement: Record "Customer Agreement";
}