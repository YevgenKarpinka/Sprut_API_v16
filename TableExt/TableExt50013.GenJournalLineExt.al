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
    }

    var
        xDescription: Text[100];
}