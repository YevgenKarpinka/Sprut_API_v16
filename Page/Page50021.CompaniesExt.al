page 50021 "Companies Ext"
{
    CaptionML = ENU = 'Companies Ext List',
                RUS = 'Организации расширенный список';
    SourceTable = Company;
    DataCaptionFields = Name, "Display Name";
    ApplicationArea = All;
    PageType = List;
    UsageCategory = History;
    // Editable = false;

    layout
    {
        area(Content)
        {
            repeater(RepeaterName)
            {
                field(Name; Name)
                {
                    ApplicationArea = All;

                }
                field("Display Name"; "Display Name")
                {
                    ApplicationArea = All;

                }
                field(OKPO; GetOKPOByName())
                {
                    ApplicationArea = All;

                }
            }
        }
    }

    local procedure GetOKPOByName(): Text
    var
        CompInfo: Record "Company Information";
    begin
        if Name <> CompanyName then
            CompInfo.ChangeCompany(Name);
        CompInfo.Get();
        exit(CompInfo."OKPO Code")
    end;
}