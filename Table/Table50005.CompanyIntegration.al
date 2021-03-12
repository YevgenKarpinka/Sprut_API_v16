table 50005 "Company Integration"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;
    CaptionML = ENU = 'Company Integration',
                RUS = 'Компания интеграции';

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

            trigger OnValidate()
            begin
                if not "Copy Items From" then exit;

                ComIntegr.Reset();
                ComIntegr.SetCurrentKey("Copy Items From");
                ComIntegr.SetRange("Copy Items From", true);
                if ComIntegr.Count > 1 then
                    Error(errCompanyForCopyItemsFromCountMoreOneNotAllowed);
            end;
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

            trigger OnValidate()
            begin
                if not "Copy Items To" then exit;

                ComIntegr.Reset();
                TotalCount := ComIntegr.Count;

                ComIntegr.SetRange("Copy Items To", true);
                if ComIntegr.Count = TotalCount then
                    Error(errAllCompanyForCopyItemsToNotAllowed);
            end;
        }
        field(7; "Send Email Error Tasks"; Boolean)
        {
            CaptionML = ENU = 'Send Email Error Tasks',
                        RUS = 'Отсылать почту ошибок задач';
            DataClassification = CustomerContent;
        }
        field(8; "Integration With 1C"; Boolean)
        {
            CaptionML = ENU = 'Integration With 1C',
                        RUS = 'Интеграция с 1С';
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