extends SceneTree

var failures := 0

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func _init() -> void:
	var g := FarmMatch.new()
	g.tick(1.0, false)
	check(is_equal_approx(g.farms[0].coins, 75.2), "Chicken income accrues in real time")
	check(g.buy(0, "chicken"), "Affordable chicken can be bought")
	check(g.farms[0].chickens == 9, "Purchase increases flock")
	g.farms[0].coins = 500
	g.farms[0].chickens = 12
	check(not g.buy(0, "chicken"), "Capacity prevents purchase")
	check(g.buy(0, "coop") and g.capacity(0) == 24, "Coop expands capacity")
	check(not g.buy(0, "invalid"), "Unknown action rejected")
	g = FarmMatch.new()
	check(g.buy(0, "raid"), "Raid launches")
	check(not g.buy(0, "raid"), "Raid cooldown prevents repeated launch")
	g.tick(9.0, false)
	check(g.farms[1].chickens == 4 and g.farms[0].chickens == 8, "Birds stolen at arrival, not launch")
	g.tick(9.0, false)
	check(g.farms[0].chickens == 12 and g.raids.is_empty(), "Stolen chickens delivered on return")
	g = FarmMatch.new()
	g.farms[1].fence = 3
	g.buy(0, "raid")
	g.tick(9.0, false)
	check(g.raids[0].loot == 0, "Strong fence stops base raider")
	g = FarmMatch.new()
	g.buy(0, "raid")
	g.tick(9.0, false)
	g.farms[0].chickens = 11
	g.tick(9.0, false)
	check(g.farms[0].chickens == 12 and g.farms[1].chickens == 7, "Excess loot returns to rival")
	g = FarmMatch.new()
	g.buy(0, "raid")
	g.tick(9.0, false)
	g.remaining = 1
	g.tick(1.0, false)
	check(g.finished and g.winner == -1, "Undelivered birds return before final score")
	check(not g.buy(0, "chicken"), "Finished matches reject actions")
	g = FarmMatch.new()
	for i in 2400:
		g.tick(0.1)
		for side in 2:
			check(g.farms[side].coins >= 0 and g.farms[side].chickens >= 0, "AI match resources stay nonnegative")
	check(g.finished and g.raids.is_empty(), "Full AI simulation finishes")
	check(g.farms[1].chickens > 8, "AI builds its farm")
	print("Farm match tests: %s" % ("PASS" if failures == 0 else "%d FAILURES" % failures))
	quit(0 if failures == 0 else 1)
