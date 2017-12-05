#include <amxmodx>
#include <engine>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>


#if (AMXX_VERSION_NUM < 183) || defined NO_NATIVE_COLORCHAT
	#include <colorchat>
	#include <dhudmessage>

	#define set_ent_rendering set_rendering
	#define OBS_NONE 0
	#define OBS_CHASE_FREE 2
#else
	#define DontChange print_team_default
	#define Grey print_team_grey
	#define Red print_team_red
	#define Blue print_team_blue
#endif

#define DEBUG

#pragma ctrlchar			'\'
#pragma semicolon			1
#define NULL				0

#define PLUGIN				"FrozenTag Mod"
#define VERSION				"2.96-r beta"
#define AUTHOR				"s1lent"

/*
* Options Main
*/
#define CSDM				// Использование CSDM, если не используете CSDM закомментируйте
#define FROZEN_MOD_API			// Использование API

#define FROZEN_CUBE_MOBILE_OBJECT	// Куб - передвижной объект (имеет физику)
#define FROZEN_CUBE_PUSHABLE		// Куб можно толкать
#define FROZEN_CUBE_DAMAGE		// Кубу можно наносить урон (оружием)
#define FROZEN_BARTIME			// Использовать бартайм при размораживания
#define FROZEN_STATUS_TEXT		// Использовать StatusText для куба
#define FROZEN_STATUS_TEXT_ENEMIES	// Показывать StatusText у противников
#define FROZEN_STATUS_TEXT_WHO_KILLER	// Показывать в StatusText, после заморозки - кто убил
//#define WAIT_TO_NEXT_ROUND		// Заставлять новых игроков ждать окончания раунда
					// если они не успели зайти в игру за время ROUND_WAIT_NEXT от начала раунда

#define INFO_VGUI_DISABLED		// Информировать игроков - выключить VGUI опцию
//#define SOUND_HELP_AUTO		// Звать автоматически на помощь (звук Help Me) или вручную на USE

/*
* Options Effects
*/
//#define SPARK_EFFECTS			// Искры от куба при стрельбе по нему
//#define TELEPORT_UNSTUCK_EFFECTS	// Эффект при unstuck (звук + сообщение)

/*
* Option Other
*/

#define SBAR_STRING_SIZE		128

#define MAX_CLIENTS			32	// Максимальное число игроков на сервере
#define MAX_EXTRA_ITEM			40	// Максимальное число 
#define MAX_ITEM_ON_PAGE		8	// Максимальное количество item на 1 странице

#define MAX_RADIUS_USE			64.0	// Максимальный радиус поиска замороженного игрока
#define MAX_CHECK_RADIUS_VALID		128.0	// Максимальный радиус для проверки валидности координат игрока (по аналогии unstuck)

#define GIVE_HEALTH_COUNT		1.0	// Сколько давать доп. health за разморозку
#define MULTIPLY_MONEY			2	// Множитель денег, с каждой секундой разморозки деньги умножаются на MULTIPLY_MONEY
#define MULTIDIV_DAMAGE			50.0	// Коэффициент деления наносимого урона кубу

#define ROUND_WAIT_NEXT			1.0	// Сколько пройдет времени от начала раунда
						// после чего новые зашедшие игроки будут ждать нового раунда

#define HELP_USE_TIME   		15.0	// Время через которое можно повторно звать на помощь в ручном режиме
#define ALERT_TIME			30.0	// Время через которое будет повторное сообщение о помощи своего товарища
#define HELP_TIME			12.0	// Время через которое будет повторное воспроизведение звука "Help me"
#define DISTANCE_ALERT			300.0	// Какая должна быть дистанция (в юнитах/в дюймах) между игроком и замороженным, для оповещение сообщением о помощи
#define DISTANCE_HELP_ME		300.0	// Какая должна быть дистанция (в юнитах/в дюймах) между игроком и замороженным, для воспроизведения звука (Help Me)

#define MAX_HEALTH			150.0	// Предел здоровья которое может набрать игрок "бонусами"
#define DEFAULT_HEAHLT			100.0	// Стандартное количество HP
#define TIME_HAND_DEFORSTING		5.0	// Время за которое игрок должен разморозить куб (от начала до конца)
#define TIME_DEFORSTING			60.0	// Время за которое игрок сам растает

#define ROUND_MONEY_WIN			1500	// Сколько денег получит выигрышная команда
#define ROUND_MONEY_LOSE		500	// Сколько денег получит проигрышная команда

#define MONEY_KILL			400				// Сколько денег получит за убийство (заморозка)
#define CUBE_HEALTH			100.0 + MIN_POOL_AMOUNT		// HP куба (не трогать MIN_POOL_AMOUNT)
#define COLOR_DHUD_MESSAGE_USE		25, 255, 25			// Цвет сообщения DHUD

#define TIME_PROTECT_SPAWN		1.5	// Время защиты после разморозки
#define UPDATE_HUD_MONEY		0.1	// Частота обновления денег во время разморозки
#define VEC_VIEW			17	// Стандартный view_ofs

/*
* Settings fog
*/
#define FOG_DENSITY			"0.0005"	// Плотность тумана
#define FOG_COLOR			"128 128 128"	// Цвет RGB тумана

/*
* Resource
*/
#define SPRITE_SNOW_CT			"sprites/ftmod/snowct.spr"		// Снежинки от куба CT
#define SPRITE_TRAIL_CT			"sprites/ftmod/trailct.spr"		// Следы снежинок от куба CT

#define SPRITE_SNOW_T			"sprites/ftmod/snowt.spr"		// Снежинки от куба TT
#define SPRITE_TRAIL_T			"sprites/ftmod/trailt.spr"		// Следы снежинок от куба TT

#define FROZEN_CRACK			"sprites/fast_wallpuff1.spr"		// Осколки куба после разморозки

new const PREFIX[]			= "\1[\4FTM\1]";																// Префикс у чат сообщений

new const SPRITE_RADIO[]		= "sprites/radio.spr";
new const SOUND_FROZEN[]		= "impalehit.wav";			// Звук при заморозке				
new const SOUND_FROZEN_BREAK[]		= "impalelaunch1.wav";			// Звук при разморозке
new const SOUND_HELP_ME[][]		=					// Просьба о помощи
{
	"ftmod/helpme1.wav",
	"ftmod/helpme2.wav",
	"ftmod/hey1.wav",
	"ftmod/hey2.wav",
	"ftmod/overhere1.wav",
	"ftmod/overhere2.wav"
};

new const FROZEN_CUBE[]			= "models/ftmod/icecube_mod.mdl";	// Модель куба

/*
* Defines
*/

#define INFOTARGET_UID			1493276213
#define INFOCUBE_UID			1248121937

#define MIN_POOL_AMOUNT			20.0	// not touch (Минимальный порог прозрачности для полного разморожения)
#define INTERP_TIME_DEFAULT		0.01	// not touch
						// 1 - 0.01 sec.
						// 10 - 0.1 sec.

#define CLASS_PLAYER			2

#define Vector(%0,%1,%2)		Float:{ %0.0, %1.0, %2.0 }

#define printf(%0)			server_print(%0)
#define memset(%0,%1,%2)		arrayset(%0, %1, %2)

#define EMIT_SOUND(%0,%1,%2,%3,%4)	emit_sound(%0, %1, %2, %3, %4, 0, PITCH_NORM)

#define MESSAGE_BEGIN_F(%0,%1,%2,%3)	engfunc(EngFunc_MessageBegin, %0, %1, %2, %3)
#define WRITE_COORD_F(%0)		engfunc(EngFunc_WriteCoord, %0)

#define EMESSAGE_BEGIN(%0,%1,%2,%3)	emessage_begin(%0, %1, %2, %3)
#define EWRITE_SHORT(%0)		ewrite_short(%0)
#define EMESSAGE_END()			emessage_end()

#define MESSAGE_BEGIN(%0,%1,%2,%3)	message_begin(%0, %1, %2, %3)
#define WRITE_SHORT(%0)			write_short(%0)
#define WRITE_BYTE(%0)			write_byte(%0)
#define WRITE_STRING(%0)		write_string(%0)
#define WRITE_LONG(%0)			write_long(%0)
#define WRITE_COORD(%0)			write_coord(%0)
#define MESSAGE_END()			message_end()

#define CREATE_NAMED_ENTITY(%0)		create_entity(%0)
#define FIND_ENTITY_IN_SPHERE(%0,%1,%2)	find_ent_in_sphere(%0, %1, %2)
#define FIND_ENTITY_BY_CLASSNAME(%0,%1)	find_ent_by_class(%0, %1)

#define MAKE_VECTORS(%0)		engfunc(EngFunc_MakeVectors, %0)
#define SET_MODEL(%0,%1)		entity_set_model(%0, %1)

#define SET_SIZE(%0,%1,%2)		entity_set_size(%0, %1, %2)
#define SET_VIEW(%0,%1)			attach_view(%0, %1)
#define SET_ORIGIN(%0,%1)		entity_set_origin(%0, %1)

#define VectorCompare(%0,%1)		(%0[ 0 ] == %1[ 0 ] && %0[ 1 ] == %1[ 1 ] && %0[ 2 ] == %1[ 2 ])
#define VectorCopy(%0,%1)		(%1[ 0 ] = %0[ 0 ],%1[ 1 ] = %0[ 1 ],%1[ 2 ] = %0[ 2 ])
#define VectorSubScalar(%0,%1,%2,%3)	(%2[ 0 ] = %0[ 0 ] - (%1[ 0 ] * %3),%2[ 1 ] = %0[ 1 ] - (%1[ 1 ] * %3),%2[ 2 ] = %0[ 2 ] - (%1[ 2 ] * %3))

#define SPEED_BARTIME			((CUBE_HEALTH - MIN_POOL_AMOUNT) / TIME_HAND_DEFORSTING) + 0.75
#define SPEED_DEFORST			((CUBE_HEALTH - MIN_POOL_AMOUNT) / TIME_DEFORSTING)


const PDATA_SAFE = 2;

enum EXTRA_TEAM (<<= 1)
{
	ITEM_TEAM_ANY = (1 << 0),

	ITEM_TEAM_T,
	ITEM_TEAM_CT
};



enum JOIN_STATE
{
	JOINED = 0,
	JOIN_TO_GAME,
	JOIN_TO_BACK_GAME,
	JOIN_IN_TO_SPEC,
	JOIN_IN_TO_GAME,
	JOIN_LOCK_SPAWN
};

enum HANDLE_BUTTON
{
	BUTTON_MOUSE1 = 0,
	BUTTON_MOUSE2
};

enum
{
	DATA_CUBE_OWNER = 3,	// EV_INT_iuser1
	DATA_CUBE_MODE,		// EV_INT_iuser2
	DATA_CUBE_TEAMID,	// EV_INT_iuser3
	DATA_CUBE_RESERVE,	// EV_INT_iuser4

	DATA_CUBE_SMALL = 17,	// EV_INT_body
	DATA_CUBE_ORIGIN = 19,	// EV_VEC_vuser1
};

enum
{
	RETURN_BACK_GAME = 1,
	RETURN_LOCK_SPAWN
};

enum
{
	MODE_NONE = 0,
	MODE_CRACK,
	MODE_SPAWN
};

enum
{
	SKIN_ICECUB_CT = 0,
	SKIN_ICECUB_T,

	SKIN_ICECUB_CT_CRACK,
	SKIN_ICECUB_T_CRACK
};

enum
{
	SBAR_TARGETTYPE_TEAMMATE = 1,
	SBAR_TARGETTYPE_ENEMY,
	SBAR_TARGETTYPE_HOSTAGE
};

enum _:MESSAGE_USER
{
	Message_BarTime,
	Message_DeathMsg,
	Message_HostageK,
	Message_ScoreInfo,
	Message_HostagePos,
	Message_ScreenFade,
	Message_ScoreAttrib,
	Message_RoundTime,
	Message_Money,
	Message_StatusText,
	Message_StatusValue,
	Message_HudTextArgs,
	Message_HideWeapon,
	Message_StatusIcon
};

enum _:INFO_HAM_HOOK
{
	HamHook:InfoHook_RoundRespawn,
	HamHook:InfoHook_TraceAttack,
	HamHook:InfoHook_ObjectCaps
};

enum _:INFO_STRUCT
{
// integer
	JOIN_STATE:Player_State,
	Player_RoundPlayed,
	Player_Money,
	Player_Target,
	Player_ShopPos,
	Player_ViewModel,
	CsTeams:Player_Teamid,
	Player_Rescuerid,
// array
	Player_Ip[ 16 ],
	Player_Authid[ 26 ],
	Player_Itemid[ MAX_EXTRA_ITEM ],
// float
	Float:Player_WaitHelp,
	Float:Player_WaitAlert,
	Float:Player_ProtectTime,
	Float:Player_AddHealth,
	Float:Player_ButtonNext,
	Float:Player_InterpTime,
	Float:Player_LastUpdate,
// booleans
	bool:Player_SpawnLock,
	bool:Player_Stay,
	bool:Player_Alive,
	bool:Player_Frozen,
	bool:Player_Ingame,
	bool:Player_VGUI,
// ent
// don't change the numeration
	Player_EntView,
	Player_EntCube,
	Player_EntBody,
	Player_EntWeapon
};

enum _:INFO_SBAR
{
	SBAR_ID_TARGETTYPE = 1,
	SBAR_ID_TARGETNAME,
	SBAR_ID_TARGETHEALTH,
	SBAR_END
};

enum INFO_STATS
{
	InfoStats_Frozen = 0,
	InfoStats_Rescued
};

enum INFO_STOREBUFFER
{
	Trie:InfoStore_RoundPlayed = 0,
	Trie:InfoStore_Origin,
	Trie:InfoStore_SpawnLock,
	Trie:InfoStore_Teamid,
	Trie:InfoStore_Stay
};

enum _:AnimationProperty
{
	Animation_Number,
	Float:Animation_Frame
};

new const AnimationsData[][ AnimationProperty ] =
{
	{ 59, 6.0 }, // duck

	{ 21, 11.0 },
	{ 57, 9.0 },
	{ 57, 6.0 }
};

static const Float:vecZero[] =
{
	0.0, 0.0, 0.0
};

/*
* Globals ...
*/

#if defined DEBUG
new g_pCvarDebug;
#endif // DEBUG

new Float:g_flLastOrigin[ MAX_CLIENTS + 1 ][ 3 ],
	Float:g_flLastAngles[ MAX_CLIENTS + 1 ][ 3 ];

new g_pPlayerInfo[ MAX_CLIENTS + 1 ][ INFO_STRUCT ];
new Trie:g_gpSaveRestoreCache[ INFO_STOREBUFFER ];

new g_iUserMsg[ MESSAGE_USER ],
	g_iStats[ CsTeams ][ INFO_STATS ],
	g_iMenuShopId = -1;

new HamHook:g_pHookTable[ INFO_HAM_HOOK ];

new g_iMaxPlayers,
	g_iModelGlass,
	g_iSpriteCrack,
	g_iSpriteRadio;

new g_iSprSnowCT,
	g_iSprTrailCT,
	g_iSprSnowT,
	g_iSprTrailT;

#if defined FROZEN_STATUS_TEXT

new __newSBarState[ SBAR_END ],
	__izSBarState[ MAX_CLIENTS + 1 ][ SBAR_END ],
	__SbarString[ MAX_CLIENTS + 1 ][ SBAR_STRING_SIZE ];

#endif // FROZEN_STATUS_TEXT

#if defined FROZEN_MOD_API

new Array:g_pExtraItemName,
	Array:g_pExtraItemCost,
	Array:g_pExtraItemTeam,
	g_iExtraItemNum;

#endif // FROZEN_MOD_API

enum INFO_FORWARDS
{
	CLIENT_FROZEN,
	CLIENT_FROZEN_POST,
	CLIENT_FROZEN_STUFF,

	CLIENT_UNFROZEN,
	CLIENT_UNFROZEN_POST,

	CLIENT_SPAWN,
	CLIENT_SPAWN_PRE,
	CLIENT_SPAWN_POST,

	CLIENT_RESPAWN,

	CLIENT_FIND_TARGET,
	CLIENT_FIND_OBS_TARGET,
	CLIENT_UNFREEZE,

	SERVER_ROUND_END,
	SERVER_ROUND_NEW,
	SERVER_ROUND_RESTART,
	SERVER_CONDITIONS,

	SHOP_ITEM_SELECTED
};

/*
* Forwards
*/
new g_pForwards[ INFO_FORWARDS ];
static g_pResultDummy = 0;

public plugin_precache()
{
	precache_model(FROZEN_CUBE);
	precache_sound(SOUND_FROZEN);
	precache_sound(SOUND_FROZEN_BREAK);

	for (new i; i < sizeof(SOUND_HELP_ME); i++)
		precache_sound(SOUND_HELP_ME[i]);

	g_iSpriteRadio = precache_model(SPRITE_RADIO);
	g_iSpriteCrack = precache_model(FROZEN_CRACK);

	g_iSprSnowCT = precache_model(SPRITE_SNOW_CT);
	g_iSprTrailCT = precache_model(SPRITE_TRAIL_CT);

	g_iSprSnowT = precache_model(SPRITE_SNOW_T);
	g_iSprTrailT = precache_model(SPRITE_TRAIL_T);

	g_iModelGlass = precache_model("models/glassgibs.mdl");

	/*
	* Initialization weather
	*/
	UTIL__CreateWeather();
}

#if defined CSDM

forward csdm_PostDeath(killer, victim, headshot, const weapon[]);

public csdm_PostDeath(killer, victim, headshot, const weapon[])
{
	if (get_member_game(m_iRoundWinStatus) == 0)
		g_pPlayerInfo[ victim ][ Player_SpawnLock ] = true;

	/*
	* Block next respawn CSDM
	*/
	return 1;
}

#endif // CSDM

public plugin_init()
{
	register_plugin
	(
		PLUGIN,
		VERSION,
		AUTHOR
	);

	new const szCmdShop[][] =
	{
		"say /shop", "say /shopmenu", "cl_autobuy", "shop", "shopmenu", "buy", "nightvision",
		"usp", "glock", "deagle", "p228", "elites", "fn57", "m3", "xm1014", "mp5", "tmp", "p90",
		"mac10", "ump45", "ak47", "galil", "famas", "sg552", "m4a1", "aug", "scout", "awp", "g3sg1",
		"sg550", "m249", "vest", "vesthelm", "flash", "hegren", "sgren", "defuser", "nvgs", "shield",
		"primammo", "secammo", "km45", "9x19mm", "nighthawk", "228compact", "fiveseven", "12gauge", "autoshotgun",
		"mp", "c90", "cv47", "defender", "clarion", "krieg552", "bullpup", "magnum", "d3au1", "krieg550",
		"buy", "buyequip", "cl_autobuy", "cl_rebuy", "cl_setautobuy", "cl_setrebuy", "buyammo1", "buyammo2"
	};

	for (new i; i < sizeof(szCmdShop); i++)
		register_clcmd(szCmdShop[ i ], "CMD_ShopMenu");

	register_cvar("ftmod_version", VERSION, FCVAR_SERVER | FCVAR_SPONLY);

	register_clcmd("client_buy_open", "CMD_ShopVGUIMenu");

	register_impulse(100, "CMD_FlashLight");
	register_think("CFTMod__Informer", "CFTMod__InformerThink");
	register_think("info_icecube", "CPointEntity__IceCubeThink");

	register_forward(FM_ClientKill, "ClientKill");
	register_forward(FM_ClientDisconnect, "ClientDisconnect_Post", 1);

#if defined FROZEN_STATUS_TEXT
	register_forward(FM_TraceLine, "TraceLine", 1);
#endif // FROZEN_STATUS_TEXT

	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0");
	register_event("TextMsg", "Event_RestartRound", "a", "2=#Game_Commencing", "2=#Game_will_restart_in");
	register_event("ResetHUD", "Event_ResetHUD", "be");

	RegisterHam(Ham_Killed, "player", "CBasePlayer__Killed");
	RegisterHam(Ham_TakeDamage, "info_target", "CBaseEntity__TakeDamage");

#if defined FROZEN_CUBE_PUSHABLE
	register_touch("info_icecube", "*", "CPointEntity__IcecubeTouch");
#endif // FROZEN_CUBE_PUSHABLE

#if defined SPARK_EFFECTS
	RegisterHam(Ham_TraceAttack, "info_target", "CBaseEntity__TraceAttack");
#endif // SPARK_EFFECTS

	RegisterHam(Ham_Spawn, "player", "CBasePlayer__Spawn_Pre");
	RegisterHam(Ham_Spawn, "player", "CBasePlayer__Spawn_Post", 1);
	RegisterHam(Ham_Player_PreThink, "player", "CBasePlayer__PreThink_Post", 1);
	RegisterHam(Ham_Valid_Player_ResetMaxSpeed(), "player", "CBasePlayer__ResetMaxSpeed_Post", 1);

	g_pHookTable[ InfoHook_RoundRespawn ] = RegisterHam(Ham_CS_RoundRespawn, "player", "CBasePlayer__CS_RoundRespawn");
	g_pHookTable[ InfoHook_TraceAttack ] = RegisterHam(Ham_TraceAttack, "player", "CBasePlayer__TraceAttack");
	g_pHookTable[ InfoHook_ObjectCaps ] = RegisterHam(Ham_ObjectCaps, "player", "CBasePlayer__ObjectCaps_Post", 1);

	DisableHamForward(g_pHookTable[ InfoHook_RoundRespawn ]);
	DisableHamForward(g_pHookTable[ InfoHook_TraceAttack ]);
	DisableHamForward(g_pHookTable[ InfoHook_ObjectCaps ]);

	g_gpSaveRestoreCache[ InfoStore_RoundPlayed ] = TrieCreate();
	g_gpSaveRestoreCache[ InfoStore_Origin ] = TrieCreate();
	g_gpSaveRestoreCache[ InfoStore_SpawnLock ] = TrieCreate();
	g_gpSaveRestoreCache[ InfoStore_Teamid ] = TrieCreate();
	g_gpSaveRestoreCache[ InfoStore_Stay ] = TrieCreate();

	new pEnt = CREATE_NAMED_ENTITY("info_target");

	if (pEnt)
	{
		entity_set_string(pEnt, EV_SZ_classname, "CFTMod__Informer");
		entity_set_float(pEnt, EV_FL_nextthink, get_gametime() + 1.0);
	}

	new const szUserMsg[][] =
	{
		"BarTime",
		"DeathMsg",
		"HostageK",
		"ScoreInfo",
		"HostagePos",
		"ScreenFade",
		"ScoreAttrib",
		"RoundTime",
		"Money",
		"StatusText",
		"StatusValue",
		"HudTextArgs",
		"HideWeapon",
		"StatusIcon"
	};

	for (new i; i < sizeof(szUserMsg); i++)
		g_iUserMsg[ i ] = get_user_msgid(szUserMsg[ i ]);

	g_iMaxPlayers = get_maxplayers();

	set_msg_block(g_iUserMsg[ Message_RoundTime ], BLOCK_SET);

	register_dictionary("ftmod.txt");

#if defined FROZEN_STATUS_TEXT

	set_msg_block(g_iUserMsg[ Message_StatusText ], BLOCK_SET);
	set_msg_block(g_iUserMsg[ Message_StatusValue ], BLOCK_SET);
	set_msg_block(g_iUserMsg[ Message_HudTextArgs ], BLOCK_SET);

#endif // FROZEN_STATUS_TEXT

	register_message(g_iUserMsg[ Message_HideWeapon ], "MessageHook_HideWeapon");
	register_message(g_iUserMsg[ Message_Money ], "MessageHook_Money");

#if defined FROZEN_MOD_API

	g_pExtraItemName = ArrayCreate(64, 1);
	g_pExtraItemCost = ArrayCreate(1, 1);
	g_pExtraItemTeam = ArrayCreate(1, 1);

	g_iMenuShopId = register_menuid("FTMod Menu");
	register_menucmd(g_iMenuShopId, 1023, "MenuShop__Handler");

	CFTMod__RegisterForwards();

#endif // FROZEN_MOD_API

#if defined DEBUG
	g_pCvarDebug = register_cvar("ftmod_debug", "0");
#endif // DEBUG

	new pBuyZone = NULL;
	while ((pBuyZone = FIND_ENTITY_BY_CLASSNAME(pBuyZone, "func_buyzone")) != NULL)
	{
		set_pev(pBuyZone, pev_flags, pev(pBuyZone, pev_flags) | FL_KILLME);
	}
}

public MessageHook_HideWeapon(const msgid, const msgdest, const id)
{
	if (!g_pPlayerInfo[ id ][ Player_Frozen ])
		set_msg_arg_int(1, ARG_BYTE, (get_msg_arg_int(1) & ~HIDEHUD_FLASHLIGHT) | HIDEHUD_TIMER);
	else
		set_msg_arg_int(1, ARG_BYTE, (get_msg_arg_int(1) & ~HIDEHUD_TIMER) | HIDEHUD_FLASHLIGHT);
}

public MessageHook_Money(const msgid, const msgdest, const id)
{
	/*
	* forcing everything message of gamedll chage to own value
	*/

	new iAccount = g_pPlayerInfo[ id ][ Player_Money ];

	set_member(id, m_iAccount, iAccount);
	set_msg_arg_int(1, ARG_LONG, iAccount);
	set_msg_arg_int(2, ARG_BYTE, 0);
}

public plugin_end()
{
	CFTMod__DestroyForwards();
}

#if defined FROZEN_MOD_API

public plugin_natives()
{
	/*
	* Execute func
	*/
	register_native("ftm_execute_frozen", "_ftm_execute_frozen", 1);
	register_native("ftm_execute_unfrozen", "_ftm_execute_unfrozen", 1);
	register_native("ftm_execute_clean_frozen", "_ftm_execute_clean_frozen", 1);

	/*
	* Additions natives
	*/
	register_native("ftm_register_extra_item", "_ftm_register_extra_item", 1);

	/*
	* Specific player natives
	*/
	register_native("ftm_set_frozen", "_ftm_set_frozen", 1);
	register_native("ftm_get_frozen", "_ftm_get_frozen", 1);

	register_native("ftm_set_alive", "_ftm_set_alive", 1);
	register_native("ftm_get_alive", "_ftm_get_alive", 1);

	register_native("ftm_get_teamid", "_ftm_get_teamid", 1);

	register_native("ftm_set_add_health", "_ftm_set_add_health", 1);
	register_native("ftm_get_add_health", "_ftm_get_add_health", 1);
	register_native("ftm_set_money", "_ftm_set_money", 1);
	register_native("ftm_get_money", "_ftm_get_money", 1);
	register_native("ftm_get_rescuer_id", "_ftm_get_rescuer_id", 1);
	register_native("ftm_get_obs_target", "_ftm_get_obs_target", 1);
	register_native("ftm_get_protect_spawn", "_ftm_get_protect_spawn", 1);
	register_native("ftm_get_play_origin", "_ftm_get_play_origin");
	register_native("ftm_get_play_round", "_ftm_get_play_round", 1);

	register_native("ftm_set_spawnlock", "_ftm_set_spawnlock", 1);
	register_native("ftm_get_spawnlock", "_ftm_get_spawnlock", 1);

	register_native("ftm_set_stay", "_ftm_set_stay", 1);
	register_native("ftm_get_stay", "_ftm_get_stay", 1);

	register_native("ftm_get_entity_owner", "_ftm_get_entity_owner");

	register_native("ftm_defrost_break", "_ftm_defrost_break", 1);
}

public _ftm_execute_frozen(const id)
{
	CPlayer__Frozen(id);
}

public _ftm_execute_unfrozen(const id)
{
	CPlayer__UnFrozen(id);
}

public _ftm_execute_clean_frozen(const id, bool:bIsKill)
{
	CPlayer__CleanFrozen(id, bIsKill);
}

public _ftm_set_frozen(const id, bool:bIsFrozen)
{
	g_pPlayerInfo[ id ][ Player_Frozen ] = bIsFrozen;
}

public _ftm_get_frozen(const id)
{
	return g_pPlayerInfo[ id ][ Player_Frozen ];
}

public _ftm_set_alive(const id, bool:bIsAlive)
{
	g_pPlayerInfo[ id ][ Player_Alive ] = bIsAlive;
}

public _ftm_get_alive(const id)
{
	return g_pPlayerInfo[ id ][ Player_Alive ];
}

public _ftm_get_teamid(const id)
{
	return _:g_pPlayerInfo[ id ][ Player_Teamid ];
}

public _ftm_set_add_health(const id, const Float:amount)
{
	UTIL__SetHealth(id, amount);
}

public Float:_ftm_get_add_health(const id)
{
	return g_pPlayerInfo[ id ][ Player_AddHealth ];
}

public _ftm_set_money(const id, const amount, const flash)
{
	g_pPlayerInfo[ id ][ Player_Money ] += amount;
	UTIL__AddAccount(id, g_pPlayerInfo[ id ][ Player_Money ], flash);
}

public _ftm_get_money(const id)
{
	return g_pPlayerInfo[ id ][ Player_Money ];
}

public _ftm_get_rescuer_id(const id)
{
	return g_pPlayerInfo[ id ][ Player_Rescuerid ];
}

public _ftm_get_obs_target(const id)
{
	return g_pPlayerInfo[ id ][ Player_Target ];
}

public _ftm_get_protect_spawn(const id)
{
	new Float:flProtectTime = g_pPlayerInfo[ id ][ Player_ProtectTime ];

	if (flProtectTime <= 0.0)
		return 0;

	return flProtectTime > get_gametime();
}

public _ftm_get_play_origin(iPlugins, iParams)
{
	new id = get_param(1);

	set_array(2, _:g_flLastOrigin[ id ], 3);
}

public _ftm_get_play_round(const id)
{
	return g_pPlayerInfo[ id ][ Player_RoundPlayed ];
}

public _ftm_set_spawnlock(const id, const bool:bLock)
{
	g_pPlayerInfo[ id ][ Player_SpawnLock ] = bLock;

	if (bLock)
		EnableHamForward(g_pHookTable[ InfoHook_RoundRespawn ]);
}

public _ftm_get_spawnlock(const id)
{
	return g_pPlayerInfo[ id ][ Player_SpawnLock ];
}

public _ftm_set_stay(const id, const bool:bLock)
{
	g_pPlayerInfo[ id ][ Player_Stay ] = bLock;
}

public _ftm_get_stay(const id)
{
	return g_pPlayerInfo[ id ][ Player_Stay ];
}

public _ftm_get_entity_owner(iPlugins, iParams)
{
	new id = get_param(1);
	if (id > 0)
	{
		set_param_byref(2, g_pPlayerInfo[ id ][ Player_EntCube ]);
		set_param_byref(3, g_pPlayerInfo[ id ][ Player_EntView ]);
		set_param_byref(4, g_pPlayerInfo[ id ][ Player_EntBody ]);
		set_param_byref(5, g_pPlayerInfo[ id ][ Player_EntWeapon ]);
	}
}

public _ftm_register_extra_item(const szItem[], const iMoneyCost, EXTRA_TEAM:iTeam)
{
	param_convert(1);

	if (strlen(szItem) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[FTM] Can't register extra item with an empty name (%s)", szItem);
		return -1;
	}

	if (g_iExtraItemNum >= MAX_EXTRA_ITEM)
	{
		log_error(AMX_ERR_NATIVE, "[FTM] Can't register extra item, it has reached the limit (Max: %d)", szItem, MAX_EXTRA_ITEM);
		return -1;
	}

	new szBuffer[ 64 ];
	for (new i; i < g_iExtraItemNum; i++)
	{
		ArrayGetString(g_pExtraItemName, i, szBuffer, charsmax(szBuffer));
		if (equali(szBuffer, szItem))
		{
			if (ArrayGetCell(g_pExtraItemTeam, i) == _:iTeam)
			{
				log_error(AMX_ERR_NATIVE, "[FTM] Extra item already registered (%s)", szItem);
				return -1;
			}
		}
	}

	if (iTeam == ITEM_TEAM_ANY)
		iTeam |= (ITEM_TEAM_CT | ITEM_TEAM_T);

	ArrayPushString(g_pExtraItemName, szItem);
	ArrayPushCell(g_pExtraItemCost, iMoneyCost);
	ArrayPushCell(g_pExtraItemTeam, iTeam);

	return g_iExtraItemNum++;
}

public _ftm_defrost_break(const id)
{
	new rescuedID = g_pPlayerInfo[ id ][ Player_Rescuerid ];

	if (rescuedID)
	{
		UTIL__PlayerAllowShoot(rescuedID);
		UTIL__BarTime(rescuedID, id);
	}
}

public CMD_FlashLight(const id)
{
	return g_pPlayerInfo[ id ][ Player_Frozen ];
}

/*
* Not blocked cmd
*/
public CMD_ShopVGUIMenu(const id)
{
	if (g_pPlayerInfo[ id ][ Player_State ] != JOIN_IN_TO_GAME)
		return;

	MenuShop(id, g_pPlayerInfo[ id ][ Player_ShopPos ] = 0);
}

public CMD_ShopMenu(const id)
{
	if (g_pPlayerInfo[ id ][ Player_State ] != JOIN_IN_TO_GAME)
		return 1;

	return MenuShop(id, g_pPlayerInfo[ id ][ Player_ShopPos ] = 0);
}

stock MenuShop(const id, iPos)
{
	if (iPos < 0)
		return 1;

	new iNumItem = 0;
	new iExtraTeam = _:g_pPlayerInfo[ id ][ Player_Teamid ];

	for (new i; i < g_iExtraItemNum; i++)
	{
		if (!(ArrayGetCell(g_pExtraItemTeam, i) & (1 << iExtraTeam)))
			continue;

		g_pPlayerInfo[ id ][ Player_Itemid ][ iNumItem++ ] = i;
	}

	if (iNumItem < 1)
	{
		client_print_color(id, DontChange, "%L", LANG_PLAYER, "FTM_SHOP_EMTPY", PREFIX);
		return 1;
	}

	static szBuffer[ 1024 ];
	static szItem[ 32 ];

	new iIndex;
	new iBitsKey = MENU_KEY_0;
	new iLen = formatex(szBuffer, charsmax(szBuffer), "%L", LANG_PLAYER, "FTM_SHOP_MENU_TITLE", iPos + 1, (((iNumItem - 1) / MAX_ITEM_ON_PAGE) + 1));

	new iNum, iCost;
	new iStart = iPos * MAX_ITEM_ON_PAGE;
	new iEnd = iStart + MAX_ITEM_ON_PAGE;

	iPos = iStart / MAX_ITEM_ON_PAGE;

	g_pPlayerInfo[ id ][ Player_ShopPos ] = iPos;

	for (new i = iStart; i < iEnd; i++)
	{
		iIndex = g_pPlayerInfo[ id ][ Player_Itemid ][ i ];

		if (i < iNumItem)
		{
			iCost = ArrayGetCell(g_pExtraItemCost, iIndex);
			ArrayGetString(g_pExtraItemName, iIndex, szItem, charsmax(szItem));

			if (iCost <= g_pPlayerInfo[ id ][ Player_Money ])
			{
				iBitsKey |= (1 << iNum);
				iLen += formatex(szBuffer[ iLen ], charsmax(szBuffer) - iLen, "%L", LANG_PLAYER, "FTM_SHOP_MENU_LINE_ACTIVE", ++iNum, szItem, iCost);
			}
			else
				iLen += formatex(szBuffer[ iLen ], charsmax(szBuffer) - iLen, "%L", LANG_PLAYER, "FTM_SHOP_MENU_LINE_DEACTIVE", ++iNum, szItem, iCost);
		}
		else
			szBuffer[ iLen++ ] = '\n';
	}

	if (iEnd < iNumItem)
	{
		iBitsKey |= MENU_KEY_9;
		formatex(szBuffer[ iLen ], charsmax(szBuffer) - iLen,"%L", LANG_PLAYER, "FTM_SHOP_MENU_FOOTER_1", LANG_PLAYER, iPos ? "FTM_SHOP_MENU_FOOTER_BACK" : "FTM_SHOP_MENU_FOOTER_EXIT");
	}
	else formatex(szBuffer[ iLen ], charsmax(szBuffer) - iLen,"%L", LANG_PLAYER, "FTM_SHOP_MENU_FOOTER_2", LANG_PLAYER, iPos ? "FTM_SHOP_MENU_FOOTER_BACK" : "FTM_SHOP_MENU_FOOTER_EXIT");

	if (pev_valid(id) == PDATA_SAFE)
		set_member(id, m_iMenu, 0);

	return show_menu(id, iBitsKey, szBuffer, -1, "FTMod Menu");
}

public MenuShop__Handler(const id, const iKey)
{
	new iPos = g_pPlayerInfo[ id ][ Player_ShopPos ];
	new iItemId = g_pPlayerInfo[ id ][ Player_Itemid ][ iPos * MAX_ITEM_ON_PAGE + iKey ];

	switch(iKey)
	{
		// Next
		case 8:
			MenuShop(id, ++iPos);

		// Back/Exit
		case 9:
			MenuShop(id, --iPos);

		default:
		{
			ExecuteForward(g_pForwards[ SHOP_ITEM_SELECTED ], g_pResultDummy, id, iItemId);

			if (g_pResultDummy == PLUGIN_HANDLED)
				return 1;

			new iCost = ArrayGetCell(g_pExtraItemCost, iItemId);

			g_pPlayerInfo[ id ][ Player_Money ] -= iCost;
			UTIL__AddAccount(id, g_pPlayerInfo[ id ][ Player_Money ]);
		}
	}
	return 1;
}

#endif // FROZEN_MOD_API

public Event_ResetHUD(const id)
{
	if (pev_valid(id) == PDATA_SAFE)
		set_member(id, m_iClientHideHUD, 0);
}

public Event_RestartRound()
{
	for (new i = 1; i <= g_iMaxPlayers; i++)
		memset(_:g_flLastOrigin[ i ], 0, 3);

	CFTMod__ClearStats();
	CSaveRestore__Clear();

#if defined FROZEN_MOD_API
	ExecuteForward(g_pForwards[ SERVER_ROUND_RESTART ], g_pResultDummy);
#endif // FROZEN_MOD_API
}

public Event_NewRound()
{
	/*
	* fix
	* This member nulled after spawn the players, but need to beforehand
	*/
	//set_pgame_int(m_iRoundWinStatus, 0);

	/*
	* ... to be sure that the entity removed
	*/
	CFTMod__CleanUpMap();

	for (new i = 1; i <= g_iMaxPlayers; i++)
	{
		if (!g_pPlayerInfo[ i ][ Player_Ingame ] || pev_valid(i) != PDATA_SAFE)
			continue;

		if (g_pPlayerInfo[ i ][ Player_Alive ])
			UTIL__DestroyShopMenu(i);

		g_pPlayerInfo[ i ][ Player_SpawnLock ] = false;
		g_pPlayerInfo[ i ][ Player_Stay ] = false;

		memset(_:g_flLastOrigin[ i ], 0, 3);
	}

	DisableHamForward(g_pHookTable[ InfoHook_RoundRespawn ]);
	DisableHamForward(g_pHookTable[ InfoHook_TraceAttack ]);
	EnableHamForward(g_pHookTable[ InfoHook_ObjectCaps ]);

#if defined FROZEN_MOD_API
	ExecuteForward(g_pForwards[ SERVER_ROUND_NEW ], g_pResultDummy);
#endif // FROZEN_MOD_API

}

#if defined FROZEN_STATUS_TEXT

public TraceLine(const Float:vecStart[ 3 ], const Float:vecEnd[ 3 ], fNoMonsters, id, ptr)
{
	if (id < 1 || id > g_iMaxPlayers || g_pPlayerInfo[ id ][ Player_Frozen ] || !g_pPlayerInfo[ id ][ Player_Alive ])
		return FMRES_IGNORED;

	new Float:vecOrigin[ 3 ], Float:vecViewOfs[ 3 ];

	entity_get_vector(id, EV_VEC_origin, vecOrigin);
	entity_get_vector(id, EV_VEC_view_ofs, vecViewOfs);

	vecOrigin[ 2 ] += vecViewOfs[ 2 ];

	/*
	* Ignore through wall tracelines
	*/
	if (!VectorCompare(vecOrigin, vecStart))
		return FMRES_IGNORED;

	CPlayer__UpdateStatusBar(id, ptr);
	return FMRES_IGNORED;
}

#endif // FROZEN_STATUS_TEXT

public ClientDisconnect_Post(id)
{
	if (is_user_bot(id) || is_user_hltv(id))
		return;

	g_pPlayerInfo[ id ][ Player_Rescuerid ] = 0;
	g_pPlayerInfo[ id ][ Player_Alive ] = false;
	g_pPlayerInfo[ id ][ Player_AddHealth ] = _:0.0;
	g_pPlayerInfo[ id ][ Player_Money ] = 0;
	g_pPlayerInfo[ id ][ Player_ButtonNext ] = _:0.0;

	CPlayer__CleanupEntity(id);

	/*
	* find next target, after disconnected from game current target
	*/
	for (new i = 1; i <= g_iMaxPlayers; i++)
	{
		if (id == i || !g_pPlayerInfo[ i ][ Player_Ingame ] || !g_pPlayerInfo[ i ][ Player_Frozen ] || g_pPlayerInfo[ i ][ Player_Target ] != id)
			continue;

		CPlayer__HandleButtons(i, BUTTON_MOUSE1);
	}

	if (g_pPlayerInfo[ id ][ Player_State ] == JOIN_IN_TO_GAME)
	{
#if defined WAIT_TO_NEXT_ROUND
		if (get_pgame_float(m_fRoundCount) + ROUND_WAIT_NEXT > get_gametime())
#endif // WAIT_TO_NEXT_ROUND
		CSaveRestore__WriteData(id);
	}

	g_pPlayerInfo[ id ][ Player_Ingame ] = false;
	g_pPlayerInfo[ id ][ Player_Frozen ] = false;
	g_pPlayerInfo[ id ][ Player_Teamid ] = _:CS_TEAM_UNASSIGNED;
	g_pPlayerInfo[ id ][ Player_SpawnLock ] = false;
	g_pPlayerInfo[ id ][ Player_Stay ] = false;
	g_pPlayerInfo[ id ][ Player_InterpTime ] = _:0.0;
	g_pPlayerInfo[ id ][ Player_VGUI ] = false;

	memset(_:g_flLastOrigin[ id ], 0, 3);

	CFTMod__ConditionsCheckWin();
}

public client_connect(id)
{
	if (is_user_bot(id) || is_user_hltv(id))
		return;

	g_pPlayerInfo[ id ][ Player_SpawnLock ] = false;
	g_pPlayerInfo[ id ][ Player_Stay ] = false;
	g_pPlayerInfo[ id ][ Player_State ] = _:JOINED;
	g_pPlayerInfo[ id ][ Player_Ingame ] = false;
	g_pPlayerInfo[ id ][ Player_Teamid ] = _:CS_TEAM_UNASSIGNED;
}

public client_putinserver(id)
{
	if (is_user_bot(id) || is_user_hltv(id))
		return;

	g_pPlayerInfo[ id ][ Player_ShopPos ] = 0;
	g_pPlayerInfo[ id ][ Player_Alive ] = false;
	g_pPlayerInfo[ id ][ Player_Ingame ] = true;
	g_pPlayerInfo[ id ][ Player_Frozen ] = false;

	g_pPlayerInfo[ id ][ Player_Money ] = 0;
	g_pPlayerInfo[ id ][ Player_ViewModel ] = 0;
	g_pPlayerInfo[ id ][ Player_Rescuerid ] = 0;
	g_pPlayerInfo[ id ][ Player_AddHealth ] = _:0.0;
	g_pPlayerInfo[ id ][ Player_ButtonNext ] = _:0.0;
	g_pPlayerInfo[ id ][ Player_InterpTime ] = _:INTERP_TIME_DEFAULT;

	get_user_authid(id, g_pPlayerInfo[ id ][ Player_Authid ], charsmax(g_pPlayerInfo[][ Player_Authid ]));
	get_user_ip(id, g_pPlayerInfo[ id ][ Player_Ip ], charsmax(g_pPlayerInfo[][ Player_Ip ]), 1);
}

public ClientKill(const id)
{
	return g_pPlayerInfo[ id ][ Player_Frozen ] ? FMRES_SUPERCEDE : FMRES_IGNORED;
}

public CFTMod__InformerThink(const ent)
{
	static iPlayers[ 2 ][ MAX_CLIENTS + 1 ], iNum[ 4 ], szName[ 32 ], szBuffer[ 512 ];

	new iTeam, bIsFrozen, a, b, i;
	new Float:flDist, Float:flCurrentTime;

	flCurrentTime = get_gametime();

	memset(iNum, 0, 4);

	for (i = 1; i <= g_iMaxPlayers; i++)
	{
		if (!g_pPlayerInfo[ i ][ Player_Alive ] || g_pPlayerInfo[ i ][ Player_Stay ])// || !g_pPlayerInfo[ i ][ Player_Ingame ])
			continue;

		iTeam = _:g_pPlayerInfo[ i ][ Player_Teamid ] - 1;

		if (iTeam >= 0)
		{
			if (g_pPlayerInfo[ i ][ Player_Frozen ])
				iPlayers[ iTeam ][ iNum[ iTeam ]++ ] = i;

			// 2 alive t | 3 alive ct
			iNum[ iTeam + 2 ]++;
		}
	}

	if (!(iNum[ 0 ] + iNum[ 1 ]))
	{
		entity_set_float(ent, EV_FL_nextthink, flCurrentTime + 1.0);
		return;
	}

	for (i = 1; i <= g_iMaxPlayers; i++)
	{
		if (!g_pPlayerInfo[ i ][ Player_Alive ])// || !g_pPlayerInfo[ i ][ Player_Ingame ])
			continue;

		iTeam = _:g_pPlayerInfo[ i ][ Player_Teamid ] - 1;

		if (iTeam >= 0 && iNum[ iTeam ])
		{
			szBuffer[ 0 ] = '\0';

			bIsFrozen = g_pPlayerInfo[ i ][ Player_Frozen ];

			for (b = 0; b < iNum[ iTeam ]; b++)
			{
				a = iPlayers[ iTeam ][ b ];
				flDist = entity_range(i, a);

				if (!bIsFrozen && !g_pPlayerInfo[ a ][ Player_Stay ])
				{
					if (flCurrentTime > g_pPlayerInfo[ i ][ Player_WaitAlert ] && flDist < DISTANCE_ALERT)
					{
						g_pPlayerInfo[ i ][ Player_WaitAlert ] = _:(flCurrentTime + ALERT_TIME);

						set_dhudmessage(COLOR_DHUD_MESSAGE_USE, -1.0, 0.65, 2, 0.25, 2.0, 0.01, 0.5);
						show_dhudmessage(i, "%L", LANG_PLAYER, "FTM_MSG_NOTICE_USE");
					}
#if defined SOUND_HELP_AUTO
					if (flCurrentTime > g_pPlayerInfo[ a ][ Player_WaitHelp ] && flDist < DISTANCE_HELP_ME)
					{
						g_pPlayerInfo[ a ][ Player_WaitHelp ] = _:(flCurrentTime + HELP_TIME);

						EMIT_SOUND(a, CHAN_VOICE, SOUND_HELP_ME[ random_num(0, sizeof(SOUND_HELP_ME) - 1) ], VOL_NORM, ATTN_NORM);
						CPlayer__RadioIcon(a);
					}
#else // SOUND_HELP_AUTO
					if (flCurrentTime > g_pPlayerInfo[ a ][ Player_WaitHelp ] && flCurrentTime > g_pPlayerInfo[ a ][ Player_WaitAlert ] && flDist < DISTANCE_ALERT && entity_get_int(a, EV_INT_iuser2) == 0)
					{
						g_pPlayerInfo[ a ][ Player_WaitAlert ] = _:(flCurrentTime + HELP_USE_TIME);

						set_dhudmessage(COLOR_DHUD_MESSAGE_USE, -1.0, 0.65, 2, 0.25, 2.0, 0.01, 0.5);
						show_dhudmessage(a, "%L", LANG_PLAYER, "FTM_MSG_NOTICE_USE_OWNER");
					}
#endif // SOUND_HELP_AUTO
				}

				entity_get_string(a, EV_SZ_netname, szName, charsmax(szName));

				if (szName[ 0 ] != '\0')
				{
					strcat(szName, "\n", charsmax(szName));
					strcat(szBuffer, szName, charsmax(szBuffer));
				}
			}

			set_hudmessage(128, 128, 128, 0.01, 0.18, 0, 0.7, 0.7, _, 0.5);
			show_hudmessage(i, "%L", LANG_PLAYER, "FTM_INFO_STATS", iNum[ iTeam ], iNum[ iTeam + 2 ], szBuffer);
		}
	}

	entity_set_float(ent, EV_FL_nextthink, flCurrentTime + 1.0);
}

public CBasePlayer__ObjectCaps_Post(const id)
{
	if (g_pPlayerInfo[ id ][ Player_Frozen ])
		return;

	new afButtonReleased = get_member(id, m_afButtonReleased);
	if (!((entity_get_int(id, EV_INT_button) | get_member(id, m_afButtonPressed) | afButtonReleased) & IN_USE))
		return;

	static Float:__flNextUpdateMoney[ MAX_CLIENTS + 1 ] = { 0.0, ... };

	new Float:vecOrigin[ 3 ], Float:flHealth, Float:flCurrentTime;
	new pEnt, pEntAiming, pEntRescued, pEntCube, pBody, teamID;

	flCurrentTime = get_gametime();
	pEntRescued = g_pPlayerInfo[ id ][ Player_Rescuerid ];
	teamID = _:g_pPlayerInfo[ id ][ Player_Teamid ];

	if (!(afButtonReleased & IN_USE))
	{
		entity_get_vector(id, EV_VEC_origin, vecOrigin);

		/*
		* Defrost player in the process
		*/
		if (pEntRescued > 0)
		{
			pEntCube = g_pPlayerInfo[ pEntRescued ][ Player_EntCube ];
			if (pev_valid(pEntCube))
			{
				get_user_aiming(id, pEntAiming, pBody);

#if defined FROZEN_MOD_API
				ExecuteForward(g_pForwards[ CLIENT_UNFREEZE ], g_pResultDummy, id, pEntRescued, pEntCube, g_pPlayerInfo[ id ][ Player_Money ]);
				if (!g_pPlayerInfo[ pEntRescued ][ Player_Stay ] && pEntAiming == pEntCube && g_pResultDummy != PLUGIN_HANDLED)
#else
				if (!g_pPlayerInfo[ pEntRescued ][ Player_Stay ] && pEntAiming == pEntCube)
#endif // FROZEN_MOD_API
				{
					UTIL__PlayerAllowShoot(id, false);

					g_pPlayerInfo[ id ][ Player_Money ] += MULTIPLY_MONEY;
					g_pPlayerInfo[ pEntRescued ][ Player_ButtonNext ] = _:(flCurrentTime + 2.5);

					if (flCurrentTime > __flNextUpdateMoney[ id ])
					{
						UTIL__AddAccount(id, g_pPlayerInfo[ id ][ Player_Money ]);
						__flNextUpdateMoney[ id ] = flCurrentTime + UPDATE_HUD_MONEY;
					}

					flHealth = entity_get_float(pEntCube, EV_FL_health);

					if (flHealth <= 0.0)
						return;

					flHealth -= (g_pPlayerInfo[ id ][ Player_InterpTime ] * 100.0 / TIME_HAND_DEFORSTING) * (CUBE_HEALTH - MIN_POOL_AMOUNT) / 100.0;

					if (flHealth < 0.0)
						flHealth = 0.0;

					entity_set_float(pEntCube, EV_FL_health, flHealth);
					entity_set_float(pEntCube, EV_FL_renderamt, flHealth);

					CPlayer__UnFrozenProccess(pEntRescued, pEntCube, g_flLastOrigin[ pEntRescued ], flHealth);
				}
				else
				{
					UTIL__PlayerAllowShoot(id);
					UTIL__BarTime(id, pEntRescued);
				}
			}
		}
		/*
		* Find freezed player
		*/
		else
		{
			get_user_aiming(id, pEntAiming, pBody);

			if (!pev_valid(pEntAiming))
				return;

			while ((pEnt = FIND_ENTITY_IN_SPHERE(pEnt, vecOrigin, MAX_RADIUS_USE)) != NULL)
			{
				if (pEnt <= g_iMaxPlayers || !pev_valid(pEnt) || entity_get_int(pEnt, EV_INT_impulse) != INFOCUBE_UID)
					continue;

				if (entity_get_int(pEnt, DATA_CUBE_TEAMID) != teamID)
					continue;

				pEntRescued = entity_get_int(pEnt, DATA_CUBE_OWNER);

				if (!pEntRescued || !g_pPlayerInfo[ pEntRescued ][ Player_Alive ])
					continue;
#if !defined FROZEN_MOD_API
				if (g_pPlayerInfo[ pEntRescued ][ Player_Stay ])
					continue;
#endif // FROZEN_MOD_API

				if (!g_pPlayerInfo[ pEntRescued ][ Player_Frozen ] || g_pPlayerInfo[ pEntRescued ][ Player_Rescuerid ])
					continue;

				if (pEntAiming == pEnt)
				{
					flHealth = entity_get_float(pEnt, EV_FL_health);

					new iTime = floatround((flHealth - MIN_POOL_AMOUNT) / SPEED_BARTIME);
					if (iTime < 1)
						iTime = 1;
#if defined FROZEN_MOD_API
					ExecuteForward(g_pForwards[ CLIENT_FIND_TARGET ], g_pResultDummy, id, pEntRescued, iTime);

					if (g_pResultDummy == PLUGIN_HANDLED)
						return;

					if (g_pPlayerInfo[ pEntRescued ][ Player_Stay ])
						continue;
#endif // FROZEN_MOD_API

					UTIL__PlayerAllowShoot(id, false);
					UTIL__BarTime(id, pEntRescued, iTime);

					g_pPlayerInfo[ id ][ Player_InterpTime ] = _:UTIL__GetUserInterpTime(id);

					/*
					* reset view to owner, if the him begin defrosted
					*/
					if (g_pPlayerInfo[ pEntRescued ][ Player_Target ] != pEnt)
					{
						entity_set_int(pEntRescued, EV_INT_iuser1, OBS_NONE);
						entity_set_int(pEntRescued, EV_INT_iuser2, NULL);

						g_pPlayerInfo[ pEntRescued ][ Player_Target ] = pEnt;
						g_pPlayerInfo[ pEntRescued ][ Player_ButtonNext ] = _:(flCurrentTime + 2.5);

						UTIL__ScreenFade(pEntRescued, 0x0005, 0, 0);
					}

					break;
				}
			}
		}
	}
	else if (pEntRescued > 0)
	{
		UTIL__PlayerAllowShoot(id);
		UTIL__BarTime(id, pEntRescued);
	}
}

#if defined SPARK_EFFECTS

public CBaseEntity__TraceAttack(const victim, const idattacker, const Float:damage, const Float:flDirection[ 3 ], const tracehandle, const damagebits)
{
	if (entity_get_int(victim, EV_INT_impulse) != INFOCUBE_UID)
		return HAM_IGNORED;

	if (idattacker < 1 || idattacker > g_iMaxPlayers || !g_pPlayerInfo[ idattacker ][ Player_Alive ])
		return HAM_SUPERCEDE;

	new Float:vecEndPos[ 3 ];
	if (random_num(0, 5) == 1)
	{
		get_tr2(tracehandle, TR_EndPos, vecEndPos);
		CEffects__Spark(vecEndPos);
	}
	return HAM_IGNORED;
}

#endif // SPARK_EFFECTS

public CPointEntity__IcecubeTouch(const ent, const toucher)
{
	if (!pev_valid(toucher))
		return;

	new Float:vecVelocity[ 3 ], Float:vecVelocityToucher[ 3 ];

	entity_get_vector(ent, EV_VEC_velocity, vecVelocity);
	entity_get_vector(toucher, EV_VEC_velocity, vecVelocityToucher);

	if (toucher > g_iMaxPlayers && entity_get_int(toucher, EV_INT_impulse) == INFOCUBE_UID)
	{
		vecVelocity[ 0 ] += vecVelocityToucher[ 0 ] * 0.9;
		vecVelocity[ 1 ] += vecVelocityToucher[ 1 ] * 0.9;
	}
	else
	{
		if (!(entity_get_int(toucher, EV_INT_flags)) || entity_get_edict(toucher, EV_ENT_groundentity) == ent)
			return;

		// coefficient
		vecVelocity[ 0 ] += vecVelocityToucher[ 0 ] * 0.5;
		vecVelocity[ 1 ] += vecVelocityToucher[ 1 ] * 0.5;
	}

	entity_set_vector(ent, EV_VEC_velocity, vecVelocity);
}

public CBaseEntity__TakeDamage(const victim, const idinflictor, const idattacker, const Float:flDamage, const damagebits)
{
	if (entity_get_int(victim, EV_INT_impulse) != INFOCUBE_UID)
		return HAM_IGNORED;

	if (idattacker < 1 || idattacker > g_iMaxPlayers || !g_pPlayerInfo[ idattacker ][ Player_Alive ] || get_member_game(m_iRoundWinStatus) != 0)
		return HAM_SUPERCEDE;

	/*
	* block the damage, if it defrosted the player
	*/
	if (g_pPlayerInfo[ idattacker ][ Player_Rescuerid ] > 0)
		return HAM_SUPERCEDE;

	new pOwner = entity_get_int(victim, DATA_CUBE_OWNER);
	if (pOwner > 0 && g_pPlayerInfo[ pOwner ][ Player_Stay ])
		return HAM_SUPERCEDE;

	SetHamParamFloat(4, flDamage / MULTIDIV_DAMAGE);

	return HAM_IGNORED;
}

public CBasePlayer__Killed(const victim, const killer, const shouldgib)
{
	if (g_pPlayerInfo[ victim ][ Player_Ingame ])
		UTIL__BarTime(victim, g_pPlayerInfo[ victim ][ Player_Rescuerid ]);

	if (!killer || killer > g_iMaxPlayers || killer == victim || !g_pPlayerInfo[ killer ][ Player_Alive ])
	{
		CFTMod__ConditionsCheckWin();
		return HAM_IGNORED;
	}

#if defined FROZEN_MOD_API

	ExecuteForward(g_pForwards[ CLIENT_FROZEN ], g_pResultDummy, victim, killer);
	if (g_pResultDummy > 0)
		return g_pResultDummy;

#endif // FROZEN_MOD_API

	new CsTeams:teamID = g_pPlayerInfo[ killer ][ Player_Teamid ];
	g_iStats[ teamID ][ InfoStats_Frozen ]++;

	static szWeaponName[ 22 ];
	if (killer && killer != victim && pev_valid(killer) == PDATA_SAFE)
	{
		MESSAGE_BEGIN(MSG_ALL, g_iUserMsg[ Message_ScoreInfo ], _, NULL);
		WRITE_BYTE(killer);
		WRITE_SHORT(floatround(entity_get_float(killer, EV_FL_frags)) + 1);
		WRITE_SHORT(get_member(killer, m_iDeaths));
		WRITE_SHORT(0);
		WRITE_SHORT(_:g_pPlayerInfo[ victim ][ Player_Teamid ]);
		MESSAGE_END();

		UTIL__GetWeaponByKiller(killer, entity_get_edict(victim, EV_ENT_dmg_inflictor), szWeaponName, charsmax(szWeaponName));

		MESSAGE_BEGIN(MSG_ALL, g_iUserMsg[ Message_DeathMsg ], _, NULL);
		WRITE_BYTE(killer);
		WRITE_BYTE(victim);
		WRITE_BYTE((get_member(victim, m_LastHitGroup) == HIT_HEAD));
		write_string(szWeaponName);
		MESSAGE_END();

		g_pPlayerInfo[ killer ][ Player_Money ] += MONEY_KILL;
		UTIL__AddAccount(killer, g_pPlayerInfo[ killer ][ Player_Money ]);

		ExecuteHam(Ham_AddPoints, killer, 1, false);
	}

	CPlayer__Frozen(victim, killer);

#if defined FROZEN_MOD_API
	ExecuteForward(g_pForwards[ CLIENT_FROZEN_POST ], g_pResultDummy, victim, killer);
#endif // FROZEN_MOD_API

	return HAM_SUPERCEDE;
}

public CPointEntity__IceCubeThink(const ent)
{
	new id = entity_get_int(ent, DATA_CUBE_OWNER);

	if (!g_pPlayerInfo[ id ][ Player_Alive ])
		return HAM_IGNORED;

	static Float:flCurrentTime, Float:flHealth;
	static pEntBody, pEntCam, CsTeams:teamID, rescuedID;
	static Float:vecSrc[ 3 ], Float:vecEnd[ 3 ], Float:vecEndPos[ 3 ], Float:vecAiming[ 3 ], Float:vecOrigin[ 3 ], Float:vecVelocity[ 3 ], Float:vecAngle[ 3 ];

	static Float:__flNextUpdate[ MAX_CLIENTS + 1 ] = { 0.0, ... };
	static Float:__flNextSend[ MAX_CLIENTS + 1 ] = { 0.0, ... };

	static const iSkinCrack[] =
	{
		0,
		SKIN_ICECUB_T_CRACK,
		SKIN_ICECUB_CT_CRACK
	};

	if (!g_pPlayerInfo[ id ][ Player_Frozen ])
		return HAM_IGNORED;

	pEntBody = g_pPlayerInfo[ id ][ Player_EntBody ];
	pEntCam = g_pPlayerInfo[ id ][ Player_EntView ];
	teamID = g_pPlayerInfo[ id ][ Player_Teamid ];
	rescuedID = g_pPlayerInfo[ id ][ Player_Rescuerid ];

	if (!pev_valid(ent))
		return HAM_IGNORED;

	/*
	* forcing don't shoots
	*/
	set_member(id, m_flNextAttack, get_gametime() + 1.0);

	flCurrentTime = get_gametime();

	if (pev_valid(pEntCam) && pev_valid(pEntBody))
	{
		entity_get_vector(id, EV_VEC_v_angle, vecAngle);

		MAKE_VECTORS(vecAngle);

		new pTarget = g_pPlayerInfo[ id ][ Player_Target ];

		entity_get_vector(pTarget, EV_VEC_origin, vecOrigin);

		if (pTarget == ent)
			vecOrigin[ 2 ] += 36.0;

		vecSrc[ 0 ] = vecOrigin[ 0 ];
		vecSrc[ 1 ] = vecOrigin[ 1 ];
		vecSrc[ 2 ] = vecOrigin[ 2 ] + VEC_VIEW;

#if defined FROZEN_CUBE_MOBILE_OBJECT

		entity_get_vector(ent, EV_VEC_origin, vecOrigin);
		entity_get_vector(ent, EV_VEC_velocity, vecVelocity);

		if (entity_get_int(ent, DATA_CUBE_SMALL) != 1)
			vecOrigin[ 2 ] += 36.0;
		else
			vecOrigin[ 2 ] += 46.0;

		entity_set_vector(id, EV_VEC_origin, vecOrigin);
		entity_set_vector(id, EV_VEC_velocity, vecVelocity);

		entity_set_vector(pEntBody, EV_VEC_origin, vecOrigin);
		entity_set_vector(pEntBody, EV_VEC_velocity, vecVelocity);

		VectorCopy(vecOrigin, g_flLastOrigin[ id ]);

#endif // FROZEN_CUBE_MOBILE_OBJECT

		get_global_vector(GL_v_forward, vecAiming);

		VectorSubScalar(vecSrc, vecAiming, vecEnd, 128);

		trace_line(id, vecSrc, vecEnd, vecEndPos);

		entity_set_vector(ent, DATA_CUBE_ORIGIN, vecOrigin);
		entity_set_vector(pEntCam, EV_VEC_origin, vecEndPos);
		entity_set_vector(pEntCam, EV_VEC_angles, vecAngle);
	}

	new iMode = entity_get_int(ent, DATA_CUBE_MODE);
	if (iMode == MODE_CRACK && get_member_game(m_iRoundWinStatus) == 0)
	{
		CPlayer__UnFrozen(id, rescuedID);
		entity_set_int(ent, DATA_CUBE_MODE, MODE_SPAWN);
		entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.01);

		return HAM_IGNORED;
	}

	if (flCurrentTime > __flNextUpdate[ id ])
	{
		__flNextUpdate[ id ] = flCurrentTime + 0.1;
		flHealth = entity_get_float(ent, EV_FL_health);

		new Float:flLeft = ((flHealth - MIN_POOL_AMOUNT) / SPEED_DEFORST);
		if (flCurrentTime >= __flNextSend[ id ])
		{
			__flNextSend[ id ] = flCurrentTime + 1.0;

			if (entity_get_int(ent, EV_INT_skin) != iSkinCrack[ _:teamID ])
			{
				if (flHealth - MIN_POOL_AMOUNT <= ((CUBE_HEALTH - MIN_POOL_AMOUNT) / 2))
				{
					entity_set_int(ent, EV_INT_skin, iSkinCrack[ _:teamID ]);
					CEffects__BeamCylinder(vecOrigin, 150, 180.0, 60, { 100, 100, 100 }, g_iSpriteCrack, 5.0);
				}
			}

			/*
			* Update location frozen the players
			*/
			for (new i = 1; i <= g_iMaxPlayers; i++)
			{
				if (!g_pPlayerInfo[ i ][ Player_Alive ] || g_pPlayerInfo[ i ][ Player_Frozen ] || teamID != g_pPlayerInfo[ i ][ Player_Teamid ])
					continue;

				CPlayer__UpdatePosition(id, i, vecOrigin);
			}

			/*
			* Update RoundTime, the remaining time until full defrosted
			*/
			MESSAGE_BEGIN(MSG_ONE_UNRELIABLE, g_iUserMsg[ Message_RoundTime ], _, id);
			WRITE_SHORT(floatround(flLeft));
			MESSAGE_END();
		}
	}

	entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.01);
	return HAM_IGNORED;
}

public CBasePlayer__PreThink_Post(const id)
{
	static Float:flCurrentTime;
	static Float:__flNextUpdate[ MAX_CLIENTS + 1 ] = { 0.0, ... };

	flCurrentTime = get_gametime();

	g_pPlayerInfo[ id ][ Player_LastUpdate ] = _:flCurrentTime;

	if (g_pPlayerInfo[ id ][ Player_Alive ])
	{
		new Float:flProtectTime = g_pPlayerInfo[ id ][ Player_ProtectTime ];

		if (flProtectTime != 0.0)
		{
			new iButton = entity_get_int(id, EV_INT_button);

			if (flCurrentTime > flProtectTime || (iButton & (IN_ATTACK | IN_ATTACK2)))
			{
				set_ent_rendering(id);

				g_pPlayerInfo[ id ][ Player_ProtectTime ] = _:0.0;
				entity_set_float(id, EV_FL_takedamage, DAMAGE_YES);
			}
		}
	}

	new pEnt = g_pPlayerInfo[ id ][ Player_EntCube ];

	if (g_pPlayerInfo[ id ][ Player_Frozen ])
	{
		new iButton = entity_get_int(id, EV_INT_button);
		new iOldButtons = entity_get_int(id, EV_INT_oldbuttons);

		if (iButton & IN_ATTACK && !(iOldButtons & IN_ATTACK))
			CPlayer__HandleButtons(id, BUTTON_MOUSE1);

		else if (iButton & IN_ATTACK2 && !(iOldButtons & IN_ATTACK2))
			CPlayer__HandleButtons(id, BUTTON_MOUSE2);

#if !defined SOUND_HELP_AUTO

		if ((iButton & IN_USE) && !(iOldButtons & IN_USE) && flCurrentTime > g_pPlayerInfo[ id ][ Player_WaitHelp ] && entity_get_int(id, EV_INT_iuser2) == 0)
		{
			g_pPlayerInfo[ id ][ Player_WaitHelp ] = _:(flCurrentTime + HELP_TIME);
			EMIT_SOUND(id, CHAN_VOICE, SOUND_HELP_ME[ random_num(0, sizeof(SOUND_HELP_ME) - 1) ], VOL_NORM, ATTN_NORM);
			CPlayer__RadioIcon(id);
		}

#endif // SOUND_HELP_AUTO
	}
	if (pev_valid(pEnt) && flCurrentTime > __flNextUpdate[ id ])
	{
		__flNextUpdate[ id ] = flCurrentTime + 0.1;
		new Float:flHealth = entity_get_float(pEnt, EV_FL_health);

		/*
		* auto-defrosting
		*/

		new rescuedID = g_pPlayerInfo[ id ][ Player_Rescuerid ];

		if (rescuedID == NULL && !g_pPlayerInfo[ id ][ Player_Stay ])
		{
			flHealth -= (INTERP_TIME_DEFAULT * 1000.0 / TIME_DEFORSTING) * (CUBE_HEALTH - MIN_POOL_AMOUNT) / 100.0;

			if (flHealth > 0.0)
			{
				if (flHealth < MIN_POOL_AMOUNT)
				{
					new Float:vecOrigin[3];
					entity_get_vector(pEnt, DATA_CUBE_ORIGIN, vecOrigin);

					CPlayer__UnFrozenProccess(id, pEnt, vecOrigin, flHealth);
				}

				/*
				* reset view to owner, if the time nearing the end
				*/
				if (flHealth < MIN_POOL_AMOUNT + 20.0)
				{
					if (g_pPlayerInfo[ id ][ Player_Target ] != pEnt)
					{
						entity_set_int(id, EV_INT_iuser1, OBS_NONE);
						entity_set_int(id, EV_INT_iuser2, NULL);

						g_pPlayerInfo[ id ][ Player_Target ] = pEnt;
						g_pPlayerInfo[ id ][ Player_ButtonNext ] = _:(flCurrentTime + 90.0);

						UTIL__ScreenFade(id, 0x0005, 0, 0);
					}
				}

				entity_set_float(pEnt, EV_FL_health, flHealth);
				entity_set_float(pEnt, EV_FL_renderamt, flHealth);
			}
		}
	}

	return HAM_IGNORED;
}

public CBasePlayer__CS_RoundRespawn(const id)
{
	if (g_pPlayerInfo[ id ][ Player_Frozen ])
		return HAM_IGNORED;

	if (g_pPlayerInfo[ id ][ Player_SpawnLock ] || get_member_game(m_iRoundWinStatus) != 0)
		return HAM_SUPERCEDE;

#if defined WAIT_TO_NEXT_ROUND

	if (get_pgame_bool(m_bFirstConnected) && get_gametime() > get_member_game(m_fRoundCount) + ROUND_WAIT_NEXT)
		return HAM_SUPERCEDE;

#endif // WAIT_TO_NEXT_ROUND

	return HAM_IGNORED;
}

public CBasePlayer__TraceAttack(victim, idattacker, Float:damage, Float:direction[ 3 ], tracehandle, damagebits)
{
	return HAM_SUPERCEDE;
}

/*
* Blocked spawning the player
*/
public CBasePlayer__ResetMaxSpeed_Post(id)
{
	if (pev_valid(id) != PDATA_SAFE || get_member(id, m_iJoiningState) != 5)
		return;

#if defined WAIT_TO_NEXT_ROUND
	if ((!get_pgame_bool(m_bFirstConnected) || (get_gametime() <= get_member_game(m_fRoundCount) + ROUND_WAIT_NEXT)) && g_pPlayerInfo[ id ][ Player_State ] != JOIN_LOCK_SPAWN)
		return;
#else
	if (g_pPlayerInfo[ id ][ Player_State ] != JOIN_LOCK_SPAWN)
		return;
#endif // WAIT_TO_NEXT_ROUND

	set_member(id, m_iNumSpawns, 1);
	set_member(id, m_iJoiningState, 0);

	EnableHamForward(g_pHookTable[ InfoHook_RoundRespawn ]);
}

public CBasePlayer__Spawn_Pre(const id)
{
	CPlayer__InitStatusBar(id);

	if (pev_valid(id) != PDATA_SAFE)
		return HAM_IGNORED;

	/*
	* The player yet has not entered the game
	*/
	if (get_member(id, m_bJustConnected) & (1 << 0))
	{
		switch(CSaveRestore__ReadData(id))
		{
		case RETURN_BACK_GAME:
			g_pPlayerInfo[ id ][ Player_State ] = _:JOIN_TO_BACK_GAME;
		case RETURN_LOCK_SPAWN:
			g_pPlayerInfo[ id ][ Player_State ] = _:JOIN_LOCK_SPAWN;
		default:
			g_pPlayerInfo[ id ][ Player_State ] = _:JOIN_IN_TO_SPEC;
		}

		set_member_game(m_bMapHasBuyZone, true);
		return HAM_IGNORED;
	}

	if (g_pPlayerInfo[ id ][ Player_SpawnLock ])
	{
#if defined WAIT_TO_NEXT_ROUND
		goto _jump_loc;
	}

	if (g_pPlayerInfo[ id ][ Player_State ] != JOIN_IN_TO_GAME && !g_pPlayerInfo[ id ][ Player_Frozen ] && get_pgame_bool(m_bFirstConnected) && get_gametime() > get_pgame_float(m_fRoundCount) + ROUND_WAIT_NEXT)
	{
		set_dhudmessage(COLOR_DHUD_MESSAGE_USE, -1.0, 0.65, 2, 0.25, 5.0, 0.01, 0.5);
		show_dhudmessage(id, "%L", LANG_PLAYER, "FTM_MSG_NOT_ALLOW_INGAME");
_jump_loc:
#endif // WAIT_TO_NEXT_ROUND

		entity_set_int(id, EV_INT_deadflag, DEAD_RESPAWNABLE);
		entity_set_int(id, EV_INT_flags, entity_get_int(id, EV_INT_flags) & ~FL_FROZEN);

		return HAM_SUPERCEDE;
	}

	if (g_pPlayerInfo[ id ][ Player_State ] == JOIN_TO_BACK_GAME)
	{
		CSaveRestore__Delete(id);
		g_pPlayerInfo[ id ][ Player_Alive ] = false;
		cs_set_user_team(id, g_pPlayerInfo[ id ][ Player_Teamid ]);
	}
	else
		g_pPlayerInfo[ id ][ Player_Teamid ] = _:cs_get_user_team(id);

#if defined FROZEN_MOD_API
	ExecuteForward(g_pForwards[ CLIENT_SPAWN ], g_pResultDummy, id, _:g_pPlayerInfo[ id ][ Player_Teamid ]);
	if (g_pResultDummy == PLUGIN_HANDLED)
		return HAM_IGNORED;
#endif // FROZEN_MOD_API

	if (g_pPlayerInfo[ id ][ Player_Frozen ] && get_member(id, m_bNotKilled))
	{
		if (g_pPlayerInfo[ id ][ Player_ViewModel ])
		{
			set_pev(id, pev_viewmodel, g_pPlayerInfo[ id ][ Player_ViewModel ]);
			g_pPlayerInfo[ id ][ Player_ViewModel ] = 0;
		}
	}

	return HAM_IGNORED;
}

public CBasePlayer__Spawn_Post(const id)
{
	if (pev_valid(id) != PDATA_SAFE)
		return HAM_IGNORED;

	if (get_member(id, m_bJustConnected) & (1 << 0))
	{
		/*
		* Spawn on client_putinserver
		*/

		g_pPlayerInfo[ id ][ Player_VGUI ] = bool:!!(get_member(id, m_bVGUIMenus) & (1<<0));
		set_member(id, m_iHideHUD, get_member(id, m_iHideHUD) | HIDEHUD_TIMER | HIDEHUD_MONEY);
		return HAM_IGNORED;
	}

	if (!is_user_alive(id))
		return HAM_IGNORED;

#if defined INFO_VGUI_DISABLED
	if (g_pPlayerInfo[ id ][ Player_VGUI ])
	{
		client_print_color(id, DontChange, "%L", LANG_PLAYER, "FTM_NOTICE_VGUI", PREFIX);
		g_pPlayerInfo[ id ][ Player_VGUI ] = false;
	}
#endif // INFO_VGUI_DISABLED

	/*
	* Disable find buyzone of the nearest spawn
	*/
	set_member_game(m_bMapHasBuyZone, true);

	//g_pPlayerInfo[ id ][ Player_Teamid ] = _:cs_get_user_team(id);

	new bool:bIsFrozen = g_pPlayerInfo[ id ][ Player_Frozen ];

#if defined FROZEN_MOD_API
	ExecuteForward(g_pForwards[ CLIENT_SPAWN_PRE ], g_pResultDummy, id, bIsFrozen);
	if (g_pResultDummy == PLUGIN_HANDLED)
		return HAM_IGNORED;
#endif // FROZEN_MOD_API

	g_pPlayerInfo[ id ][ Player_SpawnLock ] = false;

	if (g_pPlayerInfo[ id ][ Player_State ] == JOIN_TO_BACK_GAME)
	{
		g_pPlayerInfo[ id ][ Player_Alive ] = true;
		g_pPlayerInfo[ id ][ Player_State ] = _:JOIN_IN_TO_GAME;

		CPlayer__Frozen(id);

		return HAM_IGNORED;
	}
	else
	{
		g_pPlayerInfo[ id ][ Player_Alive ] = true;
		g_pPlayerInfo[ id ][ Player_State ] = _:JOIN_IN_TO_GAME;
	}

	new rescuedID = g_pPlayerInfo[ id ][ Player_Rescuerid ];
	if (bIsFrozen)
		CPlayer__CleanFrozen(id);
	else
		g_pPlayerInfo[ id ][ Player_ProtectTime ] = _:0.0;

	/*
	* on default set full ammo of pistols
	*/
	switch (g_pPlayerInfo[ id ][ Player_Teamid ])
	{
	case CS_TEAM_CT:
		cs_set_user_bpammo(id, CSW_USP, 120);
	case CS_TEAM_T:
		cs_set_user_bpammo(id, CSW_GLOCK18, 120);
	}

	if (g_pPlayerInfo[ id ][ Player_AddHealth ] > 0.0)
	{
		/*
		* set only max health
		*/
		UTIL__SetHealth(id);
	}

	if (rescuedID)
		UTIL__BarTime(id, rescuedID);

#if defined FROZEN_MOD_API
	ExecuteForward(g_pForwards[ CLIENT_SPAWN_POST ], g_pResultDummy, id, bIsFrozen);
#endif // FROZEN_MOD_API

	set_member(id, m_iHideHUD, get_member(id, m_iHideHUD) | HIDEHUD_TIMER);

	/*
	* To force call message HideWeapon
	*/
	set_member(id, m_iClientHideHUD, 0);

	return HAM_IGNORED;
}

stock CFTMod__ClearStats()
{
	for (new i = 0; i < sizeof(g_iStats); i++)
	{
		g_iStats[ CsTeams:i ][ InfoStats_Frozen ] = 0;
		g_iStats[ CsTeams:i ][ InfoStats_Rescued ] = 0;
	}
}

stock CFTMod__CleanUpMap()
{
	new iFlags, iIndex;
	new pEnt = NULL;

	while ((pEnt = FIND_ENTITY_BY_CLASSNAME(pEnt, "info_target")) != NULL)
	{
		iFlags = entity_get_int(pEnt, EV_INT_flags);

		if (iFlags & FL_KILLME)
			continue;

		iIndex = entity_get_int(pEnt, EV_INT_impulse);

		if (iIndex != INFOTARGET_UID && iIndex != INFOCUBE_UID)
			continue;

		entity_set_int(pEnt, EV_INT_flags, iFlags | FL_KILLME);
	}
}

stock UTIL__LogPrintf(const fmt[], any:...)
{
#if defined DEBUG
	if (get_pcvar_num(g_pCvarDebug) <= 0)
		return;

	new const szPath[] = "/addons/amxmodx/logs/ftmod";

	if (!dir_exists(szPath))
		mkdir(szPath);

	static date[64],
		filedate[64],
		string[1024],
		filename[256];

	vformat(string, charsmax(string), fmt, 2);

	get_time("L_%d_%m_%Y", filedate, charsmax(filedate));
	get_time("%d/%m/%Y - %X", date, charsmax(date));

	format(string, charsmax(string), "%s: %s", date, string);
	formatex(filename, charsmax(filename), "%s/%s.log", szPath, filedate);

	write_file(filename, string);

#endif // DEBUG
}

stock CFTMod__addLog(const szBuffer[], any:...)
{
	log_message(szBuffer, any);
}

stock CFTMod__RegisterForwards()
{
	g_pForwards[ CLIENT_FROZEN ] = CreateMultiForward("ftm_client_frozen", ET_CONTINUE, FP_CELL, FP_CELL);
	g_pForwards[ CLIENT_FROZEN_POST ] = CreateMultiForward("ftm_client_frozen_post", ET_IGNORE, FP_CELL, FP_CELL);
	g_pForwards[ CLIENT_FROZEN_STUFF ] = CreateMultiForward("ftm_client_frozen_stuff", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_CELL);

	g_pForwards[ CLIENT_UNFROZEN ] = CreateMultiForward("ftm_client_unfrozen", ET_CONTINUE, FP_CELL, FP_CELL);
	g_pForwards[ CLIENT_UNFROZEN_POST ] = CreateMultiForward("ftm_client_unfrozen_post", ET_IGNORE, FP_CELL, FP_CELL);

	g_pForwards[ CLIENT_SPAWN ] = CreateMultiForward("ftm_client_spawn", ET_CONTINUE, FP_CELL, FP_CELL);
	g_pForwards[ CLIENT_SPAWN_PRE ] = CreateMultiForward("ftm_client_spawn_pre", ET_CONTINUE, FP_CELL, FP_CELL);
	g_pForwards[ CLIENT_SPAWN_POST ] = CreateMultiForward("ftm_client_spawn_post", ET_IGNORE, FP_CELL, FP_CELL);

	g_pForwards[ CLIENT_FIND_TARGET ] = CreateMultiForward("ftm_client_target", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
	g_pForwards[ CLIENT_FIND_OBS_TARGET ] = CreateMultiForward("ftm_client_find_obs_target", ET_IGNORE, FP_CELL, FP_CELL);
	g_pForwards[ CLIENT_UNFREEZE ] = CreateMultiForward("ftm_client_unfreeze", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL, FP_CELL);

	g_pForwards[ SERVER_ROUND_NEW ] = CreateMultiForward("ftm_round_new", ET_CONTINUE);
	g_pForwards[ SERVER_ROUND_END ] = CreateMultiForward("ftm_round_end", ET_CONTINUE, FP_CELL);
	g_pForwards[ SERVER_ROUND_RESTART ] = CreateMultiForward("ftm_round_restart", ET_CONTINUE);
	g_pForwards[ SERVER_CONDITIONS ] = CreateMultiForward("ftm_conditions", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL, FP_CELL);

	g_pForwards[ SHOP_ITEM_SELECTED ] = CreateMultiForward("ftm_shop_selected_item", ET_CONTINUE, FP_CELL, FP_CELL);
}

stock CFTMod__DestroyForwards()
{
	for (new INFO_FORWARDS:f = CLIENT_FROZEN; f <= SERVER_CONDITIONS; f++)
	{
		if (g_pForwards[ f ] != NULL)
			DestroyForward(g_pForwards[ f ]);
	}
}



stock CSaveRestore__WriteData(id)
{
	/*
	* If now havent event the end of the round
	*/
	if (get_member_game(m_iRoundWinStatus) != 0 || !get_member_game(m_bGameStarted))
		return;

	new bLockSpawn = g_pPlayerInfo[ id ][ Player_SpawnLock ];
	if (!g_pPlayerInfo[ id ][ Player_Frozen ] && !bLockSpawn)
		return;

	if (g_pPlayerInfo[ id ][ Player_Authid ][ 0 ] == 'S' && g_pPlayerInfo[ id ][ Player_Authid ][ 7 ] == ':')
	{
		if (!bLockSpawn)
		{
			TrieSetCell(g_gpSaveRestoreCache[ InfoStore_RoundPlayed ], g_pPlayerInfo[ id ][ Player_Authid ], g_pPlayerInfo[ id ][ Player_RoundPlayed ]);
			TrieSetArray(g_gpSaveRestoreCache[ InfoStore_Origin ], g_pPlayerInfo[ id ][ Player_Authid ], g_flLastOrigin[ id ], 3);
			TrieSetCell(g_gpSaveRestoreCache[ InfoStore_Teamid ], g_pPlayerInfo[ id ][ Player_Authid ], g_pPlayerInfo[ id ][ Player_Teamid ]);
		}
		else
			TrieSetCell(g_gpSaveRestoreCache[ InfoStore_SpawnLock ], g_pPlayerInfo[ id ][ Player_Authid ], g_pPlayerInfo[ id ][ Player_SpawnLock ]);

		TrieSetCell(g_gpSaveRestoreCache[ InfoStore_Stay ], g_pPlayerInfo[ id ][ Player_Authid ], g_pPlayerInfo[ id ][ Player_Stay ]);
	}
	if (!bLockSpawn)
	{
		TrieSetCell(g_gpSaveRestoreCache[ InfoStore_RoundPlayed ], g_pPlayerInfo[ id ][ Player_Ip ], g_pPlayerInfo[ id ][ Player_RoundPlayed ]);
		TrieSetArray(g_gpSaveRestoreCache[ InfoStore_Origin ], g_pPlayerInfo[ id ][ Player_Ip ], g_flLastOrigin[ id ], 3);
		TrieSetCell(g_gpSaveRestoreCache[ InfoStore_Teamid ], g_pPlayerInfo[ id ][ Player_Ip ], g_pPlayerInfo[ id ][ Player_Teamid ]);
	}
	else
		TrieSetCell(g_gpSaveRestoreCache[ InfoStore_SpawnLock ], g_pPlayerInfo[ id ][ Player_Ip ], g_pPlayerInfo[ id ][ Player_SpawnLock ]);

	TrieSetCell(g_gpSaveRestoreCache[ InfoStore_Stay ], g_pPlayerInfo[ id ][ Player_Ip ], g_pPlayerInfo[ id ][ Player_Stay ]);
}

stock CSaveRestore__Clear()
{
	TrieClear(g_gpSaveRestoreCache[ InfoStore_RoundPlayed ]);
	TrieClear(g_gpSaveRestoreCache[ InfoStore_Origin ]);
	TrieClear(g_gpSaveRestoreCache[ InfoStore_Teamid ]);
	TrieClear(g_gpSaveRestoreCache[ InfoStore_SpawnLock ]);
	TrieClear(g_gpSaveRestoreCache[ InfoStore_Stay ]);
}

stock CSaveRestore__Delete(const id)
{
	TrieDeleteKey(g_gpSaveRestoreCache[ InfoStore_RoundPlayed ], g_pPlayerInfo[ id ][ Player_Authid ]);
	TrieDeleteKey(g_gpSaveRestoreCache[ InfoStore_Origin ], g_pPlayerInfo[ id ][ Player_Authid ]);
	TrieDeleteKey(g_gpSaveRestoreCache[ InfoStore_Teamid ], g_pPlayerInfo[ id ][ Player_Authid ]);
	TrieDeleteKey(g_gpSaveRestoreCache[ InfoStore_SpawnLock ], g_pPlayerInfo[ id ][ Player_Authid ]);
	TrieDeleteKey(g_gpSaveRestoreCache[ InfoStore_Stay ], g_pPlayerInfo[ id ][ Player_Authid ]);

	TrieDeleteKey(g_gpSaveRestoreCache[ InfoStore_RoundPlayed ], g_pPlayerInfo[ id ][ Player_Ip ]);
	TrieDeleteKey(g_gpSaveRestoreCache[ InfoStore_Origin ], g_pPlayerInfo[ id ][ Player_Ip ]);
	TrieDeleteKey(g_gpSaveRestoreCache[ InfoStore_Teamid ], g_pPlayerInfo[ id ][ Player_Ip ]);
	TrieDeleteKey(g_gpSaveRestoreCache[ InfoStore_SpawnLock ], g_pPlayerInfo[ id ][ Player_Ip ]);
	TrieDeleteKey(g_gpSaveRestoreCache[ InfoStore_Stay ], g_pPlayerInfo[ id ][ Player_Ip ]);
}

// TODO: need to implement better
stock CSaveRestore__ReadData(const id)
{
	new iRestoreRoundsPlayed = -1;
	new iCurrentRoundsPlayed = get_member_game(m_iTotalRoundsPlayed);

	if (TrieKeyExists(g_gpSaveRestoreCache[ InfoStore_Stay ], g_pPlayerInfo[ id ][ Player_Authid ]))
	{
		TrieGetCell(g_gpSaveRestoreCache[ InfoStore_Stay ], g_pPlayerInfo[ id ][ Player_Authid ], g_pPlayerInfo[ id ][ Player_Stay ]);
	}
	else if (TrieKeyExists(g_gpSaveRestoreCache[ InfoStore_Stay ], g_pPlayerInfo[ id ][ Player_Ip ]))
	{
		TrieGetCell(g_gpSaveRestoreCache[ InfoStore_Stay ], g_pPlayerInfo[ id ][ Player_Ip ], g_pPlayerInfo[ id ][ Player_Stay ]);
	}

	if (TrieKeyExists(g_gpSaveRestoreCache[ InfoStore_SpawnLock ], g_pPlayerInfo[ id ][ Player_Authid ]))
	{
		TrieGetCell(g_gpSaveRestoreCache[ InfoStore_SpawnLock ], g_pPlayerInfo[ id ][ Player_Authid ], g_pPlayerInfo[ id ][ Player_SpawnLock ]);
		return RETURN_LOCK_SPAWN;
	}

	if (TrieKeyExists(g_gpSaveRestoreCache[ InfoStore_SpawnLock ], g_pPlayerInfo[ id ][ Player_Ip ]))
	{
		TrieGetCell(g_gpSaveRestoreCache[ InfoStore_SpawnLock ], g_pPlayerInfo[ id ][ Player_Ip ], g_pPlayerInfo[ id ][ Player_SpawnLock ]);
		return RETURN_LOCK_SPAWN;
	}

	if (TrieKeyExists(g_gpSaveRestoreCache[ InfoStore_RoundPlayed ], g_pPlayerInfo[ id ][ Player_Authid ]))
	{
		TrieGetCell(g_gpSaveRestoreCache[ InfoStore_RoundPlayed ], g_pPlayerInfo[ id ][ Player_Authid ], iRestoreRoundsPlayed);
		if (iRestoreRoundsPlayed != iCurrentRoundsPlayed)
		{
			return 0;
		}
		if (TrieKeyExists(g_gpSaveRestoreCache[ InfoStore_Origin ], g_pPlayerInfo[ id ][ Player_Authid ]))
		{
			TrieGetArray(g_gpSaveRestoreCache[ InfoStore_Origin ], g_pPlayerInfo[ id ][ Player_Authid ], g_flLastOrigin[ id ], 3);
			if (TrieKeyExists(g_gpSaveRestoreCache[ InfoStore_Teamid ], g_pPlayerInfo[ id ][ Player_Authid ]))
			{
				TrieGetCell(g_gpSaveRestoreCache[ InfoStore_Teamid ], g_pPlayerInfo[ id ][ Player_Authid ], g_pPlayerInfo[ id ][ Player_Teamid ]);
				return RETURN_BACK_GAME;
			}
		}
	}

	if (TrieKeyExists(g_gpSaveRestoreCache[ InfoStore_RoundPlayed ], g_pPlayerInfo[ id ][ Player_Ip ]))
	{
		if (iRestoreRoundsPlayed == -1)
		{
			TrieGetCell(g_gpSaveRestoreCache[ InfoStore_RoundPlayed ], g_pPlayerInfo[ id ][ Player_Ip ], iRestoreRoundsPlayed);

			if (iRestoreRoundsPlayed != iCurrentRoundsPlayed)
			{
				return 0;
			}
		}
		if (TrieKeyExists(g_gpSaveRestoreCache[ InfoStore_Origin ], g_pPlayerInfo[ id ][ Player_Ip ]))
		{
			if (VectorCompare(g_flLastOrigin[ id ], vecZero))
			{
				TrieGetArray(g_gpSaveRestoreCache[ InfoStore_Origin ], g_pPlayerInfo[ id ][ Player_Ip ], g_flLastOrigin[ id ], 3);
			}

			if (TrieKeyExists(g_gpSaveRestoreCache[ InfoStore_Teamid ], g_pPlayerInfo[ id ][ Player_Ip ]))
			{
				if (g_pPlayerInfo[ id ][ Player_Teamid ] == CS_TEAM_UNASSIGNED)
				{
					TrieGetCell(g_gpSaveRestoreCache[ InfoStore_Teamid ], g_pPlayerInfo[ id ][ Player_Ip ], g_pPlayerInfo[ id ][ Player_Teamid ]);
					return RETURN_BACK_GAME;
				}
			}
		}
	}
	return 0;
}

/*
* Block string cmd
*/
public client_command(id)
{
	if (!g_pPlayerInfo[ id ][ Player_Alive ])
		return 0;

	if ((!g_pPlayerInfo[ id ][ Player_Frozen ] && g_pPlayerInfo[ id ][ Player_Rescuerid ]) || g_pPlayerInfo[ id ][ Player_Frozen ])
	{
		new szCommand[ 32 ];
		read_argv(0, szCommand, charsmax(szCommand));

		if (equal(szCommand, "weapon_", 7))
			return 1;

		static const szCommandRsstrict[][] =
		{
			"jointeam",
			"joinclass",
			"chooseteam",
			"specmode",
			"lastinv",
			"drop"
		};

		for (new i; i < sizeof(szCommandRsstrict); i++)
		{
			if (equal(szCommand, szCommandRsstrict[ i ]))
				return 1;
		}
	}
	return 0;
}

stock CPlayer__IsValidTarget(const ent, const CsTeams:teamID)
{
	return (g_pPlayerInfo[ ent ][ Player_Alive ] && g_pPlayerInfo[ ent ][ Player_Teamid ] == teamID);
}

stock CPlayer__ObserverSpecifedTarget(const id, const target = 0)
{
	if (target)
		g_pPlayerInfo[ id ][ Player_Target ] = target;
	else
		g_pPlayerInfo[ id ][ Player_Target ] = g_pPlayerInfo[ id ][ Player_EntCube ];
}

stock CPlayer__ObserverFindNextTarget(const id, const HANDLE_BUTTON:Button)
{
	new pCurrentTarget;
	new pStart = g_pPlayerInfo[ id ][ Player_Target ];
	new CsTeams:teamID = g_pPlayerInfo[ id ][ Player_Teamid ];

	if (pStart <= 0 || pStart == g_pPlayerInfo[ id ][ Player_EntCube ])
		pStart = id;

	pCurrentTarget = pStart;

	new const iStepSize = (Button == BUTTON_MOUSE1) ? 1 : -1;

	do
	{
		pCurrentTarget += iStepSize;

		if (pCurrentTarget > g_iMaxPlayers)
			pCurrentTarget = 1;

		else if (pCurrentTarget < 1)
			pCurrentTarget = g_iMaxPlayers;

		/*
		* Ignore frozen the players, so the happened :/
		*/
		if (g_pPlayerInfo[ pCurrentTarget ][ Player_Frozen ] && pCurrentTarget != id)
			continue;

		if (CPlayer__IsValidTarget(pCurrentTarget, teamID))
			break;
	}
	while (pCurrentTarget != pStart);

	if (pCurrentTarget)
	{
		if (pCurrentTarget == id)
		{
			entity_set_int(id, EV_INT_iuser1, OBS_NONE);
			entity_set_int(id, EV_INT_iuser2, NULL);

			pCurrentTarget = g_pPlayerInfo[ id ][ Player_EntCube ];
		}
		else
		{
			entity_set_int(id, EV_INT_iuser1, OBS_CHASE_FREE);
			entity_set_int(id, EV_INT_iuser2, pCurrentTarget);
		}
	}

#if defined FROZEN_MOD_API
	ExecuteForward(g_pForwards[ CLIENT_FIND_OBS_TARGET ], g_pResultDummy, id, pCurrentTarget);
#endif // FROZEN_MOD_API

	return g_pPlayerInfo[ id ][ Player_Target ] = pCurrentTarget;
}

stock CPlayer__HandleButtons(const id, const HANDLE_BUTTON:Button)
{
	new Float:flHealth;
	new Float:flCurrentTime;

	flCurrentTime = get_gametime();
	if (g_pPlayerInfo[ id ][ Player_ButtonNext ] > flCurrentTime)
		return;

	flHealth = entity_get_float(g_pPlayerInfo[ id ][ Player_EntCube ], EV_FL_health);

	if (flHealth < MIN_POOL_AMOUNT + 20.0)
		return;

	g_pPlayerInfo[ id ][ Player_Target ] = CPlayer__ObserverFindNextTarget(id, Button);

	if (g_pPlayerInfo[ id ][ Player_Target ] != g_pPlayerInfo[ id ][ Player_EntCube ])
		UTIL__ScreenFade(id, .iDuration = 0, .iHoldTime = 0);
	else
		UTIL__ScreenFade(id, 0x0005, 0, 0);

	g_pPlayerInfo[ id ][ Player_ButtonNext ] = _:(flCurrentTime + 0.25);
}

stock CPlayer__CleanupEntity(const id)
{
	new pEnt = NULL;
	for (new i = Player_EntView; i <= Player_EntWeapon; i++)
	{
		pEnt = g_pPlayerInfo[ id ][ i ];

		if (!pev_valid(pEnt))
			continue;

		entity_set_int(pEnt, EV_INT_flags, entity_get_int(pEnt, EV_INT_flags) | FL_KILLME);
		g_pPlayerInfo[ id ][ i ] = 0;
	}
}

stock CPlayer__Frozen(const id, const killer = 0)
{
	if (!g_pPlayerInfo[ id ][ Player_Alive ] || g_pPlayerInfo[ id ][ Player_Frozen ] || pev_valid(id) != PDATA_SAFE)
		return;

	new Float:flCurrentTime = get_gametime();
	new iDeaths = get_member(id,m_iDeaths) + 1;
	new bDucking = !!(entity_get_int(id, EV_INT_flags) & FL_DUCKING);

	if (VectorCompare(g_flLastOrigin[ id ], vecZero))
		entity_get_vector(id, EV_VEC_origin, g_flLastOrigin[ id ]);

	set_member(id, m_iFOV, 0);
	set_member(id, m_iDeaths, iDeaths);

	UTIL__PlayerAllowShoot(id, false);

	new iHideHUD = (get_member(id, m_iHideHUD) & ~HIDEHUD_TIMER);
	iHideHUD |= (HIDEHUD_WEAPONS | HIDEHUD_HEALTH | HIDEHUD_FLASHLIGHT);

	set_member(id, m_iHideHUD, iHideHUD);
	//set_pdata_int(id, m_fInitHUD, 1);

	entity_set_int(id, EV_INT_effects, entity_get_int(id, EV_INT_effects) & ~EF_DIMLIGHT);

#if !defined SOUND_HELP_AUTO
	g_pPlayerInfo[ id ][ Player_WaitAlert ] = _:(flCurrentTime + 5.0);
#endif // SOUND_HELP_AUTO

	g_pPlayerInfo[ id ][ Player_RoundPlayed ] = get_member_game(m_iTotalRoundsPlayed);

	MESSAGE_BEGIN(MSG_ALL, g_iUserMsg[ Message_ScoreInfo ], _, NULL);
	WRITE_BYTE(id);
	WRITE_SHORT(floatround(entity_get_float(id, EV_FL_frags)));
	WRITE_SHORT(iDeaths);
	WRITE_SHORT(0);
	WRITE_SHORT(_:g_pPlayerInfo[ id ][ Player_Teamid ]);
	MESSAGE_END();

	MESSAGE_BEGIN(MSG_ALL, g_iUserMsg[ Message_ScoreAttrib ], _, NULL);
	WRITE_BYTE(id);
	WRITE_BYTE(1);
	MESSAGE_END();

#if defined FROZEN_STATUS_TEXT

#if defined FROZEN_STATUS_TEXT_WHO_KILLER
	if (killer != NULL && g_pPlayerInfo[ killer ][ Player_Ingame ])
	{
		new szBuffer[128];
		formatex(szBuffer, charsmax(szBuffer), "%L", LANG_PLAYER, "FTM_STATUS_KILLER");

		MESSAGE_BEGIN(MSG_ONE, g_iUserMsg[ Message_StatusText ], _, id);
		WRITE_BYTE(0);
		WRITE_STRING(szBuffer);
		MESSAGE_END();

		new Float:flHealth;
		flHealth = entity_get_float(killer, EV_FL_health);

		__newSBarState[ SBAR_ID_TARGETNAME ] = killer;
		__newSBarState[ SBAR_ID_TARGETTYPE ] = SBAR_TARGETTYPE_ENEMY;
		__newSBarState[ SBAR_ID_TARGETHEALTH ] = floatround(flHealth);

		for (new i = 1; i < SBAR_END; i++)
		{
			MESSAGE_BEGIN(MSG_ONE, g_iUserMsg[ Message_StatusValue ], _, id);
			WRITE_BYTE(i);
			WRITE_SHORT(__newSBarState[ i ]);
			MESSAGE_END();
		}
	}
	else
	{
#endif // FROZEN_STATUS_TEXT_WHO_KILLER

		MESSAGE_BEGIN(MSG_ONE, g_iUserMsg[ Message_StatusText ], _, id);
		WRITE_BYTE(0);
		WRITE_STRING("");
		MESSAGE_END();

#if defined FROZEN_STATUS_TEXT_WHO_KILLER
	}
#endif // FROZEN_STATUS_TEXT_WHO_KILLER

	CPlayer__InitStatusBar(id);

#endif // FROZEN_STATUS_TEXT

	g_pPlayerInfo[ id ][ Player_ViewModel ] = pev(id, pev_viewmodel);
	set_pev(id, pev_viewmodel, NULL);

	entity_set_int(id, EV_INT_solid, SOLID_NOT);
	entity_set_float(id, EV_FL_health, 100.0 + g_pPlayerInfo[ id ][ Player_AddHealth ]);

	entity_set_float(id, EV_FL_friction, 0.0);
	entity_set_float(id, EV_FL_renderamt, 0.0);
	entity_set_vector(id, EV_VEC_velocity, vecZero);

	entity_set_float(id, EV_FL_takedamage, DAMAGE_NO);
	entity_set_int(id, EV_INT_rendermode, kRenderTransTexture);

	g_pPlayerInfo[ id ][ Player_WaitHelp ] = _:(flCurrentTime + 5.0);
	g_pPlayerInfo[ id ][ Player_EntCube ] = UTIL__CreateCube(id, bDucking);
	g_pPlayerInfo[ id ][ Player_EntBody ] = UTIL__CreateBody(id, bDucking);
	g_pPlayerInfo[ id ][ Player_EntView ] = UTIL__CreateCamera(id);

	g_pPlayerInfo[ id ][ Player_Target ] = g_pPlayerInfo[ id ][ Player_EntCube ];
	g_pPlayerInfo[ id ][ Player_ButtonNext ] = _:(flCurrentTime + 2.0);

	UTIL__ScreenFade(id, 0x0005);

	// TODO: always alive?
	//g_pPlayerInfo[ id ][ Player_Alive ] = false;
	g_pPlayerInfo[ id ][ Player_Frozen ] = true;
	g_pPlayerInfo[ id ][ Player_Rescuerid ] = 0;

	EMIT_SOUND(id, CHAN_AUTO, SOUND_FROZEN, 1.0, ATTN_NORM);

	if (!CFTMod__ConditionsCheckWin())
	{
		set_dhudmessage(COLOR_DHUD_MESSAGE_USE, -1.0, 0.15, 2, 0.25, 3.0, 0.01, 0.5);
		show_dhudmessage(id, "%L", LANG_PLAYER, "FTM_MSG_NOTICE_FROZEN");
	}

	/*
	* checking on everything players stuck of cube
	*/
	UTIL__CheckValidOriginSphere(g_flLastOrigin[ id ]);

#if defined FROZEN_MOD_API

	ExecuteForward(g_pForwards[ CLIENT_FROZEN_STUFF ], g_pResultDummy, id, g_pPlayerInfo[ id ][ Player_EntCube ], g_pPlayerInfo[ id ][ Player_EntBody ], g_pPlayerInfo[ id ][ Player_EntView ]);

#endif // FROZEN_MOD_API
}

stock CPlayer__UnFrozen(const id, const rescued = 0)
{
#if defined FROZEN_MOD_API

	ExecuteForward(g_pForwards[ CLIENT_UNFROZEN ], g_pResultDummy, id, rescued);
	if (g_pResultDummy == PLUGIN_HANDLED)
		return;

#endif // FROZEN_MOD_API

	new pEnt = g_pPlayerInfo[ id ][ Player_EntCube ];

	if (pev_valid(pEnt))
		entity_set_int(pEnt, EV_INT_solid, SOLID_NOT);

	if (rescued && pev_valid(rescued) == PDATA_SAFE)
	{
		new CsTeams:teamID = g_pPlayerInfo[ rescued ][ Player_Teamid ];
		g_iStats[ teamID ][ InfoStats_Rescued ]++;

		ExecuteHam(Ham_AddPoints, rescued, 1, false);

		if ((DEFAULT_HEAHLT + g_pPlayerInfo[ rescued ][ Player_AddHealth ]) < MAX_HEALTH)
			client_print_color(rescued, DontChange, "%L", LANG_PLAYER, "FTM_AWARD_ADD_HP", PREFIX, GIVE_HEALTH_COUNT);

		UTIL__PlayerAllowShoot(rescued);
		UTIL__AddAccount(rescued, g_pPlayerInfo[ rescued ][ Player_Money ]);
		UTIL__SetHealth(rescued, GIVE_HEALTH_COUNT);
	}

	entity_get_vector(id, EV_VEC_angles, g_flLastAngles[ id ]);

	g_flLastAngles[ id ][ 0 ] = 0.0;
	g_flLastAngles[ id ][ 2 ] = 0.0;

	ExecuteHamB(Ham_CS_RoundRespawn, id);

#if defined FROZEN_MOD_API

	ExecuteForward(g_pForwards[ CLIENT_UNFROZEN_POST ], g_pResultDummy, id, rescued);

#endif // FROZEN_MOD_API
}

stock CPlayer__CleanFrozen(const id, bool:bIsKill = false)
{
	g_pPlayerInfo[ id ][ Player_Frozen ] = false;
	g_pPlayerInfo[ id ][ Player_ButtonNext ] = _:0.0;

	UTIL__ScreenFade(id);
	UTIL__PlayerAllowShoot(id);

	CPlayer__CleanupEntity(id);

	SET_VIEW(id, id);

	if (!bIsKill && g_pPlayerInfo[ id ][ Player_RoundPlayed ] == get_member_game(m_iTotalRoundsPlayed))
	{
		g_pPlayerInfo[ id ][ Player_ProtectTime ] = _:(get_gametime() + TIME_PROTECT_SPAWN);

		entity_set_vector(id, EV_VEC_angles, g_flLastAngles[ id ]);
		entity_set_int(id, EV_INT_fixangle, 1);

		if (g_pPlayerInfo[ id ][ Player_LastUpdate ] + 2.0 >= get_gametime())
		{
			if (g_pPlayerInfo[ id ][ Player_Teamid ] == CS_TEAM_CT)
				set_ent_rendering(id, kRenderFxGlowShell, 10, 124, 255, kRenderNormal, 25);
			else
				set_ent_rendering(id, kRenderFxGlowShell, 255, 10, 50, kRenderNormal, 25);

			entity_set_float(id, EV_FL_takedamage, DAMAGE_NO);
		}
		else
			set_ent_rendering(id);

		if (!VectorCompare(g_flLastOrigin[ id ], vecZero))
		{
			if (!UTIL__SetOriginSafe(id, g_flLastOrigin[ id ]))
				SET_ORIGIN(id, g_flLastOrigin[ id ]);

			memset(_:g_flLastOrigin[ id ], 0, 3);
		}
	}
	else
	{
		entity_set_int(id, EV_INT_iuser1, OBS_NONE);
		entity_set_int(id, EV_INT_iuser2, NULL);

		entity_set_float(id, EV_FL_renderamt, 255.0);
		entity_set_float(id, EV_FL_takedamage, DAMAGE_YES);
		entity_set_int(id, EV_INT_rendermode, kRenderNormal);
	}
}

stock CPlayer__RadioIcon(const id)
{
	MESSAGE_BEGIN(MSG_BROADCAST, SVC_TEMPENTITY, _, id);
	WRITE_BYTE(TE_PLAYERATTACHMENT);
	WRITE_BYTE(id);
	WRITE_COORD(60);
	WRITE_SHORT(g_iSpriteRadio);
	WRITE_SHORT(15);
	MESSAGE_END();
}

stock CPlayer__UnFrozenProccess(const id, const ent,const Float:vecOrigin[3], const Float:flRenderAmount)
{
	new iMode = entity_get_int(ent, DATA_CUBE_MODE);
	if (iMode == MODE_NONE && flRenderAmount < MIN_POOL_AMOUNT)
	{
		EMIT_SOUND(id, CHAN_AUTO, SOUND_FROZEN_BREAK, VOL_NORM, ATTN_NORM);
		entity_set_int(ent, DATA_CUBE_MODE, MODE_CRACK);

		MESSAGE_BEGIN_F(MSG_PVS, SVC_TEMPENTITY, vecOrigin, NULL);
		WRITE_BYTE(TE_BREAKMODEL);
		WRITE_COORD_F(vecOrigin[ 0 ]);
		WRITE_COORD_F(vecOrigin[ 1 ]);
		WRITE_COORD_F(vecOrigin[ 2 ] + 50.0);
		WRITE_COORD(16);
		WRITE_COORD(16);
		WRITE_COORD(16);
		WRITE_COORD(random_num(-50, 50));
		WRITE_COORD(random_num(-50, 50));
		WRITE_COORD(20);
		WRITE_BYTE(10);
		WRITE_SHORT(g_iModelGlass);
		WRITE_BYTE(15);
		WRITE_BYTE(25);
		WRITE_BYTE(1);
		MESSAGE_END();
	}
}

stock CFTMod__ConditionsCheckWin()
{
	if (get_member_game(m_iRoundWinStatus) != 0)
		return 1;

	enum __DATA_BUFFER
	{
		Data_Alive,
		Data_Frozen
	};

	new pData[ CsTeams ][ __DATA_BUFFER ];
	for (new i = 1; i <= g_iMaxPlayers; i++)
	{
		if (!g_pPlayerInfo[ i ][ Player_Ingame ] || pev_valid(i) != PDATA_SAFE)
			continue;

		switch ((g_pPlayerInfo[ i ][ Player_Teamid ] = _:cs_get_user_team(i)))
		{
			case CS_TEAM_T:
			{
				if (g_pPlayerInfo[ i ][ Player_Frozen ])
					pData[ CS_TEAM_T ][ Data_Frozen ]++;

				else if ((g_pPlayerInfo[ i ][ Player_Alive ] = bool:is_user_alive(i)))
					pData[ CS_TEAM_T ][ Data_Alive ]++;
			}
			case CS_TEAM_CT:
			{
				if (g_pPlayerInfo[ i ][ Player_Frozen ])
					pData[ CS_TEAM_CT ][ Data_Frozen ]++;

				else if ((g_pPlayerInfo[ i ][ Player_Alive ] = bool:is_user_alive(i)))
					pData[ CS_TEAM_CT ][ Data_Alive ]++;
			}
		}
	}

#if defined FROZEN_MOD_API
	ExecuteForward(g_pForwards[ SERVER_CONDITIONS ], g_pResultDummy, pData[ CS_TEAM_T ][ Data_Alive ], pData[ CS_TEAM_T ][ Data_Frozen ], pData[ CS_TEAM_T ][ Data_Alive ], pData[ CS_TEAM_T ][ Data_Frozen ]);
	if (g_pResultDummy == PLUGIN_HANDLED)
		return 0;
#endif // FROZEN_MOD_API

	if (pData[ CS_TEAM_T ][ Data_Alive ] > 1 && pData[ CS_TEAM_CT ][ Data_Alive ] > 1)
		return 0;

	new WinStatus:iTeamWin;
	
	if (pData[ CS_TEAM_T ][ Data_Alive ] > 0 || pData[ CS_TEAM_CT ][ Data_Alive ] > 0)
	{
		if (pData[ CS_TEAM_T ][ Data_Alive ] == 0 && pData[ CS_TEAM_T ][ Data_Frozen ])
			iTeamWin = WINSTATUS_CTS;

		else if (pData[ CS_TEAM_CT ][ Data_Alive ] == 0 && pData[ CS_TEAM_CT ][ Data_Frozen ])
			iTeamWin = WINSTATUS_TERRORISTS;
	}
	else
		iTeamWin = WINSTATUS_DRAW;

	if (iTeamWin >= WINSTATUS_CTS)
	{
		static const szTeamWins[ WinStatus ][] =
		{
			"",
			"FTM_MSG_WIN_CT",
			"FTM_MSG_WIN_T",
			"FTM_MSG_WIN_DRAW"
		};

#if defined FROZEN_MOD_API
		ExecuteForward(g_pForwards[ SERVER_ROUND_END ], g_pResultDummy, iTeamWin);
		if (g_pResultDummy == PLUGIN_HANDLED)
			return 0;
#endif // FROZEN_MOD_API
		
		
		/*
		* forcing to block everything plugins used with Ham_CS_RoundRespawn
		* so also from CSDM spawning
		*/
		//EnableHamForward(g_pHookTable[ InfoHook_RoundRespawn ]);
		//EnableHamForward(g_pHookTable[ InfoHook_TraceAttack ]);
		//DisableHamForward(g_pHookTable[ InfoHook_ObjectCaps ]);

		/*
		* to block the spawning of new players
		*/

		
		get_member_game(m_fRoundStartTime, -25.0);

		switch (iTeamWin)
		{
			case WINSTATUS_DRAW:
				client_print_color(0, Grey, "%L", LANG_PLAYER, "FTM_WIN_DRAW", PREFIX, LANG_PLAYER, szTeamWins[ WINSTATUS_DRAW ]);

			case WINSTATUS_CTS:
			{
				client_print_color(0, Blue, "%L", LANG_PLAYER, "FTM_WIN_CT", PREFIX, LANG_PLAYER, szTeamWins[ WINSTATUS_CTS ], g_iStats[ CS_TEAM_CT ][ InfoStats_Frozen ], g_iStats[ CS_TEAM_CT ][ InfoStats_Rescued ]);
				UTIL__GiveMoneyAward(CS_TEAM_CT);
			}
			case WINSTATUS_TERRORISTS:
			{
				client_print_color(0, Red, "%L", LANG_PLAYER, "FTM_WIN_T", PREFIX, LANG_PLAYER, szTeamWins[ WINSTATUS_TERRORISTS ], g_iStats[ CS_TEAM_T ][ InfoStats_Frozen ], g_iStats[ CS_TEAM_T ][ InfoStats_Rescued ]);
				UTIL__GiveMoneyAward(CS_TEAM_T);
			}
		}

#if defined DEBUG

		new isCount_T, isCount_CT;

		for (new i = 1; i <= g_iMaxPlayers; i++)
		{
			if (!is_user_alive(i))
				continue;

			if (!g_pPlayerInfo[ i ][ Player_Frozen ])
			{
				if (g_pPlayerInfo[ i ][ Player_Teamid ] == CS_TEAM_CT)
					isCount_CT++;

				else if (g_pPlayerInfo[ i ][ Player_Teamid ] == CS_TEAM_T)
					isCount_T++;
			}
		}

#endif // DEBUG

		rg_round_end(1.0, iTeamWin); 

		CSaveRestore__Clear();
		CFTMod__ClearStats();

		return 1;
	}
	return 0;
	
}

stock CPlayer__InitStatusBar(id)
{
	set_member(id, m_flStatusBarDisappearDelay, 0.0);
	__SbarString[ id ][ 0 ] = '\0';
}

stock CPlayer__UpdateStatusBar(id, tracehandle)
{
	static sbuf0[ SBAR_STRING_SIZE ];

	new pOwner, pEnt;
	new Float:flFraction, Float:flHealth;

	memset(__newSBarState, 0, SBAR_END);

	get_tr2(tracehandle, TR_flFraction, flFraction);
	copy(sbuf0, charsmax(sbuf0), __SbarString[ id ]);

	if (flFraction != 1.0)
	{
		pEnt = get_tr2(tracehandle, TR_pHit);

		if (pev_valid(pEnt))
		{
			flHealth = entity_get_float(pEnt, EV_FL_health);
			if (ExecuteHam(Ham_Classify, pEnt) == CLASS_PLAYER)
			{
				__newSBarState[ SBAR_ID_TARGETNAME ] = pEnt;
				__newSBarState[ SBAR_ID_TARGETTYPE ] = (g_pPlayerInfo[ id ][ Player_Teamid ] == g_pPlayerInfo[ pEnt ][ Player_Teamid ]) ? SBAR_TARGETTYPE_TEAMMATE : SBAR_TARGETTYPE_ENEMY;

				if (g_pPlayerInfo[ id ][ Player_Teamid ] == g_pPlayerInfo[ pEnt ][ Player_Teamid ])
				{
					formatex(sbuf0, charsmax(sbuf0), "%L", LANG_PLAYER, "FTM_STATUS_TEXT_TEAMMATE");
					__newSBarState[ SBAR_ID_TARGETHEALTH ] = floatround(flHealth);

				}
				else
					formatex(sbuf0, charsmax(sbuf0), "%L", LANG_PLAYER, "FTM_STATUS_TEXT_ENEMY");
			}
			else if (entity_get_int(pEnt, EV_INT_impulse) == INFOCUBE_UID)
			{
				pOwner = entity_get_int(pEnt, DATA_CUBE_OWNER);
				if (pOwner != id && pOwner > 0 && g_pPlayerInfo[ pOwner ][ Player_Frozen ])
				{
#if !defined FROZEN_STATUS_TEXT_ENEMIES
					if (g_pPlayerInfo[ id ][ Player_Teamid ] == g_pPlayerInfo[ pEnt ][ Player_Teamid ])
					{
#endif // FROZEN_STATUS_TEXT_ENEMIES
					flHealth -= MIN_POOL_AMOUNT;
					formatex(sbuf0, charsmax(sbuf0), "%L", LANG_PLAYER, "FTM_STATUS_TEXT_FROZEN");

					__newSBarState[ SBAR_ID_TARGETNAME ] = pOwner;
					__newSBarState[ SBAR_ID_TARGETTYPE ] = (g_pPlayerInfo[ id ][ Player_Teamid ] == g_pPlayerInfo[ pOwner ][ Player_Teamid ]) ? SBAR_TARGETTYPE_TEAMMATE : SBAR_TARGETTYPE_ENEMY;
					__newSBarState[ SBAR_ID_TARGETHEALTH ] = floatround(flHealth / (CUBE_HEALTH - MIN_POOL_AMOUNT) * 100.0);

					set_member(id, m_flStatusBarDisappearDelay, get_gametime() + 2.0);
#if !defined FROZEN_STATUS_TEXT_ENEMIES
					}
#endif // FROZEN_STATUS_TEXT_ENEMIES
				}
			}
		}
	}
	else if (get_member(id, m_flStatusBarDisappearDelay) > get_gametime())
	{
		__newSBarState[ SBAR_ID_TARGETTYPE ] = __izSBarState[ id ][ SBAR_ID_TARGETTYPE ];
		__newSBarState[ SBAR_ID_TARGETNAME ] = __izSBarState[ id ][ SBAR_ID_TARGETNAME ];
		__newSBarState[ SBAR_ID_TARGETHEALTH ] = __izSBarState[ id ][ SBAR_ID_TARGETHEALTH ];
	}

	new bool:bForceResend = false;
	if (strcmp(sbuf0, __SbarString[ id ]) != 0)
	{
		MESSAGE_BEGIN(MSG_ONE, g_iUserMsg[ Message_StatusText ], _, id);
		WRITE_BYTE(0);
		WRITE_STRING(sbuf0);
		MESSAGE_END();

		copy(__SbarString[ id ], charsmax(__SbarString[]), sbuf0);

		bForceResend = true;
	}

	for (new i = 1; i < SBAR_END; i++)
	{
		if (__newSBarState[ i ] != __izSBarState[ id ][ i ] || bForceResend)
		{
			MESSAGE_BEGIN(MSG_ONE, g_iUserMsg[ Message_StatusValue ], _, id);
			WRITE_BYTE(i);
			WRITE_SHORT(__newSBarState[ i ]);
			MESSAGE_END();

			__izSBarState[ id ][ i ] = __newSBarState[ i ];
		}
	}
}

stock CPlayer__UpdatePosition(const id, const iSend, const Float:vecOrigin[ 3 ])
{
	MESSAGE_BEGIN(MSG_ONE_UNRELIABLE, g_iUserMsg[ Message_HostagePos ], _, iSend);
	WRITE_BYTE(0);
	WRITE_BYTE(id);
	WRITE_COORD_F(vecOrigin[ 0 ]);
	WRITE_COORD_F(vecOrigin[ 1 ]);
	WRITE_COORD_F(vecOrigin[ 2 ]);
	MESSAGE_END();

	MESSAGE_BEGIN(MSG_ONE_UNRELIABLE, g_iUserMsg[ Message_HostageK ], _, iSend);
	WRITE_BYTE(id);
	MESSAGE_END();
}

stock UTIL__GiveMoneyAward(const CsTeams:iTeamWin)
{
	new CsTeams:teamID;
	for (new i = 1; i <= g_iMaxPlayers; i++)
	{
		if (!g_pPlayerInfo[ i ][ Player_Ingame ] || g_pPlayerInfo[ i ][ Player_State ] != JOIN_IN_TO_GAME || pev_valid(i) != PDATA_SAFE)
			continue;

		teamID = g_pPlayerInfo[ i ][ Player_Teamid ];

		if (!(CS_TEAM_T <= teamID <= CS_TEAM_CT))
			continue;

		/*
		* reset BarTime
		*/
		if (g_pPlayerInfo[ i ][ Player_Rescuerid ] > 0)
		{
			g_pPlayerInfo[ i ][ Player_Rescuerid ] = 0;

			MESSAGE_BEGIN(MSG_ONE_UNRELIABLE, g_iUserMsg[ Message_BarTime ], _, i);
			WRITE_SHORT(0);
			MESSAGE_END();
		}

		g_pPlayerInfo[ i ][ Player_Money ] += (teamID == iTeamWin) ? ROUND_MONEY_WIN : ROUND_MONEY_LOSE;

		/*
		* Remove all items on next spawn
		*/
		if (teamID != iTeamWin)
			set_member(i, m_bNotKilled, 0);

		//set_pdata_int(i, m_iAccount, g_pPlayerInfo[ i ][ Player_Money ]);
	}
}

stock UTIL__BarTime(const id, const rescued = 0, const iTime = 0)
{
#if defined FROZEN_BARTIME

	MESSAGE_BEGIN(MSG_ONE_UNRELIABLE, g_iUserMsg[ Message_BarTime ], _, id);
	WRITE_SHORT(iTime);
	MESSAGE_END();

	if (rescued && g_pPlayerInfo[ rescued ][ Player_Ingame ])
	{
		MESSAGE_BEGIN(MSG_ONE_UNRELIABLE, g_iUserMsg[ Message_BarTime ], _, rescued);
		WRITE_SHORT(iTime);
		MESSAGE_END();
	}

#endif // FROZEN_BARTIME

	if (iTime)
	{
		g_pPlayerInfo[ id ][ Player_Rescuerid ] = rescued;
		g_pPlayerInfo[ rescued ][ Player_Rescuerid ] = id;
	}
	else
	{
		g_pPlayerInfo[ id ][ Player_Rescuerid ] = 0;
		g_pPlayerInfo[ rescued ][ Player_Rescuerid ] = 0;
	}
}

stock UTIL__UpdateCurWeapon(const id)
{
	static __msgidCurWeapon = 0;

	new pActiveItem = get_pdata_cbase(id, m_pActiveItem);

	if (pev_valid(pActiveItem) != PDATA_SAFE)
		return;

	if (__msgidCurWeapon || (__msgidCurWeapon = get_user_msgid("CurWeapon")))
	{
		MESSAGE_BEGIN(MSG_ONE, __msgidCurWeapon, _, id);
		WRITE_BYTE(get_pdata_int(pActiveItem, m_iClientWeaponState));
		WRITE_BYTE(get_pdata_int(pActiveItem, m_iId));
		WRITE_BYTE(get_pdata_int(pActiveItem, m_iClip));
		MESSAGE_END();
	}
}

stock UTIL__ScreenFade(const id, const iFlags = 0x0000, const iDuration = (1 << 11), const iHoldTime = (1 << 12))
{
	MESSAGE_BEGIN(MSG_ONE_UNRELIABLE, g_iUserMsg[ Message_ScreenFade ], _, id);
	WRITE_SHORT(iDuration);
	WRITE_SHORT(iHoldTime);
	WRITE_SHORT(iFlags);

	if (g_pPlayerInfo[ id ][ Player_Teamid ] == CS_TEAM_CT)
	{
		WRITE_BYTE(0);
		WRITE_BYTE(255);
		WRITE_BYTE(255);
	}
	else
	{
		WRITE_BYTE(255);
		WRITE_BYTE(35);
		WRITE_BYTE(0);
	}

	WRITE_BYTE(15);
	MESSAGE_END();
}

/*
* Create fake body for visuality
*/
stock UTIL__CreateBody(const id, const bDucking)
{
	static szModel[ 100 ], szModelPath[ 100 ];

	new Float:vecAngle[ 3 ];
	new pEnt = CREATE_NAMED_ENTITY("info_target");

	if (!pEnt)
		return NULL;

	entity_get_vector(id, EV_VEC_v_angle, vecAngle);
	entity_set_float(pEnt, EV_FL_framerate, 1.0);

	new frameExt = bDucking ? 0 : random_num(1, charsmax(AnimationsData));

	entity_set_float(pEnt, EV_FL_frame, AnimationsData[ frameExt ][ Animation_Frame ]);
	entity_set_int(pEnt, EV_INT_sequence, AnimationsData[ frameExt ][ Animation_Number ]);

	if (get_member(id, m_LastHitGroup) == HIT_HEAD)
	{
		vecAngle[ 1 ] -= random_float(10.0, 20.0);
		vecAngle[ 2 ] += random_float(10.0, 20.0);
	}

	cs_get_user_model(id, szModel, charsmax(szModel));
	formatex(szModelPath, charsmax(szModelPath), "models/player/%s/%s.mdl", szModel, szModel);

#if defined FROZEN_CUBE_MOBILE_OBJECT

	entity_set_int(pEnt, EV_INT_movetype, MOVETYPE_PUSHSTEP);

#endif // FROZEN_CUBE_MOBILE_OBJECT

	entity_set_vector(pEnt, EV_VEC_angles, vecAngle);
	entity_set_vector(pEnt, EV_VEC_origin, g_flLastOrigin[ id ]);
	entity_set_int(pEnt, EV_INT_impulse, INFOTARGET_UID);

	SET_MODEL(pEnt, szModelPath);
	/*
	* Create fake weapons in hands
	*/

	entity_get_string(id, EV_SZ_weaponmodel, szModel, charsmax(szModel));
	if (szModel[ 0 ] != '\0')
	{
		new pWeapon = CREATE_NAMED_ENTITY("info_target");

		if (pWeapon)
		{
			entity_set_int(pWeapon, EV_INT_impulse, INFOTARGET_UID);

			entity_set_edict(pWeapon, EV_ENT_owner, id);
			entity_set_edict(pWeapon, EV_ENT_aiment, pEnt);

			entity_set_int(pWeapon, EV_INT_solid, SOLID_NOT);
			entity_set_int(pWeapon, EV_INT_movetype, MOVETYPE_FOLLOW);
			entity_set_float(pWeapon, EV_FL_takedamage, DAMAGE_NO);

			g_pPlayerInfo[ id ][ Player_EntWeapon ] = pWeapon;
			SET_MODEL(pWeapon, szModel);
		}
	}

	return pEnt;
}

/*
* Create camera for to browse around yourself
*/
stock UTIL__CreateCamera(id)
{
	new pEnt = CREATE_NAMED_ENTITY("info_target");

	if (!pEnt)
		return NULL;

	SET_MODEL(pEnt, FROZEN_CUBE);
	SET_SIZE(pEnt, vecZero, vecZero);

	entity_set_int(pEnt, EV_INT_movetype, MOVETYPE_NOCLIP);
	entity_set_int(pEnt, EV_INT_solid, SOLID_NOT);
	entity_set_float(pEnt, EV_FL_takedamage, DAMAGE_NO);
	entity_set_float(pEnt, EV_FL_gravity, 0.0);
	entity_set_int(pEnt, EV_INT_impulse, INFOTARGET_UID);

	entity_set_float(pEnt, EV_FL_renderamt, 0.0);
	entity_set_int(pEnt, EV_INT_rendermode, kRenderTransTexture);

	SET_VIEW(id, pEnt);

	return pEnt;
}

/*
* Create cube for blocking move and is the important part
*/
stock UTIL__CreateCube(const id, const bDucking)
{
	new pEnt = CREATE_NAMED_ENTITY("info_target");

	if (!pEnt)
		return NULL;

	new iPallete[ 3 ];
	new Float:vecOrigin[ 3 ];
	new iIndex, iIndexTrail;

	VectorCopy(g_flLastOrigin[ id ], vecOrigin);

	if (g_pPlayerInfo[ id ][ Player_Teamid ] == CS_TEAM_T)
	{
		iPallete = { 255, 10, 50 };
		iIndex = g_iSprSnowT;
		iIndexTrail = g_iSprTrailT;
	}
	else
	{
		iPallete = { 10, 124, 255 };
		iIndex = g_iSprSnowCT;
		iIndexTrail = g_iSprTrailCT;
	}

	CEffects__SpriteTrail(vecOrigin, random_num(6, 9), 3, iIndex);
	CEffects__SpriteTrail(vecOrigin, random_num(15, 20), 2, iIndex);
	CEffects__SpriteTrail(vecOrigin, random_num(6, 9), 1, iIndex);

	CEffects__BeamCylinder(vecOrigin, 255, 150.0, 150, iPallete, iIndexTrail, 25.0);
	CEffects__BeamCylinder(vecOrigin, 150, 100.0, 100, iPallete, iIndexTrail, 25.0);
	CEffects__BeamCylinder(vecOrigin, 65, 50.0, 50, iPallete, iIndexTrail, 25.0);

	CEffects__Light(vecOrigin, iPallete);

	vecOrigin[ 2 ] -= bDucking ? 27.0 : 36.0;

	SET_MODEL(pEnt, FROZEN_CUBE);
	DispatchSpawn(pEnt);

	entity_set_string(pEnt, EV_SZ_classname, "info_icecube");
	entity_set_float(pEnt, EV_FL_nextthink, get_gametime() + 0.1);

	/*
	* Owner
	*/
	entity_set_int(pEnt, DATA_CUBE_OWNER, id);
	entity_set_int(pEnt, DATA_CUBE_TEAMID, _:g_pPlayerInfo[ id ][ Player_Teamid ]);
	entity_set_vector(pEnt, EV_VEC_origin, vecOrigin);

	entity_set_int(pEnt, EV_INT_solid, SOLID_BBOX);
	entity_set_int(pEnt, EV_INT_impulse, INFOCUBE_UID);

#if defined FROZEN_CUBE_MOBILE_OBJECT
	entity_set_int(pEnt, EV_INT_movetype, MOVETYPE_PUSHSTEP);
#endif // FROZEN_CUBE_MOBILE_OBJECT

	if (bDucking)
		SET_SIZE(pEnt, Float:{ -24.0, -24.0, 10.0 }, Float:{ 24.0, 24.0, 68.0 });
	else
		SET_SIZE(pEnt, Float:{ -24.0, -24.0, 0.0 }, Float:{ 24.0, 24.0, 78.0 });

	entity_set_float(pEnt, EV_FL_takedamage, DAMAGE_YES);

	entity_set_int(pEnt, EV_INT_skin, (g_pPlayerInfo[ id ][ Player_Teamid ] == CS_TEAM_CT) ? SKIN_ICECUB_CT : SKIN_ICECUB_T);
	entity_set_int(pEnt, EV_INT_body, bDucking);

	entity_set_float(pEnt, EV_FL_health, CUBE_HEALTH);
	entity_set_float(pEnt, EV_FL_renderamt, CUBE_HEALTH);

	entity_set_int(pEnt, EV_INT_rendermode, kRenderTransAdd);
	entity_set_vector(pEnt, EV_VEC_rendercolor, Float:{ 255.0, 255.0, 255.0 });//?

	return pEnt;
}

stock UTIL__GetWeaponByKiller(pKiller, pInflictor, szBuffer[], iLen)
{
	new szWeaponName[ 32 ] = "world";

	if (pev_valid(pKiller) == PDATA_SAFE && (entity_get_int(pKiller, EV_INT_flags) & FL_CLIENT))
	{
		if (pev_valid(pInflictor))
		{
			if (pInflictor == pKiller)
			{
				new weaponId = get_user_weapon(pKiller);
				get_weaponname(weaponId, szWeaponName, charsmax(szWeaponName));
			}
			else entity_get_string(pInflictor, EV_SZ_classname, szWeaponName, charsmax(szWeaponName));
		}
	}
	else
	{
		if (pev_valid(pKiller) == PDATA_SAFE)
			entity_get_string(pInflictor, EV_SZ_classname, szWeaponName, charsmax(szWeaponName));

		else if (!pKiller)
			szWeaponName = "worldspawn";
	}

	if (equal(szWeaponName, "weapon_", 7))
		copy(szWeaponName, charsmax(szWeaponName), szWeaponName[ 7 ]);

	copy(szBuffer, iLen, szWeaponName);
}

stock UTIL__AddAccount(const id, const iAmount, const bTrackChange = 1)
{
	set_member(id, m_iAccount, iAmount);

	MESSAGE_BEGIN(MSG_ONE, g_iUserMsg[ Message_Money ], _, id);
	WRITE_LONG(iAmount);
	WRITE_BYTE(bTrackChange);
	MESSAGE_END();
}

stock UTIL__SetHealth(const id, const Float:flAddHealth = 0.0, const bSetHealth = 1)
{
	new Float:flCurrentHealth;

	if (bSetHealth)
	{
		flCurrentHealth = entity_get_float(id, EV_FL_health);
		flCurrentHealth += flAddHealth;

		if (flCurrentHealth >= MAX_HEALTH)
			flCurrentHealth = MAX_HEALTH;

		entity_set_float(id, EV_FL_health, flCurrentHealth);
	}

	g_pPlayerInfo[ id ][ Player_AddHealth ] += flAddHealth;

	if (g_pPlayerInfo[ id ][ Player_AddHealth ] > (MAX_HEALTH - DEFAULT_HEAHLT))
		g_pPlayerInfo[ id ][ Player_AddHealth ] = _:(MAX_HEALTH - DEFAULT_HEAHLT);

	entity_set_float(id, EV_FL_max_health, DEFAULT_HEAHLT + g_pPlayerInfo[ id ][ Player_AddHealth ]);
}

stock UTIL__SetOriginSafe(const id, const Float:vecOrigin[ 3 ])
{
	new Float:vecNewOrigin[ 3 ], Float:vecMins[ 3 ];

	new isHull = (entity_get_int(id, EV_INT_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN;

	if (!trace_hull(vecOrigin, isHull, id, DONT_IGNORE_MONSTERS))
		return 0;

	entity_get_vector(id, EV_VEC_mins, vecMins);

	static const Float:__coordOffsets[ ][ 3 ] =
	{
		{0.0,0.0,0.5},{0.0,0.0,-0.5},{0.0,0.5,0.0},{0.0,-0.5,0.0},{0.5,0.0,0.0},{-0.5,0.0,0.0},{-0.5,0.5,0.5},
		{0.5,0.5,0.5},{0.5,-0.5,0.5},{0.5,0.5,-0.5},{-0.5,-0.5,0.5},{0.5,-0.5,-0.5},{-0.5,0.5,-0.5},{-0.5,-0.5,-0.5},

		{0.0,0.0,1.0},{0.0,0.0,-1.0},{0.0,1.0,0.0},{0.0,-1.0,0.0},{1.0,0.0,0.0},{-1.0,0.0,0.0},{-1.0,1.0,1.0},
		{1.0,1.0,1.0},{1.0,-1.0,1.0},{1.0,1.0,-1.0},{-1.0,-1.0,1.0},{1.0,-1.0,-1.0},{-1.0,1.0,-1.0},{-1.0,-1.0,-1.0},

		{0.0,0.0,2.0},{0.0,0.0,-2.0},{0.0,2.0,0.0},{0.0,-2.0,0.0},{2.0,0.0,0.0},{-2.0,0.0,0.0},{-2.0,2.0,2.0},
		{2.0,2.0,2.0},{2.0,-2.0,2.0},{2.0,2.0,-2.0},{-2.0,-2.0,2.0},{2.0,-2.0,-2.0},{-2.0,2.0,-2.0},{-2.0,-2.0,-2.0},

		{0.0,0.0,3.0},{0.0,0.0,-3.0},{0.0,3.0,0.0},{0.0,-3.0,0.0},{3.0,0.0,0.0},{-3.0,0.0,0.0},{-3.0,3.0,3.0},
		{3.0,3.0,3.0},{3.0,-3.0,3.0},{3.0,3.0,-3.0},{-3.0,-3.0,3.0},{3.0,-3.0,-3.0},{-3.0,3.0,-3.0},{-3.0,-3.0,-3.0},

		{0.0,0.0,4.0},{0.0,0.0,-4.0},{0.0,4.0,0.0},{0.0,-4.0,0.0},{4.0,0.0,0.0},{-4.0,0.0,0.0},{-4.0,4.0,4.0},
		{4.0,4.0,4.0},{4.0,-4.0,4.0},{4.0,4.0,-4.0},{-4.0,-4.0,4.0},{4.0,-4.0,-4.0},{-4.0,4.0,-4.0},{-4.0,-4.0,-4.0},

		{0.0,0.0,5.0},{0.0,0.0,-5.0},{0.0,5.0,0.0},{0.0,-5.0,0.0},{5.0,0.0,0.0},{-5.0,0.0,0.0},{-5.0,5.0,5.0},
		{5.0,5.0,5.0},{5.0,-5.0,5.0},{5.0,5.0,-5.0},{-5.0,-5.0,5.0},{5.0,-5.0,-5.0},{-5.0,5.0,-5.0},{-5.0,-5.0,-5.0}
	};

	for (new i; i < sizeof(__coordOffsets); i++)
	{
		vecNewOrigin[ 0 ] = vecOrigin[ 0 ] - vecMins[ 0 ] * __coordOffsets[ i ][ 0 ];
		vecNewOrigin[ 1 ] = vecOrigin[ 1 ] - vecMins[ 1 ] * __coordOffsets[ i ][ 1 ];
		vecNewOrigin[ 2 ] = vecOrigin[ 2 ] - vecMins[ 2 ] * __coordOffsets[ i ][ 2 ];

		if (!trace_hull(vecNewOrigin, HULL_HEAD, id, DONT_IGNORE_MONSTERS))
		{
			entity_set_int(id, EV_INT_flags, entity_get_int(id, EV_INT_flags) | FL_DUCKING);
checkorigin__:
			SET_ORIGIN(id, vecNewOrigin);
			return 1;
		}

		if (!trace_hull(vecNewOrigin, HULL_HUMAN, id, DONT_IGNORE_MONSTERS))
			goto checkorigin__;
	}
	return 0;
}

stock UTIL__SendSound(const id, const szFileName[])
{
	static __msgidSendAudio = 0;
	if (__msgidSendAudio || (__msgidSendAudio = get_user_msgid("SendAudio")))
	{
		MESSAGE_BEGIN(MSG_ONE_UNRELIABLE, __msgidSendAudio, _, id);
		WRITE_BYTE(0);
		WRITE_STRING(szFileName);
		WRITE_SHORT(PITCH_NORM);
		MESSAGE_END();
	}
}

stock UTIL__CheckValidOriginSphere(const Float:vecStart[ 3 ])
{
	new pEnt = NULL;
	new Float:vecOrigin[ 3 ];

	while ((pEnt = FIND_ENTITY_IN_SPHERE(pEnt, vecStart, MAX_CHECK_RADIUS_VALID)) != NULL)
	{
		if (pEnt > g_iMaxPlayers)
			continue;

		if (g_pPlayerInfo[ pEnt ][ Player_Frozen ] || !g_pPlayerInfo[ pEnt ][ Player_Alive ])
			continue;

		entity_get_vector(pEnt, EV_VEC_origin, vecOrigin);
#if defined TELEPORT_UNSTUCK_EFFECTS
		if (UTIL__SetOriginSafe(pEnt, vecOrigin) != 0)
		{
			/*
			* teleport a safe place
			*/

			UTIL__SendSound(pEnt, "fvox/blip.wav");
			set_hudmessage(255, 150, 50, -1.0, 0.65, 0, 6.0, 1.5, 0.1, 0.7);
			show_hudmessage(pEnt, "Вы застряли и были перемещены");
		}
#else
		UTIL__SetOriginSafe(pEnt, vecOrigin);
#endif // TELEPORT_UNSTUCK_EFFECTS
	}
}

stock UTIL__DestroyShopMenu(const id)
{
	new iMenuid, iKey;
	get_user_menu(id, iMenuid, iKey);

	if (iMenuid == g_iMenuShopId)
		show_menu(id, 0, "\n", 1);
}

stock UTIL__PlayerAllowShoot(const id, bool:bAllow = true)
{
	new pActiveItem = get_member(id, m_pActiveItem);

	if (pev_valid(pActiveItem) != PDATA_SAFE)
		return;

	new WeaponState:iBitsum = get_member(pActiveItem, m_Weapon_iWeaponState);
	if (!bAllow)
	{
		if (iBitsum & WPNSTATE_SHIELD_DRAWN)
			return;

		iBitsum |= WPNSTATE_SHIELD_DRAWN;
	}
	else
		iBitsum &= ~WPNSTATE_SHIELD_DRAWN;

	set_member(pActiveItem, m_Weapon_iWeaponState, iBitsum);
}

stock UTIL__CreateWeather()
{
	new pEnt = CREATE_NAMED_ENTITY("env_fog");

	if (pEnt)
	{
		set_kvd(0, KV_ClassName, "env_fog");
		set_kvd(0, KV_KeyName, "density");
		set_kvd(0, KV_Value, FOG_DENSITY);
		set_kvd(0, KV_fHandled, NULL);

		dllfunc(DLLFunc_KeyValue, pEnt, NULL);

		set_kvd(0, KV_KeyName, "rendercolor");
		set_kvd(0, KV_Value, FOG_COLOR);

		dllfunc(DLLFunc_KeyValue, pEnt, NULL);
	}
	CREATE_NAMED_ENTITY("env_snow");
}

/*
* Thanks Asmodai for the idea
* not bad hack :)
*/
stock Float:UTIL__GetUserInterpTime(const id)
{
	static __isOffset = 0;
	if (!__isOffset)
	{
		const OFFSET_FROM_USERINFO_LIN = -19104; // the offset to the based beginning from userinfo[MAX_INFO_STRING]
		const OFFSET_FROM_USERCMD_LIN = 9280; // offset to usercmd

		const OFFSET_FROM_USERINFO = -19392;
		const OFFSET_FROM_USERCMD = 9552;

		if (is_linux_server())
			__isOffset = OFFSET_FROM_USERINFO_LIN + OFFSET_FROM_USERCMD_LIN;
		else
			__isOffset = OFFSET_FROM_USERINFO + OFFSET_FROM_USERCMD;
	}

	new pUserInfo = engfunc(EngFunc_GetInfoKeyBuffer, id);
	new lerp_msec = get_uc(pUserInfo + __isOffset, UC_Msec);

	if (lerp_msec <= 0)
		return INTERP_TIME_DEFAULT;

	return lerp_msec * 0.001;
}

stock UTIL__ShowBuyIcon(const id)
{
	MESSAGE_BEGIN(MSG_ONE, g_iUserMsg[ Message_StatusIcon ], _, id);
	WRITE_BYTE(1);
	WRITE_STRING("buyzone");
	WRITE_BYTE(0);
	WRITE_BYTE(160);
	WRITE_BYTE(0);
	MESSAGE_END();
}

stock Ham:Ham_Valid_Player_ResetMaxSpeed()
{
	#if defined Ham_CS_Player_ResetMaxSpeed
		return IsHamValid(Ham_CS_Player_ResetMaxSpeed) ? Ham_CS_Player_ResetMaxSpeed : Ham_Item_PreFrame;
	#else
		return Ham_Item_PreFrame;
	#endif
}

stock CEffects__BeamCylinder(const Float:vecOrigin[ 3 ], const iBrightness, const Float:flNum, const iWidth, const iPallete[ 3 ], const iSpriteIndex, const Float:flScaleUp)
{
	MESSAGE_BEGIN_F(MSG_PVS, SVC_TEMPENTITY, vecOrigin, NULL);
	WRITE_BYTE(TE_BEAMCYLINDER);
	WRITE_COORD_F(vecOrigin[ 0 ]);
	WRITE_COORD_F(vecOrigin[ 1 ]);
	WRITE_COORD_F(vecOrigin[ 2 ] + flScaleUp);
	WRITE_COORD_F(vecOrigin[ 0 ]);
	WRITE_COORD_F(vecOrigin[ 1 ]);
	WRITE_COORD_F(vecOrigin[ 2 ] + flNum);
	WRITE_SHORT(iSpriteIndex);
	WRITE_BYTE(0);
	WRITE_BYTE(2);
	WRITE_BYTE(6);
	WRITE_BYTE(iWidth);
	WRITE_BYTE(40);
	WRITE_BYTE(iPallete[ 0 ]);
	WRITE_BYTE(iPallete[ 1 ]);
	WRITE_BYTE(iPallete[ 2 ]);
	WRITE_BYTE(iBrightness);
	WRITE_BYTE(0);
	MESSAGE_END();
}

stock CEffects__Light(const Float:vecOrigin[ 3 ], const iPallete[ 3 ])
{
	MESSAGE_BEGIN_F(MSG_PVS, SVC_TEMPENTITY, vecOrigin, NULL);
	WRITE_BYTE(TE_DLIGHT);
	WRITE_COORD_F(vecOrigin[ 0 ]);
	WRITE_COORD_F(vecOrigin[ 1 ]);
	WRITE_COORD_F(vecOrigin[ 2 ] + 4.0);
	WRITE_BYTE(60);
	WRITE_BYTE(iPallete[ 0 ]);
	WRITE_BYTE(iPallete[ 1 ]);
	WRITE_BYTE(iPallete[ 2 ]);
	WRITE_BYTE(8);
	WRITE_BYTE(60);
	MESSAGE_END();
}

stock CEffects__Spark(const Float:vecOrigin[ 3 ])
{
	MESSAGE_BEGIN_F(MSG_PVS, SVC_TEMPENTITY, vecOrigin, NULL);
	write_byte(TE_SPARKS);
	WRITE_COORD_F(vecOrigin[ 0 ]);
	WRITE_COORD_F(vecOrigin[ 1 ]);
	WRITE_COORD_F(vecOrigin[ 2 ]);
	MESSAGE_END();
}

stock CEffects__SpriteTrail(const Float:vecOrigin[ 3 ], const iNum, const iScale, const iSpriteIndex)
{
	MESSAGE_BEGIN_F(MSG_PVS, SVC_TEMPENTITY, vecOrigin, NULL);
	WRITE_BYTE(TE_SPRITETRAIL);
	WRITE_COORD_F(vecOrigin[ 0 ]);
	WRITE_COORD_F(vecOrigin[ 1 ]);
	WRITE_COORD_F(vecOrigin[ 2 ] + 4.0);
	WRITE_COORD_F(vecOrigin[ 0 ] + random_float(-5.0, 5.0));
	WRITE_COORD_F(vecOrigin[ 1 ] + random_float(-5.0, 5.0));
	WRITE_COORD_F(vecOrigin[ 2 ] + 16.0);
	WRITE_SHORT(iSpriteIndex);
	WRITE_BYTE(iNum);
	WRITE_BYTE(random_num(3, 6));
	WRITE_BYTE(iScale);
	WRITE_BYTE(10);
	WRITE_BYTE(25);
	MESSAGE_END();
}
