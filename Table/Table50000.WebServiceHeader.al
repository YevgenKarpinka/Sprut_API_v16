table 50000 "Web Service Header"
{
    DataClassification = ToBeClassified;
    CaptionML = ENU = 'Web Service Header', RUS = 'Заголовок Web сервиса';

    fields
    {
        field(1; Code; Code[20])
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'Code', RUS = 'Код';
            NotBlank = true;
        }
        field(2; "Web Service Name"; Text[50])
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'Code', RUS = 'Код';
        }
        field(3; "Token URL"; Text[200])
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'Token URL', RUS = 'URL токена';
            NotBlank = true;
        }
        field(4; "Client Id"; Text[50])
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'Client Id', RUS = 'Id клиента';
            NotBlank = true;
        }
        field(5; "Client Secret"; Text[50])
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'Client Secret', RUS = 'Secret клиента';
            NotBlank = true;
        }
        field(6; Resource; Text[150])
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'Resource', RUS = 'Ресурс';
            NotBlank = true;
        }
        field(7; "Request Body"; Text[150])
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'Request Body', RUS = 'Тело запроса';
            NotBlank = true;
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }

}