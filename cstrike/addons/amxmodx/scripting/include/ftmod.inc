#if defined _ftmod_included
	#endinput
#endif

#define _ftmod_included

#tryinclude <roundcontrol>

#if !defined _roundcontrol_included
	#assert "Required AMXX module RoundControl for plugin!"
#endif

#define INFOTARGET_UID		1493276213	// ID entity info_target on impulse every entity owner 
#define INFOCUBE_UID		1248121937	// ID entity info_target on impulse entity ICE cube

enum EXTRA_TEAM (<<= 1)
{
	ITEM_TEAM_ANY = (1<<0),

	ITEM_TEAM_T,
	ITEM_TEAM_CT
};

/**
 *
 * @note The player gets the item from shop
 *
 * @param index		Client index
 * @param itemid	Item index
 *
 */
forward ftm_shop_selected_item(const index, const itemid);

/**
 *
 * PRE function
 *
 * @note The player frozen
 *
 * @param victim	Client index
 * @param killer	Client index killed which victim
 *
 */
forward ftm_client_frozen(victim, killer);

/**
 *
 * POST function
 *
 */
forward ftm_client_frozen_post(victim, killer);

/**
 *
 * @note The player frozen, get it the fake entities
 *
 * @param index		Client index
 * @param pCube		Entity cube
 * @param pBody		Entity fake body
 * @param pView		Entity camera view
 *
 */
forward ftm_client_frozen_stuff(index, pCube, pBody, pView);

/**
 *
 * @note The player unfrozen
 *
 * @param index		Client index
 * @param rescued	Client index who rescued
 *
 */
forward ftm_client_unfrozen(index, rescued);

/**
 *
 * POST function
 *
 */
forward ftm_client_unfrozen_post(index, rescued);

/**
 *
 * @note The player spawned PRE
 *
 * @param index		Client index
 * @param team		Team index
 *
 */
forward ftm_client_spawn(index, team);

/**
 *
 * @note The player spawned pre posted
 *
 * @param index		Client index
 * @param bIsFrozen	Frozen respawn
 *
 */
forward ftm_client_spawn_pre(index, bool:bIsFrozen);

/**
 *
 * POST function
 *
 */
forward ftm_client_spawn_post(index, bool:bIsFrozen);

/**
 *
 * @note The event when player defrosting of frozen the player
 *
 * @param index		Client index
 * @param target	Client index target which defrosted
 * @param time		The remaining time for defrosting (etc BarTime)
 *
 */
forward ftm_client_target(index, target, time);

/**
 *
 * @note Find for observer, next target
 *
 * @param index		Client index
 * @param target	Client index next target for observer
 *
 */
forward ftm_client_find_obs_target(index, target);

/**
 *
 * @note 
 *
 * @param index		Client index
 * @param target	Client index target which unfreezes
 * @param ent		Entity frost cube
 * @param money		How many have already received money at defrosting
 *
 */
forward ftm_client_unfreeze(index, target, ent, money);

/**
 *
 * @note Event round win
 *
 */
forward ftm_round_new();

/**
 *
 * @note Event round win
 *
 * @param iTeamWin		which team won the round
 *
 */
forward ftm_round_end(RoundControlWin:iTeamWin);

/**
 *
 * @note Event round restart
 *
 */
forward ftm_round_restart();

/**
 *
 * @note 
 *
 * @param ct_alive		the amount of alive CT
 * @param ct_frozed		the amount of frozen CT
 * @param t_alive		the amount of alive T
 * @param t_frozed		the amount of frozen T
 *
 */
forward ftm_conditions(ct_alive, ct_frozen, t_alive, t_frozen);

/**
 *
 * @note Is check have player frozen
 *
 * @param szItem	The name of the item
 * @param iMoneyCost	Price value of a item
 * @param iTeam		Relationship to team which have access extra item
 *
 * @return		item index
 */
native ftm_register_extra_item(const szItem[], const iMoneyCost, EXTRA_TEAM:iTeam = ITEM_TEAM_ANY);

/**
 *
 * @note Set the frozen status
 *
 * @param index		Client index
 * @param bIsFrozen	true/false
 *
 */
native ftm_set_frozen(index, bool:bIsFrozen);

/**
 *
 * @note Is check have player frozen
 *
 * @param index		Client index
 *
 * @return		false/true frozen
 */
native ftm_get_frozen(index);

/**
 *
 * @note Set the alive status
 *
 * @param index		Client index
 * @param bIsFrozen	true/false
 *
 */
native ftm_set_alive(index, bool:bIsAlive);

/**
 *
 * @note Is check have player alive
 *
 * @param index		Client index
 *
 * @return		false/true alive
 */
native ftm_get_alive(index);

/**
 *
 * @note Get teamid
 *
 * @param index		Client index
 *
 * @return		Team ID
 */
native ftm_get_teamid(index);

/**
 *
 * @note Set additional health
 *
 * @param index		Client index
 * @param amount	amount health
 *
 * @noreturn
 */
native ftm_set_add_health(index, Float:amount);

/**
 *
 * @note Get additional health
 *
 * @param index		Client index
 *
 * @return		amount additional health
 */
native Float:ftm_get_add_health(index);

/**
 *
 * @note Set money
 *
 * @param index		Client index
 * @param amount	amount money
 * @param flash		flash
 *
 * @noreturn
 */
native ftm_set_money(index, amount, flash = 1);

/**
 *
 * @note Get money
 *
 * @param index		Client index
 *
 * @return		amount money
 */
native ftm_get_money(index);

/**
 *
 * @note Get is there index player which rescues
 *
 * @param index		Client index
 *
 * @return		index rescues the player
 */
native ftm_get_rescuer_id(index);

/**
 *
 * @note Get index target of observer
 *
 * @param index		Client index
 *
 * @return		index target
 */
native ftm_get_obs_target(index);

/**
 *
 * @note Get have player protect on spawn
 *
 * @param index		Client index
 *
 * @return		false/true protect spawn
 */
native ftm_get_protect_spawn(index);

/**
 *
 * @note Get origin is player frozen
 *
 * @param index		Client index
 * @param vecOut	Copy to array vecOut
 *
 * @noreturn
 */
native ftm_get_play_origin(index, Float:vecOut[3]);

/**
 *
 * @note Get number the round which was frozen
 *
 * @param index		Client index
 *
 * @return		Number round
 */
native ftm_get_play_round(index);

/**
 *
 * @note Set locking spawn until the end of the round
 *
 * @param index		Client index
 * @param bLock		false/true lock value
 *
 * @noreturn
 */
native ftm_set_spawnlock(index, bool:bLock);

/**
 *
 * @note Get have whether at a the player spawn lock
 *
 * @param index		Client index
 *
 * @return		true/false block spawn
 */
native bool:ftm_get_spawnlock(index);

/**
 *
 * @note Set stayed defrost
 *
 * @param index		Client index
 * @param bLock		false/true pause defrosted
 *
 * @noreturn
 */
native ftm_set_stay(index, bool:bLock);

/**
 *
 * @note Get have whether at a the player spawn lock
 *
 * @param index		Client index
 *
 * @return		true/false pause defrost
 */
native bool:ftm_get_stay(index);

/**
 *
 * @note Get every entity by owner ICE
 *
 * @param index		Client index
 * @param ent_view	Entity camera
 * @param ent_cube	Entity ICE Cube
 * @param ent_body	Entity fake body 
 * @param ent_weapon	Entity fake weapon
 *
 * @noreturn
 */
native ftm_get_entity_owner(index, &ent_cube = 0, &ent_view = 0, &ent_body = 0, &ent_weapon = 0);

/**
 *
 * @note Break process defrost
 *
 * @param index		Client index
 *
 * @noreturn
 */
native ftm_defrost_break(index);

/**
 *
 * @note Call function CPlayer__Frozen
 *
 * @param index		Client index
 *
 * @noreturn
 */
native ftm_execute_frozen(index);

/**
 *
 * @note Call function CPlayer__UnFrozen
 *
 * @param index		Client index
 *
 * @noreturn
 */
native ftm_execute_unfrozen(index);

/**
 *
 * @note Call function CPlayer__CleanFrozen
 *
 * @param index		Client index
 * @param bIsKill	The player will is dead
 *
 * @noreturn
 */
native ftm_execute_clean_frozen(index, bool:bIsKill = false);

/**
 *
 * @note Call function CFTMod__Clear__api
 *
 * @noreturn
 */
native ftm_execute_clear();
