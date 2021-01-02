table 50005 "Company Integration"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            AutoIncrement = true;
        }
        field(2; "Company Name"; Text[30])
        {
            CaptionML = ENU = 'Company Name',
                        RUS = 'Имя компании';
            DataClassification = CustomerContent;
            TableRelation = Company.Name;
        }
        field(3; "Copy Items"; Boolean)
        {
            CaptionML = ENU = 'Copy Items',
                        RUS = 'Копировать товары';
            DataClassification = CustomerContent;
        }
        field(4; "Environment Production"; Boolean)
        {
            CaptionML = ENU = 'Environment Production',
                        RUS = 'Производственная среда';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(SK; "Company Name")
        { }
    }

    var

    trigger OnInsert()
    begin

    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

}