page 50001 "APIV2 - Customer Agreement"
{
    PageType = API;
    Caption = 'customerAgreement', Locked = true;
    APIPublisher = 'tcomtech';
    APIGroup = 'app';
    APIVersion = 'v1.0';
    EntityName = 'customerAgreement';
    EntitySetName = 'customerAgreements';
    SourceTable = "Customer Agreement";
    DelayedInsert = true;
    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            group(GroupName)
            {
                field(systemId; SystemId)
                {
                    ApplicationArea = All;
                    Caption = 'agentServicesId', Locked = true;
                }
                field(customerNo; "Customer No.")
                {
                    ApplicationArea = All;
                    Caption = 'serviceCode', Locked = true;
                }
                field(agentCode; "Shipping Agent Code")
                {
                    ApplicationArea = All;
                    Caption = 'agentCode', Locked = true;
                }
                field(description; Description)
                {
                    ApplicationArea = All;
                    Caption = 'description', Locked = true;
                }
                // field(ssCarrierCode; "SS Carrier Code")
                // {
                //     ApplicationArea = All;
                //     Caption = 'ssCarrierCode', Locked = true;
                // }
                // field(ssCode; "SS Code")
                // {
                //     ApplicationArea = All;
                //     Caption = 'ssCode', Locked = true;
                // }
            }
        }
    }
}