// 7.62x38mmR (Nagant Revolver)

/obj/projectile/bullet/n762
	name = "7.62x38mmR bullet"
	generic_name = "bullet"
	damage = 60

// .50AE (Desert Eagle)

/obj/projectile/bullet/a50ae
	name = ".50AE bullet"
	generic_name = "bullet"
	damage = 60

// .38 (Detective's Gun)

/obj/projectile/bullet/c38
	name = ".38 bullet"
	generic_name = "bullet"
	damage = 25
	ricochets_max = 2
	ricochet_chance = 50
	ricochet_auto_aim_angle = 10
	ricochet_auto_aim_range = 3
	wound_bonus = -20
	bare_wound_bonus = 10
	embed_type = /datum/embed_data/bullet/c38
	embed_falloff_tile = 4

/datum/embed_data/bullet/c38
	embed_chance = 33
	fall_chance = 0.0020
	jostle_chance = 2
	pain_stam_pct = 0.4
	pain_mult = 3
	jostle_pain_mult = 5
	rip_time = 8 SECONDS

/obj/projectile/bullet/c38/match
	name = ".38 Match bullet"
	ricochets_max = 4
	ricochet_chance = 100
	ricochet_auto_aim_angle = 40
	ricochet_auto_aim_range = 5
	ricochet_incidence_leeway = 50
	ricochet_decay_chance = 1
	ricochet_decay_damage = 1

/obj/projectile/bullet/c38/match/bouncy
	name = ".38 Rubber bullet"
	damage = 10
	pain = 30
	weak_against_armour = TRUE
	ricochets_max = 6
	ricochet_incidence_leeway = 0
	ricochet_chance = 130
	ricochet_decay_damage = 0.8
	shrapnel_type = null
	sharpness = NONE
	embed_type = null

// premium .38 ammo from cargo, weak against armor, lower base damage, but excellent at embedding and causing slice wounds at close range
/obj/projectile/bullet/c38/dumdum
	name = ".38 DumDum bullet"
	damage = 15
	weak_against_armour = TRUE
	ricochets_max = 0
	sharpness = SHARP_EDGED
	wound_bonus = 20
	bare_wound_bonus = 20
	embed_type = /datum/embed_data/bullet/c38/dumdum
	wound_falloff_tile = -5
	embed_falloff_tile = -15

/datum/embed_data/bullet/c38/dumdum
	embed_chance = 75
	fall_chance = 0.0030
	jostle_chance = 4
	pain_mult = 5
	jostle_pain_mult = 6
	rip_time = 5 SECONDS

/obj/projectile/bullet/c38/trac
	name = ".38 TRAC bullet"
	damage = 10
	ricochets_max = 0

/obj/projectile/bullet/c38/trac/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	var/mob/living/carbon/M = target
	if(!istype(M))
		return
	var/obj/item/implant/tracking/c38/imp
	for(var/obj/item/implant/tracking/c38/TI in M.implants) //checks if the target already contains a tracking implant
		imp = TI
		return
	if(!imp)
		imp = new /obj/item/implant/tracking/c38(M)
		imp.implant(M)

/obj/projectile/bullet/c38/hotshot //similar to incendiary bullets, but do not leave a flaming trail
	name = ".38 Hot Shot bullet"
	damage = 20
	ricochets_max = 0

/obj/projectile/bullet/c38/hotshot/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	if(iscarbon(target))
		var/mob/living/carbon/M = target
		M.adjust_fire_stacks(6)
		M.ignite_mob()

/obj/projectile/bullet/c38/iceblox //see /obj/projectile/temp for the original code
	name = ".38 Iceblox bullet"
	damage = 20
	ricochets_max = 0
	/// How cold to chill the target down to
	var/temperature = -8 CELCIUS

/obj/projectile/bullet/c38/iceblox/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	if(isliving(target))
		var/mob/living/M = target
		// if we made 100% insulation make you immune, we would be useless
		var/final_change = temperature * (1 - (0.5 * M.get_insulation(M.body_temperature + temperature))) * ((100 - blocked) / 100)
		M.adjust_body_temperature(final_change)

// .357 (Syndie Revolver)

/obj/projectile/bullet/a357
	name = ".357 bullet"
	generic_name = "bullet"
	damage = 60
	wound_bonus = -30

/obj/projectile/bullet/a357/phasic
	name = ".357 phasic bullet"
	icon_state = "gaussphase"
	damage = 35
	armour_penetration = 100
	projectile_phasing =  PASSTABLE | PASSGLASS | PASSGRILLE | PASSCLOSEDTURF | PASSMACHINE | PASSSTRUCTURE | PASSDOORS

/obj/projectile/bullet/a357/heartseeker
	name = ".357 heartseeker bullet"
	icon_state = "gauss"
	damage = 50
	homing = TRUE
	homing_turn_speed = 120

// admin only really, for ocelot memes
/obj/projectile/bullet/a357/match
	name = ".357 match bullet"
	ricochets_max = 5
	ricochet_chance = 140
	ricochet_auto_aim_angle = 50
	ricochet_auto_aim_range = 6
	ricochet_incidence_leeway = 80
	ricochet_decay_chance = 1
