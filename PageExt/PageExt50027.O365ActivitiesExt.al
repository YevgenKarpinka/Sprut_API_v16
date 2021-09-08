pageextension 50027 "O365 Activities Ext." extends "O365 Activities"
{
    layout
    {
        // Add changes to page layout here
        addbefore("Ongoing Sales")
        {
            cuegroup(Sprut)
            {
                CaptionML = ENU = 'Sprut',
                            RUS = 'Спрут';

                field("Deduplicated Customers"; "Deduplicated Customers")
                {
                    ApplicationArea = All;
                    Visible = EnableTools;
                }
                field("Open Sales Order"; "Open Sales Order")
                {
                    ApplicationArea = All;
                    Visible = EnableTools;
                }
                field("UnApply Credit Memo"; "UnApply Credit Memo")
                {
                    ApplicationArea = All;
                    Visible = EnableTools;
                }
                field("UnApply Prepm. Doc."; "UnApply Prepm. Doc.")
                {
                    ApplicationArea = All;

                }
                field("Error Job Queue Entries"; "Error Job Queue Entries")
                {
                    ApplicationArea = All;
                    Visible = EnableTools;
                }
                field("UnSchedule Job Queue Entries"; "UnSchedule Job Queue Entries")
                {
                    ApplicationArea = All;
                    Visible = EnableTools;
                }
                field("Modify Order Entries"; "Modify Order Entries")
                {
                    ApplicationArea = All;
                    Visible = EnableTools;
                }
                field("Modify Order Entries In Work"; "Modify Order Entries In Work")
                {
                    ApplicationArea = All;
                    Visible = EnableTools;
                }

            }
        }
    }

    actions
    {
        // Add changes to page actions here
        addafter(RefreshData)
        {
            action(newReFresh)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'ReFresh';
                Image = Setup;
                ToolTip = 'Re Fresh the cues (status tiles) related to the role.';
                Visible = EnableTools;

                trigger OnAction()
                begin
                    "Last Date/Time Modified" := 0DT;
                    Modify();

                    Codeunit.Run(Codeunit::"Activities Mgt.");
                    CaptionMgt.UpdateCueTool();
                    CurrPage.Update(false);
                end;
            }
            action(newSetUpCues)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Set Up Cues';
                Image = Setup;
                ToolTip = 'Set up the cues (status tiles) related to the role.';
                Visible = EnableTools;

                trigger OnAction()
                var
                    CueRecordRef: RecordRef;
                    CuesAndKpis: Codeunit "Cues And KPIs";
                begin
                    Commit();
                    CueRecordRef.GetTable(Rec);
                    CuesAndKpis.OpenCustomizePageForCurrentUser(CueRecordRef.Number);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if UserSetup.Get(UserId) then
            EnableTools := UserSetup."Admin. Holding";

        CaptionMgt.UpdateCueTool();
    end;

    var
        UserSetup: Record "User Setup";
        CaptionMgt: Codeunit "Caption Mgt.";
        EnableTools: Boolean;
}