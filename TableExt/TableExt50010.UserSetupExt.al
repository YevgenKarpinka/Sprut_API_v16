tableextension 50010 "User Setup Ext" extends "User Setup"
{
    fields
    {
        // Add changes to table fields here
        field(50000; "Send Email UnApply Doc."; Boolean)
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'Send Email UnApply Doc.',
                        RUS = 'Отослать почтой непримен. док.';
        }
        field(50002; "Send Email Error Tasks"; Boolean)
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'Send Email Error Tasks',
                        RUS = 'Отослать почтой ошибки задач';
        }
    }
}