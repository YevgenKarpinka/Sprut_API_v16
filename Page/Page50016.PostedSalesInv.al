page 50016 "Posted Sales Inv."
{
    Caption = 'Posted Sales Invoice by Order';
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    PageType = List;
    SourceTable = "Sales Invoice Header";
    ODataKeyFields = "Order No.";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                Visible = false;
                field("No."; "No.")
                {
                    ApplicationArea = All;
                }
                field("Sell-to Customer No."; "Sell-to Customer No.")
                {
                    ApplicationArea = All;
                }
                field(Amount; Amount)
                {
                    ApplicationArea = All;
                }
                field("Amount Including VAT"; "Amount Including VAT")
                {
                    ApplicationArea = All;
                }
                field("Customer CRM ID"; MatchContragent.GetCustomerCRMID("Sell-to Customer No."))
                {
                    ApplicationArea = All;
                }
                field("Currency ISO Code"; MatchContragent.GetCurrencyISONumericCode("Currency Code"))
                {
                    ApplicationArea = All;
                }
                field("Order No."; "Order No.")
                {
                    ApplicationArea = All;
                }
                field("Prepayment Order No."; "Prepayment Order No.")
                {
                    ApplicationArea = All;
                }
                part(SalesInvLines; "Posted Sales Invoice Subform")
                {
                    ApplicationArea = All;
                    SubPageLink = "Document No." = FIELD("No.");
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetInit();
    end;

    var
        MatchContragent: Codeunit "Match Contragent";
        OrderNoFilter: Code[20];

    local procedure ShowThisRecord(InvoiceNo: Code[20]): Boolean
    var
        CLE: Record "Cust. Ledger Entry";
    begin
        CLE.SetRange("Document Type", CLE."Document Type"::Invoice);
        CLE.SetRange("Document No.", InvoiceNo);
        if CLE.IsEmpty then exit(false);
        exit(true);
    end;

    local procedure SetInit()
    var
        SIH: Record "Sales Invoice Header";
    begin
        OrderNoFilter := GetFilter("Order No.");
        Reset();

        if OrderNoFilter <> '' then
            SIH.SetRange("Order No.", OrderNoFilter);

        if SIH.FindSet(false, false) then
            repeat
                if ShowThisRecord(SIH."No.") then begin
                    Rec.Init();
                    Rec := SIH;
                    Rec.Insert();
                end;
            until SIH.Next() = 0;

        if OrderNoFilter <> '' then begin
            SIH.Reset();
            SIH.SetRange("Prepayment Order No.", OrderNoFilter);

            if SIH.FindSet(false, false) then
                repeat
                    if ShowThisRecord(SIH."No.") then begin
                        Rec.Init();
                        Rec := SIH;
                        Rec.Insert();
                    end;
                until SIH.Next() = 0;
            SIH.Reset();
        end;

    end;
}

