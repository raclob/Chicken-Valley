#include "ValleyFarmer.h"
#include "ValleyGameMode.h"
#include "ValleyGeometry.h"
#include "Camera/CameraComponent.h"
#include "Camera/PlayerCameraManager.h"
#include "GameFramework/SpringArmComponent.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "GameFramework/PlayerController.h"
#include "Components/InputComponent.h"

AValleyFarmer::AValleyFarmer()
{
    PrimaryActorTick.bCanEverTick = true;
    bUseControllerRotationYaw = false;
    GetCharacterMovement()->bOrientRotationToMovement = true;
    GetCharacterMovement()->RotationRate = FRotator(0, 540, 0);
    GetCharacterMovement()->MaxWalkSpeed = 450;
    GetCharacterMovement()->JumpZVelocity = 450;
    Body = CreateDefaultSubobject<USceneComponent>(TEXT("FarmerBody"));
    Body->SetupAttachment(GetRootComponent());
    Body->SetRelativeLocation(FVector(0, 0, -88));
    Arm = CreateDefaultSubobject<USpringArmComponent>(TEXT("FollowArm"));
    Arm->SetupAttachment(GetRootComponent());
    Arm->TargetArmLength = 480;
    Arm->TargetOffset = FVector(0, 0, 65);
    Arm->bUsePawnControlRotation = true;
    Arm->bEnableCameraLag = true;
    Arm->CameraLagSpeed = 12;
    Camera = CreateDefaultSubobject<UCameraComponent>(TEXT("FollowCamera"));
    Camera->SetupAttachment(Arm, USpringArmComponent::SocketName);
    Camera->FieldOfView = 75;
}

void AValleyFarmer::BeginPlay()
{
    Super::BeginPlay();
    ValleyMesh(this, Body, TEXT("Cube"), FVector(0, 0, 114), FVector(42, 64, 62), FLinearColor(0.75, 0.57, 0.28));
    ValleyMesh(this, Body, TEXT("Cube"), FVector(24, 0, 106), FVector(8, 48, 45), FLinearColor(0.03, 0.28, 0.48));
    ValleyMesh(this, Body, TEXT("Sphere"), FVector(0, 0, 162), FVector(46), FLinearColor(0.76, 0.42, 0.20));
    ValleyMesh(this, Body, TEXT("Cylinder"), FVector(0, 0, 189), FVector(112, 112, 9), FLinearColor(0.75, 0.52, 0.12));
    ValleyMesh(this, Body, TEXT("Cylinder"), FVector(0, 0, 201), FVector(66, 66, 24), FLinearColor(0.75, 0.52, 0.12));
    for (int Side : {-1, 1})
    {
        auto* Leg = NewObject<USceneComponent>(this);
        AddInstanceComponent(Leg);
        Leg->SetupAttachment(Body);
        Leg->SetRelativeLocation(FVector(0, Side*18, 77));
        Leg->RegisterComponent();
        ValleyMesh(this, Leg, TEXT("Cube"), FVector(0, 0, -28), FVector(25, 23, 56), FLinearColor(0.04, 0.22, 0.36));
        ValleyMesh(this, Leg, TEXT("Cube"), FVector(7, 0, -63), FVector(40, 26, 20), FLinearColor(0.16, 0.1, 0.04));
        Limbs.Add(Leg);
        auto* Hand = NewObject<USceneComponent>(this);
        AddInstanceComponent(Hand);
        Hand->SetupAttachment(Body);
        Hand->SetRelativeLocation(FVector(0, Side*44, 140));
        Hand->RegisterComponent();
        ValleyMesh(this, Hand, TEXT("Cube"), FVector(0, 0, -28), FVector(23, 20, 56), FLinearColor(0.76, 0.42, 0.20));
        Limbs.Add(Hand);
    }
    CarriedBird = ValleyMesh(this, Body, TEXT("Sphere"), FVector(44, 0, 110), FVector(52, 44, 40), FLinearColor(0.95, 0.88, 0.65));
    CarriedBird->SetVisibility(false);
    if (auto* PC = Cast<APlayerController>(Controller))
    {
        PC->bShowMouseCursor = true;
        PC->SetControlRotation(FRotator(-15, -90, 0));
        if (PC->PlayerCameraManager) { PC->PlayerCameraManager->ViewPitchMin = -55; PC->PlayerCameraManager->ViewPitchMax = 10; }
    }
    ResetFarmer();
}

void AValleyFarmer::Tick(float Delta)
{
    Super::Tick(Delta);
    const float Speed = GetVelocity().Size2D();
    WalkTime += Delta * Speed / 45.f;
    for (int I = 0; I < Limbs.Num(); ++I)
        Limbs[I]->SetRelativeRotation(FRotator(FMath::Sin(WalkTime + (I == 0 || I == 3 ? 0 : PI))*27*FMath::Clamp(Speed/450.f, 0.f, 1.f), 0, 0));
    if (auto* GM = GetWorld()->GetAuthGameMode<AValleyGameMode>())
        CarriedBird->SetVisibility(GM->Match.Carried > 0);
    const FVector P = GetActorLocation();
    if (FMath::Abs(P.X) > 2100 || FMath::Abs(P.Y) > 1600 || P.Z < -300) ResetFarmer();
}

void AValleyFarmer::PossessedBy(AController* NewController)
{
    Super::PossessedBy(NewController);
    NewController->SetControlRotation(FRotator(-15, -90, 0));
    if (auto* PC = Cast<APlayerController>(NewController))
    {
        PC->bShowMouseCursor = true;
        if (PC->PlayerCameraManager) { PC->PlayerCameraManager->ViewPitchMin = -55; PC->PlayerCameraManager->ViewPitchMax = 10; }
    }
}

void AValleyFarmer::Forward(float Value)
{
    if (Controller && Value != 0)
        AddMovementInput(FRotationMatrix(FRotator(0, Controller->GetControlRotation().Yaw, 0)).GetUnitAxis(EAxis::X), Value);
}
void AValleyFarmer::Right(float Value)
{
    if (Controller && Value != 0)
        AddMovementInput(FRotationMatrix(FRotator(0, Controller->GetControlRotation().Yaw, 0)).GetUnitAxis(EAxis::Y), Value);
}
void AValleyFarmer::Turn(float Value) { if (Looking) AddControllerYawInput(Value); }
void AValleyFarmer::Look(float Value) { if (Looking) AddControllerPitchInput(Value); }
void AValleyFarmer::LookOn()
{
    Looking = true;
    if (auto* PC = Cast<APlayerController>(Controller)) PC->bShowMouseCursor = false;
}
void AValleyFarmer::LookOff()
{
    Looking = false;
    if (auto* PC = Cast<APlayerController>(Controller)) PC->bShowMouseCursor = true;
}
void AValleyFarmer::Interact() { if (auto* GM = GetWorld()->GetAuthGameMode<AValleyGameMode>()) GM->Interact(this); }
void AValleyFarmer::BuyChicken() { if (auto* GM = GetWorld()->GetAuthGameMode<AValleyGameMode>()) GM->Purchase(Valley::Action::Chicken); }
void AValleyFarmer::BuyCoop() { if (auto* GM = GetWorld()->GetAuthGameMode<AValleyGameMode>()) GM->Purchase(Valley::Action::Coop); }
void AValleyFarmer::BuyFence() { if (auto* GM = GetWorld()->GetAuthGameMode<AValleyGameMode>()) GM->Purchase(Valley::Action::Fence); }
void AValleyFarmer::BuyBoots() { if (auto* GM = GetWorld()->GetAuthGameMode<AValleyGameMode>()) GM->Purchase(Valley::Action::Boots); }
void AValleyFarmer::PauseMatch() { LookOff(); if (auto* GM = GetWorld()->GetAuthGameMode<AValleyGameMode>()) GM->TogglePause(); }
void AValleyFarmer::RestartMatch() { LookOff(); if (auto* GM = GetWorld()->GetAuthGameMode<AValleyGameMode>()) GM->Restart(); }
void AValleyFarmer::ResetFarmer()
{
    SetActorLocation(FVector(-1400, 350, 100));
    GetCharacterMovement()->StopMovementImmediately();
    if (Controller) Controller->SetControlRotation(FRotator(-15, -90, 0));
}

void AValleyFarmer::SetupPlayerInputComponent(UInputComponent* Input)
{
    Super::SetupPlayerInputComponent(Input);
    Input->BindAxis("Forward", this, &AValleyFarmer::Forward);
    Input->BindAxis("Right", this, &AValleyFarmer::Right);
    Input->BindAxis("Turn", this, &AValleyFarmer::Turn);
    Input->BindAxis("Look", this, &AValleyFarmer::Look);
    Input->BindAction("LookHold", IE_Pressed, this, &AValleyFarmer::LookOn);
    Input->BindAction("LookHold", IE_Released, this, &AValleyFarmer::LookOff);
    Input->BindAction("Interact", IE_Pressed, this, &AValleyFarmer::Interact);
    Input->BindAction("Chicken", IE_Pressed, this, &AValleyFarmer::BuyChicken);
    Input->BindAction("Coop", IE_Pressed, this, &AValleyFarmer::BuyCoop);
    Input->BindAction("Fence", IE_Pressed, this, &AValleyFarmer::BuyFence);
    Input->BindAction("Boots", IE_Pressed, this, &AValleyFarmer::BuyBoots);
    Input->BindAction("Jump", IE_Pressed, this, &ACharacter::Jump);
    Input->BindAction("Jump", IE_Released, this, &ACharacter::StopJumping);
    Input->BindAction("Pause", IE_Pressed, this, &AValleyFarmer::PauseMatch).bExecuteWhenPaused = true;
    Input->BindAction("Restart", IE_Pressed, this, &AValleyFarmer::RestartMatch).bExecuteWhenPaused = true;
}
