pageextension 50028 "Customer Agreements Card Ext" extends "Customer Agreement Card"
{
    layout
    {
        // Add changes to page layout here
        addafter(Active)
        {
            field(Status; Status)
            {
                ApplicationArea = All;
                ToolTipML = ENU = 'Specifies the status of the customer agreement.',
                            RUS = 'Указывает статус договора клиента.';
            }
            field("CRM ID"; "CRM ID")
            {
                ApplicationArea = All;
                ToolTipML = ENU = 'Specifies the CRM ID of the customer agreement.',
                            RUS = 'Указывает CRM ID договора клиента.';
            }
        }
    }

    actions
    {
        addafter(Action100)
        {
            group(Integration1C)
            {
                CaptionML = ENU = 'Integration with 1C',
                            RUS = 'Интеграция с 1С';

                action(InitAgreement)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'Init Agreement',
                            RUS = 'Инициировать договор';
                    ToolTipML = ENU = 'Specify init customer agreement for transfer to 1C',
                            RUS = 'Определяет инициализацию договора для передачи в 1С';

                    trigger OnAction()
                    begin
                        FillCRMID();
                    end;
                }
                action(ClearAgreement)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'Clear Agreement',
                                RUS = 'Очистить договор';
                    ToolTipML = ENU = 'Specify clear customer agreement for disable transfer to 1C',
                                RUS = 'Определяет очистку договора для деактивации передачи в 1С';

                    trigger OnAction()
                    begin
                        ClearCRMID();
                    end;
                }
            }
        }
    }

    var
        blankGuid: guid;
        errAgreementUsedInUnPostedSalesDocuments: TextConst ENU = 'Agreement Used In UnPosted Sales Documents',
                                                            RUS = 'Договор используется в неучтенных документах продажи';

        errAgreementUsedInPostedSalesDocuments: TextConst ENU = 'Agreement Used In Posted Sales Documents',
                                                        RUS = 'Договор используется в учтенных документах продажи';

    local procedure ClearCRMID()
    begin
        CheckAgreementUnpostedDocs();

        if "External Agreement No." = Description then exit;
        "CRM ID" := blankGuid;
        "Init 1C" := false;
    end;

    local procedure FillCRMID()
    begin
        if IsNullGuid("CRM ID") then
            "Init 1C" := true;
    end;

    local procedure CheckAgreementUnpostedDocs()
    var
        SalesHeader: Record "Sales Header";
        CustLE: Record "Cust. Ledger Entry";
    begin
        SalesHeader.SetCurrentKey("Agreement No.");
        SalesHeader.SetRange("Agreement No.", "No.");
        if not SalesHeader.IsEmpty then
            Error(errAgreementUsedInUnPostedSalesDocuments);

        CustLE.SetCurrentKey("Agreement No.");
        CustLE.SetRange("Agreement No.", "No.");
        if not CustLE.IsEmpty then
            Error(errAgreementUsedInPostedSalesDocuments);
    end;
}