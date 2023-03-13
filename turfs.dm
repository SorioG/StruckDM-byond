
turf
	ice
		icon_state = "iceblock"
		var/list/on_ice = list()

		New()
			..()
			WalkLoop()

		Exited(mob/living/M)
			if (!istype(M)) return ..()

			if (on_ice.Find(M))
				on_ice.Remove(M)
				walk(M, 0)

			..()

		proc/WalkLoop()
			spawn while(1)

				var/mob/living/M

				for (M in view(0, src))
					if (!on_ice.Find(M))
						on_ice.Add(M)
					walk(M, M.dir)

				sleep(0.5)