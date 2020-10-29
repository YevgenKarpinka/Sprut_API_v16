tableextension 50000 "Sales Order Entity Buffer Ext." extends "Sales Order Entity Buffer"
{
    fields
    {
        // Add changes to table fields here
        field(50000; "Agreement No."; Code[20])
        {
            CaptionML = ENU = 'Agreement No.',
                        RUS = 'Номер договора';
        }

    }
}