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

        SalesLine."Prepmt. Line Amount" := ROUND(SalesLine."Line Amount" * SalesLine."Prepayment %" / 100, Currency."Amount Rounding Precision");
        CurrentAdjPrepAmount := SalesLine."Prepmt. Amt. Inv." - SalesLine."Prepmt. Line Amount";
        if SalesLine."Prepmt. Amount Inv. (LCY)" <> 0 then begin
            Ratio := SalesLine."Prepmt. Amount Inv. (LCY)" / SalesLine."Prepmt. Amt. Inv.";
        end else
            Ratio := 0;

        SalesLineUpdate.SetCurrentKey(Type, "Prepmt. Line Amount");
        SalesLineUpdate.SetRange("Document Type", SalesHeader."Document Type");
        SalesLineUpdate.SetRange("Document No.", SalesHeader."No.");
        SalesLineUpdate.SetFilter(Type, '<>%1', SalesLineUpdate.Type::" ");
        SalesLineUpdate.SetFilter("Prepmt. Line Amount", '<>0');
        SalesLineUpdate.LockTable();
        if SalesLineUpdate.FindSet() then
            repeat
                if SalesLineUpdate."Prepmt. Line Amount" > SalesLineUpdate."Prepmt. Amt. Inv." then begin
                    AdjPrepAmount := SalesLineUpdate."Prepmt. Line Amount" - SalesLineUpdate."Prepmt. Amt. Inv.";

                    if CurrentAdjPrepAmount > AdjPrepAmount then begin
                        SalesLine."Prepmt. Amt. Inv." -= AdjPrepAmount;
                        SalesLineUpdate."Prepmt. Amt. Inv." += AdjPrepAmount;
                        CurrentAdjPrepAmount -= AdjPrepAmount;
                    end else begin
                        SalesLine."Prepmt. Amt. Inv." -= CurrentAdjPrepAmount;
                        SalesLineUpdate."Prepmt. Amt. Inv." += CurrentAdjPrepAmount;
                        CurrentAdjPrepAmount := 0;
                    end;

                    if SalesHeader."Prices Including VAT" then begin
                        SalesLine."Prepmt. Amt. Incl. VAT" := SalesLine."Prepmt. Line Amount";
                        SalesLine."Prepmt. VAT Base Amt." := SalesLine."Prepmt. Line Amount";
                        SalesLine."Prepmt. Amount Inv. Incl. VAT" := SalesLine."Prepmt. Amt. Inv.";

                        SalesLineUpdate."Prepmt. Amt. Incl. VAT" := SalesLineUpdate."Prepmt. Line Amount";
                        SalesLineUpdate."Prepmt. VAT Base Amt." := SalesLineUpdate."Prepmt. Line Amount";
                        SalesLineUpdate."Prepmt. Amount Inv. Incl. VAT" := SalesLineUpdate."Prepmt. Amt. Inv.";
                    end else begin
                        SalesLine."Prepmt. Amt. Incl. VAT" := Round(SalesLine."Prepmt. Line Amount" + SalesLine."Prepmt. Line Amount" * SalesLine."VAT %" / 100, Currency."Amount Rounding Precision");
                        SalesLine."Prepmt. VAT Base Amt." := SalesLine."Prepmt. Line Amount";
                        SalesLine."Prepmt. Amount Inv. Incl. VAT" := Round(SalesLine."Prepmt. Amt. Inv." + SalesLine."Prepmt. Amt. Inv." * SalesLine."VAT %" / 100, Currency."Amount Rounding Precision");

                        SalesLineUpdate."Prepmt. Amt. Incl. VAT" := Round(SalesLineUpdate."Prepmt. Line Amount" + SalesLineUpdate."Prepmt. Line Amount" * SalesLineUpdate."VAT %" / 100, Currency."Amount Rounding Precision");
                        SalesLineUpdate."Prepmt. VAT Base Amt." := SalesLineUpdate."Prepmt. Line Amount";
                        SalesLineUpdate."Prepmt. Amount Inv. Incl. VAT" := Round(SalesLineUpdate."Prepmt. Amt. Inv." + SalesLineUpdate."Prepmt. Amt. Inv." * SalesLineUpdate."VAT %" / 100, Currency."Amount Rounding Precision");
                    end;

                    if Ratio <> 0 then begin
                        SalesLineUpdate."Prepmt. Amount Inv. (LCY)" :=
                            ROUND(SalesLineUpdate."Prepmt. Amt. Inv." * Ratio, Currency."Amount Rounding Precision");
                        SalesLineUpdate."Prepmt. VAT Amount Inv. (LCY)" :=
                            ROUND((SalesLineUpdate."Prepmt. Amount Inv. Incl. VAT" - SalesLineUpdate."Prepmt. Amt. Inv.") * Ratio, Currency."Amount Rounding Precision");

                        SalesLine."Prepmt. Amount Inv. (LCY)" :=
                            ROUND(SalesLine."Prepmt. Amt. Inv." * Ratio, Currency."Amount Rounding Precision");
                        SalesLine."Prepmt. VAT Amount Inv. (LCY)" :=
                            ROUND((SalesLine."Prepmt. Amount Inv. Incl. VAT" - SalesLine."Prepmt. Amt. Inv.") * Ratio, Currency."Amount Rounding Precision");
                    end;

                    SalesLineUpdate.Modify();
                    SalesLine.Modify();
                end;
            until (SalesLineUpdate.Next() = 0) or (CurrentAdjPrepAmount = 0);
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