tableextension 50020 "Sales Invoice Line Ext" extends "Sales Invoice Line"
{
    fields
    {
        // Add changes to table fields here
        field(50000; "CRM ID"; Guid)
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'CRM ID',
                        RUS = 'CRM ID';

            // trigger OnValidate()
            // var
            //     locSL: Record "Sales Line";
            // begin
            //     locSL.SetCurrentKey("CRM ID");
            //     locSL.SetRange("CRM ID", "CRM ID");
            //     if not locSL.IsEmpty then
            //         Error(errCRMIdForSalesLineAlreadyExist, "CRM ID");
            // end;
        }
    }
    var
    // errCRMIdForSalesLineAlreadyExist: Label 'CRM ID %1 for sales line already exist';
}