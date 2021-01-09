pageextension 50007 "Payment Registration Ext" extends "Payment Registration"
{
    layout
    {
        // Add changes to page layout here
        addafter(ExternalDocumentNo)
        {
            field("Agreement No."; "Agreement No.")
            {
                ApplicationArea = All;
                Editable = false;
            }

        }
    }

    actions
    {
        // Add changes to page actions here
    }

    trigger OnAfterGetRecord()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.Get("Ledger Entry No.");
        "Agreement No." := CustLedgerEntry."Agreement No.";
        "Posting Date" := CustLedgerEntry."Posting Date";
        Modify();
    end;
}