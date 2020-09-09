table 50001 "Web Service Line"
{
    DataClassification = ToBeClassified;
    CaptionML = ENU = 'Web Service Line', RUS = 'Строки Web сервиса';


    fields
    {

        field(1; "Web Service Code"; Code[20])
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'Web Service Code', RUS = 'Код Web сервиса';
            Editable = false;
        }
        field(2; "Line No."; Integer)
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'Line No.', RUS = 'Строка Но.';
            Editable = false;
        }
        field(3; "Entity"; Code[20])
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'Entity', RUS = 'Сущность';

        }

        field(4; "Request Method"; Text[10])
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'Request Method', RUS = 'Метод запроса';

        }
        field(5; "Accept Header"; Text[20])
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'Accept Header', RUS = 'Accept заголовка';

        }
        field(6; "Web API URL"; Text[250])
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'Web API URL', RUS = 'Web API URL';

        }
        field(7; Version; Text[20])
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'Version', RUS = 'Версия';
        }
    }

    keys
    {
        key(PK; "Web Service Code", "Line No.")
        {
            Clustered = true;
        }
        key(SK; Entity)
        {
        }
    }
}