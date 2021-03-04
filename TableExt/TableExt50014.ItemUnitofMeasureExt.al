tableextension 50014 "Item Unit of Measure Ext." extends "Item Unit of Measure"
{
    trigger OnInsert()
    begin
        UpdateItemLastDateTimeModified();
    end;

    trigger OnModify()
    begin
        UpdateItemLastDateTimeModified();
    end;

    trigger OnDelete()
    begin
    end;

    trigger OnRename()
    begin
        UpdateItemLastDateTimeModified();
    end;

    var
        Item: Record Item;

    local procedure UpdateItemLastDateTimeModified()
    begin
        Item.Get("Item No.");
        Item."Last DateTime Modified" := CurrentDateTime;
        Item.Modify();
    end;

}