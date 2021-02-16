tableextension 50013 "Gen. Journal Line Ext." extends "Gen. Journal Line"
{
    fields
    {
        // Add changes to table fields here
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