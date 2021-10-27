codeunit 50023 "User Entry Management"
{
    trigger OnRun()
    begin

    end;

    var
        UserSetup: Record "User Setup";

    local procedure GetUserSetup()
    begin
        if UserSetup.Get(UserId) then;
    end;

    // [EventSubscriber(ObjectType::Codeunit, Codeunit::LogInManagement, 'OnAfterLogInEnd', '', false, false)]
    local procedure HandleOnAfterLogInEnd()
    begin
        GetUserSetup();
        if UserSetup."Enable Today as Work Date" then
            WorkDate(DT2Date(CurrentDateTime));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::LogInManagement, 'OnAfterLogInStart', '', false, false)]
    local procedure HandleOnAfterLogInStart()
    begin
        GetUserSetup();
        if UserSetup."Enable Today as Work Date" then
            WorkDate(DT2Date(CurrentDateTime));
    end;
}