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
        GetSRSetup();
        if not SRSetup."Allow Modifying" then exit;

        if (SalesLine."Prepmt. Amt. Inv." = 0)
            or (SalesHeader."Document Type" <> SalesHeader."Document Type"::Order) then
            exit;

        SalesLine."Prepmt. Line Amount" := SalesLine."Line Amount" * SalesLine."Prepayment %" / 100;
        SalesLine.Modify();
        if (SalesLine."Prepmt. Amt. Inv." < SalesLine."Prepmt. Line Amount") then begin
            UpdatePrepmtAmountCurrLine(SalesHeader, SalesLine);
            exit;
        end;

        Currency.Initialize(SalesHeader."Currency Code");

        with SalesLine do begin
            "Prepmt. Line Amount" := ROUND("Line Amount" * "Prepayment %" / 100, Currency."Amount Rounding Precision");
            CurrentAdjPrepAmount := "Prepmt. Amt. Inv." - "Prepmt. Line Amount";
            if "Prepmt. Amount Inv. (LCY)" <> 0 then begin
                Ratio := "Prepmt. Amount Inv. (LCY)" / "Prepmt. Amt. Inv.";
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

                            "Prepmt. Amt. Incl. VAT" := "Prepmt. Line Amount";
                            "Prepmt. VAT Base Amt." := "Prepmt. Line Amount";
                            "Prepmt. Amount Inv. Incl. VAT" := "Prepmt. Amt. Inv.";
                        end else begin
                            SalesLine."Prepmt. Amt. Incl. VAT" := Round(SalesLine."Prepmt. Line Amount" + SalesLine."Prepmt. Line Amount" * SalesLine."VAT %" / 100, Currency."Amount Rounding Precision");
                            SalesLine."Prepmt. VAT Base Amt." := SalesLine."Prepmt. Line Amount";
                            SalesLine."Prepmt. Amount Inv. Incl. VAT" := Round(SalesLine."Prepmt. Amt. Inv." + SalesLine."Prepmt. Amt. Inv." * SalesLine."VAT %" / 100, Currency."Amount Rounding Precision");

                            "Prepmt. Amt. Incl. VAT" := Round("Prepmt. Line Amount" + "Prepmt. Line Amount" * "VAT %" / 100, Currency."Amount Rounding Precision");
                            "Prepmt. VAT Base Amt." := "Prepmt. Line Amount";
                            "Prepmt. Amount Inv. Incl. VAT" := Round("Prepmt. Amt. Inv." + "Prepmt. Amt. Inv." * "VAT %" / 100, Currency."Amount Rounding Precision");
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

    local procedure UpdatePrepmtAmountCurrLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line");
    begin
        if SalesHeader."Prices Including VAT" then begin
            SalesLine."Prepmt. Amt. Incl. VAT" := SalesLine."Prepmt. Line Amount";
            SalesLine."Prepmt. VAT Base Amt." := SalesLine."Prepmt. Line Amount";
            // SalesLine."Prepmt. Amount Inv. Incl. VAT" := SalesLine."Prepmt. Amt. Inv.";
        end else begin
            // SalesLine."Line Amount" + SalesLine."Prepayment %" / 100
            SalesLine."Prepmt. Amt. Incl. VAT" := Round(SalesLine."Prepmt. Line Amount" + SalesLine."Prepmt. Line Amount" * SalesLine."VAT %" / 100, Currency."Amount Rounding Precision");
            SalesLine."Prepmt. VAT Base Amt." := SalesLine."Prepmt. Line Amount";
            // SalesLine."Prepmt. Amount Inv. Incl. VAT" := Round(SalesLine."Prepmt. Amt. Inv." + SalesLine."Prepmt. Amt. Inv." * SalesLine."VAT %" / 100, Currency."Amount Rounding Precision");
        end;
        SalesLine.Modify();
    end;

    local procedure GetSRSetup()
    begin
        IF not SRSetup.Get() then begin
            SRSetup.Init();
            SRSetup.Insert();
        end;
    end;

    var
        Currency: Record Currency;
        SRSetup: Record "Sales & Receivables Setup";
}