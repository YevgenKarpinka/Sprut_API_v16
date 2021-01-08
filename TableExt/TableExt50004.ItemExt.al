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
            Editable = false;
        }
        field(50001; "1C Path"; Text[30])
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = '1C Path',
                        RUS = '1C Путь';
            Editable = false;
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

    var
        CopyItemFromMainCompany: Boolean;

    local procedure CheckModifyItemAllowed();
    var
        CompIntegr: Record "Company Integration";
    begin
        if CopyItemFromMainCompany then exit;

        CompIntegr.SetCurrentKey("Company Name", "Copy Items To");
        CompIntegr.SetRange("Company Name", CompanyName);
        CompIntegr.FindFirst();
        CompIntegr.TestField("Copy Items To", false);
    end;

    procedure InitToCopyItem(xCopyItemFromMainCompany: Boolean)
    begin
        CopyItemFromMainCompany := xCopyItemFromMainCompany;
    end;
}