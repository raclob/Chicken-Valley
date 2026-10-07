class_name FarmMatch
extends RefCounted

const MATCH_SECONDS := 240.0
const RAID_TIME := 9.0
var farms: Array[Dictionary] = []
var raids: Array[Dictionary] = []
var remaining := MATCH_SECONDS
var ai_timer := 5.0
var finished := false
var winner := -1
var notice := "Build your flock. Raid your rival. Most chickens after 4 minutes wins."
var next_id := 0

func _init() -> void:
	for i in 2:
		farms.append({"coins": 70.0, "chickens": 8, "coops": 1, "fence": 0, "boots": 0, "cooldown": 0.0})

func cost(side: int, action: String) -> int:
	var f := farms[side]
	match action:
		"chicken": return 20
		"coop": return 65 + (f.coops - 1) * 30
		"fence": return 45 + f.fence * 35
		"boots": return 55 + f.boots * 40
		"raid": return 30
	return 0

func capacity(side: int) -> int:
	return farms[side].coops * 12

func available(side: int, action: String) -> bool:
	if finished or side < 0 or side > 1:
		return false
	var f := farms[side]
	if f.coins < cost(side, action): return false
	match action:
		"chicken": return f.chickens < capacity(side)
		"coop": return f.coops < 4
		"fence": return f.fence < 3
		"boots": return f.boots < 3
		"raid": return f.cooldown <= 0 and f.chickens < capacity(side) and farms[1-side].chickens > 0
	return false

func buy(side: int, action: String) -> bool:
	if not available(side, action): return false
	var f := farms[side]
	f.coins -= cost(side, action)
	match action:
		"chicken": f.chickens += 1
		"coop": f.coops += 1
		"fence": f.fence += 1
		"boots": f.boots += 1
		"raid":
			f.cooldown = 14.0
			raids.append({"id": next_id, "side": side, "elapsed": 0.0, "leg": 0, "loot": 0, "duration": RAID_TIME - f.boots * 1.2, "power": 4 + f.boots})
			next_id += 1
			if side == 0: notice = "Your raider is crossing the field!"
	return true

func tick(delta: float, run_ai: bool = true) -> void:
	if finished: return
	var step := minf(delta, remaining)
	remaining = maxf(0.0, remaining - step)
	for f in farms:
		f.coins += f.chickens * 0.65 * step
		f.cooldown = maxf(0.0, f.cooldown - step)
	for index in range(raids.size()-1, -1, -1):
		var r := raids[index]
		r.elapsed += step
		if r.elapsed < r.duration: continue
		if r.leg == 0:
			var enemy := farms[1-r.side]
			r.loot = mini(enemy.chickens, maxi(0, r.power - enemy.fence * 2))
			enemy.chickens -= r.loot
			r.leg = 1
			r.elapsed = 0.0
			notice = ("Your raider grabbed %d chickens!" if r.side == 0 else "Enemy raider took %d chickens! Upgrade your fence.") % r.loot
		else:
			var home := farms[r.side]
			var delivered := mini(r.loot, capacity(r.side) - home.chickens)
			home.chickens += delivered
			# Excess birds go back to their original owner; raids conserve birds.
			farms[1-r.side].chickens += r.loot - delivered
			raids.remove_at(index)
	if run_ai:
		ai_timer -= step
		if ai_timer <= 0:
			ai_timer = 4.5
			ai_turn()
	if remaining < 0.001:
		remaining = 0.0
		# Return birds still in transit before scoring.
		for r in raids:
			if r.leg == 1: farms[1-r.side].chickens += r.loot
		raids.clear()
		finished = true
		winner = -1 if farms[0].chickens == farms[1].chickens else (0 if farms[0].chickens > farms[1].chickens else 1)
		notice = "Draw!" if winner == -1 else ("Your farm wins!" if winner == 0 else "Rival farm wins!")

func ai_turn() -> void:
	var f := farms[1]
	var threatened := false
	for r in raids:
		if r.side == 0 and r.leg == 0: threatened = true
	if threatened and f.fence < 2 and buy(1, "fence"): return
	if f.chickens >= capacity(1) - 2 and buy(1, "coop"): return
	if farms[0].fence < 2 and buy(1, "raid"): return
	if f.chickens < capacity(1) and buy(1, "chicken"): return
	if f.boots < 3 and buy(1, "boots"): return
	buy(1, "fence")
