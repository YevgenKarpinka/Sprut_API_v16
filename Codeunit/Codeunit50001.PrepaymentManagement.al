codeunit 50001 "Prepayment Management"
{
    trigger OnRun()
    begin

    end;

    [EventSubscriber(ObjectType::Table, 37, 'OnBeforeUpdatePrepmtAmounts', '', false, false)]
    local procedure UpdatePrepaymentAmounts(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    var
        SalesLineUpdate: Record "Sales Line";
        CurrentAdjPrepAmount: Decimal;
        CurrentAdjPrepAmountIncVAT: Decimal;
        AdjPrepAmount: Decimal;
        AdjPrepAmountIncVAT: Decimal;
        Ratio: Decimal;
    begin
        if (SalesLine."Prepmt. Amt. Inv." < SalesLine."Prepmt. Line Amount")
            or (SalesLine."Prepmt. Amt. Inv." = 0)
            or (SalesHeader."Document Type" <> SalesHeader."Document Type"::Order) then
            exit;

        Currency.Initialize(SalesHeader."Currency Code");

        with SalesLine do begin
            "Prepmt. Line Amount" := ROUND("Line Amount" * "Prepayment %" / 100, Currency."Amount Rounding Precision");
            CurrentAdjPrepAmount := "Prepmt. Amt. Inv." - "Prepmt. Line Amount";
            // CurrentAdjPrepAmountIncVAT := "Prepmt. Amount Inv. Incl. VAT" - "Prepmt. Amt. Incl. VAT";
            if "Prepmt. Amount Inv. (LCY)" <> 0 then begin
                Ratio := "Prepmt. Amount Inv. (LCY)" / "Prepmt. Amt. Inv.";
                Ratio := 44.0555; // for update
            end else
                Ratio := 0;
        end;

        with SalesLineUpdate do begin
            SetCurrentKey(Type, "Prepmt. Line Amount");
            SetRange("Document Type", SalesHeader."Document Type");
            SetRange("Document No.", SalesHeader."No.");
            SetFilter(Type, '<>%1', Type::" ");
            SetFilter("Prepmt. Line Amount", '<>0');
            LockTable();
            if FindSet() then
                repeat
                    if "Prepmt. Line Amount" > "Prepmt. Amt. Inv." then begin
                        AdjPrepAmount := "Prepmt. Line Amount" - "Prepmt. Amt. Inv.";
                        // AdjPrepAmountIncVAT := "Prepmt. Amt. Incl. VAT" - "Prepmt. Amount Inv. Incl. VAT";


                        if CurrentAdjPrepAmount > AdjPrepAmount then begin
                            SalesLine."Prepmt. Amt. Inv." -= AdjPrepAmount;
                            "Prepmt. Amt. Inv." += AdjPrepAmount;
                            CurrentAdjPrepAmount -= AdjPrepAmount;
                        end else begin
                            SalesLine."Prepmt. Amt. Inv." -= CurrentAdjPrepAmount;
                            "Prepmt. Amt. Inv." += CurrentAdjPrepAmount;
                            CurrentAdjPrepAmount := 0;
                        end;

                        if SalesHeader."Prices Including VAT" then begin
                            SalesLine."Prepmt. Amt. Incl. VAT" := SalesLine."Prepmt. Line Amount";
                            SalesLine."Prepmt. VAT Base Amt." := SalesLine."Prepmt. Line Amount";
                            SalesLine."Prepmt. Amount Inv. Incl. VAT" := SalesLine."Prepmt. Amt. Inv.";

                            "Prepmt. Amount Inv. Incl. VAT" := "Prepmt. Amt. Inv.";
                        end else begin
                            SalesLine."Prepmt. Amt. Incl. VAT" := Round(SalesLine."Prepmt. Line Amount" * "VAT %", Currency."Amount Rounding Precision");
                            SalesLine."Prepmt. VAT Base Amt." := SalesLine."Prepmt. Line Amount";
                            SalesLine."Prepmt. Amount Inv. Incl. VAT" := Round(SalesLine."Prepmt. Amt. Inv." * "VAT %", Currency."Amount Rounding Precision");

                            "Prepmt. Amount Inv. Incl. VAT" := Round("Prepmt. Amt. Inv." * "VAT %", Currency."Amount Rounding Precision");
                        end;

                        if Ratio <> 0 then begin
                            "Prepmt. Amount Inv. (LCY)" :=
                                ROUND("Prepmt. Amt. Inv." * Ratio, Currency."Amount Rounding Precision");
                            "Prepmt. VAT Amount Inv. (LCY)" :=
                                ROUND(("Prepmt. Amount Inv. Incl. VAT" - "Prepmt. Amt. Inv.") * Ratio, Currency."Amount Rounding Precision");

                            SalesLine."Prepmt. Amount Inv. (LCY)" :=
                                ROUND(SalesLine."Prepmt. Amt. Inv." * Ratio, Currency."Amount Rounding Precision");
                            SalesLine."Prepmt. VAT Amount Inv. (LCY)" :=
                                ROUND((SalesLine."Prepmt. Amount Inv. Incl. VAT" - SalesLine."Prepmt. Amt. Inv.") * Ratio, Currency."Amount Rounding Precision");
                        end;

                        Modify();
                        SalesLine.Modify();
                    end;
                until (Next() = 0) or (CurrentAdjPrepAmount = 0);
        end;
    end;

    var
        Currency: Record Currency;

}