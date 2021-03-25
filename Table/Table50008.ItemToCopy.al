table 50008 "Item To Copy"
{
    DataClassification = CustomerContent;
    DataPerCompany = false;
    DrillDownPageId = "Item To Copy List";

    fields
    {
        field(1; "No."; Code[20])
        {
            DataClassification = SystemMetadata;
            CaptionML = ENU = 'Item No.',
                        RUS = 'Товар Но.';

            trigger OnValidate()
            var
                Item: Record Item;
                Vendor: Record Vendor;
            begin
                case Type of
                    Type::Item:
                        begin
                            if Item.Get("No.") then
                                Description := Item.Description
                            else
                                Description := '';
                        end;
                    Type::Vendor:
                        begin
                            if Vendor.Get("No.") then
                                Description := Vendor.Name
                            else
                                Description := '';
                        end;
                end;
            end;
        }
        field(2; "Description"; Text[100])
        {
            CaptionML = ENU = 'Description',
                        RUS = 'Описание';
            FieldClass = FlowField;
            Editable = false;
        }
        field(3; Type; Enum "Entity Type")
        {
            DataClassification = SystemMetadata;
            CaptionML = ENU = 'Type',
                        RUS = 'Тип';
        }
    }

    keys
    {
        key(PK; Type, "No.")
        {
            Clustered = true;
        }
    }

}

enum 50006 "Entity Type"
{
    Extensible = true;

    value(0; Item)
    {
        CaptionML = ENU = 'Item',
                    RUS = 'Товар';
    }
    value(2; Vendor)
    {
        CaptionML = ENU = 'Vendor',
                    RUS = 'Поставщик';
    }
}