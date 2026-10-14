#pragma once
#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "ValleyFarmer.generated.h"

class USpringArmComponent;
class UCameraComponent;
class UStaticMeshComponent;

UCLASS()
class CHICKENVALLEY_API AValleyFarmer : public ACharacter
{
    GENERATED_BODY()
public:
    AValleyFarmer();
    virtual void BeginPlay() override;
    virtual void PossessedBy(AController* NewController) override;
    virtual void Tick(float DeltaSeconds) override;
    virtual void SetupPlayerInputComponent(UInputComponent* Input) override;
    void ResetFarmer();
private:
    UPROPERTY() TObjectPtr<USpringArmComponent> Arm;
    UPROPERTY() TObjectPtr<UCameraComponent> Camera;
    UPROPERTY() TObjectPtr<USceneComponent> Body;
    UPROPERTY() TArray<TObjectPtr<USceneComponent>> Limbs;
    UPROPERTY() TObjectPtr<UStaticMeshComponent> CarriedBird;
    bool Looking = false;
    float WalkTime = 0;
    void Forward(float Value);
    void Right(float Value);
    void Turn(float Value);
    void Look(float Value);
    void LookOn();
    void LookOff();
    void Interact();
    void BuyChicken();
    void BuyCoop();
    void BuyFence();
    void BuyBoots();
    void PauseMatch();
    void RestartMatch();
};
