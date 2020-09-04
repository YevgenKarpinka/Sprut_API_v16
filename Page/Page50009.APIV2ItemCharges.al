page 50009 "APIV2 - Item Charges"
{
    PageType = API;
    Caption = 'itemCharges', Locked = true;
    APIPublisher = 'tcomtech';
    APIGroup = 'app';
    APIVersion = 'v1.0';
    EntityName = 'itemCharge';
    EntitySetName = 'itemCharges';
    SourceTable = "Item Charge";
    DelayedInsert = true;
    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            group(GroupName)
            {
                field(itemChargeNo; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'itemChargeNo', Locked = true;
                }
                field(description; Description)
                {
                    ApplicationArea = All;
                    Caption = 'description', Locked = true;
                }
            }
        }
    }
}