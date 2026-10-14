#pragma once
#include <algorithm>
#include <array>
#include <cmath>
#include <string>
#include <vector>

namespace Valley
{
enum class Action { Chicken, Coop, Fence, Boots, Raid };
struct Farm
{
    double Coins = 70.0;
    int Chickens = 8, Coops = 1, Fence = 0, Boots = 0;
    double Cooldown = 0.0;
};
struct Raid
{
    int Id, Side, Loot = 0;
    double Elapsed = 0.0, Duration = 9.0;
    int Power = 4;
    bool Returning = false;
};
class Match
{
public:
    std::array<Farm, 2> Farms;
    std::vector<Raid> Raids;
    double Remaining = 240.0;
    bool Finished = false;
    int Winner = -1, Carried = 0;
    std::string Notice = "Grow your farm. Cross the field and press E to steal chickens.";

    int Capacity(int Side) const { return Farms[Side].Coops * 12; }
    int Cost(int Side, Action A) const
    {
        const auto& F = Farms[Side];
        switch (A)
        {
        case Action::Chicken: return 20;
        case Action::Coop: return 65 + (F.Coops - 1) * 30;
        case Action::Fence: return 45 + F.Fence * 35;
        case Action::Boots: return 55 + F.Boots * 40;
        case Action::Raid: return 30;
        }
        return 0;
    }
    bool Available(int Side, Action A) const
    {
        if (Finished || Side < 0 || Side > 1) return false;
        const auto& F = Farms[Side];
        if (F.Coins < Cost(Side, A)) return false;
        switch (A)
        {
        case Action::Chicken: return F.Chickens < Capacity(Side);
        case Action::Coop: return F.Coops < 4;
        case Action::Fence: return F.Fence < 3;
        case Action::Boots: return F.Boots < 3;
        case Action::Raid: return F.Cooldown <= 0 && F.Chickens < Capacity(Side) && Farms[1-Side].Chickens > 0;
        }
        return false;
    }
    bool Buy(int Side, Action A)
    {
        if (!Available(Side, A)) return false;
        auto& F = Farms[Side];
        F.Coins -= Cost(Side, A);
        switch (A)
        {
        case Action::Chicken: ++F.Chickens; break;
        case Action::Coop: ++F.Coops; break;
        case Action::Fence: ++F.Fence; break;
        case Action::Boots: ++F.Boots; break;
        case Action::Raid:
            F.Cooldown = 14.0;
            Raids.push_back({NextId++, Side, 0, 0.0, 9.0 - F.Boots * 1.2, 4 + F.Boots, false});
            break;
        }
        return true;
    }
    bool Steal()
    {
        if (Carried > 0 || !Available(0, Action::Raid)) return false;
        const int Loot = std::min({Farms[1].Chickens, Capacity(0)-Farms[0].Chickens, std::max(0, 4+Farms[0].Boots-Farms[1].Fence*2)});
        if (Loot == 0) { Notice = "Their fence stopped you. Upgrade raider boots."; return false; }
        Farms[0].Coins -= Cost(0, Action::Raid);
        Farms[0].Cooldown = 14.0;
        Farms[1].Chickens -= Loot;
        Carried = Loot;
        Notice = "Chickens grabbed! Return to your farm to bank them.";
        return true;
    }
    int Deliver()
    {
        if (Finished || Carried == 0) return 0;
        const int Delivered = std::min(Carried, std::max(0, Capacity(0)-Farms[0].Chickens));
        Farms[0].Chickens += Delivered;
        Farms[1].Chickens += Carried - Delivered;
        Carried = 0;
        Notice = "Stolen chickens delivered to your farm!";
        return Delivered;
    }
    void Tick(double Delta, bool RunAI = true)
    {
        if (Finished || !std::isfinite(Delta) || Delta <= 0) return;
        const double Step = std::min(Delta, Remaining);
        Remaining = std::max(0.0, Remaining-Step);
        for (auto& F : Farms)
        {
            F.Coins += F.Chickens * 0.65 * Step;
            F.Cooldown = std::max(0.0, F.Cooldown-Step);
        }
        for (int I = static_cast<int>(Raids.size())-1; I >= 0; --I)
        {
            auto& R = Raids[I];
            R.Elapsed += Step;
            if (R.Elapsed < R.Duration) continue;
            if (!R.Returning)
            {
                auto& Enemy = Farms[1-R.Side];
                R.Loot = std::min(Enemy.Chickens, std::max(0, R.Power-Enemy.Fence*2));
                Enemy.Chickens -= R.Loot;
                R.Elapsed = 0;
                R.Returning = true;
                Notice = R.Side == 1 ? "Enemy raider stole chickens. Upgrade your fence!" : "Your raider is coming home.";
            }
            else
            {
                const int Count = std::min(R.Loot, std::max(0, Capacity(R.Side)-Farms[R.Side].Chickens));
                Farms[R.Side].Chickens += Count;
                Farms[1-R.Side].Chickens += R.Loot-Count;
                Raids.erase(Raids.begin()+I);
            }
        }
        if (RunAI && Remaining > 0)
        {
            AITimer -= Step;
            if (AITimer <= 0) { AITimer = 4.5; AITurn(); }
        }
        if (Remaining < 0.001)
        {
            Remaining = 0;
            for (const auto& R : Raids) if (R.Returning) Farms[1-R.Side].Chickens += R.Loot;
            Raids.clear();
            Farms[1].Chickens += Carried;
            Carried = 0;
            Finished = true;
            Winner = Farms[0].Chickens == Farms[1].Chickens ? -1 : (Farms[0].Chickens > Farms[1].Chickens ? 0 : 1);
            Notice = Winner == -1 ? "Draw! Press R to play again." : (Winner == 0 ? "Your farm wins! Press R to play again." : "Rival farm wins. Press R to play again.");
        }
    }
private:
    int NextId = 0;
    double AITimer = 5.0;
    void AITurn()
    {
        auto& F = Farms[1];
        if (Carried > 0 && F.Fence < 2 && Buy(1, Action::Fence)) return;
        if (F.Chickens >= Capacity(1)-2 && Buy(1, Action::Coop)) return;
        if (Farms[0].Fence < 2 && Buy(1, Action::Raid)) return;
        if (Buy(1, Action::Chicken)) return;
        if (Buy(1, Action::Boots)) return;
        Buy(1, Action::Fence);
    }
};
}
