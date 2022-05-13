#include <amxmodx>
#define CC_COLORS_TYPE CC_COLORS_SHORT
#include <cromchat>
#include <cstrike>
#include <hamsandwich>
#include <fun>

#define PLUGIN_VERSION "1.2"

enum _:Cvars {
	gospec_spec_flag,
	gospec_change_flag,
	gospec_respawn
}

new g_eCvars[Cvars]
new CsTeams:g_iOldTeam[33]
new name[33]

public plugin_init() {
	register_plugin("db: Go Spec", PLUGIN_VERSION, "-LeQuiM-")
	register_cvar("@CRXGoSpec", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED)
	register_dictionary("GoSpec.txt")

	register_clcmd("say /spec", "GoSpec")
	register_clcmd("say /voltar", "GoBack")
	register_clcmd("say /ct", "SwitchCT")
	register_clcmd("say /tr", "SwitchTR")

	register_concmd("cmd_spec", "GoSpec")
	register_concmd("cmd_voltar", "GoBack")
	register_concmd("cmd_ct", "SwitchCT")
	register_concmd("cmd_tr", "SwitchTR")

	g_eCvars[gospec_respawn] = register_cvar("gospec_respawn", "0")
	// CC_SetPrefix("!gdb-info:")
}

public plugin_cfg() {
	new szFlag[2]
	get_pcvar_string(g_eCvars[gospec_spec_flag], szFlag, charsmax(szFlag))
	get_pcvar_string(g_eCvars[gospec_change_flag], szFlag, charsmax(szFlag))
}

public GoSpec(id) {
	new CsTeams:iTeam = cs_get_user_team(id);
	get_user_name(id, name, 32);
	if(iTeam == CS_TEAM_SPECTATOR)
		client_print_color(id, print_chat, "!rdb-info: !r{!nVocê já está de !wSPEC!r}")
	else {
		g_iOldTeam[id] = iTeam
		cs_set_user_team(id, CS_TEAM_SPECTATOR)
		set_pev(id, pev_solid, SOLID_NOT)
		// set_pev(id, pev_movetype, MOVETYPE_FLY)
		set_pev(id, pev_effects, EF_NODRAW)
		set_pev(id, pev_deadflag, DEAD_DEAD)
		// cs_set_user_deaths(id, cs_get_user_deaths(id) -1)
		client_print_color(0, print_chat, "!gdb-info: !w%s !nmudou para !wSPEC", name)

		// if(is_user_alive(id))
		// 	user_silentkill(id)
   }
	// return PLUGIN_HANDLED
}

new iPlayers[32], iCT, iT, pl

public GoBack(id) {
	if(cs_get_user_team(id) != CS_TEAM_SPECTATOR)
		client_print_color(id, print_chat, "!rdb-info: !r{!nApenas quem está SPEC !npode usar '/voltar'!r}")
	else {
		get_players(iPlayers, iCT, "e", "CT")
		get_players(iPlayers, iT, "e", "TERRORIST")
		get_players(iPlayers, pl, "a")

		if (g_iOldTeam[id] == CS_TEAM_T) iT++
		else iCT++

		if (iCT - iT >= 0 && iCT - iT <= 1 && iT - iCT >= 0 && iT - iCT <= 1 || pl == 0 ) {
			cs_set_user_team(id, g_iOldTeam[id])
			client_print_color(id, print_chat, "!wdb-info: {!nVocê voltou para seu time anterior!w}")
		}else {
			client_print(0, print_chat, "%i %i", (iCT - iT), (iT - iCT))
			cs_set_user_team(id, iCT > iT ? CS_TEAM_T : CS_TEAM_CT)
			client_print_color(id, print_chat, "!wdb-info: {!nVocê voltou para o time com menos Players!w}")
		}

		if(get_pcvar_num(g_eCvars[gospec_respawn]) || get_cvar_num("mp_forcerespawn") != 0) {
			ExecuteHamB(Ham_CS_RoundRespawn, id)
			give_item(id, "weapon_knife")
			give_item(id, "weapon_usp")
		}
	}
}

public SwitchCT(id) {
   get_players(iPlayers, iCT, "e", "CT")
   get_players(iPlayers, iT, "e", "TERRORIST")

   if (cs_get_user_team(id) == CS_TEAM_CT)
      client_print_color(id, print_chat, "!rdb-info: !r{!nVocê já está no time CT!r}")
   else if (iCT > iT && iT != 0) {
      client_print_color(id, print_chat, "!rdb-info: !r{!nTime CT possui + Players - troca !rnão !nrealizada!r}")
      return PLUGIN_HANDLED
   }else if (is_user_alive(id) && get_user_health(id) < 90 && iCT + iT > 1) {
      client_print_color(id, print_chat, "!rdb-info: !r{!nVocê já perdeu !rHP!n, espere o próximo Round para trocar de Time!r}")
      return PLUGIN_HANDLED
   }else {
		set_pev(id, pev_effects, 0)
		set_pev(id, pev_movetype, MOVETYPE_WALK)
		set_pev(id, pev_deadflag, DEAD_NO)
		set_pev(id, pev_takedamage, DAMAGE_AIM)
		give_item(id,"weapon_knife")
		give_item(id,"weapon_usp")

		get_user_name(id, name, 32)
		client_print_color(0, print_chat, "!gdb-info: !b%s !nmudou para o time !bCT", name)

		if(is_user_alive(id) || get_user_team(id) == 0) {
   		// user_silentkill(id)
   		// cs_set_user_deaths(id, cs_get_user_deaths(id) -1)
			cs_set_user_team(id,CS_TEAM_CT)
			ExecuteHamB(Ham_CS_RoundRespawn, id)
      }
   }
   return PLUGIN_CONTINUE
}

public SwitchTR(id) {
   get_players(iPlayers, iCT, "e", "CT")
   get_players(iPlayers, iT, "e", "TERRORIST")

   if (cs_get_user_team(id) == CS_TEAM_T)
      client_print_color(id, print_chat, "!rdb-info: !r{!nVocê já está no time TR!r}")
   else if (iT > iCT && iCT!= 0) {
      client_print_color(id, print_chat, "!rdb-info: !r{!Time TR possui + Players - troca !rnão !nrealizada!r}");
      return PLUGIN_HANDLED
	}else if (is_user_alive(id) && get_user_health(id) < 90 && iCT + iT > 1) {
      client_print_color(id, print_chat, "!rdb-info: !r{!nVocê já perdeu !rHP!n, espere o próximo Round para trocar de Time!r}")
      return PLUGIN_HANDLED
	}else {
		set_pev(id, pev_effects, 0)
		set_pev(id, pev_movetype, MOVETYPE_WALK)
		set_pev(id, pev_deadflag, DEAD_NO)
		set_pev(id, pev_takedamage, DAMAGE_AIM)
		give_item(id,"weapon_knife")
		give_item(id,"weapon_glock18")

		get_user_name(id, name, 32)
		client_print_color(0, print_chat, "!gdb-info: !r%s !nmudou para o time !rTR", name)
		if(is_user_alive(id) || get_user_team(id) == 0) {
			cs_set_user_team(id, CS_TEAM_T)
			ExecuteHamB(Ham_CS_RoundRespawn, id)
      }
   }
   return PLUGIN_CONTINUE
}
