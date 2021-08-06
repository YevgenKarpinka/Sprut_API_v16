tableextension 50025 "Bank Acc. Rec. Line Ext" extends "Bank Acc. Reconciliation Line"
{
    fields
    {
        // Add changes to table fields here
        field(50000; "Description Extended"; Text[350])
        {
            DataClassification = SystemMetadata;
            CaptionML = ENU = 'Description Extended',
                        RUS = 'Описание расширенное';

            trigger OnValidate()
            begin
                if "Description Extended" <> '' then
                    Description := CopyStr("Description Extended", 1, MaxStrLen(Description));
            end;
        }
    }
}