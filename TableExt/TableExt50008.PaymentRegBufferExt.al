tableextension 50008 "Payment Reg. Buffer Ext" extends "Payment Registration Buffer"
{
    fields
    {
        // Add changes to table fields here
        field(50000; "Agreement No."; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(50001; "Posting Date"; Date)
        {
            DataClassification = CustomerContent;
        }
    }
}