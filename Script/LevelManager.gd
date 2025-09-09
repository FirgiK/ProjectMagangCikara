extends Node

var player_stats: StatResource = null

func gain_exp(amount: int):
	if player_stats == null:
		return

	player_stats.current_exp += amount
	
	while player_stats.current_exp >= player_stats.exp_to_next_level:
		level_up()

func level_up():
	player_stats.level += 1
	player_stats.current_exp -= player_stats.exp_to_next_level
	player_stats.exp_to_next_level = int(player_stats.exp_to_next_level * 1.5)
	
	var hp_base_gain = 40
	var atk_base_gain = 2
	var def_base_gain = 2
	var agi_base_gain = 2
	
	player_stats.hp += hp_base_gain
	player_stats.atk += atk_base_gain
	player_stats.def += def_base_gain
	player_stats.agi += agi_base_gain
	
	var stats_pool = ["HP", "ATK", "DEF", "AGI"]
	var chosen_stat = stats_pool.pick_random()
	var bonus_value = randi_range(3, 6)
	
	print("LEVEL UP! Sekarang Level ", player_stats.level)
	print("Base Stat Gains -> HP: +%d, ATK: +%d, DEF: +%d, AGI: +%d" % [hp_base_gain, atk_base_gain, def_base_gain, agi_base_gain])

	match chosen_stat:
		"HP":
			var scaled_hp_bonus = bonus_value * 10
			player_stats.hp += scaled_hp_bonus
			print("BONUS: +%d HP!" % scaled_hp_bonus)
		"ATK":
			player_stats.atk += bonus_value
			print("BONUS: +%d ATK!" % bonus_value)
		"DEF":
			player_stats.def += bonus_value
			print("BONUS: +%d DEF!" % bonus_value)
		"AGI":
			player_stats.agi += bonus_value
			print("BONUS: +%d AGI!" % bonus_value)
