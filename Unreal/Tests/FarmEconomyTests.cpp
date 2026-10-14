#include "../Source/ChickenValley/FarmEconomy.h"
#include <cassert>
#include <iostream>
#include <limits>

int main()
{
    using namespace Valley;
    Match M;
    M.Tick(1, false);
    assert(std::abs(M.Farms[0].Coins-75.2) < 0.0001);
    assert(M.Buy(0, Action::Chicken) && M.Farms[0].Chickens == 9);
    assert(!M.Buy(-1, Action::Chicken));
    M.Farms[0].Coins = 0;
    assert(!M.Buy(0, Action::Chicken));
    M.Farms[0].Coins = 500;
    M.Farms[0].Chickens = 12;
    assert(!M.Buy(0, Action::Chicken));
    assert(M.Buy(0, Action::Coop) && M.Capacity(0) == 24);
    M = Match();
    assert(M.Steal() && M.Carried == 4 && M.Farms[1].Chickens == 4);
    assert(M.Farms[0].Chickens == 8 && !M.Steal());
    assert(M.Deliver() == 4 && M.Farms[0].Chickens == 12 && M.Carried == 0);
    M = Match();
    M.Farms[1].Fence = 3;
    assert(!M.Steal() && M.Farms[0].Coins == 70);
    M.Farms[0].Boots = 3;
    assert(M.Steal() && M.Carried == 1);
    M = Match();
    assert(M.Steal());
    M.Remaining = 1;
    M.Tick(1, false);
    assert(M.Finished && M.Winner == -1 && M.Carried == 0 && M.Farms[1].Chickens == 8);
    assert(!M.Buy(0, Action::Chicken) && !M.Steal());
    M = Match();
    assert(M.Buy(1, Action::Raid));
    M.Tick(9, false);
    assert(M.Farms[0].Chickens == 4 && M.Farms[1].Chickens == 8);
    M.Tick(9, false);
    assert(M.Farms[1].Chickens == 12 && M.Raids.empty());
    M = Match();
    M.Tick(std::numeric_limits<double>::quiet_NaN());
    M.Tick(-5);
    assert(M.Remaining == 240);
    for (int I=0; I<2401; ++I)
    {
        M.Tick(0.1);
        for (const auto& F : M.Farms) assert(F.Coins >= 0 && F.Chickens >= 0);
    }
    assert(M.Finished && M.Raids.empty() && M.Farms[1].Chickens > 8);
    std::cout << "Unreal-port economy tests: PASS\n";
}
