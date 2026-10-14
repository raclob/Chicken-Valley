using UnrealBuildTool;
using System.Collections.Generic;
public class ChickenValleyTarget : TargetRules
{
    public ChickenValleyTarget(TargetInfo Target) : base(Target)
    {
        Type = TargetType.Game;
        DefaultBuildSettings = BuildSettingsVersion.V5;
        IncludeOrderVersion = EngineIncludeOrderVersion.Unreal5_6;
        ExtraModuleNames.Add("ChickenValley");
    }
}
