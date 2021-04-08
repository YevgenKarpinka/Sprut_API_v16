page 50019 "Responce CRM FactBox"
{
    PageType = CardPart;
    ApplicationArea = Basic, Suite;
    UsageCategory = History;
    SourceTable = "Task Modify Order";
    CaptionML = ENU = 'Responce CRM', RUS = 'Ответ CRM';
    AccessByPermission = tabledata "Task Modify Order" = r;
    Editable = false;

    layout
    {
        area(Content)
        {
            group("CRM Specification")
            {
                field(Specification; CRMSpecification)
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ShowCaption = false;
                }
            }
            group("CRM Invoices")
            {
                field(Invoices; CRMInvoices)
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ShowCaption = false;
                }
            }
            group("Error")
            {
                field("Error Text"; "Error Text")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ShowCaption = false;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CRMSpecification := GetCRMSpecification();
        CRMInvoices := GetCRMInvoices();
    end;

    var
        CRMSpecification: Text;
        CRMInvoices: Text;
}