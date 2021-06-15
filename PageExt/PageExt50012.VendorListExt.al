pageextension 50012 "Vendor List Ext." extends "Vendor List"
{
    layout
    {
        // Add changes to page layout here
        addafter("Payments (LCY)")
        {
            field("Deduplicate No."; "Deduplicate No.")
            {
                ApplicationArea = All;
                ToolTipML = ENU = 'Specifies the Deduplicate No.',
                            RUS = 'Указывает на номер дедубликации.';
            }
        }
    }

    actions
    {
        // Add changes to page actions here
        addafter(PayVendor)
        {
            action(CopyVendorsToCompanies)
            {
                ApplicationArea = All;
                CaptionML = ENU = 'Copy Vendors To Companies',
                            RUS = 'Копировать поставщиков по организациям';
                // Visible = false;

                trigger OnAction()
                begin
                    Codeunit.Run(Codeunit::"Copy Vend. to All Companies");
                end;
            }
        }
    }
}