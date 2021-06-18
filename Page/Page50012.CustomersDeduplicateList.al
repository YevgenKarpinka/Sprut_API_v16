page 50012 "Customers Deduplicate List"
{
    PageType = ListPart;
    // ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = Customer;
    SourceTableView = where("Deduplicate Id" = filter(<> '00000000-0000-0000-0000-000000000000'));
    Editable = false;
    CaptionML = ENU = 'Deduplicate Customers List',
                RUS = 'Список клиентов для дедубликации';

    layout
    {
        area(Content)
        {
            repeater(CustomersDeduplicate)
            {
                field("No."; "No.")
                {
                    ApplicationArea = All;
                }
                field(Name; Name)
                {
                    ApplicationArea = All;
                }
                field(DeduplicatNo; GetDeduplicatNo())
                {
                    ApplicationArea = All;
                }
                field(DeduplicatName; GetDeduplicatName())
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {

        }
    }

    local procedure GetDeduplicatNo(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.SetCurrentKey("CRM ID");
        Customer.SetRange("CRM ID", "Deduplicate Id");
        if Customer.FindFirst() then
            exit(Customer."No.");

        exit('');
    end;

    local procedure GetDeduplicatName(): Text[100]
    var
        Customer: Record Customer;
    begin
        Customer.SetCurrentKey("CRM ID");
        Customer.SetRange("CRM ID", "Deduplicate Id");
        if Customer.FindFirst() then
            exit(Customer.Name);

        exit('');
    end;
}