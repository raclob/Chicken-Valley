#pragma once
#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "FarmEconomy.h"
#include "ValleyGameMode.generated.h"

UCLASS()
class CHICKENVALLEY_API AValleyGameMode : public AGameModeBase
{
    GENERATED_BODY()
public:
    AValleyGameMode();
    virtual void BeginPlay() override;
    virtual void Tick(float DeltaSeconds) override;
    Valley::Match Match;
    void Purchase(Valley::Action Action);
    void Interact(APawn* Farmer);
    void TogglePause();
    void Restart();
    bool NearFarm(APawn* Farmer, int Side) const;
private:
    UPROPERTY() TObjectPtr<AActor> Flocks[2];
    UPROPERTY() TObjectPtr<AActor> Structures[2];
    UPROPERTY() TMap<int32, TObjectPtr<AActor>> RaidActors;
    int Counts[2] = {-1, -1};
    int Buildings[2] = {-1, -1};
    float Refresh = 0;
    AActor* Group(FVector Position);
    void BuildWorld();
    void SyncFarms();
    void SyncRaids();
};
