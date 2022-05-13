#include <amxmodx>
#include <hamsandwich>
#include <colorchat>
#include <fakemeta>


#define DB_LEVEL ADMIN_KICK
#define MSG MSG_ONE_UNRELIABLE
#define MAX_ENTITYS 900+15*32
#define IsOnLadder(%1) (pev(%1, pev_movetype) == MOVETYPE_FLY)
#define VERSION "3.0"

#define SCOREATTRIB_NONE  0
#define SCOREATTRIB_DEAD  (1 << 0)
#define SCOREATTRIB_BOMB  (1 << 1)
#define SCOREATTRIB_VIP   (1 << 2)

#define VEC_NULL Float:{0.0, 0.0, 0.0}

#define RefreshPlayersList()  get_players(g_iPlayers, g_iNum, g_szAliveFlags)

new const FL_ONGROUND2 = (FL_ONGROUND | FL_PARTIALGROUND | FL_INWATER | FL_CONVEYOR | FL_FLOAT)
new const DB_STARTFILE[] = "start.ini"
new const DB_STARTFILE_TEMP[] = "temp_start.ini"

new Float:Checkpoints[MAX_PLAYERS][3][3]
new Float:SavedStart[33][3]
new hookorigin[33][3]
new Float:DefaultStartPos[3]

new Float:SavedTime[33]
new SavedChecks[33]
new SavedGoChecks[33]
new SavedOrigins[33][3]

new bool:timer_started[33]
new bool:firstspawn[33]
new bool:canusehook[33]
new bool:ishooked[33]
new bool:DefaultStart
new bool:AutoStart[33]

new checknumbers[33]
new gochecknumbers[33]
new iMapName[64]
new Kzdir[128]
new SavePosDir[128]
new prefix[33]

new db_checkpoints
new db_hud_color
new db_chat_prefix
new hud_message
new db_pick_weapons
new db_hook_sound
new db_hook_speed
new db_vip
new db_save_pos
new db_save_pos_gochecks
new db_save_autostart
new Sbeam = 0

public plugin_init() {
	register_plugin("db: CheckPoint Treino", VERSION, "-LeQuiM-")

	db_checkpoints = register_cvar("db_checkpoints","1")
	db_hook_sound = register_cvar("db_hook_sound","1")
	db_hook_speed = register_cvar("db_hook_speed", "300.0")
	db_vip = register_cvar("db_vip","1")
	db_save_autostart = register_cvar("db_save_autostart", "1")
	db_save_pos = register_cvar("db_save_pos", "1")
	db_save_pos_gochecks = register_cvar("db_save_pos_gochecks", "1")

	register_clcmd("/cp","CheckPoint")
	register_clcmd("/gc", "GoCheck")
	register_clcmd("+hook","hook_on",DB_LEVEL)
	register_clcmd("-hook","hook_off",DB_LEVEL)
	register_concmd("db_hook","give_hook", DB_LEVEL, "<name|#userid|steamid|@ALL> <on/off>")
	register_clcmd("/tp","GoCheck")
	register_concmd("cmd_kzmenu", "db_menu")

	db_register_saycmd("check","db_menu", 0)
	db_register_saycmd("cp","CheckPoint",0)
	db_register_saycmd("gc", "GoCheck",0)
	db_register_saycmd("gocheck", "GoCheck",0)
	db_register_saycmd("reset", "reset_checkpoints", 0)
	db_register_saycmd("respawn", "goStart", 0)
	db_register_saycmd("savepos", "SavePos", 0)
	db_register_saycmd("setstart", "setStart", DB_LEVEL)
	db_register_saycmd("start", "goStart", 0)
	db_register_saycmd("teleport", "GoCheck", 0)
	db_register_saycmd("tp", "GoCheck",0)

	register_event ("StatusValue", "EventStatusValue", "b", "1>0", "2>0");

	register_message (get_user_msgid ("ScoreAttrib"), "MessageScoreAttrib")
	register_dictionary("prokreedz.txt")
	get_pcvar_string(db_chat_prefix, prefix, 31)
	get_mapname(iMapName, 63)
	set_msg_block(get_user_msgid("ClCorpse"), BLOCK_SET)
	set_task(1.0,"timer_task", 2000, "", 0, "ab")

	new kreedz_cfg[128], ConfigDir[64]
	get_configsdir (ConfigDir, 64)
	formatex(Kzdir,128, "%s/kz", ConfigDir)
	if (!dir_exists(Kzdir))
		mkdir(Kzdir)

	formatex(SavePosDir, 128, "%s/savepos", Kzdir)
	if (!dir_exists(SavePosDir))
		mkdir(SavePosDir)

	formatex(kreedz_cfg,128,"%s/kreedz.cfg", Kzdir)

	if (file_exists (kreedz_cfg)) {
		server_exec()
		server_cmd("exec %s",kreedz_cfg)
	}

}

public plugin_precache() {
	hud_message = CreateHudSyncObj()
	precache_sound("weapons/xbow_hit2.wav")
	Sbeam = precache_model("sprites/laserbeam.spr")
}

public plugin_cfg() {
	new startcheck[100], data[256], map[64], x[13], y[13], z[13];
	formatex(startcheck, 99, "%s/%s", Kzdir, DB_STARTFILE)
	new f = fopen(startcheck, "rt")
	while (!feof (f)) {
		fgets (f, data, sizeof data - 1)
		parse (data, map, 63, x, 12, y, 12, z, 12)

		if (equali (map, iMapName)) {
			DefaultStartPos[0] = str_to_float(x)
			DefaultStartPos[1] = str_to_float(y)
			DefaultStartPos[2] = str_to_float(z)

			DefaultStart = true
			break;
		}
	}
	fclose(f)
}

public client_command(id) {

	new sArg[13];
	if (read_argv(0, sArg, 12) > 11) {
		return PLUGIN_CONTINUE;
	}
	return PLUGIN_CONTINUE;
}

public CmdRespawn(id) {
	if (get_user_team(id) == 3)
		return PLUGIN_HANDLED
	else
		ExecuteHamB(Ham_CS_RoundRespawn, id)

	return PLUGIN_HANDLED
}

//Start location

public goStart(id) {
	if (!is_user_alive (id)) {
		return PLUGIN_HANDLED
	}

	if(get_pcvar_num(db_save_autostart) == 1 && AutoStart [id]) {
		set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0})
		set_pev (id, pev_flags, pev(id, pev_flags) | FL_DUCKING)
		set_pev(id, pev_origin, SavedStart [id])

	} else if (DefaultStart) {
		set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0})
		set_pev(id, pev_origin, DefaultStartPos)
	} else
		CmdRespawn(id)

	return PLUGIN_HANDLED
}

public setStart(id) {
	if (! (get_user_flags (id) & DB_LEVEL)) {
		return PLUGIN_HANDLED
	}

	new Float:origin[3]
	pev(id, pev_origin, origin)
	db_set_start(iMapName, origin)
	AutoStart[id] = false;
	ColorChat(id, GREEN, "%s^x01 %L.", prefix, id, "DB_SET_START")

	return PLUGIN_HANDLED
}

// Hook

public give_hook(id) {
	if (! ( get_user_flags (id) & DB_LEVEL))
		return PLUGIN_HANDLED

	new szarg1[32], szarg2[8], bool:mode
	read_argv(1,szarg1,32)
	read_argv(2,szarg2,32)
	if(equal(szarg2,"on"))
		mode = true

	if(equal(szarg1,"@ALL")) {
		new Alive[32], alivePlayers
		get_players(Alive, alivePlayers, "ach")
		for(new i;i<alivePlayers;i++) {
			canusehook[i] = mode
			if(mode)
				ColorChat(i, GREEN, "%s^x01, %L.", prefix, i, "DB_HOOK")
		}
	} else {
		new pid = find_player("bl",szarg1);
		if(pid > 0) {
			canusehook[pid] = mode
			if(mode) {
				ColorChat(pid, GREEN, "%s^x01 %L.", prefix, pid, "DB_HOOK")
			}
		}
	}

	return PLUGIN_HANDLED
}

public hook_on(id) {
	if (!canusehook[id] && ! ( get_user_flags (id) & DB_LEVEL) || !is_user_alive(id))
		return PLUGIN_HANDLED

	get_user_origin(id,hookorigin[id],3)
	ishooked[id] = true

	if (get_pcvar_num(db_hook_sound) == 1)
	emit_sound(id,CHAN_STATIC,"weapons/xbow_hit2.wav",1.0,ATTN_NORM,0,PITCH_NORM)

	set_task(0.1,"hook_task",id,"",0,"ab")
	hook_task(id)

	return PLUGIN_HANDLED
}

public hook_off(id) {
	remove_hook(id)

	return PLUGIN_HANDLED
}

public hook_task(id) {
	if(!is_user_connected(id) || !is_user_alive(id))
		remove_hook(id)

	remove_beam(id)
	draw_hook(id)

	new origin[3], Float:velocity[3]
	get_user_origin(id,origin)
	new distance = get_distance(hookorigin[id],origin)
	velocity[0] = (hookorigin[id][0] - origin[0]) * (2.0 * get_pcvar_num(db_hook_speed) / distance)
	velocity[1] = (hookorigin[id][1] - origin[1]) * (2.0 * get_pcvar_num(db_hook_speed) / distance)
	velocity[2] = (hookorigin[id][2] - origin[2]) * (2.0 * get_pcvar_num(db_hook_speed) / distance)

	set_pev(id,pev_velocity,velocity)
}

public draw_hook(id) {
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(1)				// TE_BEAMENTPOINT
	write_short(id)				// entid
	write_coord(hookorigin[id][0])		// origin
	write_coord(hookorigin[id][1])		// origin
	write_coord(hookorigin[id][2])		// origin
	write_short(Sbeam)			// sprite index
	write_byte(0)				// start frame
	write_byte(0)				// framerate
	write_byte(random_num(1,100))		// life
	write_byte(random_num(1,20))		// width
	write_byte(random_num(1,0))		// noise
	write_byte(random_num(1,255))		// r
	write_byte(random_num(1,255))		// g
	write_byte(random_num(1,255))		// b
	write_byte(random_num(1,500))		// brightness
	write_byte(random_num(1,200))		// speed
	message_end()
}

public remove_hook(id) {
	if(task_exists(id))
		remove_task(id)
	remove_beam(id)
	ishooked[id] = false
}

public remove_beam(id) {
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(99) // TE_KILLBEAM
	write_short(id)
	message_end()
}


// VIP In ScoreBoard

public MessageScoreAttrib (iMsgID, iDest, iReceiver) {
	if (get_pcvar_num(db_vip)) {
		new iPlayer = get_msg_arg_int (1)
		if (is_user_alive (iPlayer) && (get_user_flags (iPlayer) & DB_LEVEL)) {
			set_msg_arg_int (2, ARG_BYTE, SCOREATTRIB_VIP);
		}
	}
}

public EventStatusValue (const id) {

	new szMessage[ 34 ], Target, aux
	get_user_aiming(id, Target, aux)
	if (is_user_alive(Target)) {
		formatex (szMessage, 33, "1 %s: %%p2", get_user_flags (Target) & DB_LEVEL ? "VIP" : "Player")
		message_begin (MSG, get_user_msgid ("StatusText") , _, id)
		write_byte (0)
		write_string (szMessage)
		message_end ()
	}
}


// Cmds


public CheckPoint(id) {

	if (!is_user_alive (id)) {
		return PLUGIN_HANDLED
	}

	if(get_pcvar_num(db_checkpoints) == 0) {
		return PLUGIN_HANDLED
	}

	pev(id, pev_origin, Checkpoints[id][0]);
	pev(id, pev_v_angle, Checkpoints[id][1]);
	if(pev(id, pev_flags) & FL_ONGROUND2) Checkpoints[id][2] = VEC_NULL; else pev(id, pev_velocity, Checkpoints[id][2]);

	checknumbers[id]++

	return PLUGIN_HANDLED
}

public GoCheck(id) {
	if (!is_user_alive (id)) {
		return PLUGIN_HANDLED
	}

	if (checknumbers[id] == 0 ) {
		return PLUGIN_HANDLED
	}

	set_pev(id, pev_gravity, 1.0)
	set_pev(id, pev_velocity, VEC_NULL)
	set_pev(id, pev_basevelocity, VEC_NULL)
	set_pev(id, pev_view_ofs, Float:{0.0, 0.0, 12.0})
	set_pev(id, pev_flags, pev(id, pev_flags) | FL_DUCKING)
	set_pev(id, pev_fuser2, 0.0)
	engfunc(EngFunc_SetSize, id, {-16.0, -16.0, -18.0}, {16.0, 16.0, 32.0})
	set_pev(id, pev_origin, Checkpoints[id][0])
	set_pev(id, pev_v_angle, 0)
	set_pev(id, pev_angles, Checkpoints[id][1])
	set_pev(id, pev_velocity, Checkpoints[id][2])
	set_pev(id, pev_fixangle, 1)
	gochecknumbers[id]++

	return PLUGIN_HANDLED
}


public reset_checkpoints(id) {
	checknumbers[id] = 0
	gochecknumbers[id] = 0
	timer_started[id] = false
	return PLUGIN_HANDLED
}


stock db_set_start(const map[], Float:origin[3]) {
	new realfile[128], tempfile[128], formatorigin[50]
	formatex(realfile, 127, "%s/%s", Kzdir, DB_STARTFILE)
	formatex(tempfile, 127, "%s/%s", Kzdir, DB_STARTFILE_TEMP)
	formatex(formatorigin, 49, "%f %f %f", origin[0], origin[1], origin[2])

	DefaultStartPos = origin
	DefaultStart = true

	new file = fopen(tempfile, "wt")
	new vault = fopen(realfile, "rt")

	new data[128], key[64]
	new bool:replaced = false

	while (!feof(vault)) {
		fgets(vault, data, 127)
		parse(data, key, 63)

		if (equal(key, map) && !replaced) {
			fprintf(file, "%s %s^n", map, formatorigin)

			replaced = true
		}
		else {
			fputs(file, data)
		}
	}

	if (!replaced) {
		fprintf(file, "%s %s^n", map, formatorigin)
	}

	fclose(file)
	fclose(vault)

	delete_file(realfile)
	while (!rename_file(tempfile, realfile, 1)) {}
}

stock db_print_config(id, const msg[]) {
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, id);
	write_byte(id);
	write_string(msg);
	message_end();
}

stock db_remplace_colors(message[], len) {
	replace_all(message, len, "!g", "^x04")
	replace_all(message, len, "!t", "^x03")
	replace_all(message, len, "!y", "^x01")
}

stock db_hud_message(id, const message[], {Float,Sql,Result,_}:...) {
	static msg[192], colors[12], r[4], g[4], b[4];
	vformat(msg, 191, message, 3);

	get_pcvar_string(db_hud_color, colors, 11)
	parse(colors, r, 3, g, 3, b, 4)

	set_hudmessage(str_to_num(r), str_to_num(g), str_to_num(b), -1.0, 0.90, 0, 0.0, 2.0, 0.0, 1.0, -1);
	ShowSyncHudMsg(id, hud_message, msg);
}

stock db_register_saycmd(const saycommand[], const function[], flags) {
	new temp[64]
	formatex(temp, 63, "say /%s", saycommand)
	register_clcmd(temp, function, flags)
	formatex(temp, 63, "say .%s", saycommand)
	register_clcmd(temp, function, flags)
	formatex(temp, 63, "say_team /%s", saycommand)
	register_clcmd(temp, function, flags)
	formatex(temp, 63, "say_team .%s", saycommand)
	register_clcmd(temp, function, flags)
}

stock get_configsdir(name[],len) {
	return get_localinfo("amxx_configsdir",name,len);
}

public GroundWeapon_Touch(iWeapon, id) {
	if (is_user_alive(id) && timer_started[id] && get_pcvar_num(db_pick_weapons) == 0)
		return HAM_SUPERCEDE

	return HAM_IGNORED
}

// Save positions

public SavePos(id) {

	new authid[33];
	get_user_authid(id, authid, 32)
	if(get_pcvar_num(db_save_pos) == 0) {
		return PLUGIN_HANDLED
	}

	if(equal(authid, "VALVE_ID_LAN") || equal(authid, "STEAM_ID_LAN") || strlen(authid) > 18) {
		ColorChat (id, GREEN, "%s^x01 %L", prefix, id, "DB_NO_STEAM")

		return PLUGIN_HANDLED
	}

	if (! (pev (id, pev_flags) & FL_ONGROUND2 )) {

		return PLUGIN_HANDLED
	}

	if(!timer_started[id]) {
		return PLUGIN_HANDLED
	}

	if(Verif(id,1)) {
		ColorChat(id, GREEN, "%s^x01 %L", prefix, id, "DB_SAVEPOS_ALREADY")
		savepos_menu(id)
		return PLUGIN_HANDLED
	}

	new Float:origin[3], scout
	pev(id, pev_origin, origin)
	new Float:Time,check,gocheck

	check=checknumbers[id]
	gocheck=gochecknumbers[id]
	ColorChat(id, GREEN, "%s^x01 %L", prefix, id, "DB_SAVEPOS")
	db_savepos(id, Time, check, gocheck, origin, scout)
	reset_checkpoints(id)

	return PLUGIN_HANDLED
}

public GoPos(id) {
	remove_hook(id)
	if(Verif(id,0)) {
		set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0})
		set_pev(id, pev_flags, pev(id, pev_flags) | FL_DUCKING)
		set_pev(id, pev_origin, SavedOrigins[id])
	}

	checknumbers[id]=SavedChecks[id]
	gochecknumbers[id]=SavedGoChecks[id]+((get_pcvar_num(db_save_pos_gochecks)>0) ? 1 : 0)
	CheckPoint(id)
	CheckPoint(id)
	timer_started[id]=true
}

public Verif(id, action) {
	new realfile[128], tempfile[128], authid[32], map[64]
	new bool:exist = false
	get_mapname(map, 63)
	get_user_authid(id, authid, 31)
	formatex(realfile, 127, "%s/%s.ini", SavePosDir, map)
	formatex(tempfile, 127, "%s/temp.ini", SavePosDir)

	if (!file_exists(realfile))
		return 0

	new file = fopen(tempfile, "wt")
	new vault = fopen(realfile, "rt")
	new data[150], sid[32], time[25], checks[5], gochecks[5], x[25], y[25], z[25], scout[5]
	while (!feof(vault)) {
		fgets(vault, data, 149)
		parse(data, sid, 31, time, 24, checks, 4, gochecks, 4, x, 24, y, 24, z, 24, scout, 4)

		if (equal(sid, authid) && !exist) { // ma aflu in fisier?
			if(action == 1)
				fputs(file, data)
			exist= true
			SavedChecks[id] = str_to_num(checks)
			SavedGoChecks[id] = str_to_num(gochecks)
			SavedTime[id] = str_to_float(time)
			SavedOrigins[id][0]=str_to_num(x)
			SavedOrigins[id][1]=str_to_num(y)
			SavedOrigins[id][2]=str_to_num(z)
		}
		else {
			fputs(file, data)
		}
	}

	fclose(file)
	fclose(vault)

	delete_file(realfile)
	if(file_size(tempfile) == 0)
		delete_file(tempfile)
	else
		while (!rename_file(tempfile, realfile, 1)) {}


	if(!exist)
		return 0

	return 1
}
public db_savepos (id, Float:time, checkpoints, gochecks, Float:origin[3], scout) {
	new realfile[128], formatorigin[128], map[64], authid[32]
	get_mapname(map, 63)
	get_user_authid(id, authid, 31)
	formatex(realfile, 127, "%s/%s.ini", SavePosDir, map)
	formatex(formatorigin, 127, "%s %f %d %d %d %d %d %d", authid, time, checkpoints, gochecks, origin[0], origin[1], origin[2], scout)

	new vault = fopen(realfile, "rt+")
	write_file(realfile, formatorigin) // La sfarsit adaug datele mele

	fclose(vault)
}


// Events / Forwards

public client_disconnected(id) {
	checknumbers[id] = 0
	gochecknumbers[id] = 0
	firstspawn[id] = true
	remove_hook(id)
}

public client_putinserver(id) {
	checknumbers[id] = 0
	gochecknumbers[id] = 0
	firstspawn[id] = true
	remove_hook(id)
}


// Menu

public db_menu(id) {

	new menu = menu_create("\rdb: Treinar Trick^n", "MenuHandler")

	new msgcheck[64], msggocheck[64]
	formatex(msgcheck, 63, "Salvar Posição - \y#%i", checknumbers[id])
	formatex(msggocheck, 63, "Teleportar - \y#%i ^n", gochecknumbers[id])

	menu_additem(menu, msgcheck, "0")
	menu_additem(menu, msggocheck, "1")
	menu_additem(menu, "Start", "2")
	menu_additem(menu, "Resetar Contagem^n^n", "3")

	menu_additem(menu, " \y< Voltar", "4")


	menu_setprop(menu, MPROP_EXITNAME, " \rSair [x]")
	menu_display(id, menu, 0)
	return PLUGIN_HANDLED
}

public MenuHandler(id, menu, item) {
	if (item == MENU_EXIT) {
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	switch(item) {
		case 0:{
			CheckPoint(id)
			db_menu(id)
		} case 1: {
			GoCheck(id)
			db_menu(id)
		} case 2: {
			goStart(id)
			db_menu(id)
		} case 3: {
			reset_checkpoints(id)
			db_menu(id)
		} case 4: {
			client_cmd(id, "cmd_menugeral")
		}
	}

	return PLUGIN_HANDLED
}

public savepos_menu(id) {
	new menu = menu_create("SavePos Menu", "SavePosHandler")

	menu_additem (menu, "Reload previous run", "1")
	menu_additem (menu, "Start a new run", "2")

	menu_display(id, menu, 0)
	return PLUGIN_HANDLED
}

public SavePosHandler(id, menu, item) {

	switch(item) {
		case 0: {
			GoPos(id)
		} case 1: {
			Verif(id,0)
		}
	}
	return PLUGIN_HANDLED
}