pageextension 50011 "Location List Ext." extends "Location List"
{
    layout
    {
        // Add changes to page layout here
        addafter(Name)
        {
            field(Address; Address)
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("Address 2"; "Address 2")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field(City; City)
            {
                ApplicationArea = All;
                Visible = false;
            }
            field(Contact; Contact)
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("E-Mail"; "E-Mail")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("Responsible Employee No."; "Responsible Employee No.")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("Country/Region Code"; "Country/Region Code")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field(County; County)
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("Always Create Pick Line"; "Always Create Pick Line")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("Always Create Put-away Line"; "Always Create Put-away Line")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("Bin Mandatory"; "Bin Mandatory")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("Cross-Dock Bin Code"; "Cross-Dock Bin Code")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("Default Bin Code"; "Default Bin Code")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("Default Bin Selection"; "Default Bin Selection")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("Directed Put-away and Pick"; "Directed Put-away and Pick")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("From-Assembly Bin Code"; "From-Assembly Bin Code")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("From-Production Bin Code"; "From-Production Bin Code")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("Last Modified Date Time"; "Last Modified Date Time")
            {
                ApplicationArea = All;
                Visible = false;
            }
        }
    }

    actions
    {
        // Add changes to page actions here
        addafter("Create Warehouse location")
        {
            action(CopyLocationsToCompanies)
            {
                ApplicationArea = All;
                CaptionML = ENU = 'Copy Locations To Companies',
                            RUS = 'Копировать склады по организациям';
                // Visible = false;

                trigger OnAction()
                begin
                    Codeunit.Run(Codeunit::"Copy Whses. to All Companies");
                end;
            }
        }
    }

    var
        CopyWhse: Codeunit "Copy Whses. to All Companies";
}