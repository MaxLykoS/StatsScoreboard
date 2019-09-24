class KFSSPlayerController extends KFPlayerController;

function SetPawnClass(string inClass, string inCharacter) 
{
    super.SetPawnClass(inClass, inCharacter);
    PawnClass= Class'KFSSHumanPawn';
}