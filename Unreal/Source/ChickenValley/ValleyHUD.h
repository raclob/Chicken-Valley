#pragma once
#include "CoreMinimal.h"
#include "GameFramework/HUD.h"
#include "ValleyHUD.generated.h"

UCLASS()
class CHICKENVALLEY_API AValleyHUD : public AHUD
{
    GENERATED_BODY()
public:
    virtual void DrawHUD() override;
};
