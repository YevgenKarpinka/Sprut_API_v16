tableextension 50019 "Activities Cue Ext." extends "Activities Cue"
{
    fields
    {
        // Add changes to table fields here
        field(50000; "UnApply Prepm. Doc."; Integer)
        {
            // DataClassification = CustomerContent;
            CaptionML = ENU = 'UnApply Prepm. Doc.',
                        RUS = 'Непримен. док. предоплаты';
            FieldClass = FlowField;
            CalcFormula = Count("Sales Cr.Memo Header" where("Prepayment Order No." = filter(<> ''), "Remaining Amount" = filter(< 0)));
        }
        field(50001; "Deduplicated Customers"; Integer)
        {
            // DataClassification = CustomerContent;
            CaptionML = ENU = 'Deduplicated Customers',
                        RUS = 'Дедублицированные клиенты';
            FieldClass = FlowField;
            CalcFormula = Count(Customer where("Deduplicate Id" = filter(<> '00000000-0000-0000-0000-000000000000')));
        }
        field(50002; "Error Job Queue Entries"; Integer)
        {
            // DataClassification = CustomerContent;
            CaptionML = ENU = 'Error Job Queue Entries',
                        RUS = 'Ошибки в операциях очереди работ';
            FieldClass = FlowField;
            CalcFormula = Count("Activity Entries" where("Table ID" = filter(472)));
        }
        field(50003; "Modify Order Entries"; Integer)
        {
            // DataClassification = CustomerContent;
            CaptionML = ENU = 'Error Modify Order Entries',
                        RUS = 'Ошибки в операциях изменения заказа';
            FieldClass = FlowField;
            CalcFormula = Count("Activity Entries" where("Table ID" = filter(50002)));
        }
        field(50004; "Open Sales Order"; Integer)
        {
            // DataClassification = CustomerContent;
            CaptionML = ENU = 'Open Sales Order',
                        RUS = 'Открытые заказы на продажу';
            FieldClass = FlowField;
            CalcFormula = Count("Activity Entries" where("Table ID" = filter(36)));
        }
    }

}