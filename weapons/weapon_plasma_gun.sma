/*
 *		  | [CSO] Plasma Gun
 *		  | by S3xTy
 *                | ~ CREDITS: xUnicorn ~
 *		  | ~ DISCORD: https://discord.gg/KJnfR3u ~
 *                | ~ YOUTUBE: https://youtube.com/sthreexty ~
 *
*/ 

#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
// #include <zombieplague>

/* ~ [ Extra Item ] ~ */
new const WEAPON_ITEM_NAME[] = "Plasma Gun";
const WEAPON_ITEM_COST = 0;

/* ~ [ Weapon Settings ] ~ */
new const WEAPON_REFERENCE[] = "weapon_m249";
new const WEAPON_ANIMATION[] = "mp5";
new const WEAPON_WEAPONLIST[] = "zh_plasmagun";
new const WEAPON_NATIVE[] = "zp_give_user_plasmagun";
new const WEAPON_MODEL_VIEW[] = "models/zHero/Weapons/v_plasmagun.mdl";
new const WEAPON_MODEL_PLAYER[] = "models/zHero/Weapons/p_plasmagun.mdl";
new const WEAPON_MODEL_WORLD[] = "models/zHero/Weapons/w_plasmagun.mdl";
new const WEAPON_SOUNDS[][] =
{
	"weapons/plasmagun-1.wav",
	"common/null.wav"
};
new const WEAPON_RESOURCES[][] =
{
	// Custom resources precache, sprites for example
	"sprites/zhero/640hud91.spr",
	"sprites/zhero/640hud3.spr",
	"sound/weapons/plasmagun_clipin1.wav",
	"sound/weapons/plasmagun_clipin2.wav",
	"sound/weapons/plasmagun_clipout.wav",
	"sound/weapons/plasmagun_draw.wav",
	"sound/weapons/plasmagun_idle.wav"
};

const WEAPON_SPECIAL_CODE = 773225;
const WEAPON_MODEL_WORLD_BODY = 0;

const WEAPON_MAX_CLIP = 80;
const WEAPON_DEFAULT_AMMO = 200;
const Float: WEAPON_RATE = 0.14;

new const iWeaponList[] = 
{
	3, WEAPON_DEFAULT_AMMO, -1, -1, 0, 4, 20, 0 // weapon_m249
	//4, WEAPON_DEFAULT_AMMO, -1, -1, 0, 14, 8, 0 // weapon_aug
};

/* ~ [ Entity: Plasma Ball ] ~ */
new const ENTITY_PLASMABALL_CLASSNAME[] = "ent_ball";
new const ENTITY_PLASMABALL_SPRITE[] = "sprites/zhero/ef_plasmaball.spr";
new const ENTITY_PLASMABALL_EXPLODE[] = "sprites/zhero/ef_plasmaexp.spr";
new const ENTITY_PLASMABALL_SOUND[] = "weapons/plasmagun_exp.wav";
const Float: ENTITY_PLASMABALL_SPEED = 2250.0;
const Float: ENTITY_PLASMABALL_RADIUS = 55.0;
const Float: ENTITY_PLASMABALL_DAMAGE = 300.0;
const ENTITY_PLASMABALL_INTOLERANCE = 100;
const ENTITY_PLASMABALL_DMGTYPE = DMG_SONIC|DMG_NEVERGIB; // (DMG_BULLET)

/* ~ [ Weapon Animations ] ~ */
#define WEAPON_ANIM_IDLE_TIME 201/30.0
#define WEAPON_ANIM_RELOAD_TIME 101/30.0
#define WEAPON_ANIM_DRAW_TIME 31/30.0
#define WEAPON_ANIM_SHOOT_TIME 31/30.0

#define WEAPON_ANIM_IDLE 0
#define WEAPON_ANIM_RELOAD 1
#define WEAPON_ANIM_DRAW 2
#define WEAPON_ANIM_SHOOT random_num(3,5)

/* ~ [ Params ] ~ */
new gl_iszAllocString_Weapon,
	gl_iszAllocString_ModelView,
	gl_iszAllocString_ModelPlayer,
	gl_iszAllocString_PlasmaBall,
	gl_iszModelIndex_Explode,
	gl_iMsgID_Weaponlist,
	gl_iItemID;

/* ~ [ Macroses ] ~ */
#define DONT_BLEED -1
#define PDATA_SAFE 2

#define KillEntity(%0) (set_pev(%0, pev_flags, pev(%0, pev_flags) | FL_KILLME))
#define IsValidEntity(%0) (pev_valid(%0) == PDATA_SAFE)
#define IsCustomItem(%0) (pev(%0, pev_impulse) == WEAPON_SPECIAL_CODE)
#define WeaponTiming_Set(%0,%1,%2) \
	set_pdata_float(%0, m_flNextPrimaryAttack, %1, linux_diff_weapon), \
	set_pdata_float(%0, m_flNextSecondaryAttack, %1, linux_diff_weapon), \
	set_pdata_float(%0, m_flTimeWeaponIdle, %2, linux_diff_weapon)

/* ~ [ Offsets ] ~ */
// Linux extra offsets
#define linux_diff_weapon 4
#define linux_diff_player 5
#define linux_diff_animating 4

// CWeaponBox
#define m_rgpPlayerItems_CWeaponBox 34

// CBasePlayerItem
#define m_pPlayer 41
#define m_pNext 42
#define m_iId 43

// CBasePlayerWeapon
#define m_flNextPrimaryAttack 46
#define m_flNextSecondaryAttack 47
#define m_flTimeWeaponIdle 48
#define m_iPrimaryAmmoType 49
#define m_iClip 51
#define m_fInReload 54
#define m_iDirection 60
#define m_iShotsFired 64
#define m_iWeaponState 74
#define m_flNextReload 75

// CBaseMonster
#define m_LastHitGroup 75
#define m_flNextAttack 83

// CBasePlayer
#define m_flPainShock 108
#define m_iPlayerTeam 114
#define m_rpgPlayerItems 367
#define m_pActiveItem 373
#define m_rgAmmo 376
#define m_szAnimExtention 492

/* ~ [ AMX Mod X ] ~ */
public plugin_init()
{
	register_plugin("Weapon: Plasma Gun", "1.0", "S3xTy");

	// Forwards
	register_forward(FM_UpdateClientData,		"FM_Hook_UpdateClientData_Post", true);
	register_forward(FM_SetModel, 			"FM_Hook_SetModel_Pre", false);

	// Weapon
	RegisterHam(Ham_Item_Holster,			WEAPON_REFERENCE,	"CWeapon__Holster_Post", true);
	RegisterHam(Ham_Item_Deploy,			WEAPON_REFERENCE,	"CWeapon__Deploy_Post", true);
	RegisterHam(Ham_Item_PostFrame,			WEAPON_REFERENCE,	"CWeapon__PostFrame_Pre", false);
	RegisterHam(Ham_Item_AddToPlayer,		WEAPON_REFERENCE,	"CWeapon__AddToPlayer_Post", true);
	RegisterHam(Ham_Weapon_Reload,			WEAPON_REFERENCE,	"CWeapon__Reload_Pre", false);
	RegisterHam(Ham_Weapon_WeaponIdle,		WEAPON_REFERENCE,	"CWeapon__WeaponIdle_Pre", false);
	RegisterHam(Ham_Weapon_PrimaryAttack,		WEAPON_REFERENCE,	"CWeapon__PrimaryAttack_Pre", false);

	// Entity
	RegisterHam(Ham_Think, 				"info_target",		"CEntity__Think_Pre", false);
	RegisterHam(Ham_Touch, 				"info_target",		"CEntity__Touch_Pre", false);

	// Register on Extra-Items
	// gl_iItemID = zp_register_extra_item(WEAPON_ITEM_NAME, WEAPON_ITEM_COST, ZP_TEAM_HUMAN);

	// Messages
	gl_iMsgID_Weaponlist = get_user_msgid("WeaponList");

	// Alloc String
	gl_iszAllocString_Weapon = engfunc(EngFunc_AllocString, WEAPON_REFERENCE);
	gl_iszAllocString_ModelView = engfunc(EngFunc_AllocString, WEAPON_MODEL_VIEW);
	gl_iszAllocString_ModelPlayer = engfunc(EngFunc_AllocString, WEAPON_MODEL_PLAYER);
	gl_iszAllocString_PlasmaBall = engfunc(EngFunc_AllocString, ENTITY_PLASMABALL_CLASSNAME);
}

public plugin_precache()
{
	new i;

	// Hook weapon
	register_clcmd(WEAPON_WEAPONLIST, "Command_HookWeapon");

	register_clcmd("givenew" , "Command_GiveWeapon");

	// Precache models
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_VIEW);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_PLAYER);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_WORLD);

	engfunc(EngFunc_PrecacheModel, ENTITY_PLASMABALL_SPRITE);

	// Precache generic
	new szWeaponList[128]; formatex(szWeaponList, charsmax(szWeaponList), "sprites/%s.txt", WEAPON_WEAPONLIST);
	engfunc(EngFunc_PrecacheGeneric, szWeaponList);

	for(i = 0; i < sizeof WEAPON_RESOURCES; i++)
		engfunc(EngFunc_PrecacheGeneric, WEAPON_RESOURCES[i]);
	
	// Precache sounds
	for(i = 0; i < sizeof WEAPON_SOUNDS; i++)
		engfunc(EngFunc_PrecacheSound, WEAPON_SOUNDS[i]);

	engfunc(EngFunc_PrecacheSound, ENTITY_PLASMABALL_SOUND);

	// Model Index
	gl_iszModelIndex_Explode = engfunc(EngFunc_PrecacheModel, ENTITY_PLASMABALL_EXPLODE);
}

public plugin_natives() 
	register_native(WEAPON_NATIVE, "Command_GiveWeapon", 1);

public Command_HookWeapon(const pPlayer)
{
	engclient_cmd(pPlayer, WEAPON_REFERENCE);
	return PLUGIN_HANDLED;
}

public Command_GiveWeapon(const pPlayer)
{
	static pWeapon; pWeapon = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_Weapon);
	if(!IsValidEntity(pWeapon)) return FM_NULLENT;

	set_pev(pWeapon, pev_impulse, WEAPON_SPECIAL_CODE);
	ExecuteHam(Ham_Spawn, pWeapon);
	set_pdata_int(pWeapon, m_iClip, WEAPON_MAX_CLIP, linux_diff_weapon);
	UTIL_DropWeapon(pPlayer, ExecuteHamB(Ham_Item_ItemSlot, pWeapon));

	if(!ExecuteHamB(Ham_AddPlayerItem, pPlayer, pWeapon))
	{
		KillEntity(pWeapon);
		return FM_NULLENT;
	}

	ExecuteHamB(Ham_Item_AttachToPlayer, pWeapon, pPlayer);

	new iAmmoType = m_rgAmmo + get_pdata_int(pWeapon, m_iPrimaryAmmoType, linux_diff_weapon);
	if(get_pdata_int(pPlayer, m_rgAmmo, linux_diff_player) < WEAPON_DEFAULT_AMMO)
		set_pdata_int(pPlayer, iAmmoType, WEAPON_DEFAULT_AMMO, linux_diff_player);

	emit_sound(pPlayer, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	return pWeapon;
}

/* ~ [ Zombie Plague ] ~ */
public zp_extra_item_selected(pPlayer, iItemID)
{
	if(iItemID == gl_iItemID)
		Command_GiveWeapon(pPlayer);
}

/* ~ [ Fakemeta ] ~ */
public FM_Hook_UpdateClientData_Post(const pPlayer, const iSendWeapons, const CD_Handle)
{
	if(!is_user_alive(pPlayer)) return;

	static pActiveItem; pActiveItem = get_pdata_cbase(pPlayer, m_pActiveItem, linux_diff_player);
	if(!IsValidEntity(pActiveItem) || !IsCustomItem(pActiveItem)) return;

	set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001);
}

public FM_Hook_SetModel_Pre(const pEntity)
{
	static i, szClassName[32], pItem;
	pev(pEntity, pev_classname, szClassName, charsmax(szClassName));
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;

	for(i = 0; i < 6; i++)
	{
		pItem = get_pdata_cbase(pEntity, m_rgpPlayerItems_CWeaponBox + i, linux_diff_weapon);
		if(IsValidEntity(pItem) && IsCustomItem(pItem))
		{
			engfunc(EngFunc_SetModel, pEntity, WEAPON_MODEL_WORLD);
			set_pev(pEntity, pev_body, WEAPON_MODEL_WORLD_BODY);
			
			return FMRES_SUPERCEDE;
		}
	}

	return FMRES_IGNORED;
}

public FM_Hook_PlaybackEvent_Pre() return FMRES_SUPERCEDE;
public FM_Hook_TraceLine_Post(const Float: vecStart[3], const Float: vecEnd[3], const bitsFlags, const pAttacker, const pTrace)
{
	if(bitsFlags & IGNORE_MONSTERS) return FMRES_IGNORED;
	if(!is_user_alive(pAttacker)) return FMRES_IGNORED;

	static pHit; pHit = get_tr2(pTrace, TR_pHit);
	static Float: vecEndPos[3]; get_tr2(pTrace, TR_vecEndPos, vecEndPos);

	if(pHit > 0) if(pev(pHit, pev_solid) != SOLID_BSP) return FMRES_IGNORED;

	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEndPos, 0);
	write_byte(TE_GUNSHOTDECAL);
	engfunc(EngFunc_WriteCoord, vecEndPos[0]);
	engfunc(EngFunc_WriteCoord, vecEndPos[1]);
	engfunc(EngFunc_WriteCoord, vecEndPos[2]);
	write_short(pHit > 0 ? pHit : 0);
	write_byte(random_num(41, 45));
	message_end();

	return FMRES_IGNORED;
}

/* ~ [ HamSandwich ] ~ */
public CWeapon__Holster_Post(const pItem)
{
	if(!IsValidEntity(pItem) || !IsCustomItem(pItem)) return;
	static pPlayer; pPlayer = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);

	WeaponTiming_Set(pItem, 0.0, 0.0);
	set_pdata_float(pPlayer, m_flNextAttack, 0.0, linux_diff_player);
	emit_sound(pPlayer, CHAN_ITEM, WEAPON_SOUNDS[1], VOL_NORM, ATTN_NONE, 0, PITCH_NORM);
}

public CWeapon__Deploy_Post(const pItem)
{
	if(!IsValidEntity(pItem) || !IsCustomItem(pItem)) return;
	static pPlayer; pPlayer = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);

	set_pev_string(pPlayer, pev_viewmodel2, gl_iszAllocString_ModelView);
	set_pev_string(pPlayer, pev_weaponmodel2, gl_iszAllocString_ModelPlayer);

	UTIL_SendWeaponAnim(pPlayer, WEAPON_ANIM_DRAW);

	set_pdata_float(pPlayer, m_flNextAttack, WEAPON_ANIM_DRAW_TIME, linux_diff_player);
	set_pdata_float(pItem, m_flTimeWeaponIdle, WEAPON_ANIM_DRAW_TIME, linux_diff_weapon);
	set_pdata_string(pPlayer, m_szAnimExtention * 4, WEAPON_ANIMATION, -1, linux_diff_player * linux_diff_animating);
}

public CWeapon__PostFrame_Pre(const pItem)
{
	if(!IsValidEntity(pItem) || !IsCustomItem(pItem)) return HAM_IGNORED;

	static pPlayer; pPlayer = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);
	static iClip; iClip = get_pdata_int(pItem, m_iClip, linux_diff_weapon);

	// Reload
	if(get_pdata_int(pItem, m_fInReload, linux_diff_weapon) == 1)
	{
		static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(pItem, m_iPrimaryAmmoType, linux_diff_weapon);
		static iAmmo; iAmmo = get_pdata_int(pPlayer, iAmmoType, linux_diff_player);
		static j; j = min(WEAPON_MAX_CLIP - iClip, iAmmo);

		set_pdata_int(pItem, m_iClip, iClip + j, linux_diff_weapon);
		set_pdata_int(pPlayer, iAmmoType, iAmmo - j, linux_diff_player);
		set_pdata_int(pItem, m_fInReload, 0, linux_diff_weapon);
	}
	return HAM_IGNORED;
}

public CWeapon__AddToPlayer_Post(const pItem, const pPlayer)
{
	if(IsValidEntity(pItem) && IsCustomItem(pItem)) UTIL_WeaponList(pPlayer, true);
	else if(pev(pItem, pev_impulse) == 0) UTIL_WeaponList(pPlayer, false);
}

public CWeapon__Reload_Pre(const pItem)
{
	if(!IsValidEntity(pItem) || !IsCustomItem(pItem)) return HAM_IGNORED;

	static iClip; iClip = get_pdata_int(pItem, m_iClip, linux_diff_weapon);
	if(iClip >= WEAPON_MAX_CLIP) return HAM_SUPERCEDE;

	static pPlayer; pPlayer = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);
	static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(pItem, m_iPrimaryAmmoType, linux_diff_weapon);
	if(get_pdata_int(pPlayer, iAmmoType, linux_diff_player) <= 0) return HAM_SUPERCEDE;

	set_pdata_int(pItem, m_iClip, 0, linux_diff_weapon);
	ExecuteHam(Ham_Weapon_Reload, pItem);
	set_pdata_int(pItem, m_iClip, iClip, linux_diff_weapon);
	set_pdata_int(pItem, m_fInReload, 1, linux_diff_weapon);

	UTIL_SendWeaponAnim(pPlayer, WEAPON_ANIM_RELOAD);

	WeaponTiming_Set(pItem, WEAPON_ANIM_RELOAD_TIME, WEAPON_ANIM_RELOAD_TIME);
	set_pdata_float(pPlayer, m_flNextAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_player);

	return HAM_SUPERCEDE;
}

public CWeapon__WeaponIdle_Pre(const pItem)
{
	if(!IsValidEntity(pItem) || !IsCustomItem(pItem) || get_pdata_float(pItem, m_flTimeWeaponIdle, linux_diff_weapon) > 0.0) return HAM_IGNORED;
	static pPlayer; pPlayer = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);

	UTIL_SendWeaponAnim(pPlayer, WEAPON_ANIM_IDLE);
	set_pdata_float(pItem, m_flTimeWeaponIdle, WEAPON_ANIM_IDLE_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CWeapon__PrimaryAttack_Pre(const pItem)
{
	if(!IsValidEntity(pItem) || !IsCustomItem(pItem)) return HAM_IGNORED;

	static iClip; iClip = get_pdata_int(pItem, m_iClip, linux_diff_weapon);
	if(!iClip)
	{
		ExecuteHam(Ham_Weapon_PlayEmptySound, pItem);
		set_pdata_float(pItem, m_flNextPrimaryAttack, 0.2, linux_diff_weapon);

		return HAM_SUPERCEDE;
	}

	static pPlayer; pPlayer = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);
	static Float: vecVelocity[3]; pev(pPlayer, pev_velocity, vecVelocity);

	UTIL_SendWeaponAnim(pPlayer, WEAPON_ANIM_SHOOT);
	emit_sound(pPlayer, CHAN_WEAPON, WEAPON_SOUNDS[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	CWeapon__Create_PlasmaBall(pPlayer);

	// https://github.com/s1lentq/ReGameDLL_CS/blob/master/regamedll/dlls/wpn_shared/wpn_ak47.cpp#L155
	if(xs_vec_len(vecVelocity) > 0)
		UTIL_WeaponKickBack(pItem, pPlayer, 1.5, 0.45, 0.225, 0.05, 6.5, 2.5, 7);
	else if(!(pev(pPlayer, pev_flags) & FL_ONGROUND))
		UTIL_WeaponKickBack(pItem, pPlayer, 2.0, 1.0, 0.5, 0.35, 9.0, 6.0, 5);
	else if(pev(pPlayer, pev_flags) & FL_DUCKING)
		UTIL_WeaponKickBack(pItem, pPlayer, 0.9, 0.35, 0.15, 0.025, 5.5, 1.5, 9);
	else
		UTIL_WeaponKickBack(pItem, pPlayer, 1.0, 0.375, 0.175, 0.0375, 5.75, 1.75, 8);

	set_pdata_int(pItem, m_iClip, iClip - 1, linux_diff_weapon);
	WeaponTiming_Set(pItem, WEAPON_RATE, WEAPON_ANIM_SHOOT_TIME);

	return HAM_SUPERCEDE;
}

public CEntity__Think_Pre(const pEntity)
{
	if(!IsValidEntity(pEntity)) return HAM_IGNORED;
	if(pev(pEntity, pev_classname) == gl_iszAllocString_PlasmaBall)
	{
		new pOwner = pev(pEntity, pev_owner);
		if(!is_user_alive(pOwner))
		{
			KillEntity(pEntity);
			return HAM_IGNORED;
		}

		// Animation
		static Float: flFrame; pev(pEntity, pev_frame, flFrame);
		flFrame = (flFrame >= 29.0) ? 0.0 : flFrame + 1.0;
		set_pev(pEntity, pev_frame, flFrame);

		set_pev(pEntity, pev_nextthink, get_gametime() + 0.05);
	}

	return HAM_IGNORED;
}

public CEntity__Touch_Pre(const pEntity, const pTouch)
{
	if(!IsValidEntity(pEntity)) return HAM_IGNORED;
	if(pev(pEntity, pev_classname) == gl_iszAllocString_PlasmaBall)
	{
		static pOwner; pOwner = pev(pEntity, pev_owner);
		if(!is_user_alive(pOwner))
		{
			KillEntity(pEntity);
			return HAM_IGNORED;
		}

		if(pTouch == pOwner || pev(pTouch, pev_classname) == gl_iszAllocString_PlasmaBall) return HAM_SUPERCEDE;

		static Float: vecOrigin[3]; pev(pEntity, pev_origin, vecOrigin);
		if(engfunc(EngFunc_PointContents, vecOrigin) == CONTENTS_SKY)
		{
			KillEntity(pEntity);
			return HAM_IGNORED;
		}

		UTIL_CreateExplosion(gl_iszModelIndex_Explode, vecOrigin, -10.0, random_num(4, 6), random_num(16, 24), TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES);
		UTIL_CreateExplosion(gl_iszModelIndex_Explode, vecOrigin, -10.5, 3, random_num(30, 35), TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES);
		emit_sound(pEntity, CHAN_ITEM, ENTITY_PLASMABALL_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

		static pItem; pItem = get_pdata_cbase(pOwner, m_rpgPlayerItems + 1, linux_diff_player);
		if(IsValidEntity(pItem) && IsCustomItem(pItem))
		{
			static pVictim; pVictim = FM_NULLENT;
			static Float: flDamage; flDamage = ENTITY_PLASMABALL_DAMAGE;
			while((pVictim = engfunc(EngFunc_FindEntityInSphere, pVictim, vecOrigin, ENTITY_PLASMABALL_RADIUS)) > 0)
			{
				if(pev(pVictim, pev_takedamage) == DAMAGE_NO) 
					continue;

				if(pVictim == pOwner)
					continue;
				else if(pev(pVictim, pev_solid) == SOLID_BSP)
				{
					if(pev(pVictim, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY)
						continue;
				}

				flDamage *= random_float(0.75, 1.25);
				set_pdata_int(pVictim, m_LastHitGroup, HIT_GENERIC, linux_diff_player);
				ExecuteHamB(Ham_TakeDamage, pVictim, pItem, pOwner, flDamage, ENTITY_PLASMABALL_DMGTYPE);
			}
		}

		KillEntity(pEntity);
	}

	return HAM_IGNORED;
}

/* ~ [ Other ] ~ */
public CWeapon__Create_PlasmaBall(const pPlayer)
{
	if(global_get(glb_maxEntities) - engfunc(EngFunc_NumberOfEntities) < ENTITY_PLASMABALL_INTOLERANCE) return FM_NULLENT;

	static pEntity, iszAllocStringCached;
	if(iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, "info_target")))
		pEntity = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);

	if(!IsValidEntity(pEntity)) return FM_NULLENT;

	static Float: vecOrigin[3]; pev(pPlayer, pev_origin, vecOrigin);
	static Float: vecViewOfs[3]; pev(pPlayer, pev_view_ofs, vecViewOfs);
	static Float: vecAngles[3]; pev(pPlayer, pev_v_angle, vecAngles);
	static Float: vecForward[3]; angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecForward);
	static Float: vecVelocity[3]; xs_vec_copy(vecForward, vecVelocity);

	// Start Origin
	xs_vec_mul_scalar(vecForward, 10.0, vecForward);
	xs_vec_add(vecViewOfs, vecForward, vecViewOfs);
	xs_vec_add(vecOrigin, vecViewOfs, vecOrigin);

	// Speed for missile
	xs_vec_mul_scalar(vecVelocity, ENTITY_PLASMABALL_SPEED, vecVelocity);

	engfunc(EngFunc_SetModel, pEntity, ENTITY_PLASMABALL_SPRITE);

	set_pev_string(pEntity, pev_classname, gl_iszAllocString_PlasmaBall);
	set_pev(pEntity, pev_spawnflags, SF_SPRITE_STARTON);
	set_pev(pEntity, pev_animtime, get_gametime());
	set_pev(pEntity, pev_framerate, 32.0);
	set_pev(pEntity, pev_frame, 1.0);
	set_pev(pEntity, pev_rendermode, kRenderTransAdd);
	set_pev(pEntity, pev_renderamt, 230.0);
	set_pev(pEntity, pev_scale, random_float(0.1, 0.4));
	set_pev(pEntity, pev_nextthink, get_gametime());

	dllfunc(DLLFunc_Spawn, pEntity);

	set_pev(pEntity, pev_solid, SOLID_BBOX);
	set_pev(pEntity, pev_movetype, MOVETYPE_FLY);
	set_pev(pEntity, pev_owner, pPlayer);
	set_pev(pEntity, pev_velocity, vecVelocity);

	engfunc(EngFunc_SetOrigin, pEntity, vecOrigin);
	engfunc(EngFunc_SetSize, pEntity, Float: {-3.0, -3.0, -3.0}, Float: {3.0, 3.0, 3.0});

	return pEntity;
}

/* ~ [ Stocks ] ~ */
stock is_wall_between_points(const pEntity1, const pEntity2)
{
	if(!is_user_alive(pEntity2)) return false;

	static pTrace; pTrace = create_tr2();
	static Float: vecStart[3]; pev(pEntity1, pev_origin, vecStart);
	static Float: vecEnd[3]; pev(pEntity2, pev_origin, vecEnd);

	engfunc(EngFunc_TraceLine, vecStart, vecEnd, IGNORE_MONSTERS, pEntity1, pTrace);
	static Float: vecEndPos[3]; get_tr2(pTrace, TR_vecEndPos, vecEndPos);
	free_tr2(pTrace);

	return xs_vec_equal(vecEnd, vecEndPos);
}

stock UTIL_SendWeaponAnim(const pPlayer, const iAnim)
{
	set_pev(pPlayer, pev_weaponanim, iAnim);

	message_begin(MSG_ONE, SVC_WEAPONANIM, _, pPlayer);
	write_byte(iAnim);
	write_byte(0);
	message_end();
}

stock UTIL_WeaponList(const pPlayer, const bool: bEnabled)
{
	message_begin(MSG_ONE, gl_iMsgID_Weaponlist, _, pPlayer);
	write_string(bEnabled ? WEAPON_WEAPONLIST : WEAPON_REFERENCE);
	write_byte(iWeaponList[0]);
	write_byte(bEnabled ? WEAPON_DEFAULT_AMMO : iWeaponList[1]);
	write_byte(iWeaponList[2]);
	write_byte(iWeaponList[3]);
	write_byte(iWeaponList[4]);
	write_byte(iWeaponList[5]);
	write_byte(iWeaponList[6]);
	write_byte(iWeaponList[7]);
	message_end();
}

stock UTIL_CreateExplosion(const iszModelIndex, const Float: vecOrigin[3], const Float: flUp, const iScale, const iFramerate, const iFlags)
{
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2] + flUp);
	write_short(iszModelIndex);
	write_byte(iScale); // Scale
	write_byte(iFramerate); // Framerate
	write_byte(iFlags); // Flags
	message_end();
}

stock UTIL_WeaponKickBack(const pItem, const pPlayer, Float: upBase, Float: lateralBase, const Float: upMod, const Float: lateralMod, Float: upMax, Float: lateralMax, const directionChange)
{
	static iDirection, iShotsFired; iShotsFired = get_pdata_int(pItem, m_iShotsFired, linux_diff_weapon)
	static Float: vecPunchangle[3]; pev(pPlayer, pev_punchangle, vecPunchangle);
	if(iShotsFired != 1)
	{
		upBase += iShotsFired * upMod;
		lateralBase += iShotsFired * lateralMod;
	}
	
	upMax *= -1.0; vecPunchangle[0] -= upBase;
	if(upMax >= vecPunchangle[0])
		vecPunchangle[0] = upMax;
	
	if((iDirection = get_pdata_int(pItem, m_iDirection, linux_diff_weapon)))
	{
		vecPunchangle[1] += lateralBase;
		if(lateralMax < vecPunchangle[1])
			vecPunchangle[1] = lateralMax;
	}
	else
	{
		lateralMax *= -1.0;
		vecPunchangle[1] -= lateralBase;
		
		if(lateralMax > vecPunchangle[1])
			vecPunchangle[1] = lateralMax;
	}
	
	if(!random_num(0, directionChange))
		set_pdata_int(pItem, m_iDirection, !iDirection, linux_diff_weapon);
	
	set_pev(pPlayer, pev_punchangle, vecPunchangle);
}

stock UTIL_DropWeapon(const pPlayer, const iSlot)
{
	static pEntity, iNext, szWeaponName[32];
	pEntity = get_pdata_cbase(pPlayer, m_rpgPlayerItems + iSlot, linux_diff_player);
	if(IsValidEntity(pEntity))
	{
		do
		{
			iNext = get_pdata_cbase(pEntity, m_pNext, linux_diff_weapon);
			if(get_weaponname(get_pdata_int(pEntity, m_iId, linux_diff_weapon), szWeaponName, charsmax(szWeaponName)))
				engclient_cmd(pPlayer, "drop", szWeaponName);
		}
		
		while((pEntity = iNext) > 0);
	}
}