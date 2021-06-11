tableextension 50021 "Vendor Ext" extends Vendor
{
    fields
    {
        // Add changes to table fields here
        field(50000; "Certificate"; Text[20])
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'Certificate',
                        RUS = 'Свидетельство';
        }

    }

    trigger OnInsert()
    begin
        GetInsertAllowed();
    end;

    trigger OnModify()
    begin
        GetInsertAllowed();
    end;

    var
        companyIntegration: Record "Company Integration";

    local procedure GetInsertAllowed(): Boolean
    begin
        companyIntegration.Reset();
        companyIntegration.SetCurrentKey("Company Name");
        companyIntegration.SetRange("Company Name", CompanyName);
        if companyIntegration.FindFirst() then
            companyIntegration.TestField("Copy Items To", false);

        exit(true);
    end;
}