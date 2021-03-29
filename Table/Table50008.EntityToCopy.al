table 50008 "Entity To Copy"
{
    DataClassification = CustomerContent;
    DataPerCompany = false;
    DrillDownPageId = "Entity To Copy List";

    fields
    {
        field(1; Type; Enum EntityType)
        {
            DataClassification = SystemMetadata;
            CaptionML = ENU = 'Type',
                        RUS = 'Тип';
        }
        field(2; "No."; Code[20])
        {
            DataClassification = SystemMetadata;
            CaptionML = ENU = 'No.',
                        RUS = 'Но.';

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
        field(3; "Description"; Text[100])
        {
            CaptionML = ENU = 'Description',
                        RUS = 'Описание';
            Editable = false;
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

enum 50006 EntityType
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