pageextension 50013 "Customer List Ext." extends "Customer List"
{
    layout
    {
        // Add changes to page layout here
        addafter(Name)
        {
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
        addafter("Sales Journal")
        {
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
                    Codeunit.Run(Codeunit::"Copy Customers");
                end;
            }
        }
    }

}