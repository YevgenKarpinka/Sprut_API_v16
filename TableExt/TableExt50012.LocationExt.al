tableextension 50012 "Location Ext." extends Location
{
    fields
    {
        // Add changes to table fields here
        field(50000; "Last Modified Date Time"; DateTime)
        {
            DataClassification = SystemMetadata;
            CaptionML = ENU = 'Last Modified Date Time',
                        RUS = 'Дата и время последнего изменения';
            Editable = false;
        }
    }

    trigger OnInsert()
    begin
        CaptionMgt.CheckModifyAllowed();
        "Last Modified Date Time" := CurrentDateTime;
    end;

    trigger OnModify()
    begin
        CaptionMgt.CheckModifyAllowed();
        "Last Modified Date Time" := CurrentDateTime;
    end;

    trigger OnRename()
    begin
        CaptionMgt.CheckModifyAllowed();
        "Last Modified Date Time" := CurrentDateTime;
    end;

    var
        CaptionMgt: Codeunit "Caption Mgt.";
}