table 50005 "Company Integration"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;
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
        field(3; "Copy Items From"; Boolean)
        {
            CaptionML = ENU = 'Copy Items From',
                        RUS = 'Копировать товары с';
            DataClassification = CustomerContent;
        }
        field(4; "Environment Production"; Boolean)
        {
            CaptionML = ENU = 'Environment Production',
                        RUS = 'Производственная среда';
            DataClassification = CustomerContent;
        }
        field(5; "Send Email UnApply Doc."; Boolean)
        {
            CaptionML = ENU = 'Send Email UnApply Doc.',
                        RUS = 'Отсылать почту непримен. док.';
            DataClassification = CustomerContent;
        }
        field(6; "Copy Items To"; Boolean)
        {
            CaptionML = ENU = 'Copy Items To',
                        RUS = 'Копировать товары в';
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
        errCompanyForCopyItemsFromCountMoreOneNotAllowed: TextConst ENU = 'Company For Copy Items From Count More One Not Allowed',
                                RUS = 'Компания источник справочника товаров не может быть больше одной';
        errAllCompanyForCopyItemsToNotAllowed: TextConst ENU = 'All Company For Copy Items To Not Allowed',
                                RUS = 'Все компании не могут быть получателями справочника товаров';

    trigger OnInsert()
    begin

    end;

    trigger OnModify()
    begin
        ComIntegr.Reset();
        TotalCount := ComIntegr.Count;

        ComIntegr.SetRange("Copy Items From", true);
        if ComIntegr.Count > 1 then
            Error(errCompanyForCopyItemsFromCountMoreOneNotAllowed);

        ComIntegr.Reset();
        ComIntegr.SetRange("Copy Items To", true);
        if ComIntegr.Count = TotalCount then
            Error(errAllCompanyForCopyItemsToNotAllowed);
    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

    var
        TotalCount: Integer;
        ComIntegr: Record "Company Integration";
}