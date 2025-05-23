
/////BURN FIXING SURGERIES//////

///// Debride burnt flesh
/datum/surgery/debride
	name = "Debride infected flesh"
	surgery_flags = SURGERY_REQUIRE_RESTING | SURGERY_REQUIRE_LIMB | SURGERY_REQUIRES_REAL_LIMB
	targetable_wound = /datum/wound/flesh
	possible_locs = list(
		BODY_ZONE_R_ARM,
		BODY_ZONE_L_ARM,
		BODY_ZONE_R_LEG,
		BODY_ZONE_L_LEG,
		BODY_ZONE_CHEST,
		BODY_ZONE_HEAD,
	)
	steps = list(
		/datum/surgery_step/debride,
		/datum/surgery_step/dress,
	)

/datum/surgery/debride/is_valid_wound(datum/wound/flesh/wound)
	return ..() && wound.infestation > 0

//SURGERY STEPS

///// Debride
/datum/surgery_step/debride
	name = "excise infection (hemostat)"
	implements = list(
		TOOL_HEMOSTAT = 100,
		TOOL_SCALPEL = 85,
		TOOL_SAW = 60,
		TOOL_WIRECUTTER = 40)
	time = 30
	repeatable = TRUE
	preop_sound = 'sound/surgery/scalpel1.ogg'
	success_sound = 'sound/surgery/retractor2.ogg'
	failure_sound = 'sound/surgery/organ1.ogg'
	/// How much sanitization is added per step
	var/sanitization_added = 0.5
	/// How much infestation is removed per step (positive number)
	var/infestation_removed = 4

/// To give the surgeon a heads up how much work they have ahead of them
/datum/surgery_step/debride/proc/get_progress(mob/user, mob/living/carbon/target, datum/wound/flesh/burn_wound)
	if(!burn_wound?.infestation || !infestation_removed)
		return
	var/estimated_remaining_steps = burn_wound.infestation / infestation_removed
	var/progress_text

	switch(estimated_remaining_steps)
		if(-INFINITY to 1)
			return
		if(1 to 2)
			progress_text = ", preparing to remove the last remaining bits of infection"
		if(2 to 4)
			progress_text = ", steadily narrowing the remaining bits of infection"
		if(5 to INFINITY)
			progress_text = ", though there's still quite a lot to excise"

	return progress_text

/datum/surgery_step/debride/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	if(surgery.operated_wound)
		var/datum/wound/flesh/burn_wound = surgery.operated_wound
		if(burn_wound.infestation <= 0)
			to_chat(user, span_notice("[target]'s [parse_zone(target_zone)] has no infected flesh to remove!"))
			surgery.status++
			repeatable = FALSE
			return
		display_results(
			user,
			target,
			span_notice("You begin to excise infected flesh from [target]'s [parse_zone(target_zone)]..."),
			span_notice("[user] begins to excise infected flesh from [target]'s [parse_zone(target_zone)] with [tool]."),
			span_notice("[user] begins to excise infected flesh from [target]'s [parse_zone(target_zone)]."),
		)
		display_pain(
			target = target,
			target_zone = target_zone,
			pain_message = "The infection in your [parse_zone(target_zone)] stings like hell! It feels like you're being stabbed!",
			pain_amount = SURGERY_PAIN_LOW,
			pain_type = BURN,
		)
	else
		user.visible_message(span_notice("[user] looks for [target]'s [parse_zone(target_zone)]."), span_notice("You look for [target]'s [parse_zone(target_zone)]..."))

/datum/surgery_step/debride/success(mob/living/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery, default_display_results = FALSE)
	var/datum/wound/flesh/burn_wound = surgery.operated_wound
	if(burn_wound)
		var/progress_text = get_progress(user, target, burn_wound)
		display_results(
			user,
			target,
			span_notice("You successfully excise some of the infected flesh from [target]'s [parse_zone(target_zone)][progress_text]."),
			span_notice("[user] successfully excises some of the infected flesh from [target]'s [parse_zone(target_zone)] with [tool]!"),
			span_notice("[user] successfully excises some of the infected flesh from  [target]'s [parse_zone(target_zone)]!"),
		)
		log_combat(user, target, "excised infected flesh in", addition="COMBAT MODE: [uppertext(user.combat_mode)]")
		target.apply_damage(3, BRUTE, surgery.operated_bodypart, wound_bonus = CANT_WOUND, attacking_item = tool)
		burn_wound.infestation -= infestation_removed
		burn_wound.sanitization += sanitization_added
		if(burn_wound.infestation <= 0)
			repeatable = FALSE
	else
		to_chat(user, span_warning("[target] has no infected flesh there!"))
	return ..()

/datum/surgery_step/debride/failure(mob/user, mob/living/target, target_zone, obj/item/tool, datum/surgery/surgery, fail_prob = 0)
	..()
	display_results(
		user,
		target,
		span_notice("You carve away some of the healthy flesh from [target]'s [parse_zone(target_zone)]."),
		span_notice("[user] carves away some of the healthy flesh from [target]'s [parse_zone(target_zone)] with [tool]!"),
		span_notice("[user] carves away some of the healthy flesh from  [target]'s [parse_zone(target_zone)]!"),
	)
	target.apply_damage(rand(4, 8), BRUTE, surgery.operated_bodypart, wound_bonus = 10, sharpness = SHARP_EDGED, attacking_item = tool)

/datum/surgery_step/debride/initiate(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery, try_to_fail = FALSE)
	if(!..())
		return
	var/datum/wound/flesh/burn/burn_wound = surgery.operated_wound
	while(burn_wound && burn_wound.infestation > 0.25)
		if(!..())
			break

///// Dressing burns
/datum/surgery_step/dress
	name = "bandage flesh (gauze/tape)"
	implements = list(
		/obj/item/stack/medical/gauze = 100,
		/obj/item/stack/sticky_tape/surgical = 100)
	time = 40
	/// How much sanitization is added
	var/sanitization_added = 3
	/// How much flesh healing is added
	var/flesh_healing_added = 5


/datum/surgery_step/dress/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	var/datum/wound/flesh/burn_wound = surgery.operated_wound
	if(burn_wound)
		display_results(
			user,
			target,
			span_notice("You begin to dress the flesh on [target]'s [parse_zone(target_zone)]..."),
			span_notice("[user] begins to dress the flesh on [target]'s [parse_zone(target_zone)] with [tool]."),
			span_notice("[user] begins to dress the flesh on [target]'s [parse_zone(target_zone)]."),
		)
		display_pain(
			target = target,
			target_zone = target_zone,
			pain_message = "The infection in your [parse_zone(target_zone)] stings like hell!",
		)
	else
		user.visible_message(span_notice("[user] looks for [target]'s [parse_zone(target_zone)]."), span_notice("You look for [target]'s [parse_zone(target_zone)]..."))

/datum/surgery_step/dress/success(mob/living/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery, default_display_results = FALSE)
	var/datum/wound/flesh/burn_wound = surgery.operated_wound
	if(burn_wound)
		display_results(
			user,
			target,
			span_notice("You successfully wrap [target]'s [parse_zone(target_zone)] with [tool]."),
			span_notice("[user] successfully wraps [target]'s [parse_zone(target_zone)] with [tool]!"),
			span_notice("[user] successfully wraps [target]'s [parse_zone(target_zone)]!"),
		)
		log_combat(user, target, "dressed flesh in", addition="COMBAT MODE: [uppertext(user.combat_mode)]")
		burn_wound.sanitization += sanitization_added
		burn_wound.flesh_healing += flesh_healing_added
		var/obj/item/bodypart/the_part = target.get_bodypart(target_zone)
		the_part.apply_gauze(tool)
	else
		to_chat(user, span_warning("[target] has no flesh wounds there!"))
	return ..()

/datum/surgery_step/dress/failure(mob/user, mob/living/target, target_zone, obj/item/tool, datum/surgery/surgery, fail_prob = 0)
	..()
	if(isstack(tool))
		var/obj/item/stack/used_stack = tool
		used_stack.use(1)
