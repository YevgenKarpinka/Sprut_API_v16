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

                }
                field("Error Job Queue Entries"; "Error Job Queue Entries")
                {
                    ApplicationArea = All;

                }
                field("Modify Order Entries"; "Modify Order Entries")
                {
                    ApplicationArea = All;

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
        EnableTools := UserId = UpperCase('yekar');
    end;

    trigger OnAfterGetRecord()
    begin
        CaptionMgt.ErrorJobQueueEntries();
        CaptionMgt.ErrorModifyOrderEntries();

    end;

    var
        CaptionMgt: Codeunit "Caption Mgt.";
        EnableTools: Boolean;
}