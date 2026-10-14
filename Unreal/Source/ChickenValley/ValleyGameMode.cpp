#include "ValleyGameMode.h"
#include "ValleyFarmer.h"
#include "ValleyHUD.h"
#include "ValleyGeometry.h"
#include "Engine/DirectionalLight.h"
#include "Engine/SkyLight.h"
#include "Engine/SkyAtmosphere.h"
#include "Components/DirectionalLightComponent.h"
#include "Components/SkyLightComponent.h"
#include "Kismet/GameplayStatics.h"

AValleyGameMode::AValleyGameMode()
{
    PrimaryActorTick.bCanEverTick = true;
    DefaultPawnClass = AValleyFarmer::StaticClass();
    HUDClass = AValleyHUD::StaticClass();
}

AActor* AValleyGameMode::Group(FVector Position)
{
    auto* Actor = GetWorld()->SpawnActor<AActor>();
    auto* Root = NewObject<USceneComponent>(Actor);
    Actor->AddInstanceComponent(Root);
    Actor->SetRootComponent(Root);
    Root->RegisterComponent();
    Actor->SetActorLocation(Position);
    return Actor;
}

void AValleyGameMode::BeginPlay()
{
    Super::BeginPlay();
    BuildWorld();
    SyncFarms();
}

void AValleyGameMode::BuildWorld()
{
    auto* Sun = GetWorld()->SpawnActor<ADirectionalLight>(FVector(0, 0, 2500), FRotator(-45, -30, 0));
    Sun->GetLightComponent()->SetIntensity(3.f);
    Cast<UDirectionalLightComponent>(Sun->GetLightComponent())->bAtmosphereSunLight = true;
    GetWorld()->SpawnActor<ASkyAtmosphere>();
    auto* Sky = GetWorld()->SpawnActor<ASkyLight>();
    Sky->GetLightComponent()->SetIntensity(0.6f);
    Sky->GetLightComponent()->SetRealTimeCaptureEnabled(true);
    auto* Ground = Group(FVector::ZeroVector);
    ValleyMesh(Ground, Ground->GetRootComponent(), TEXT("Cube"), FVector(0, 0, -30), FVector(14000, 14000, 60), FLinearColor(0.17, 0.30, 0.08), true);
    ValleyMesh(Ground, Ground->GetRootComponent(), TEXT("Cube"), FVector(0, 0, 1), FVector(600, 2600, 2), FLinearColor(0.50, 0.38, 0.20));
    for (int Side = 0; Side < 2; ++Side)
    {
        const float X = Side == 0 ? -1400.f : 1400.f;
        auto* Barn = Group(FVector(X, -700, 0));
        const FLinearColor Color = Side == 0 ? FLinearColor(0.03, 0.28, 0.40) : FLinearColor(0.50, 0.13, 0.06);
        ValleyMesh(Barn, Barn->GetRootComponent(), TEXT("Cube"), FVector(0, 0, 150), FVector(550, 400, 300), Color, true);
        for (int RoofSide : {-1, 1})
        {
            auto* Roof = ValleyMesh(Barn, Barn->GetRootComponent(), TEXT("Cube"), FVector(RoofSide*140, 0, 344), FVector(320, 470, 25), FLinearColor(0.08, 0.11, 0.13));
            Roof->SetRelativeRotation(FRotator(-RoofSide*25, 0, 0));
        }
        ValleyMesh(Barn, Barn->GetRootComponent(), TEXT("Cube"), FVector(0, 201, 100), FVector(120, 5, 200), FLinearColor(0.60, 0.43, 0.20));
        for (int Window : {-1, 1})
            ValleyMesh(Barn, Barn->GetRootComponent(), TEXT("Cube"), FVector(Window*180, 203, 180), FVector(75, 5, 80), FLinearColor(0.25, 0.55, 0.70));
        auto* Field = Group(FVector(X, 0, 0));
        ValleyMesh(Field, Field->GetRootComponent(), TEXT("Cube"), FVector(0, 150, 3), FVector(1250, 1300, 6), FLinearColor(0.26, 0.40, 0.09));
    }
    for (int I = 0; I < 24; ++I)
    {
        const float Angle = I * 2.f * PI / 24.f;
        auto* Tree = Group(FVector(FMath::Cos(Angle)*3200, FMath::Sin(Angle)*2800, 0));
        ValleyMesh(Tree, Tree->GetRootComponent(), TEXT("Cylinder"), FVector(0, 0, 200), FVector(55, 55, 400), FLinearColor(0.22, 0.12, 0.05), true);
        ValleyMesh(Tree, Tree->GetRootComponent(), TEXT("Sphere"), FVector(0, 0, 460), FVector(430, 430, 470), FLinearColor(0.07, 0.25, 0.08));
    }
}

void AValleyGameMode::SyncFarms()
{
    for (int Side = 0; Side < 2; ++Side)
    {
        const auto& F = Match.Farms[Side];
        const float X = Side == 0 ? -1400.f : 1400.f;
        if (Counts[Side] != F.Chickens)
        {
            if (Flocks[Side]) Flocks[Side]->Destroy();
            Flocks[Side] = Group(FVector(X, 0, 0));
            for (int I = 0; I < F.Chickens; ++I)
            {
                const FVector P((I%6-2.5f)*130, (I/6)*100-120, 0);
                ValleyMesh(Flocks[Side], Flocks[Side]->GetRootComponent(), TEXT("Sphere"), P+FVector(0, 0, 36), FVector(58, 65, 64), FLinearColor(0.95, 0.88, 0.67));
                ValleyMesh(Flocks[Side], Flocks[Side]->GetRootComponent(), TEXT("Sphere"), P+FVector(25, 0, 69), FVector(38), FLinearColor(1, 0.97, 0.86));
                ValleyMesh(Flocks[Side], Flocks[Side]->GetRootComponent(), TEXT("Cube"), P+FVector(43, 0, 69), FVector(18, 13, 12), FLinearColor(0.90, 0.46, 0.05));
                ValleyMesh(Flocks[Side], Flocks[Side]->GetRootComponent(), TEXT("Cube"), P+FVector(25, 0, 90), FVector(18, 8, 14), FLinearColor(0.65, 0.04, 0.02));
            }
            Counts[Side] = F.Chickens;
        }
        const int Key = F.Coops * 10 + F.Fence;
        if (Buildings[Side] != Key)
        {
            if (Structures[Side]) Structures[Side]->Destroy();
            Structures[Side] = Group(FVector(X, 0, 0));
            for (int I = 0; I < F.Coops; ++I)
            {
                const FVector P(-420+I*280, 750, 0);
                ValleyMesh(Structures[Side], Structures[Side]->GetRootComponent(), TEXT("Cube"), P+FVector(0, 0, 60), FVector(220, 190, 120), FLinearColor(0.53, 0.34, 0.13), true);
                ValleyMesh(Structures[Side], Structures[Side]->GetRootComponent(), TEXT("Cube"), P+FVector(0, 0, 131), FVector(250, 215, 20), FLinearColor(0.25, 0.17, 0.07));
            }
            if (F.Fence > 0)
            {
                const float Edge = Side == 0 ? 650.f : -650.f;
                for (int I = 0; I < 11; ++I)
                {
                    const float Y = -500+I*110;
                    if (FMath::Abs(Y) < 160) continue;
                    ValleyMesh(Structures[Side], Structures[Side]->GetRootComponent(), TEXT("Cube"), FVector(Edge, Y, 80), FVector(20, 20, 160), FLinearColor(0.48, 0.30, 0.13), true);
                }
                for (int Level = 0; Level < F.Fence; ++Level)
                    for (int Half : {-1, 1})
                        ValleyMesh(Structures[Side], Structures[Side]->GetRootComponent(), TEXT("Cube"), FVector(Edge, Half*365, 50+Level*40), FVector(15, 410, 14), FLinearColor(0.40, 0.23, 0.09), true);
            }
            Buildings[Side] = Key;
        }
    }
}

void AValleyGameMode::SyncRaids()
{
    TSet<int32> Alive;
    for (const auto& R : Match.Raids)
    {
        Alive.Add(R.Id);
        if (!RaidActors.Contains(R.Id))
        {
            auto* Raider = Group(FVector::ZeroVector);
            ValleyMesh(Raider, Raider->GetRootComponent(), TEXT("Cube"), FVector(0, 0, 85), FVector(45, 60, 95), FLinearColor(0.6, 0.06, 0.03));
            ValleyMesh(Raider, Raider->GetRootComponent(), TEXT("Sphere"), FVector(0, 0, 155), FVector(44), FLinearColor(0.7, 0.4, 0.2));
            ValleyMesh(Raider, Raider->GetRootComponent(), TEXT("Cylinder"), FVector(0, 0, 180), FVector(85, 85, 12), FLinearColor(0.6, 0.4, 0.1));
            RaidActors.Add(R.Id, Raider);
        }
        const float Home = R.Side == 0 ? -1400.f : 1400.f;
        const float Start = R.Returning ? -Home : Home;
        const float Finish = -Start;
        const float T = FMath::Clamp(static_cast<float>(R.Elapsed/R.Duration), 0.f, 1.f);
        RaidActors[R.Id]->SetActorLocation(FVector(FMath::Lerp(Start, Finish, T), 450, 0));
    }
    TArray<int32> Remove;
    for (const auto& Pair : RaidActors)
        if (!Alive.Contains(Pair.Key)) { Pair.Value->Destroy(); Remove.Add(Pair.Key); }
    for (int32 Id : Remove) RaidActors.Remove(Id);
}

void AValleyGameMode::Tick(float Delta)
{
    Super::Tick(Delta);
    Match.Tick(Delta);
    auto* Player = UGameplayStatics::GetPlayerPawn(this, 0);
    if (Match.Carried > 0 && NearFarm(Player, 0)) Match.Deliver();
    Refresh -= Delta;
    if (Refresh <= 0) { Refresh = 0.25; SyncFarms(); }
    SyncRaids();
}
bool AValleyGameMode::NearFarm(APawn* Farmer, int Side) const
{
    return Farmer && FVector::Dist2D(Farmer->GetActorLocation(), FVector(Side == 0 ? -1400 : 1400, 0, 0)) < 700;
}
void AValleyGameMode::Purchase(Valley::Action Action)
{
    if (Match.Finished || UGameplayStatics::IsGamePaused(this)) return;
    if (!NearFarm(UGameplayStatics::GetPlayerPawn(this, 0), 0)) { Match.Notice = "Return to your farm to build and buy chickens."; return; }
    Match.Notice = Match.Buy(0, Action) ? "Farm upgraded!" : "Not enough coins, coop space, or upgrade already at maximum.";
    SyncFarms();
}
void AValleyGameMode::Interact(APawn* Farmer)
{
    if (Match.Finished || UGameplayStatics::IsGamePaused(this)) return;
    if (NearFarm(Farmer, 1))
    {
        if (!Match.Steal() && Match.Carried == 0 && Match.Notice.find("fence") == std::string::npos)
            Match.Notice = "Need 30 coins, spare coop space, and a ready raid cooldown.";
    }
    else Match.Notice = "Walk into the rival chicken field to steal. Return home to deliver.";
    SyncFarms();
}
void AValleyGameMode::TogglePause()
{
    UGameplayStatics::SetGamePaused(this, !UGameplayStatics::IsGamePaused(this));
}
void AValleyGameMode::Restart()
{
    UGameplayStatics::SetGamePaused(this, false);
    Match = Valley::Match();
    if (auto* Farmer = Cast<AValleyFarmer>(UGameplayStatics::GetPlayerPawn(this, 0))) Farmer->ResetFarmer();
    SyncFarms();
    SyncRaids();
}
