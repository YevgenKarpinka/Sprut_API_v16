table 50006 "Integration Entity"
{
    DataClassification = CustomerContent;
    DataPerCompany = false;

    fields
    {
        field(1; "System Code"; code[20])
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'System Code',
                        RUS = 'Код системы';

        }
        field(2; "Name"; code[20])
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'Name',
                        RUS = 'Имя';
        }
        field(3; "Code 1"; code[20])
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'Code 1',
                        RUS = 'Код 1';
        }
        field(4; "Code 2"; code[20])
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'Code 2',
                        RUS = 'Код 2';
        }
        field(5; "Entity Id"; Guid)
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'Entity Id',
                        RUS = 'ИД сущности';
        }
        field(6; "Create Date Time"; DateTime)
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'Create Date Time',
                        RUS = 'Дата и время создания';
        }
        field(7; "Last Modify Date Time"; DateTime)
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'Last Modify Date Time',
                        RUS = 'Дата и время модификации';
        }
        field(8; "Company Name"; Text[30])
        {
            CaptionML = ENU = 'Company Name',
                        RUS = 'Имя компании';
            DataClassification = CustomerContent;
            TableRelation = Company.Name;
        }
    }

    keys
    {
        key(PK; "System Code", Name, "Code 1", "Code 2", "Company Name")
        {
            Clustered = true;
        }
    }

    var
        errDeleteNotAllowed: Label 'Delete Not Allowed!';

    trigger OnInsert()
    begin
        "Company Name" := CompanyName;
        "Create Date Time" := CurrentDateTime;
    end;

    trigger OnModify()
    begin
        "Last Modify Date Time" := CurrentDateTime;
    end;

    trigger OnDelete()
    begin
        Error(errDeleteNotAllowed);
    end;

    trigger OnRename()
    begin
        "Last Modify Date Time" := CurrentDateTime;
    end;

}