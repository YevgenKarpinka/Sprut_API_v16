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

                field("UnApply Prepm. Doc."; "UnApply Prepm. Doc.")
                {
                    ApplicationArea = All;

                }
                field("Deduplicated Customers"; "Deduplicated Customers")
                {
                    ApplicationArea = All;
                    Visible = EnableTools;
                }
                field("Error Job Queue Entries"; "Error Job Queue Entries")
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
                field("Open Sales Order"; "Open Sales Order")
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
    end;

    trigger OnAfterGetRecord()
    begin
        if not EnableTools then exit;
        CaptionMgt.DelayedJobQueueEntries();
        // CaptionMgt.ErrorModifyOrderEntries();
        CaptionMgt.TasksModifyOrderEntries();
        CaptionMgt.OpenSalesOrder();
    end;

    var
        UserSetup: Record "User Setup";
        CaptionMgt: Codeunit "Caption Mgt.";
        EnableTools: Boolean;
}