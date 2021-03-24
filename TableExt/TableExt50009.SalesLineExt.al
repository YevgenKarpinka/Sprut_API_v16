tableextension 50009 "Sales Line Ext" extends "Sales Line"
{
    fields
    {
        // Add changes to table fields here
        field(50000; "CRM ID"; Guid)
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'CRM ID',
                        RUS = 'CRM ID';

            trigger OnValidate()
            var
                locSL: Record "Sales Line";
                locSIL: Record "Sales Invoice Line";
            begin
                locSL.SetCurrentKey("CRM ID");
                locSL.SetRange("CRM ID", "CRM ID");
                if not locSL.IsEmpty then
                    Error(errCRMIdForSalesLineAlreadyExist, "CRM ID");

                locSIL.SetCurrentKey("CRM ID");
                locSIL.SetRange("CRM ID", "CRM ID");
                if not locSIL.IsEmpty then
                    Error(errCRMIdForSalesLineAlreadyExist, "CRM ID");
            end;
        }
    }
    var
        errCRMIdForSalesLineAlreadyExist: Label 'CRM ID %1 for sales line already exist';
}