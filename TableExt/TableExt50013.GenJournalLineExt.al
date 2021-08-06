tableextension 50013 "Gen. Journal Line Ext." extends "Gen. Journal Line"
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
        // modify(Description)
        // {
        //     trigger OnAfterValidate()
        //     begin
        //         "Description Extended" := Description;
        //     end;
        // }
        modify("Account Type")
        {

            trigger OnBeforeValidate()
            begin
                if Description <> '' then
                    xDescription := Description;
            end;

            trigger OnAfterValidate()
            begin
                if xDescription <> '' then
                    Description := xDescription;
            end;
        }
        modify("Account No.")
        {

            trigger OnBeforeValidate()
            begin
                if "Source Type" <> "Source Type"::" " then
                    xSourceType := "Source Type";
                if "Source No." <> '' then
                    xSourceNo := "Source No.";
            end;

            trigger OnAfterValidate()
            begin
                if xSourceType <> xSourceType::" " then
                    "Source Type" := xSourceType;
                if xSourceNo <> '' then
                    "Source No." := xSourceNo;
            end;
        }
    }

    var
        xDescription: Text[100];
        xSourceType: Enum "Gen. Journal Source Type";
        xSourceNo: Code[20];
}