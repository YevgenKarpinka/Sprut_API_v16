pageextension 50013 "Customer List Ext." extends "Customer List"
{
    layout
    {
        // Add changes to page layout here
        addafter(Name)
        {
            field("Agreements List"; CopyCust.GetAgreements("No."))
            {
                ApplicationArea = All;
                ToolTipML = ENU = 'Specifies agreeemnes of the customer.',
                            RUS = 'Указывает договора клиента.';
            }
            field("Init 1C"; "Init 1C")
            {
                ApplicationArea = All;
                ToolTipML = ENU = 'Specifies transfer to 1C of the customer.',
                            RUS = 'Указывает передавать ли клиента в 1С.';
            }
            field("CRM ID"; "CRM ID")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("BC Id"; "BC Id")
            {
                ApplicationArea = All;
                Visible = false;
            }
        }
    }

    actions
    {
        // Add changes to page actions here
        addbefore("Request Approval")
        {
            group(Sprut)
            {
                CaptionML = ENU = 'Sprut',
                            RUS = 'Спрут';

                action(CombineCustomers)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'CombineCustomers',
                                RUS = 'Объединить клиентов';
                    Image = ApplyEntries;

                    trigger OnAction()
                    begin
                        if not Codeunit.Run(Codeunit::"Combine Customer/Vendor") then
                            Error(GetLastErrorText());
                        Message('Ok!');
                    end;
                }
                action(CloneCustomers)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'Clone Customers',
                                RUS = 'Клонировать клиентов';
                    Image = ApplyEntries;

                    trigger OnAction()
                    begin
                        Codeunit.Run(Codeunit::"Copy Customers");
                    end;
                }
                action(FillBCIDCustomers)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'Fill BC Id Customers',
                                RUS = 'Заполнить ИД клиентов';
                    Image = ApplyEntries;

                    trigger OnAction()
                    begin
                        CopyCust.FillBCIDAllCustomers();
                        Message('BC Id filled!');
                    end;
                }
                action(FillBCIDCustomerAgrs)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'Fill BC Id Customer Agreements',
                                RUS = 'Заполнить ИД договоров клиентов';
                    Image = ApplyEntries;

                    trigger OnAction()
                    begin
                        CopyCust.FillBCIDAllCustomerAgreements();
                        Message('BC Id filled!');
                    end;
                }
            }
        }
    }

    var
        CopyCust: Codeunit "Copy Customers";
}