pageextension 50027 "O365 Activities Ext." extends "O365 Activities"
{
    layout
    {
        // Add changes to page layout here
        addbefore("Ongoing Sales")
        {
            cuegroup(Sprut)
            {
                CaptionML = ENU = 'Sprut',
                            RUS = 'Спрут';

                field("UnApply Prepm. Doc."; "UnApply Prepm. Doc.")
                {
                    ApplicationArea = All;

                }
                field("Deduplicated Customers"; "Deduplicated Customers")
                {
                    ApplicationArea = All;

                }
                field("Error Job Queue Entries"; CaptionMgt.ErrorJobQueueEntries())
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'Error Job Queue Entries',
                                RUS = 'Ошибки в операциях очереди работ';
                }
                // field("Modify Order Entries"; CaptionMgt.ErrorModifyOrderEntries())
                // {
                //     ApplicationArea = All;
                //     CaptionML = ENU = 'Error Modify Order Entries',
                //                 RUS = 'Ошибки в операциях изменения заказа';
                // }
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        CaptionMgt: Codeunit "Caption Mgt.";
}