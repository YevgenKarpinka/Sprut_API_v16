tableextension 50004 "Item Ext" extends Item
{
    fields
    {
        // Add changes to table fields here
        field(50000; "CRM Item Id"; Guid)
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'CRM Item Id',
                        RUS = 'Id товара в CRM';
            // Editable = false;
        }
        field(50001; "1C Path"; Text[30])
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = '1C Path',
                        RUS = '1C Путь';
            // Editable = false;
        }
        field(50002; "Description Print"; Text[350])
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'Description Print',
                        RUS = 'Описание для печати';
            // Editable = false;
        }
    }

    trigger OnInsert()
    begin
        // check modify item allowed
        CheckModifyItemAllowed();
    end;

    trigger OnModify()
    begin
        // check modify item allowed
        CheckModifyItemAllowed();
    end;

    trigger OnDelete()
    begin
        Error(errDeleteNotAllowed);
        // check Delete item allowed
        // CheckModifyItemAllowed();
        CheckDeleteItemAllowed();
    end;

    var
        CompIntegr: Record "Company Integration";
        CopyItemFromMainCompany: Boolean;
        blankGuid: Guid;
        errDeleteNotAllowed: Label 'Delete Not Allowed!';

    local procedure CheckModifyItemAllowed(): Boolean
    begin
        if CopyItemFromMainCompany then exit;

        CompIntegr.SetCurrentKey("Company Name");
        CompIntegr.SetRange("Company Name", CompanyName);
        if CompIntegr.FindFirst() then
            CompIntegr.TestField("Copy Items To", false);

        exit(true);
    end;

    local procedure CheckDeleteItemAllowed()
    begin
        TestField("CRM Item Id", blankGuid);
    end;

    procedure InitToCopyItem(xCopyItemFromMainCompany: Boolean)
    begin
        CopyItemFromMainCompany := xCopyItemFromMainCompany;
    end;
}