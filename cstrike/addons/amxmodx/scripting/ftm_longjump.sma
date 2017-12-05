#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <ftmod>
#include <reapi>


#define PLAYER_SUPERJUMP	7
#define ACT_LEAP		8



new bool:g_bHasLJ[MAX_CLIENTS + 1];
new bool:g_bSuperJump[MAX_CLIENTS + 1];
new g_ClientLJ[MAX_CLIENTS + 1];

public plugin_precache()
{
	precache_model("models/p_longjump.mdl");
}

public plugin_init()
{
	register_plugin("[FTM] LongJump Enabler", "1.0", "ConnorMcLeod/KORD_12.7/serfreeman1337");

	RegisterHam(Ham_Player_Jump, "player", "CBasePlayer__Jump");
	RegisterHam(Ham_Player_Duck, "player", "CBasePlayer__Duck");
	RegisterHam(Ham_Killed, "player", "CBasePlayer__Killed", 1);

	register_event("ItemPickup", "CBasePlayerItem__AddToPlayer", "b", "1&item_longjump", 1);
}

public client_disconnected(id)
{
	if(is_user_bot(id) || is_user_hltv(id))
		return;

	new pEnt = g_ClientLJ[id];
	if(pev_valid(pEnt))
	{
		set_pev(pEnt, pev_aiment, id);
		set_pev(pEnt, pev_rendermode, kRenderTransAlpha);
	}

	g_bSuperJump[id] = false;
	g_bHasLJ[id] = false;
}

public client_putinserver(id)
{
	if(is_user_bot(id) || is_user_hltv(id))
		return;

	new pEnt = g_ClientLJ[id];
	if(pev_valid(pEnt))
		set_pev(pEnt, pev_rendermode, kRenderTransAlpha);

	g_bSuperJump[id] = false;
	g_bHasLJ[id] = false;
}

/*
* for FrozenTag Mod
*/
//public ftm_round_end(RoundControlWin:iTeamWin)
//{
//	arrayset(g_bHasLJ, 0, 33);
//}

public ftm_client_unfrozen_post(id, rescued)
{
	new pEnt = g_ClientLJ[id];
	if (g_bHasLJ[id] && pev_valid(pEnt))
	{
		set_pev(pEnt, pev_aiment, id);
		set_pev(pEnt, pev_rendermode, kRenderNormal);

		set_member(id, m_fLongJump, 1);
		UTIL__UpdateIconLJ(id, 1, {255, 127, 0});
	}
}

public ftm_client_frozen_stuff(id, pCube, pBody, pView)
{
	new pEnt = g_ClientLJ[id];
	if (g_bHasLJ[id] && pev_valid(pEnt))
	{
		set_pev(pEnt, pev_rendermode, kRenderTransAlpha);
		//set_pev(pEnt, pev_aiment, pBody);
	}
}

public CBasePlayer__Killed(const victim, const killer, const shouldgib)
{
	if(!is_user_connected(victim))
		return;

	new pEnt = g_ClientLJ[victim];
	if(pev_valid(pEnt))
	{
		UTIL__UpdateIconLJ(victim);
		if (!ftm_get_frozen(victim))
			set_pev(pEnt, pev_rendermode, kRenderTransAlpha);
	}
}

public CBasePlayerItem__AddToPlayer(const id)
{
	if(pev_valid(id) != 2 || !get_member(id, m_fLongJump))
		return;

	new pEnt = g_ClientLJ[id];
	if(pev_valid(pEnt))
		set_entvar(pEnt, var_rendermode, kRenderNormal);

	else
	{
		static iszAllocInfoTarget = 0;
		if (iszAllocInfoTarget || (iszAllocInfoTarget = engfunc(EngFunc_AllocString, "info_target")))
		{
			pEnt = engfunc(EngFunc_CreateNamedEntity, iszAllocInfoTarget);
			if(pEnt)
			{
				set_pev(pEnt, pev_classname, "p_longjump");
				set_pev(pEnt, pev_movetype, MOVETYPE_FOLLOW);
				set_pev(pEnt, pev_aiment, id);

				engfunc(EngFunc_SetModel, pEnt, "models/p_longjump.mdl");
			}
			g_ClientLJ[id] = pEnt;
		}
	}

	g_bHasLJ[id] = true;
	UTIL__UpdateIconLJ(id, 1, {255, 127, 0});
}

public CBasePlayer__Duck(const id)
{
	if(g_bSuperJump[id])
	{
		g_bSuperJump[id] = false;
		return HAM_SUPERCEDE;
	}
	return HAM_IGNORED;
}

public CBasePlayer__Jump(const id)
{
	if(ftm_get_frozen(id) || !is_user_alive(id))
		return HAM_IGNORED;

	new iFlags = pev(id, pev_flags);
	if((iFlags & FL_WATERJUMP) || pev(id, pev_waterlevel) >= 2)
	{
		return HAM_IGNORED;
	}

	new afButtonPressed = get_member(id, m_afButtonPressed);
	if(!(afButtonPressed & IN_JUMP) || !(iFlags & FL_ONGROUND))
	{
		return HAM_IGNORED;
	}

	new Float:fVecTemp[3];
	if((pev(id, pev_bInDuck) || iFlags & FL_DUCKING) && get_member(id, m_fLongJump) && pev(id, pev_button) & IN_DUCK && pev(id, pev_flDuckTime))
	{
		pev(id, pev_velocity, fVecTemp);

		if(vector_length(fVecTemp) > 50.0)
		{
			pev(id, pev_punchangle, fVecTemp);
			fVecTemp[0] = -5.0;
			set_pev(id, pev_punchangle, fVecTemp);

			global_get(glb_v_forward, fVecTemp);

			fVecTemp[0] *= 560.0;
			fVecTemp[1] *= 560.0;
			fVecTemp[2] = 299.33259094191531084669989858532;

			set_pev(id, pev_velocity, fVecTemp);

			set_member(id, m_Activity, ACT_LEAP);
			set_member(id, m_IdealActivity, ACT_LEAP);

			set_pev(id, pev_oldbuttons, pev(id, pev_oldbuttons) | IN_JUMP);

			set_pev(id, pev_gaitsequence, PLAYER_SUPERJUMP);
			set_pev(id, pev_frame, 0.0);

			set_member(id, m_afButtonPressed, afButtonPressed & ~IN_JUMP);

			g_bSuperJump[id] = true;

			return HAM_SUPERCEDE;
		}
	}
	return HAM_IGNORED;
}

stock UTIL__UpdateIconLJ(const id, const bShow = 0, const iPal[] = {0,0,0})
{
	static __msgidStatusIcon = 0;
	if (__msgidStatusIcon || (__msgidStatusIcon = get_user_msgid("StatusIcon")))
	{
		message_begin(MSG_ONE_UNRELIABLE, __msgidStatusIcon, _, id);
		write_byte(bShow);
		write_string("item_longjump");
		write_byte(iPal[0]);
		write_byte(iPal[1]);
		write_byte(iPal[2]);
		message_end();
	}
}