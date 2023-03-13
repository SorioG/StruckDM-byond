obj/fire
	icon = 'turfs.dmi'
	icon_state = "fire"
	mouse_opacity = 0
	New()
		..()
		//SoundLoop()
		//DamageLoop()

		spawn(200) del(src)
	/*
	proc/SoundLoop()
		spawn while(1)
			sleep(12)
			//play_sound('fse/fire-04-loop.wav')


	proc/DamageLoop()
		spawn while(1)
			var/mob/living/M

			for (M in range(0, src))
				M.Damage(10, ,DEATH_FIRE)
				M.play_sound('fse/flamestrike.wav')

			sleep(5)
	*/

