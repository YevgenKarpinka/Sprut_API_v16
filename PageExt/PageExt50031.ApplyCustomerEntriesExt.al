pageextension 50031 "Apply Customer Entries Ext" extends "Apply Customer Entries"
{
    layout
    {
        // Add changes to page layout here
        addafter("Customer No.")
        {
            field("Source Invoice No."; GetSourceInvoiceNo())
            {
                CaptionML = ENU = 'Source Invoice No.',
                            RUS = 'Источник счета номер';
                ApplicationArea = All;
                ToolTipML = ENU = 'Specifies the number of the Source Invoice No.',
                            RUS = 'Указывает на номер Источника счета.';
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;

    local procedure GetSourceInvoiceNo(): Text[50]
    var
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        if "Document Type" = "Document Type"::Invoice then
            if SalesInvHeader.Get("Document No.") then begin
                if SalesInvHeader."Invoice No. 1C" <> '' then
                    exit(SalesInvHeader."Invoice No. 1C")
                else
                    exit(SalesInvHeader."CRM Invoice No.");
            end;
        exit('')
    end;
}