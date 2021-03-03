table 50007 "Classificator Unit of Measure"
{
    DataClassification = CustomerContent;
    DataPerCompany = false;
    DrillDownPageId = "Classificator UoM List";

    fields
    {
        field(1; "Numeric Code"; Text[4])
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'Numeric Code',
                        RUS = 'Числовой Код';

            trigger OnValidate()
            begin
                while StrLen("Numeric Code") < 4 do
                    "Numeric Code" := '0' + "Numeric Code";
            end;
        }
        field(2; "Short Name"; Text[10])
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'Short Name',
                        RUS = 'Краткое имя';
        }
        field(3; Description; Text[100])
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'Description',
                        RUS = 'Описание';
        }
        field(4; "Short Name EU"; Text[20])
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'Short Name EU',
                        RUS = 'Краткое имя (международное)';
        }
        field(5; "Numeric Code EU"; Text[4])
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'Numeric Code EU',
                        RUS = 'Числовой код (международный)';

            trigger OnValidate()
            begin
                while StrLen("Numeric Code EU") < 4 do
                    "Numeric Code EU" := '0' + "Numeric Code EU";
            end;
        }
    }

    keys
    {
        key(PK; "Numeric Code", "Short Name")
        {
            Clustered = true;
        }
    }

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