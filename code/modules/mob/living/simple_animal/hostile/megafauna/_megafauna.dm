/mob/living/simple_animal/hostile/megafauna
	name = "boss of this gym"
	desc = "Attack the weak point for massive damage."
	health = 1000
	maxHealth = 1000
	combat_mode = TRUE
	sentience_type = SENTIENCE_BOSS
	environment_smash = ENVIRONMENT_SMASH_RWALLS
	mob_biotypes = MOB_ORGANIC|MOB_SPECIAL
	obj_damage = 400
	light_range = 3
	faction = list(FACTION_MINING, FACTION_BOSS)
	weather_immunities = list(TRAIT_LAVA_IMMUNE,TRAIT_ASHSTORM_IMMUNE)
	robust_searching = TRUE
	ranged_ignores_vision = TRUE
	stat_attack = DEAD
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_plas" = 0, "max_plas" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	damage_coeff = list(BRUTE = 1, BURN = 0.5, TOX = 1, STAMINA = 0, OXY = 1)
	bodytemp_cold_damage_limit = -1
	bodytemp_heat_damage_limit = INFINITY
	vision_range = 5
	aggro_vision_range = 18
	move_force = MOVE_FORCE_OVERPOWERING
	move_resist = MOVE_FORCE_OVERPOWERING
	pull_force = MOVE_FORCE_OVERPOWERING
	mob_size = MOB_SIZE_HUGE
	layer = LARGE_MOB_LAYER //Looks weird with them slipping under mineral walls and cameras and shit otherwise
	mouse_opacity = MOUSE_OPACITY_OPAQUE // Easier to click on in melee, they're giant targets anyway
	flags_1 = PREVENT_CONTENTS_EXPLOSION_1
	/// Crusher loot dropped when the megafauna is killed with a crusher
	var/list/crusher_loot
	/// Achievement given to surrounding players when the megafauna is killed
	var/achievement_type
	/// Crusher achievement given to players when megafauna is killed
	var/crusher_achievement_type
	/// Score given to players when megafauna is killed
	var/score_achievement_type
	/// If the megafauna was actually killed (not just dying, then transforming into another type)
	var/elimination = 0
	/// Modifies attacks when at lower health
	var/anger_modifier = 0
	/// Name for the GPS signal of the megafauna
	var/gps_name = null
	/// Next time the megafauna can use a melee attack
	var/recovery_time = 0
	/// If this is a megafauna that is real (has achievements, gps signal)
	var/true_spawn = TRUE
	/// The chosen attack by the megafauna
	var/chosen_attack = 1
	/// Attack actions, sets chosen_attack to the number in the action
	var/list/attack_action_types = list()

/mob/living/simple_animal/hostile/megafauna/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/seethrough_mob)
	AddElement(/datum/element/simple_flying)
	if(gps_name && true_spawn)
		AddComponent(/datum/component/gps, gps_name)
	ADD_TRAIT(src, TRAIT_SPACEWALK, INNATE_TRAIT)
	add_traits(list(TRAIT_NO_TELEPORT, TRAIT_MARTIAL_ARTS_IMMUNE), MEGAFAUNA_TRAIT)
	grant_actions_by_list(attack_action_types)

/mob/living/simple_animal/hostile/megafauna/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change = TRUE)
	//Safety check
	if(!loc)
		return ..()
	return ..()

/mob/living/simple_animal/hostile/megafauna/death(gibbed, list/force_grant)
	if(gibbed) // in case they've been force dusted
		return ..()

	if(health > 0) // prevents instakills
		return
	var/datum/status_effect/crusher_damage/crusher_dmg = has_status_effect(/datum/status_effect/crusher_damage)
	///Whether we killed the megafauna with primarily crusher damage or not
	var/crusher_kill = FALSE
	if(crusher_dmg && crusher_dmg.total_damage >= maxHealth * 0.6)
		crusher_kill = TRUE
		if(crusher_loot) // spawn crusher loot, if any
			spawn_crusher_loot()
	if(true_spawn && !(flags_1 & ADMIN_SPAWNED_1))
		var/tab = "megafauna_kills"
		if(crusher_kill)
			tab = "megafauna_kills_crusher"
		if(!elimination) //used so the achievment only occurs for the last legion to die.
			grant_achievement(achievement_type, score_achievement_type, crusher_kill, force_grant)
			SSblackbox.record_feedback("tally", tab, 1, "[initial(name)]")
	return ..()

/// Spawns crusher loot instead of normal loot
/mob/living/simple_animal/hostile/megafauna/proc/spawn_crusher_loot()
	loot = crusher_loot

/mob/living/simple_animal/hostile/megafauna/gib()
	if(health > 0)
		return

	return ..()

/mob/living/simple_animal/hostile/megafauna/singularity_act()
	set_health(0)
	return ..()

/mob/living/simple_animal/hostile/megafauna/dust(just_ash, drop_items, force)
	if(!force && health > 0)
		return

	crusher_loot.Cut()
	loot.Cut()

	return ..()

/mob/living/simple_animal/hostile/megafauna/AttackingTarget(atom/attacked_target)
	if(recovery_time >= world.time)
		return
	. = ..()
	if(. && isliving(target))
		var/mob/living/L = target
		if(L.stat != DEAD)
			if(!client && ranged && ranged_cooldown <= world.time)
				OpenFire()

			if(L.health <= HEALTH_THRESHOLD_LIKELY_CRIT && HAS_TRAIT(L, TRAIT_NODEATH)) //Nope, it still kills yall
				devour(L)
		else
			devour(L)

/// Devours a target and restores health to the megafauna
/mob/living/simple_animal/hostile/megafauna/proc/devour(mob/living/L)
	if(!L || L.has_status_effect(/datum/status_effect/gutted))
		return FALSE
	celebrate_kill(L)
	if(!is_station_level(z) || client) //NPC monsters won't heal while on station
		adjustBruteLoss(-L.maxHealth/2)
	L.investigate_log("has been devoured by [src].", INVESTIGATE_DEATHS)
	var/mob/living/carbon/carbonTarget = L
	if(istype(carbonTarget))
		qdel(L.get_organ_slot(ORGAN_SLOT_LUNGS))
		qdel(L.get_organ_slot(ORGAN_SLOT_HEART))
		qdel(L.get_organ_slot(ORGAN_SLOT_LIVER))
	L.adjustBruteLoss(500)
	L.death(null, "being gutted by [src]") //make sure they die
	L.apply_status_effect(/datum/status_effect/gutted)
	LoseTarget()
	return TRUE

/mob/living/simple_animal/hostile/megafauna/proc/celebrate_kill(mob/living/L)
	visible_message(
		span_danger("[src] disembowels [L]!"),
		span_userdanger("You feast on [L]'s organs, restoring your health!"))



/mob/living/simple_animal/hostile/megafauna/CanAttack(atom/the_target)
	. = ..()
	if (!.)
		return FALSE
	if(!isliving(the_target))
		return TRUE
	var/mob/living/living_target = the_target
	return !living_target.has_status_effect(/datum/status_effect/gutted)


/mob/living/simple_animal/hostile/megafauna/ex_act(severity, target)
	switch (severity)
		if (EXPLODE_DEVASTATE)
			adjustBruteLoss(250)

		if (EXPLODE_HEAVY)
			adjustBruteLoss(100)

		if (EXPLODE_LIGHT)
			adjustBruteLoss(50)

	return TRUE

/// Sets/adds the next time the megafauna can use a melee or ranged attack, in deciseconds. It is a list to allow using named args. Use the ignore_staggered var if youre setting the cooldown to ranged_cooldown_time.
/mob/living/simple_animal/hostile/megafauna/proc/update_cooldowns(list/cooldown_updates, ignore_staggered = FALSE)
	if(!ignore_staggered && has_status_effect(/datum/status_effect/stagger))
		for(var/update in cooldown_updates)
			cooldown_updates[update] *= 2
	if(cooldown_updates[COOLDOWN_UPDATE_SET_MELEE])
		recovery_time = world.time + cooldown_updates[COOLDOWN_UPDATE_SET_MELEE]
	if(cooldown_updates[COOLDOWN_UPDATE_ADD_MELEE])
		recovery_time += cooldown_updates[COOLDOWN_UPDATE_ADD_MELEE]
	if(cooldown_updates[COOLDOWN_UPDATE_SET_RANGED])
		ranged_cooldown = world.time + cooldown_updates[COOLDOWN_UPDATE_SET_RANGED]
	if(cooldown_updates[COOLDOWN_UPDATE_ADD_RANGED])
		ranged_cooldown += cooldown_updates[COOLDOWN_UPDATE_ADD_RANGED]

/// Grants medals and achievements to surrounding players
/mob/living/simple_animal/hostile/megafauna/proc/grant_achievement(medaltype, scoretype, crusher_kill, list/grant_achievement = list())
	if(!achievement_type || (flags_1 & ADMIN_SPAWNED_1) || !SSachievements.achievements_enabled) //Don't award medals if the medal type isn't set
		return FALSE
	if(!grant_achievement.len)
		for(var/mob/living/L in view(7,src))
			grant_achievement += L
	for(var/mob/living/L in grant_achievement)
		if(L.stat || !L.client)
			continue
		L.add_mob_memory(/datum/memory/megafauna_slayer, antagonist = src)
		L.client.give_award(/datum/award/achievement/boss/boss_killer, L)
		L.client.give_award(achievement_type, L)
		if(crusher_kill && istype(L.get_active_held_item(), /obj/item/kinetic_crusher))
			L.client.give_award(crusher_achievement_type, L)
		L.client.give_award(/datum/award/score/boss_score, L) //Score progression for bosses killed in general
		L.client.give_award(score_achievement_type, L) //Score progression for specific boss killed
	return TRUE

/datum/action/innate/megafauna_attack
	name = "Megafauna Attack"
	button_icon = 'icons/mob/actions/actions_animal.dmi'
	button_icon_state = ""
	var/chosen_message
	var/chosen_attack_num = 0

/datum/action/innate/megafauna_attack/Grant(mob/living/L)
	if(!ismegafauna(L))
		return FALSE
	return ..()

/datum/action/innate/megafauna_attack/Activate()
	var/mob/living/simple_animal/hostile/megafauna/fauna = owner
	fauna.chosen_attack = chosen_attack_num
	to_chat(fauna, chosen_message)
