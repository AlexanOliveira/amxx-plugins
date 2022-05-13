#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>

#define FL_SPEED	(1 << 0)
#define FL_FPS		(1 << 1)
#define FL_KEYS	(1 << 2)
#define KEYS_STR_LEN 98

new keys_default
new cl_prefs[32], cl_names[32][21]
new keys_string[32][KEYS_STR_LEN]

new Float:g_fGameTime[32]
new g_iCurFPS[32]
new g_iFPS[32]
new g_iFramesPer[32]
new pl_fps[32]


new frames
new R[32], G[32], B[32]

public plugin_init() {
	register_plugin("db: Mostrar Teclas", "2.0", "-LeQuiM-")
	register_cvar("showkeys_version", "2.0", FCVAR_SERVER)
	set_cvar_string("showkeys_version", "2.0")

	keys_default = register_cvar("db_keys_default", "1")

	register_concmd("cmd_keys", "toggle_keys", _, "Toggle viewing own Keys.")

	register_dictionary("db_showkeys.txt");
	register_forward(FM_PlayerPreThink, "event_preThink")
	set_task(0.1, "showInfo", 32, _, _, "b")
}

public client_connect(id) {
	cl_prefs[id] = 0;
	if(!is_user_bot(id)) {
		if(get_pcvar_num(keys_default)) cl_prefs[id] |= FL_KEYS
	}
	get_user_name(id, cl_names[id], 20);
	return PLUGIN_CONTINUE;
}

public client_infochanged(id) {
	get_user_name(id, cl_names[id], 20);
	return PLUGIN_CONTINUE;
}

public toggle_keys(id) {
	set_hudmessage(255, 255, 255, -1.0, 0.75, 0, 0.0, 1.0, 0.5, 0.5, -1)
	cl_prefs[id] ^= FL_KEYS;
	show_hudmessage(id, "%L", id, cl_prefs[id] & FL_KEYS ? "SPEC_OWNKEYS_ENABLED" : "SPEC_OWNKEYS_DISABLED");
	return PLUGIN_HANDLED;
}

public event_preThink(id) {
	new players[32], num
	new Float: spd

	if (is_user_alive(id)) {
		g_fGameTime[id] = get_gametime()
		if(g_iFramesPer[id] > g_fGameTime[id])
			g_iFPS[id] += 1
		else {
		   g_iFramesPer[id] += 1
		   g_iCurFPS[id] = g_iFPS[id]
		   g_iFPS[id] = 0
		}
	}

	if (frames % 7 == 0) {
		get_players(players, num, "ach");
		for(new i = 0; i < num; i++) {
			id = players[i];
			new Float:speed[5]
			new buttons = pev(id, pev_button)

			pev(id, pev_velocity, speed)
			spd = floatsqroot(floatadd(floatpower(speed[0], 2.0), floatpower(speed[1], 2.0)))

			if (spd < 300) {
				R[id] = 0
				G[id] = 255
				B[id] = 0
			}else if (spd < 350) {
				R[id] = 35
				G[id] = 255
				B[id] = 0
			}else if (spd < 400) {
				R[id] = 55
				G[id] = 255
				B[id] = 0

			}else if (spd < 650) {
				R[id] = 255
				G[id] = 255
				B[id] = 0
			}else if (spd < 950) {
				R[id] = 255
				G[id] = 110
				B[id] = 0
			}else if (spd < 1200) {
				R[id] = 255
				G[id] = 50
				B[id] = 0

			}else if (spd < 1300) {
				R[id] = 255
				G[id] = 30
				B[id] = 0
			}else if (spd < 1550) {
				R[id] = 255
				G[id] = 15
				B[id] = 0
			}else if (spd < 1650) {
				R[id] = 255
				G[id] = 10
				B[id] = 0
			}else {
				R[id] = 255
				G[id] = 0
				B[id] = 0
			}

			g_iCurFPS[id]++

			query_client_cvar(id, "fps_max", "userFPS")

			if (g_iCurFPS[id] > pl_fps[id]) g_iCurFPS[id]--

			format(keys_string[id], KEYS_STR_LEN, "^n ^t^t %s %s ^n %s %s %s %s %s %s^n^n^n^n^n^n^n^n^n^n^n^n^n Speed: %1.f^n- - - - - - - - -^n   FPS: %i",
				buttons & IN_FORWARD ? " W^t^t^t" : "^t^t^t^t^t",
				buttons & IN_JUMP ? "^tSpace"  : "",
				buttons & IN_LEFT ? "<"  : "^t",
				buttons & IN_MOVELEFT ? "A" : "  ",
				buttons & IN_BACK ? "S" : "^t",
				buttons & IN_MOVERIGHT ? "D" : "^t",
				buttons & IN_RIGHT ? "> " : " ^t",
				buttons & IN_DUCK ? "Ctrl" : "",
				spd,
				g_iCurFPS[id]
			)
		}
		frames = 1
	}else {
		frames++
	}
	return PLUGIN_HANDLED
}

public userFPS(id, const cvar[], const value[]) {
	if (equal(cvar, "fps_max") && str_to_num(value)) pl_fps[id] = str_to_num(value)
}

public showInfo() {
	new players[32], num, id;
	new msg[KEYS_STR_LEN + 1]
	new id2
	get_players(players, num, "ch")

	for(new i=0; i<num; i++) {
		id = players[i]
		new prefs = cl_prefs[id]
		new bool:show_own = false

		if(is_user_alive(id) && prefs & FL_KEYS) show_own = true
		if(is_user_alive(id) && !show_own) return

		if(show_own) id2 = id
		else id2 = pev(id, pev_iuser2)

		if(!id2) return

		format(msg, KEYS_STR_LEN, "%s", keys_string[id2][1]);
		set_hudmessage(R[id2], G[id2], B[id2], 0.4785, 0.54, 0, 0.1, 0.1, 0.0, 0.1, 4)
		show_hudmessage(id, msg);
	}
}

