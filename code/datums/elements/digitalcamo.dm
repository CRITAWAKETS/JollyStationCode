/datum/element/digitalcamo
	element_flags = ELEMENT_DETACH_ON_HOST_DESTROY
	var/list/attached_mobs = list()

/datum/element/digitalcamo/New()
	. = ..()
	START_PROCESSING(SSdcs, src)

/datum/element/digitalcamo/Attach(datum/target)
	. = ..()
	if(!isliving(target) || (target in attached_mobs))
		return ELEMENT_INCOMPATIBLE
	RegisterSignal(target, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(target, COMSIG_LIVING_CAN_TRACK, PROC_REF(can_track))
	var/image/img = image(loc = target)
	img.override = TRUE
	attached_mobs[target] = img
	HideFromAIHuds(target)

/datum/element/digitalcamo/Detach(datum/target)
	. = ..()
	UnregisterSignal(target, list(COMSIG_ATOM_EXAMINE, COMSIG_LIVING_CAN_TRACK))
	for(var/mob/living/silicon/ai/AI in GLOB.player_list)
		AI.client.images -= attached_mobs[target]
	attached_mobs -= target
	UnhideFromAIHuds(target)

/datum/element/digitalcamo/proc/HideFromAIHuds(mob/living/target)
	for(var/mob/living/silicon/ai/AI in GLOB.ai_list)
		var/datum/atom_hud/M = GLOB.huds[AI.med_hud]
		M.hide_single_atomhud_from(AI,target)
		var/datum/atom_hud/S = GLOB.huds[AI.sec_hud]
		S.hide_single_atomhud_from(AI,target)

/datum/element/digitalcamo/proc/UnhideFromAIHuds(mob/living/target)
	for(var/mob/living/silicon/ai/AI in GLOB.ai_list)
		var/datum/atom_hud/M = GLOB.huds[AI.med_hud]
		M.unhide_single_atomhud_from(AI,target)
		var/datum/atom_hud/S = GLOB.huds[AI.sec_hud]
		S.unhide_single_atomhud_from(AI,target)

/datum/element/digitalcamo/proc/on_examine(datum/source, mob/M, list/examine_list)
	SIGNAL_HANDLER

	examine_list += span_danger("[source.p_Their()] skin seems to be <i>shifting</i> like something is moving below it.")

/datum/element/digitalcamo/proc/can_track(datum/source, mob/user)
	SIGNAL_HANDLER

	return COMPONENT_CANT_TRACK

/datum/element/digitalcamo/process()
	for(var/mob/living/silicon/ai/AI in GLOB.player_list)
		for(var/mob in attached_mobs)
			AI.client.images |= attached_mobs[mob]
