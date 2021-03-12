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
            CalcFormula = Count(Customer where("Deduplicate Id" = filter(<> '00000000-0000-0000-0000-000000000000'), Balance = filter(> 0)));
        }
    }
}