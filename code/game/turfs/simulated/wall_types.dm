/turf/simulated/wall/r_wall
	icon_state = "rgeneric"
/turf/simulated/wall/r_wall/New(var/newloc)
	..(newloc, "plasteel","plasteel") //3strong
/turf/simulated/wall/ocp_wall
	icon_state = "rgeneric"
/turf/simulated/wall/ocp_wall/New(var/newloc)
	..(newloc, "osmium-carbide plasteel", "osmium-carbide plasteel")




/turf/simulated/wall/cult
	icon_state = "cult"

/turf/simulated/wall/cult/New(var/newloc, var/reinforce = 0)
	..(newloc,"cult",reinforce ? "cult2" : null)

/turf/simulated/wall/cult/reinf/New(var/newloc)
	..(newloc, 1)

/turf/simulated/wall/cult/dismantle_wall()
	cult.remove_cultiness(CULTINESS_PER_TURF)
	..()

/turf/unsimulated/wall/cult
	name = "cult wall"
	desc = "Hideous images dance beneath the surface."
	icon = 'icons/turf/wall_masks.dmi'
	icon_state = "cult"

/turf/simulated/wall/iron/New(var/newloc)
	..(newloc,"iron")
/turf/simulated/wall/uranium/New(var/newloc)
	..(newloc,"uranium")
/turf/simulated/wall/diamond/New(var/newloc)
	..(newloc,"diamond")
/turf/simulated/wall/gold/New(var/newloc)
	..(newloc,"gold")
/turf/simulated/wall/silver/New(var/newloc)
	..(newloc,"silver")
/turf/simulated/wall/phoron/New(var/newloc)
	..(newloc,"phoron")
/turf/simulated/wall/sandstone/New(var/newloc)
	..(newloc,"sandstone")
/turf/simulated/wall/wood/New(var/newloc)
	..(newloc,"wood")
/turf/simulated/wall/ironphoron/New(var/newloc)
	..(newloc,"iron","phoron")
/turf/simulated/wall/golddiamond/New(var/newloc)
	..(newloc,"gold","diamond")
/turf/simulated/wall/silvergold/New(var/newloc)
	..(newloc,"silver","gold")
/turf/simulated/wall/sandstonediamond/New(var/newloc)
	..(newloc,"sandstone","diamond")


// Kind of wondering if this is going to bite me in the butt.
/turf/simulated/wall/voxshuttle/New(var/newloc)
	..(newloc,"voxalloy")
/turf/simulated/wall/voxshuttle/attackby()
	return
/turf/simulated/wall/titanium/New(var/newloc)
	..(newloc,"titanium")

/turf/simulated/wall/alium
	icon_state = "jaggy"
	floor_type = /turf/simulated/floor/fixed/alium

/turf/simulated/wall/alium/New(var/newloc)
	..(newloc,"alien alloy")

/turf/simulated/wall/alium/ex_act(severity)
	if(prob(explosion_resistance))
		return
	..()

//marines port
//Xenomorph's Resin Walls

/turf/closed/wall/resin
	name = "resin wall"
	desc = "Weird slime solidified into a wall."
	icon = 'icons/Xeno/structures.dmi'
	icon_state = "resin0"
	walltype = "resin"
	damage_cap = 200
	layer = RESIN_STRUCTURE_LAYER
	tiles_with = list(/turf/closed/wall/resin, /turf/closed/wall/resin/membrane, /obj/structure/mineral_door/resin)

/turf/closed/wall/resin/New()
	..()
	if(!locate(/obj/effect/alien/weeds) in loc)
		new /obj/effect/alien/weeds(loc)

/turf/closed/wall/resin/flamer_fire_act()
	take_damage(50)

//this one is only for map use
/turf/closed/wall/resin/ondirt
	oldTurf = "/turf/open/gm/dirt"

/turf/closed/wall/resin/thick
	name = "thick resin wall"
	desc = "Weird slime solidified into a thick wall."
	damage_cap = 400
	icon_state = "thickresin0"
	walltype = "thickresin"

/turf/closed/wall/resin/membrane
	name = "resin membrane"
	desc = "Weird slime translucent enough to let light pass through."
	icon_state = "membrane0"
	walltype = "membrane"
	damage_cap = 120
	opacity = 0
	alpha = 180

//this one is only for map use
/turf/closed/wall/resin/membrane/ondirt
	oldTurf = "/turf/open/gm/dirt"

/turf/closed/wall/resin/membrane/thick
	name = "thick resin membrane"
	desc = "Weird thick slime just translucent enough to let light pass through."
	damage_cap = 240
	icon_state = "thickmembrane0"
	walltype = "thickmembrane"
	alpha = 210

/turf/closed/wall/resin/bullet_act(var/obj/item/projectile/Proj)
	take_damage(Proj.damage/2)
	..()

	return 1

/turf/closed/wall/resin/ex_act(severity)
	switch(severity)
		if(1)
			take_damage(500)
		if(2)
			take_damage(rand(140, 300))
		if(3)
			take_damage(rand(50, 100))


/turf/closed/wall/resin/hitby(AM as mob|obj)
	..()
	if(istype(AM,/mob/living/carbon/Xenomorph))
		return
	visible_message("<span class='danger'>\The [src] was hit by \the [AM].</span>", \
	"<span class='danger'>You hit \the [src].</span>")
	var/tforce = 0
	if(ismob(AM))
		tforce = 10
	else
		tforce = AM:throwforce
	playsound(src, "alien_resin_break", 25)
	take_damage(max(0, damage_cap - tforce))


/turf/closed/wall/resin/attack_alien(mob/living/carbon/Xenomorph/M)
	if(isXenoLarva(M)) //Larvae can't do shit
		return 0
	M.animation_attack_on(src)
	M.visible_message("<span class='xenonotice'>\The [M] claws \the [src]!</span>", \
	"<span class='xenonotice'>You claw \the [src].</span>")
	playsound(src, "alien_resin_break", 25)
	take_damage((M.melee_damage_upper + 50)) //Beef up the damage a bit


/turf/closed/wall/resin/attack_animal(mob/living/M)
	M.visible_message("<span class='danger'>[M] tears \the [src]!</span>", \
	"<span class='danger'>You tear \the [name].</span>")
	playsound(src, "alien_resin_break", 25)
	M.animation_attack_on(src)
	take_damage(40)


/turf/closed/wall/resin/attack_hand(mob/user)
	user << "<span class='warning'>You scrape ineffectively at \the [src].</span>"


/turf/closed/wall/resin/attack_paw(mob/user)
	return attack_hand(user)


/turf/closed/wall/resin/attackby(obj/item/W, mob/living/user)
	if(!(W.flags_item & NOBLUDGEON))
		user.animation_attack_on(src)
		take_damage(W.force)
		playsound(src, "alien_resin_break", 25)
	else
		return attack_hand(user)

/turf/closed/wall/resin/CanPass(atom/movable/mover, turf/target)
	if(istype(mover) && mover.checkpass(PASSGLASS))
		return !opacity
	return !density

/turf/closed/wall/resin/dismantle_wall(devastated = 0, explode = 0)
	cdel(src) //ChangeTurf is called by Dispose()



/turf/closed/wall/resin/ChangeTurf(newtype)
	. = ..()
	if(.)
		var/turf/T
		for(var/i in cardinal)
			T = get_step(src, i)
			if(!istype(T)) continue
			for(var/obj/structure/mineral_door/resin/R in T)
				R.check_resin_support()




/turf/closed/wall/resin/can_be_dissolved()
	return FALSE
