/obj/item/clothing/head/hooded/mu_arbiter
	name = "arbiter hood"
	desc = "A hood given to Arbiters. Inscribed with magical runes."
	icon = 'icons/obj/clothing/head/spacehelm.dmi'
	worn_icon = 'icons/mob/clothing/head/spacehelm.dmi'
	icon_state = "spaceold"
	inhand_icon_state = "space_helmet"


/obj/item/clothing/suit/hooded/mu_arbiter
	name = "arbiter suit"
	desc = "A suit for arbiters of Finster. Inscribed with magical runes. We're going Type 3 on yo ass."
	icon = 'icons/obj/clothing/suits/wintercoat.dmi'
	icon_state = "coatwinter"
	worn_icon = 'icons/mob/clothing/suits/wintercoat.dmi'
	inhand_icon_state = "coatwinter"
	hoodtype = /obj/item/clothing/head/hooded/mu_arbiter
	min_cold_protection_temperature = SPACE_SUIT_MIN_TEMP_PROTECT
	armor_type = /datum/armor/mu_arbiter

	///Magic shields! They're pretty much just a clothing version of blade shields, even using some of the same code.
	///Maximum amount of magic shields
	var/magic_shield_max = 4
	///Recharge time for magic shields
	var/magic_shield_recharge_time = 5 SECONDS
	///The orbit radius of the shields
	var/shield_orbit_radius = 20
	///A list containing the shield effects
	var/list/obj/effect/floating_blade/mu_arbiter_shield/shields = list()

/datum/armor/mu_arbiter
	melee = 75
	bullet = 75
	laser = 75
	energy = 75
	bio = 100
	fire = 100
	acid = 100
	bomb = 100
	wound = 100

/datum/armor/mu_arbiter/shields_disabled
	melee = 50
	bullet = 50
	laser = 50
	energy = 50
	bomb = 90
	wound = 50

/obj/effect/floating_blade/mu_arbiter_shield
	name = "magic shield"
	icon = 'icons/obj/kitchen.dmi'
	icon_state = "knife"
	glow_color = "#bb55ff"

/obj/item/clothing/suit/hooded/mu_arbiter/equipped(mob/living/user, slot)
	. = ..()
	if(slot & ITEM_SLOT_OCLOTHING)
		RegisterSignal(user, COMSIG_HUMAN_CHECK_SHIELDS, PROC_REF(on_shield_react))
		for(var/shield_num in 1 to magic_shield_max)
			var/time_until_created = shield_num * magic_shield_recharge_time
			addtimer(CALLBACK(src, PROC_REF(create_shield), user), time_until_created)

/obj/item/clothing/suit/hooded/mu_arbiter/dropped(mob/living/user)
	QDEL_LIST(shields)
	. = ..()
	UnregisterSignal(user, COMSIG_HUMAN_CHECK_SHIELDS)

/obj/item/clothing/suit/hooded/mu_arbiter/pickup(mob/living/user)
	. = ..()
	if(!HAS_TRAIT(user, TRAIT_MU_ARBITER))
		to_chat(user, "You can't pick up the suit, it's too heavy!")
		user.dropItemToGround(src, TRUE)
		return

/obj/item/clothing/suit/hooded/mu_arbiter/proc/create_shield(mob/user)
	if(QDELETED(src) || QDELETED(user))
		return
	if(length(shields) >= magic_shield_max)
		return

	var/obj/effect/floating_blade/mu_arbiter_shield/shield = new(get_turf(user))
	shields += shield
	shield.orbit(user, shield_orbit_radius)
	RegisterSignal(shield, COMSIG_PARENT_QDELETING, PROC_REF(remove_shield))
	playsound(get_turf(user), 'sound/items/unsheath.ogg', 33, TRUE)

/obj/item/clothing/suit/hooded/mu_arbiter/proc/remove_shield(obj/effect/floating_blade/to_remove)
	SIGNAL_HANDLER

	if(!(to_remove in shields))
		CRASH("[type] called remove_shield() with a shield that was not in its shields list.")

	if(!ismob(loc)) //if this returns true, RUN
		CRASH("[type] called remove_shield() without a mob. Frankly, I'm impressed.")
	var/mob/user = loc
	to_remove.stop_orbit(user.orbiters)
	shields -= to_remove

	return TRUE

//Unlike the original, we're not using a trait to check if we're being shielded, if multiple shots hit at once, all the shields break.
/obj/item/clothing/suit/hooded/mu_arbiter/proc/on_shield_react(
	mob/living/carbon/human/source,
	atom/movable/hitby,
	damage = 0,
	attack_text = "the attack",
	attack_type = MELEE_ATTACK,
	armour_penetration = 0,
	damage_type = BRUTE,
)
	SIGNAL_HANDLER

	if(!length(shields))
		return

	var/obj/effect/floating_blade/to_remove = shields[1]

	playsound(get_turf(source), 'sound/weapons/parry.ogg', 100, TRUE)
	source.visible_message(
		span_warning("[to_remove] orbiting [source] snaps in front of [attack_text], blocking it before vanishing!"),
		span_warning("[to_remove] orbiting you snaps in front of [attack_text], blocking it before vanishing!"),
		span_hear("You hear a clink."),
	)

	qdel(to_remove)

	addtimer(CALLBACK(src, PROC_REF(create_shield), source), magic_shield_recharge_time)
	return SHIELD_BLOCK
