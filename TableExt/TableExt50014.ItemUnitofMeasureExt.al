tableextension 50014 "Item Unit of Measure Ext." extends "Item Unit of Measure"
{
    trigger OnInsert()
    begin
        CaptionMgt.CheckModifyAllowed();
        UpdateItemLastDateTimeModified();
    end;

    trigger OnModify()
    begin
        CaptionMgt.CheckModifyAllowed();
        UpdateItemLastDateTimeModified();
    end;

    trigger OnDelete()
    begin
    end;

    trigger OnRename()
    begin
        CaptionMgt.CheckModifyAllowed();
        UpdateItemLastDateTimeModified();
    end;

    var
        Item: Record Item;
        CaptionMgt: Codeunit "Caption Mgt.";

    local procedure UpdateItemLastDateTimeModified()
    begin
        Item.Get("Item No.");
        Item."Last DateTime Modified" := CurrentDateTime;
        Item.Modify();
    end;

}