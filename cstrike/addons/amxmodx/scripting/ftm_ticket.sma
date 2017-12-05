#include <amxmodx>
#include <engine>
#include <ftmod>
#if (AMXX_VERSION_NUM < 183) || defined NO_NATIVE_COLORCHAT
	#include <dhudmessage>
#endif

#pragma ctrlchar		'\'
#pragma semicolon		1

#define MAX_CLIENTS		32
#define TICKET_NUM		1	// Количество размораживания на команду за раунд
#define NEXT_TIME_MESSAGE	3.0	// Задержка

enum
{
	STATUS_ICON_HIDE = 0,
	STATUS_ICON_SHOW,
	STATUS_ICON_FLASH
};

enum _:Sprite_Last
{
	Sprite_None,
	Sprite_Over,
	Sprite_Num
};

enum _:Sprite_Properity
{
	Sprite_Name[ 10 ],
	Sprite_Color[ 3 ]
};

new Sprite_Data[][ Sprite_Properity ] =
{
	{ "number_0", { 0xC8, 0x32, 0x00 } },
	{ "number_1", { 0xFF, 0x64, 0x32 } },
	{ "number_2", { 0xFF, 0x8C, 0x00 } },
	{ "number_3", { 0xC8, 0xC8, 0x00 } },
	{ "number_4", { 0xFF, 0xFF, 0x64 } },
	{ "number_5", { 0xFF, 0xFF, 0x96 } },
	{ "number_6", { 0xCD, 0xAA, 0x50 } },
	{ "number_7", { 0xD2, 0xB4, 0x64 } },
	{ "number_8", { 0xB4, 0xD2, 0x69 } },
	{ "number_9", { 0xC8, 0xDC, 0x8C } }
};

new const TICKET_SPRITE_OVER[]	= "dmg_cold";				// Какую иконку отобразить, заместо количества оставшиеся респаунов больше 9 (По умолчанию: снежок)
new const MODEL_DEATH[]		= "models/ftmod/ticket/death1.mdl";

new g_iTeamIndex[ MAX_CLIENTS + 1],
	g_iSpriteEnt[ MAX_CLIENTS + 1],
	g_iLastIcon[ MAX_CLIENTS + 1];

new g_iTicketNum[ 4 ],
	g_iMaxPlayers,
	g_iStatusIcon;

public plugin_precache()
{
	precache_model(MODEL_DEATH);
}

public plugin_init()
{
	register_plugin
	(
		"[FTMod] Addon: Ticket",
		"1.1",
		"s1lent"
	);

	register_event("ResetHUD", "Event_ResetHUD", "be");

	g_iMaxPlayers = get_maxplayers();
	g_iStatusIcon = get_user_msgid("StatusIcon");

	register_dictionary("ftmod_ticket.txt");
}

public client_disconnect(id)
{
	if (is_user_bot(id) || is_user_hltv(id))
		return;

	UTIL__MakingDeath(id);

	g_iTeamIndex[ id ] = 0;
	g_iLastIcon[ id ] = 0;

	if (is_valid_ent(g_iSpriteEnt[ id ]))
	{
		remove_entity(g_iSpriteEnt[ id ]);
		g_iSpriteEnt[ id ] = 0;
	}
}

public ftm_client_target(id, target, time)
{
	static Float:__flNextMessage[ MAX_CLIENTS + 1] = { 0.0, ... };

	new iTicketNum = g_iTicketNum[ g_iTeamIndex[ id ] ];

	if (iTicketNum > 0)
	{
		return PLUGIN_CONTINUE;
	}

	new Float:flCurrentTime = get_gametime();
	if (flCurrentTime > __flNextMessage[ id ])
	{
		__flNextMessage[ id ] = flCurrentTime + NEXT_TIME_MESSAGE;

		set_dhudmessage(25, 255, 25, -1.0, 0.65, 2, 0.25, 2.0, 0.01, 0.5);
		show_dhudmessage(id, "%L", LANG_PLAYER, "FTM_TICKET_UNFREEZE");
	}

	return PLUGIN_HANDLED;
}

public ftm_round_new()
{
	arrayset(g_iLastIcon, TICKET_NUM, MAX_CLIENTS + 1);
	arrayset(g_iTicketNum, TICKET_NUM, 4);
}

public Event_ResetHUD(const id)
{
	new iTicketNum = g_iTicketNum[ g_iTeamIndex[ id ] ];

	if (iTicketNum < 0)
		iTicketNum = 0;

	if (g_iLastIcon[ id ] != iTicketNum && iTicketNum != TICKET_NUM)
	{
		message_begin(MSG_ONE_UNRELIABLE, g_iStatusIcon, _, id);
		write_byte(STATUS_ICON_HIDE);

		if (iTicketNum >= sizeof(Sprite_Data) - 1)
			write_string(TICKET_SPRITE_OVER);
		else
			write_string(Sprite_Data[ iTicketNum + 1 ][ Sprite_Name ]);
		message_end();
	}

	g_iLastIcon[ id ] = iTicketNum;

	if (iTicketNum > sizeof(Sprite_Data) - 1)
	{
		message_begin(MSG_ONE_UNRELIABLE, g_iStatusIcon, _, id);
		write_byte(STATUS_ICON_SHOW);
		write_string(TICKET_SPRITE_OVER);
		if (g_iTeamIndex[ id ] == 2)
		{
			write_byte(50);
			write_byte(170);
			write_byte(255);
		}
		else
		{
			write_byte(255);
			write_byte(40);
			write_byte(40);
		}
		message_end();
	}
	else
	{
		message_begin(MSG_ONE_UNRELIABLE, g_iStatusIcon, _, id);
		write_byte(STATUS_ICON_SHOW);
		write_string(Sprite_Data[ iTicketNum ][ Sprite_Name ]);
		write_byte(Sprite_Data[ iTicketNum ][ Sprite_Color ][ 0 ]);
		write_byte(Sprite_Data[ iTicketNum ][ Sprite_Color ][ 1 ]);
		write_byte(Sprite_Data[ iTicketNum ][ Sprite_Color ][ 2 ]);
		message_end();
	}
}

public ftm_client_frozen_stuff(id, pCube, pBody, pView)
{
	if (g_iTicketNum[ g_iTeamIndex[ id ] ] < 1)
	{
		ftm_set_spawnlock(id, true);//block next spawning
		ftm_set_stay(id, true);//block auto defrost

		UTIL__MakingDeath(id, pCube, false);
	}
}

public ftm_client_spawn(id, iTeam)
{
	new iTeamOther;
	new iTicketNum = g_iTicketNum[ iTeam ];

	g_iTeamIndex[ id ] = iTeam;

	if (!ftm_get_frozen(id))
	{
		UTIL__MakingDeath(id);
	}

	else if (get_pgame_bool(m_bFirstConnected) && ftm_get_play_round(id) == get_pgame_int(m_iTotalRoundsPlayed))
	{
		iTicketNum = --g_iTicketNum[ iTeam ];

		if (iTicketNum < 0)
			iTicketNum = 0;

		for (new i = 1; i <= g_iMaxPlayers; i++)
		{
			if (!is_user_alive(i) || i == id)
				continue;

			iTeamOther = g_iTeamIndex[ i ];
			if (iTeamOther == iTeam)
			{
				if (g_iLastIcon[ i ] != iTicketNum && iTicketNum != TICKET_NUM && iTicketNum < 10)
				{
					message_begin(MSG_ONE_UNRELIABLE, g_iStatusIcon, _, i);
					write_byte(STATUS_ICON_HIDE);

					if (iTicketNum >= sizeof(Sprite_Data) - 1)
						write_string(TICKET_SPRITE_OVER);
					else
						write_string(Sprite_Data[ iTicketNum + 1 ][ Sprite_Name ]);

					message_end();
				}

				g_iLastIcon[ i ] = iTicketNum;
				if (iTicketNum < sizeof(Sprite_Data))
				{
					message_begin(MSG_ONE_UNRELIABLE, g_iStatusIcon, _, i);
					write_byte(STATUS_ICON_SHOW);
					write_string(Sprite_Data[ iTicketNum ][ Sprite_Name ]);
					write_byte(Sprite_Data[ iTicketNum ][ Sprite_Color ][ 0 ]);
					write_byte(Sprite_Data[ iTicketNum ][ Sprite_Color ][ 1 ]);
					write_byte(Sprite_Data[ iTicketNum ][ Sprite_Color ][ 2 ]);
					message_end();
				}
			}

			if (iTicketNum < 1 && ftm_get_frozen(i) && get_pgame_bool(m_bFirstConnected))
			{
				new pEntCube;

				ftm_defrost_break(i);
				ftm_get_entity_owner(i, pEntCube);

				ftm_set_spawnlock(i, true);
				ftm_set_stay(i, true);

				UTIL__MakingDeath(i, pEntCube, false);
			}
		}
	}
}

stock UTIL__MakingDeath(const id, const dest = 0, bool:bHide = true)
{
	new pEnt = g_iSpriteEnt[ id ];
	if (!is_valid_ent(pEnt))
	{
		if (bHide)
			return;

		pEnt = create_entity("env_sprite");

		if (!pEnt)
			return;

		entity_set_string(pEnt, EV_SZ_classname, "p_death");
		entity_set_float(pEnt, EV_FL_renderamt, 175.0);
		entity_set_int(pEnt, EV_INT_rendermode, kRenderTransAdd);
		entity_set_int(pEnt, EV_INT_movetype, MOVETYPE_FOLLOW);

		entity_set_model(pEnt, MODEL_DEATH);

		g_iSpriteEnt[ id ] = pEnt;
	}
	else
	{
		new iEffect = entity_get_int(pEnt, EV_INT_effects);
		if (bHide)
		{
			if (iEffect & EF_NODRAW)
				return;

			iEffect |= EF_NODRAW;
		}
		else
			iEffect &= ~EF_NODRAW;

		entity_set_int(pEnt, EV_INT_effects, iEffect);
	}

	entity_set_edict(pEnt, EV_ENT_aiment, dest);
	entity_set_int(pEnt, EV_INT_skin, !(g_iTeamIndex[ id ] - 1));
}
