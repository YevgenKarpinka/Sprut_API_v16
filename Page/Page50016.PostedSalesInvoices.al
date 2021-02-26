page 50016 "PostedSalesInvoices"
{
    PageType = List;
    SourceTable = "Sales Invoice Header";
    ODataKeyFields = "Order No.";
    SourceTableTemporary = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(GroupName)
            {
                field("Order No."; "Order No.")
                {
                }
                field("No."; "No.")
                {
                }
                field("Sell-to Customer No."; "Sell-to Customer No.")
                {
                }
                field("Customer CRM ID"; MatchContragent.GetCustomerCRMID("Sell-to Customer No."))
                {
                }
                field("Agreement No."; "Agreement No.")
                {
                }
                field("Agreement CRM ID"; MatchContragent.GetAgreementCRMID("Sell-to Customer No.", "Agreement No."))
                {
                }
                field("Currency ISO Code"; MatchContragent.GetCurrencyISONumericCode("Currency Code"))
                {
                }
                field(Amount; Amount)
                {
                }
                field("Amount Including VAT"; "Amount Including VAT")
                {
                }
                field("CRM Invoice No."; "CRM Invoice No.")
                {
                }
                field("CRM ID"; "CRM ID")
                {
                }

            }
        }
    }

    var

    trigger OnOpenPage()
    begin
        SetInit();
    end;

    var
        MatchContragent: Codeunit "Match Contragent";

    local procedure ShowThisRecord(InvoiceNo: Code[20]): Boolean
    var
        CLE: Record "Cust. Ledger Entry";
    begin
        CLE.SetCurrentKey("Document Type", "Document No.");
        CLE.SetRange("Document Type", CLE."Document Type"::Invoice);
        CLE.SetRange("Document No.", InvoiceNo);
        if CLE.IsEmpty then exit(false);
        exit(true);
    end;

    local procedure SetInit()
    var
        SIH: Record "Sales Invoice Header";
    begin
        if SIH.FindSet(false, false) then
            repeat
                if ShowThisRecord(SIH."No.") then begin
                    Rec.Init();
                    Rec := SIH;
                    Rec."Order No." := SIH."Order No." + SIH."Prepayment Order No.";
                    Rec.Insert();
                end;
            until SIH.Next() = 0;
    end;
}