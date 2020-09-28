tableextension 50000 "Sales Order Entity Buffer Ext." extends "Sales Order Entity Buffer"
{
    fields
    {
        // Add changes to table fields here
        field(50000; "Agreement No."; Code[20])
        {
            CaptionML = ENU = 'Agreement No.',
                        RUS = 'Номер договора';
            // TableRelation = "Customer Agreement"."No." WHERE("Customer No." = FIELD("Bill-to Customer No."),
            //                                                   Active = CONST(true));
        }
        // field(50001; "External Agreement No."; Text[30])
        // {
        //     CaptionML = ENU = 'External Agreement No.',
        //                 RUS = 'Внешний номер договора';
        // }
    }
}