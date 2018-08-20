GLOBAL_LIST_INIT(registered_weapons, list())

/obj/item/weapon/gun/energy
	name = "energy gun"
	desc = "A basic energy-based gun."
	icon_state = "energy"
	fire_sound = 'sound/weapons/Taser.ogg'
	fire_sound_text = "laser blast"

	var/obj/item/weapon/cell/power_supply //What type of power cell this uses
	var/charge_cost = 20 //How much energy is needed to fire.
	var/max_shots = 10 //Determines the capacity of the weapon's power cell. Specifying a cell_type overrides this value.
	var/cell_type = null
	var/projectile_type = /obj/item/projectile/beam/practice
	var/modifystate
	var/charge_meter = 1	//if set, the icon state will be chosen based on the current charge

	//self-recharging
	var/self_recharge = 0	//if set, the weapon will recharge itself
	var/use_external_power = 0 //if set, the weapon will look for an external power source to draw from, otherwise it recharges magically
	var/recharge_time = 4
	var/charge_tick = 0
	var/icon_rounder = 25
	combustion = 1

/obj/item/weapon/gun/energy/switch_firemodes()
	. = ..()
	if(.)
		update_icon()

/obj/item/weapon/gun/energy/emp_act(severity)
	..()
	update_icon()

/obj/item/weapon/gun/energy/New()
	..()
	if(cell_type)
		power_supply = new cell_type(src)
	else
		power_supply = new /obj/item/weapon/cell/device/variable(src, max_shots*charge_cost)
	if(self_recharge)
		START_PROCESSING(SSobj, src)
	update_icon()

/obj/item/weapon/gun/energy/Destroy()
	if(self_recharge)
		STOP_PROCESSING(SSobj, src)
	return ..()

/obj/item/weapon/gun/energy/Process()
	if(self_recharge) //Every [recharge_time] ticks, recharge a shot for the cyborg
		charge_tick++
		if(charge_tick < recharge_time) return 0
		charge_tick = 0

		if(!power_supply || power_supply.charge >= power_supply.maxcharge)
			return 0 // check if we actually need to recharge

		if(use_external_power)
			var/obj/item/weapon/cell/external = get_external_power_supply()
			if(!external || !external.use(charge_cost)) //Take power from the borg...
				return 0

		power_supply.give(charge_cost) //... to recharge the shot
		update_icon()
	return 1

/obj/item/weapon/gun/energy/consume_next_projectile()
	if(!power_supply) return null
	if(!ispath(projectile_type)) return null
	if(!power_supply.checked_use(charge_cost)) return null
	return new projectile_type(src)

/obj/item/weapon/gun/energy/proc/get_external_power_supply()
	if(isrobot(src.loc))
		var/mob/living/silicon/robot/R = src.loc
		return R.cell
	if(istype(src.loc, /obj/item/rig_module))
		var/obj/item/rig_module/module = src.loc
		if(module.holder && module.holder.wearer)
			var/mob/living/carbon/human/H = module.holder.wearer
			if(istype(H) && H.back)
				var/obj/item/weapon/rig/suit = H.back
				if(istype(suit))
					return suit.cell
	return null

/obj/item/weapon/gun/energy/examine(mob/user)
	. = ..(user)
	var/shots_remaining = round(power_supply.charge / charge_cost)
	to_chat(user, "Has [shots_remaining] shot\s remaining.")
	return

/obj/item/weapon/gun/energy/update_icon()
	..()
	if(charge_meter)
		var/ratio = power_supply.percent()

		//make sure that rounding down will not give us the empty state even if we have charge for a shot left.
		if(power_supply.charge < charge_cost)
			ratio = 0
		else
			ratio = max(round(ratio, icon_rounder), icon_rounder)

		if(modifystate)
			icon_state = "[modifystate][ratio]"
		else
			icon_state = "[initial(icon_state)][ratio]"

/obj/item/weapon/gun/energy/secure
	desc = "A basic energy-based gun with a secure authorization chip."
	req_access = list(access_brig)
	var/list/authorized_modes = list(ALWAYS_AUTHORIZED) // index of this list should line up with firemodes, unincluded firemodes at the end will default to unauthorized
	var/registered_owner
	var/emagged = 0

/obj/item/weapon/gun/energy/secure/Initialize()
	if(!authorized_modes)
		authorized_modes = list()

	for(var/i = authorized_modes.len + 1 to firemodes.len)
		authorized_modes.Add(UNAUTHORIZED)

	. = ..()

/obj/item/weapon/gun/energy/secure/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if(istype(W, /obj/item/weapon/card/id))
		if(!emagged)
			if(!registered_owner)
				if(allowed(user))
					var/obj/item/weapon/card/id/id = W
					GLOB.registered_weapons += src
					registered_owner = id.registered_name
					user.visible_message("[user] swipes an ID through \the [src], registering it.", "You swipe an ID through \the [src], registering it.")
				else
					to_chat(user, "<span class='warning'>Access denied.</span>")
			else
				to_chat(user, "This weapon is already registered, you must reset it first.")
		else
			to_chat(user, "You swipe your ID, but nothing happens.")
	else
		..()

/obj/item/weapon/gun/energy/secure/verb/reset()
	set name = "Reset Registration"
	set category = "Object"
	set src in usr

	if(issilicon(usr))
		return

	if(allowed(usr))
		usr.visible_message("[usr] presses the reset button on \the [src], resetting its registration.", "You press the reset button on \the [src], resetting its registration.")
		registered_owner = null
		GLOB.registered_weapons -= src

/obj/item/weapon/gun/energy/secure/Destroy()
	GLOB.registered_weapons -= src

	. = ..()

/obj/item/weapon/gun/energy/secure/proc/authorize(var/mode, var/authorized, var/by)
	if(emagged || mode < 1 || mode > authorized_modes.len || authorized_modes[mode] == authorized)
		return 0

	authorized_modes[mode] = authorized

	if(mode == sel_mode && !authorized)
		switch_firemodes()

	var/mob/M = get_holder_of_type(src, /mob)
	if(M)
		to_chat(M, "<span class='notice'>Your [src.name] has been [authorized ? "granted" : "denied"] [firemodes[mode]] fire authorization by [by].</span>")

	return 1

/obj/item/weapon/gun/energy/secure/special_check()
	if(!emagged && (!authorized_modes[sel_mode] || !registered_owner))
		audible_message("<span class='warning'>\The [src] buzzes, refusing to fire.</span>")
		playsound(loc, 'sound/machines/buzz-sigh.ogg', 50, 0)
		return 0

	. = ..()

/obj/item/weapon/gun/energy/secure/switch_firemodes()
	var/next_mode = get_next_authorized_mode()
	if(firemodes.len <= 1 || next_mode == null || sel_mode == next_mode)
		return null

	sel_mode = next_mode
	var/datum/firemode/new_mode = firemodes[sel_mode]
	new_mode.apply_to(src)
	update_icon()

	return new_mode

/obj/item/weapon/gun/energy/secure/examine(var/mob/user)
	..()

	if(registered_owner)
		to_chat(user, "A small screen on the side of the weapon indicates that it is registered to [registered_owner].")

/obj/item/weapon/gun/energy/secure/proc/get_next_authorized_mode()
	. = sel_mode
	do
		.++
		if(. > authorized_modes.len)
			. = 1
		if(. == sel_mode) // just in case all modes are unauthorized
			return null
	while(!authorized_modes[.] && !emagged)

/obj/item/weapon/gun/energy/secure/emag_act(var/charges, var/mob/user)
	if(emagged || !charges)
		return NO_EMAG_ACT
	else
		emagged = 1
		registered_owner = null
		GLOB.registered_weapons -= src
		to_chat(user, "The authorization chip fries, giving you full use of \the [src].")
		return 1


/obj/item/weapon/gun/energy/plasmarifle
	name = "plasma rifle"
	desc = "A long-barreled heavy plasma weapon capable of taking down large game. It has a mounted scope for distant shots and an integrated battery."
	icon = 'icons/obj/items/predator.dmi'
	icon_state = "plasmarifle"
	item_state = "plasmarifle"
	origin_tech = "combat=8;materials=7;bluespace=6"
	unacidable = 1
	fire_sound = 'sound/weapons/pred_plasma_shot.ogg'
	ammo = /datum/ammo/energy/yautja/rifle/bolt
	muzzle_flash = null // TO DO, add a decent one.
	zoomdevicename = "scope"
	flags_equip_slot = SLOT_BACK
	w_class = 5
	var/charge_time = 0
	var/last_regen = 0
	flags_gun_features = GUN_UNUSUAL_DESIGN


/obj/item/weapon/gun/energy/plasmarifle/New()
	..()
	processing_objects.Add(src)
	last_regen = world.time
	update_icon()
	verbs -= /obj/item/weapon/gun/verb/field_strip
	verbs -= /obj/item/weapon/gun/verb/toggle_burst
	verbs -= /obj/item/weapon/gun/verb/empty_mag



/obj/item/weapon/gun/energy/plasmarifle/Dispose()
	. = ..()
	processing_objects.Remove(src)


/obj/item/weapon/gun/energy/plasmarifle/process()
	if(charge_time < 100)
		charge_time++
		if(charge_time == 99)
			if(ismob(loc)) loc << "<span class='notice'>[src] hums as it achieves maximum charge.</span>"
		update_icon()


/obj/item/weapon/gun/energy/plasmarifle/set_gun_config_values()
	fire_delay = config.high_fire_delay*2
	accuracy_mult = config.base_hit_accuracy_mult + config.max_hit_accuracy_mult
	accuracy_mult_unwielded = config.base_hit_accuracy_mult + config.max_hit_accuracy_mult
	scatter = config.med_scatter_value
	scatter_unwielded = config.med_scatter_value
	damage_mult = config.base_hit_damage_mult


/obj/item/weapon/gun/energy/plasmarifle/examine(mob/user)
	if(isYautja(user))
		..()
		user << "It currently has [charge_time] / 100 charge."
	else user << "This thing looks like an alien rifle of some kind. Strange."

/obj/item/weapon/gun/energy/plasmarifle/update_icon()
	if(last_regen < charge_time + 20 || last_regen > charge_time || charge_time > 95)
		var/new_icon_state = charge_time <=15 ? null : icon_state + "[round(charge_time/33, 1)]"
		update_special_overlay(new_icon_state)
		last_regen = charge_time

/obj/item/weapon/gun/energy/plasmarifle/unique_action(mob/user)
	if(!isYautja(user))
		user << "<span class='warning'>You have no idea how this thing works!</span>"
		return
	..()
	zoom(user)

/obj/item/weapon/gun/energy/plasmarifle/able_to_fire(mob/user)
	if(!isYautja(user))
		user << "<span class='warning'>You have no idea how this thing works!</span>"
		return

	return ..()

/obj/item/weapon/gun/energy/plasmarifle/load_into_chamber()
	ammo = ammo_list[charge_time < 15? /datum/ammo/energy/yautja/rifle/bolt : /datum/ammo/energy/yautja/rifle/blast]
	var/obj/item/projectile/P = create_bullet(ammo)
	P.SetLuminosity(1)
	in_chamber = P
	charge_time = round(charge_time / 2)
	return in_chamber

/obj/item/weapon/gun/energy/plasmarifle/reload_into_chamber()
	update_icon()
	return 1

/obj/item/weapon/gun/energy/plasmarifle/delete_bullet(obj/item/projectile/projectile_to_fire, refund = 0)
	cdel(projectile_to_fire)
	if(refund) charge_time *= 2
	return 1

/obj/item/weapon/gun/energy/plasmarifle/attack_self(mob/living/user)
	if(!isYautja(user))
		return ..()

	if(charge_time > 10)
		user.visible_message("<span class='notice'>You feel a strange surge of energy in the area.</span>","<span class='notice'>You release the rifle battery's energy.</span>")
		var/obj/item/clothing/gloves/yautja/Y = user:gloves
		if(Y && Y.charge < Y.charge_max)
			Y.charge += charge_time * 2
			if(Y.charge > Y.charge_max) Y.charge = Y.charge_max
			charge_time = 0
			user << "<span class='notice'>Your bracers absorb some of the released energy.</span>"
			update_icon()
	else user << "<span class='warning'>The weapon's not charged enough with ambient energy!</span>"



//marines adapt

/obj/item/weapon/gun/energy/plasmapistol
	name = "plasma pistol"
	desc = "A plasma pistol capable of rapid fire. It has an integrated battery."
	icon = 'icons/obj/items/predator.dmi'
	icon_state = "plasmapistol"
	item_state = "plasmapistol"
	origin_tech = "combat=8;materials=7;bluespace=6"
	unacidable = 1
	fire_sound = 'sound/weapons/pulse3.ogg'
	flags_equip_slot = SLOT_WAIST
	ammo = /datum/ammo/energy/yautja/pistol
	muzzle_flash = null // TO DO, add a decent one.
	w_class = 3
	var/charge_time = 40
	flags_gun_features = GUN_UNUSUAL_DESIGN


/obj/item/weapon/gun/energy/plasmapistol/New()
	..()
	processing_objects.Add(src)
	verbs -= /obj/item/weapon/gun/verb/field_strip
	verbs -= /obj/item/weapon/gun/verb/toggle_burst
	verbs -= /obj/item/weapon/gun/verb/empty_mag



/obj/item/weapon/gun/energy/plasmapistol/Dispose()
	. = ..()
	processing_objects.Remove(src)


/obj/item/weapon/gun/energy/plasmapistol/process()
	if(charge_time < 40)
		charge_time++
		if(charge_time == 39)
			if(ismob(loc)) loc << "<span class='notice'>[src] hums as it achieves maximum charge.</span>"



/obj/item/weapon/gun/energy/plasmapistol/set_gun_config_values()
	fire_delay = config.med_fire_delay
	accuracy_mult = config.base_hit_accuracy_mult + config.med_hit_accuracy_mult
	accuracy_mult_unwielded = config.base_hit_accuracy_mult + config.high_hit_accuracy_mult
	scatter = config.low_scatter_value
	scatter_unwielded = config.med_scatter_value
	damage_mult = config.base_hit_damage_mult



/obj/item/weapon/gun/energy/plasmapistol/examine(mob/user)
	if(isYautja(user))
		..()
		user << "It currently has [charge_time] / 40 charge."
	else
		user << "This thing looks like an alien rifle of some kind. Strange."


/obj/item/weapon/gun/energy/plasmapistol/able_to_fire(mob/user)
	if(!isYautja(user))
		user << "<span class='warning'>You have no idea how this thing works!</span>"
		return
	else
		return ..()

/obj/item/weapon/gun/energy/plasmapistol/load_into_chamber()
	if(charge_time < 1) return
	var/obj/item/projectile/P = create_bullet(ammo)
	P.SetLuminosity(1)
	in_chamber = P
	charge_time -= 1
	return in_chamber

/obj/item/weapon/gun/energy/plasmapistol/reload_into_chamber()
	return 1

/obj/item/weapon/gun/energy/plasmapistol/delete_bullet(obj/item/projectile/projectile_to_fire, refund = 0)
	cdel(projectile_to_fire)
	if(refund) charge_time *= 2
	return 1











/obj/item/weapon/gun/energy/plasma_caster
	icon = 'icons/obj/items/predator.dmi'
	icon_state = "plasma"
	item_state = "plasma_wear"
	name = "plasma caster"
	desc = "A powerful, shoulder-mounted energy weapon."
	fire_sound = 'sound/weapons/pred_plasmacaster_fire.ogg'
	ammo = /datum/ammo/energy/yautja/caster/bolt
	muzzle_flash = null // TO DO, add a decent one.
	w_class = 5
	force = 0
	fire_delay = 3
	var/obj/item/clothing/gloves/yautja/source = null
	var/charge_cost = 100 //How much energy is needed to fire.
	var/mode = 0
	actions_types = list(/datum/action/item_action/toggle)
	flags_atom = FPRINT|CONDUCT
	flags_item = NOBLUDGEON|DELONDROP //Can't bludgeon with this.
	flags_gun_features = GUN_UNUSUAL_DESIGN

/obj/item/weapon/gun/energy/plasma_caster/New()
	..()
	verbs -= /obj/item/weapon/gun/verb/field_strip
	verbs -= /obj/item/weapon/gun/verb/toggle_burst
	verbs -= /obj/item/weapon/gun/verb/empty_mag
	verbs -= /obj/item/weapon/gun/verb/use_unique_action

/obj/item/weapon/gun/energy/plasma_caster/Dispose()
	. = ..()
	source = null


/obj/item/weapon/gun/energy/plasma_caster/set_gun_config_values()
	fire_delay = config.high_fire_delay
	accuracy_mult = config.base_hit_accuracy_mult
	accuracy_mult_unwielded = config.base_hit_accuracy_mult + config.high_fire_delay
	scatter = config.med_scatter_value
	scatter_unwielded = config.med_scatter_value
	damage_mult = config.base_hit_damage_mult

/obj/item/weapon/gun/energy/plasma_caster/attack_self(mob/living/user)
	switch(mode)
		if(0)
			mode = 1
			charge_cost = 100
			fire_delay = config.med_fire_delay * 4
			fire_sound = 'sound/weapons/emitter2.ogg'
			user << "<span class='notice'>[src] is now set to fire medium plasma blasts.</span>"
			ammo = ammo_list[/datum/ammo/energy/yautja/caster/blast]
		if(1)
			mode = 2
			charge_cost = 300
			fire_delay = config.high_fire_delay * 20
			fire_sound = 'sound/weapons/pulse.ogg'
			user << "<span class='notice'>[src] is now set to fire heavy plasma spheres.</span>"
			ammo = ammo_list[/datum/ammo/energy/yautja/caster/sphere]
		if(2)
			mode = 0
			charge_cost = 30
			fire_delay = config.high_fire_delay
			fire_sound = 'sound/weapons/pred_lasercannon.ogg'
			user << "<span class='notice'>[src] is now set to fire light plasma bolts.</span>"
			ammo = ammo_list[/datum/ammo/energy/yautja/caster/bolt]

/obj/item/weapon/gun/energy/plasma_caster/dropped(mob/living/carbon/human/M)
	playsound(M,'sound/weapons/pred_plasmacaster_off.ogg', 15, 1)
	..()

/obj/item/weapon/gun/energy/plasma_caster/able_to_fire(mob/user)
	if(!source)	return
	if(!isYautja(user))
		user << "<span class='warning'>You have no idea how this thing works!</span>"
		return

	return ..()

/obj/item/weapon/gun/energy/plasma_caster/load_into_chamber()
	if(source.drain_power(usr,charge_cost))
		in_chamber = create_bullet(ammo)
		return in_chamber

/obj/item/weapon/gun/energy/plasma_caster/reload_into_chamber()
	return 1

/obj/item/weapon/gun/energy/plasma_caster/delete_bullet(obj/item/projectile/projectile_to_fire, refund = 0)
	cdel(projectile_to_fire)
	if(refund)
		source.charge += charge_cost
		var/perc = source.charge / source.charge_max * 100
		var/mob/living/carbon/human/user = usr //Hacky...
		user.update_power_display(perc)
	return 1
