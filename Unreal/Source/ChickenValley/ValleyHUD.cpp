#include "ValleyHUD.h"
#include "ValleyGameMode.h"
#include "Engine/Canvas.h"
#include "Kismet/GameplayStatics.h"

void AValleyHUD::DrawHUD()
{
    Super::DrawHUD();
    auto* GM = GetWorld()->GetAuthGameMode<AValleyGameMode>();
    if (!GM || !Canvas) return;
    const auto& M = GM->Match;
    const auto& F = M.Farms[0];
    const float Scale = FMath::Max(0.8f, Canvas->SizeX/1280.f);
    DrawRect(FLinearColor(0.02, 0.07, 0.06, 0.88), 15, 15, Canvas->SizeX-30, 95*Scale);
    DrawText(FString::Printf(TEXT("YOUR FARM  %d coins  |  %d/%d chickens  |  +%.1f coins/s"), int(F.Coins), F.Chickens, M.Capacity(0), F.Chickens*0.65), FLinearColor::White, 30, 30, nullptr, Scale);
    const int Seconds = FMath::CeilToInt(M.Remaining);
    DrawText(FString::Printf(TEXT("%d:%02d  |  RIVAL: %d chickens  |  Carrying: %d"), Seconds/60, Seconds%60, M.Farms[1].Chickens, M.Carried), FLinearColor(1, 0.85, 0.5), 30, 58*Scale, nullptr, Scale);
    DrawText(UTF8_TO_TCHAR(M.Notice.c_str()), FLinearColor::White, 30, 125*Scale, nullptr, Scale);
    const float Y = Canvas->SizeY-118*Scale;
    DrawRect(FLinearColor(0.02, 0.07, 0.06, 0.85), 15, Y-10, Canvas->SizeX-30, 115*Scale);
    DrawText(TEXT("WASD: walk   |   Hold right mouse: look   |   Space: jump   |   Esc: pause   |   R: restart"), FLinearColor::White, 30, Y, nullptr, Scale);
    DrawText(FString::Printf(TEXT("At home: 1 Chicken (%d)   2 Coop (%d)   3 Fence (%d)   4 Boots (%d)"), M.Cost(0, Valley::Action::Chicken), M.Cost(0, Valley::Action::Coop), M.Cost(0, Valley::Action::Fence), M.Cost(0, Valley::Action::Boots)), FLinearColor::White, 30, Y+28*Scale, nullptr, Scale);
    DrawText(FString::Printf(TEXT("At rival farm: E to steal (30 coins)   |   Return home to deliver   |   Raid cooldown: %.0fs"), F.Cooldown), FLinearColor(1, 0.85, 0.5), 30, Y+56*Scale, nullptr, Scale);
    if (UGameplayStatics::IsGamePaused(this)) DrawText(TEXT("PAUSED - press Esc to resume"), FLinearColor::Yellow, 30, 165*Scale, nullptr, Scale*1.2);
}
