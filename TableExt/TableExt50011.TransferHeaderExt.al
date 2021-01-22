tableextension 50011 "Transfer Header Ext." extends "Transfer Header"
{
    fields
    {
        // Add changes to table fields here
        field(50000; "Order No."; Code[20])
        {
            DataClassification = CustomerContent;
            CaptionML = ENU = 'Order No.',
                        RUS = 'Номер заказа';
        }
    }

    var
        myInt: Integer;
}