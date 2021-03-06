tableextension 50018 "Unit of Measure Ext." extends "Unit of Measure"
{
    fields
    {

        field(50001; "Numeric Code"; Code[4])
        {
            CaptionML = ENU = 'Numeric Code',
                        RUS = 'Числовой код';
            DataClassification = CustomerContent;
            TableRelation = "Classificator Unit of Measure"."Numeric Code";
        }
    }

    trigger OnInsert()
    begin
        UpdateLastDateTimeModified();
    end;

    trigger OnModify()
    begin
        UpdateLastDateTimeModified();
    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin
        UpdateLastDateTimeModified();
    end;

    local procedure UpdateLastDateTimeModified()
    begin
        CaptionMgt.CheckModifyAllowed();
        // "Last DateTime Modified" := CurrentDateTime;
        TestField("Numeric Code");
    end;

    var
        CaptionMgt: Codeunit "Caption Mgt.";
}