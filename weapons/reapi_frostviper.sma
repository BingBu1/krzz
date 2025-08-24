
/* =========================================
-------- Plugin Datas and Headers ----------
========================================= */

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta_util>
#include <hamsandwich>
#include <reapi>
#include <ini_file> // https://forums.alliedmods.net/showthread.php?t=315031

// Choose one
#define LIBRARY_ZP "zp50_core"
// #include <zombieplague>	// untested. if there's bug fix yourself

#define PLUGIN "Frost Viper"
#define VERSION "1.0"
#define AUTHOR "Asdian"

// Data Config
#define P_FROSTBITE "models/p_frostbite.mdl"
#define V_FROSTBITE "models/v_frostbite.mdl"
#define W_FROSTBITE "models/w_frostbite.mdl"

#define MF_1 "sprites/muzzleflash416.spr"
#define MF_2 "sprites/muzzleflash419.spr"
#define SPR_RELOAD "sprites/ef_frostbite_reload02.spr"
#define MODEL_W_OLD "models/w_m249.mdl"

new const SOUND_FIRE[][] =
{
	"weapons/frostbite-1.wav",
	"weapons/frostbite-2.wav",
	"weapons/frostbite-3.wav",

	"weapons/frostbite_idle.wav"
}

#define CSW_FROSTBITE CSW_M249
#define weapon_frostbite "weapon_m249"

#define weapon_spr "weapon_frostbite"
#define WEAPON_CODE 05022025

// Weapon Config
#define CONFIG_FILE "frostbite_config"
new Array:g_config_dmgbullet, g_config_clip, g_config_bpammo, Float:g_config_speed, Float:g_config_recoil
new Array:g_config_accuracy, Array:g_config_accuracy_range, Array:g_config_spread, Array:g_config_spread_mul

#define FROSTBITE_MFNAME "frostbite_mf"
#define FROSTBITE_RLDNAME "frostbite_rld"
#define FROSTBITE_DEATHMSG "frostbite"

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

new g_cachde_mf[2], Float:g_cache_frame_mf[2], spr_blood_spray, spr_blood_drop
//new g_cache_reload, Float:g_cache_frame_reload

#if defined _zombieplague_included
new g_extra
#endif 

// Safety
new g_HamBot
new g_IsConnected, g_IsAlive, g_PlayerWeapon[33]

#define Had_Weapon(%0,%1)					bool: (get_entvar(%0, var_impulse) == %1)
#define GetWeaponClip(%0)					get_member(%0, m_Weapon_iClip)
#define SetWeaponClip(%0,%1)				set_member(%0, m_Weapon_iClip, %1)
#define GetWeaponAmmoType(%0)				get_member(%0, m_Weapon_iPrimaryAmmoType)
#define GetWeaponAmmo2Type(%0)				get_member(%0, m_Weapon_iSecondaryAmmoType)
#define GetWeaponAmmo(%0,%1)				get_member(%0, m_rgAmmo, %1)
#define SetWeaponAmmo(%0,%1,%2)				set_member(%0, m_rgAmmo, %1, %2)

new HookChain:gl_HookChain_IsPenetrableEntity_Post
new Float:g_flSpread[33], g_iShotsFired[33], Float:g_flAccuracy[33]

// Please ignore
native ccx_custom_pmodel(id, cswpnid, const name[]);
native ccx_custom_cswpn(id, cswpnid);

/* =========================================
----- End of Plugin Datas and Headers ------
========================================= */

/* =========================================
---------- Plugin Core Function ------------
========================================= */

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// Safety
	Register_SafetyFunc()
	
	// Event
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	
	// Forward
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	RegisterHookChain(RG_CWeaponBox_SetModel, "RG_CWeaponBox__SetModel_Pre", false);
	
	// Ham
	RegisterHam(Ham_Weapon_WeaponIdle, weapon_frostbite, "Ham_CWeapon_WeaponIdle_Pre", false);
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_frostbite, "Ham_CWeapon_PrimaryAttack_Pre", false);

	RegisterHam(Ham_Spawn, weapon_frostbite, "Ham_CWeapon_Spawn_Post", true);
	RegisterHam(Ham_Item_Deploy, weapon_frostbite, "Ham_CWeapon_Deploy_Post", true);
	RegisterHam(Ham_Weapon_Reload, weapon_frostbite, "Ham_CWeapon_Reload_Post", true);
	RegisterHam(Ham_Item_AddToPlayer, weapon_frostbite, "Ham_CWeapon_AddToPlayer_Post", true);
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_frostbite, "Ham_CWeapon_PrimaryAttack_Post", true);
	RegisterHam(Ham_Item_PostFrame, weapon_frostbite, "Ham_CWeapon_PostFrame_Pre")	
	RegisterHam(Ham_Item_Holster, weapon_frostbite, "Ham_CWeapon_Holster_Post", true);

	DisableHookChain(gl_HookChain_IsPenetrableEntity_Post = RegisterHookChain(RG_IsPenetrableEntity, "RG_IsPenetrableEntity_Post", true));
	
	// Cache
	//if (LibraryExists(LIBRARY_ZP, LibType_Library))
	//	g_extra = zp_register_extra_item(PLUGIN, 10, ZP_TEAM_HUMAN | ZP_TEAM_SURVIVOR)
	//else
		
	register_clcmd("fv", "GiveWeapon")
	
	register_clcmd(weapon_spr, "hook_weapon")
}

public hook_weapon(id) {engclient_cmd(id, weapon_frostbite); }

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, P_FROSTBITE)
	engfunc(EngFunc_PrecacheModel, V_FROSTBITE)
	engfunc(EngFunc_PrecacheModel, W_FROSTBITE)
	
	new i
	for(i = 0; i < sizeof(SOUND_FIRE); i++) engfunc(EngFunc_PrecacheSound, SOUND_FIRE[i])
	
	Stock_PrecacheSoundsFromModel(V_FROSTBITE)
	Stock_PrecacheFromWeaponList(weapon_spr)
	
	g_cachde_mf[0] = engfunc(EngFunc_PrecacheModel, MF_1)
	g_cachde_mf[1] = engfunc(EngFunc_PrecacheModel, MF_2)
	//g_cache_reload = engfunc(EngFunc_PrecacheModel, SPR_RELOAD)
	g_cache_frame_mf[0] = float(engfunc(EngFunc_ModelFrames, g_cachde_mf[0]))
	g_cache_frame_mf[1] = float(engfunc(EngFunc_ModelFrames, g_cachde_mf[1]))
	//g_cache_frame_reload = float(engfunc(EngFunc_ModelFrames, g_cache_reload))
	
	spr_blood_spray = engfunc(EngFunc_PrecacheModel, "sprites/bloodspray.spr")
	spr_blood_drop = engfunc(EngFunc_PrecacheModel, "sprites/blood.spr")

	Read_WeaponConfig()
}
 
public plugin_natives()
{
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}

public module_filter(const module[])
{
	if (equal(module, LIBRARY_ZP))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public native_filter(const name[], index, trap)
{
	if (!trap) return PLUGIN_HANDLED;
	return PLUGIN_CONTINUE;
}

public Read_WeaponConfig()
{
	g_config_dmgbullet = ArrayCreate(32, 1)
	g_config_accuracy = ArrayCreate(32, 1)
	g_config_accuracy_range = ArrayCreate(32, 1)
	g_config_spread = ArrayCreate(32, 1)
	g_config_spread_mul = ArrayCreate(32, 1)

	// total random shit
	new iDmgDefault[] = { 85, 279 }
	new Float:fAccuracyDefault[] = { 160.0, 0.4 }
	new Float:fAccuracyRangeDefault[] = { 0.0, 2.5 }
	new Float:fSpreadDefault[] = { 0.025, 0.05, 0.04 }
	new Float:fSpreadMulDefault[] = { 0.01, 0.1, 0.02 }

	new g_szConfigDir[64], sPath[64], i
	get_configsdir(g_szConfigDir, charsmax(g_szConfigDir))
	format(sPath, charsmax(sPath), "%s/%s.ini", g_szConfigDir, CONFIG_FILE);
	
	if(!file_exists(sPath)) // create and write a default file
	{
		new File = fopen(sPath, "a")
		fprintf(File, "^n;Config Generated by AMXX^n")
		fprintf(File, ";Spread cells: (1-onground 2-offground 3-run)^n")

		ini_write_int(CONFIG_FILE, "MAIN", "CLIP", 60);
		ini_write_int(CONFIG_FILE, "MAIN", "BPAMMO", 200);
		ini_write_int(CONFIG_FILE, "MAIN", "AMMO2", 100);
		ini_write_float(CONFIG_FILE, "MAIN", "ROF", 0.2783);
		ini_write_float(CONFIG_FILE, "MAIN", "RECOIL", 0.6);

		for (i = 0; i < sizeof (iDmgDefault); i++) ArrayPushCell(g_config_dmgbullet, iDmgDefault[i]);
		ini_write_int_array(CONFIG_FILE, "MAIN", "DAMAGE", g_config_dmgbullet);

		for (i = 0; i < sizeof (fAccuracyDefault); i++) ArrayPushArray(g_config_accuracy, fAccuracyDefault[i]);
		ini_write_float_array(CONFIG_FILE, "SHOOTING", "ACCURACY", g_config_accuracy);
		
		for (i = 0; i < sizeof (fAccuracyRangeDefault); i++) ArrayPushArray(g_config_accuracy_range, fAccuracyRangeDefault[i]);
		ini_write_float_array(CONFIG_FILE, "SHOOTING", "ACCURACY_RANGE", g_config_accuracy_range);
		
		for (i = 0; i < sizeof (fSpreadDefault); i++) ArrayPushArray(g_config_spread, fSpreadDefault[i]);
		ini_write_float_array(CONFIG_FILE, "SHOOTING", "SPREAD", g_config_spread);
		
		for (i = 0; i < sizeof (fSpreadMulDefault); i++) ArrayPushArray(g_config_spread_mul, fSpreadMulDefault[i]);
		ini_write_float_array(CONFIG_FILE, "SHOOTING", "SPREAD_MULTIPLY", g_config_spread_mul);
	}

	// Now read, and re-write with default values if missing something
	if (!ini_read_int(CONFIG_FILE, "MAIN", "CLIP", g_config_clip)) ini_write_int(CONFIG_FILE, "MAIN", "CLIP", 60);
	if (!ini_read_int(CONFIG_FILE, "MAIN", "BPAMMO", g_config_bpammo)) ini_write_int(CONFIG_FILE, "MAIN", "BPAMMO", 200);
	if (!ini_read_float(CONFIG_FILE, "MAIN", "ROF", g_config_speed)) ini_write_float(CONFIG_FILE, "MAIN", "ROF", 0.2783);
	if (!ini_read_float(CONFIG_FILE, "MAIN", "RECOIL", g_config_recoil)) ini_write_float(CONFIG_FILE, "MAIN", "RECOIL", 0.6);
	
	ini_read_int_array(CONFIG_FILE, "MAIN", "DAMAGE", g_config_dmgbullet);
	if (!ArraySize(g_config_dmgbullet))
	{
		for (i = 0; i < sizeof (iDmgDefault); i++) ArrayPushCell(g_config_dmgbullet, iDmgDefault[i]);
		ini_write_int_array(CONFIG_FILE, "MAIN", "DAMAGE", g_config_dmgbullet);
	}

	// ---------------------
	ini_read_float_array(CONFIG_FILE, "SHOOTING", "ACCURACY", g_config_accuracy);
	if (!ArraySize(g_config_accuracy))
	{
		for (i = 0; i < sizeof (fAccuracyDefault); i++) ArrayPushArray(g_config_accuracy, fAccuracyDefault[i]);
		ini_write_float_array(CONFIG_FILE, "SHOOTING", "ACCURACY", g_config_accuracy);
	}

	ini_read_float_array(CONFIG_FILE, "SHOOTING", "ACCURACY_RANGE", g_config_accuracy_range);
	if (!ArraySize(g_config_accuracy_range))
	{
		for (i = 0; i < sizeof (fAccuracyRangeDefault); i++) ArrayPushArray(g_config_accuracy_range, fAccuracyRangeDefault[i]);
		ini_write_float_array(CONFIG_FILE, "SHOOTING", "ACCURACY_RANGE", g_config_accuracy_range);
	}

	ini_read_float_array(CONFIG_FILE, "SHOOTING", "SPREAD", g_config_spread);
	if (!ArraySize(g_config_spread))
	{
		for (i = 0; i < sizeof (fSpreadDefault); i++) ArrayPushArray(g_config_spread, fSpreadDefault[i]);
		ini_write_float_array(CONFIG_FILE, "SHOOTING", "SPREAD", g_config_spread);
	}

	ini_read_float_array(CONFIG_FILE, "SHOOTING", "SPREAD_MULTIPLY", g_config_spread_mul);
	if (!ArraySize(g_config_spread_mul))
	{
		for (i = 0; i < sizeof (fSpreadMulDefault); i++) ArrayPushArray(g_config_spread_mul, fSpreadMulDefault[i]);
		ini_write_float_array(CONFIG_FILE, "SHOOTING", "SPREAD_MULTIPLY", g_config_spread_mul);
	}
}

#if defined _zombieplague_included
public zp_extra_item_selected(i, d) if(d == g_extra) GiveWeapon(i)
public zp_user_infected_post(i) if(zp_get_user_zombie(i)) rg_remove_item(i, weapon_frostbite)
public zp_user_humanized_post(i) if(zp_get_user_survivor(i)) rg_remove_item(i, weapon_frostbite)
#endif 

public message_DeathMsg(msg_id, msg_dest, msg_ent)
{
	new szWeapon[64], id, iEntity//, iVic
	id = get_msg_arg_int(1)
	//iVic = get_msg_arg_int(2)
	get_msg_arg_string(4, szWeapon, charsmax(szWeapon))
	iEntity = get_member(id, m_pActiveItem)
	
	if (strcmp(szWeapon, "m249"))
		return PLUGIN_CONTINUE
	if (is_nullent(iEntity) || !Had_Weapon(iEntity, WEAPON_CODE))
		return PLUGIN_CONTINUE

	set_msg_arg_string(4, FROSTBITE_DEATHMSG)
	return PLUGIN_CONTINUE
}

public client_putinserver(id)
{
	Safety_Connected(id)
	
	if(!g_HamBot && is_user_bot(id))
	{
		g_HamBot = 1
		set_task(0.1, "Register_HamBot", id)
	}
}
 
public Register_HamBot(id)
{
	Register_SafetyFuncBot(id)	
}

#if AMXX_VERSION_NUM >= 183
public client_disconnected(id)  Safety_Disconnected(id)
#else
public client_disconnect(id)  Safety_Disconnected(id)
#endif

/* =========================================
------- End of Plugin Core Function --------
========================================= */

/* =========================================
----------- Weapon Core Function -----------
========================================= */

public bool:GiveWeapon(id)
{
	if (!is_user_alive(id))
		return false;

	new iWpn = rg_give_custom_item(id, weapon_frostbite, GT_DROP_AND_REPLACE, WEAPON_CODE);
	
	if (is_nullent(iWpn))
		return false;

	new iAmmoType = GetWeaponAmmoType(iWpn);
	if (GetWeaponAmmo(id, iAmmoType) < g_config_bpammo) SetWeaponAmmo(id, g_config_bpammo, iAmmoType);
	return true;
}

public fw_UpdateClientData_Post(id, iSendWeapons, CD_Handle)
{
	if (!is_user_alive(id))
		return;

	static pActiveItem; pActiveItem = get_member(id, m_pActiveItem);
	if (is_nullent(pActiveItem) || !Had_Weapon(pActiveItem, WEAPON_CODE))
		return;

	set_cd(CD_Handle, CD_flNextAttack, 1.0);
}

public RG_CWeaponBox__SetModel_Pre(pWeaponBox, szModel[]) 
{
	new iWpn = Stock_GetWeaponBoxItem(pWeaponBox);
	if (iWpn == NULLENT || !Had_Weapon(iWpn, WEAPON_CODE))
		return HC_CONTINUE;

	SetHookChainArg(2, ATYPE_STRING, W_FROSTBITE);
	return HC_CONTINUE;
}

public Ham_CWeapon_WeaponIdle_Pre(iWpn)
{
	if (is_nullent(iWpn) || !Had_Weapon(iWpn, WEAPON_CODE))
		return HAM_IGNORED;
	if (get_member(iWpn, m_Weapon_flTimeWeaponIdle) > 0.0)
		return HAM_IGNORED;

	static id; id = get_member(iWpn, m_pPlayer);
	Stock_SendWeaponAnim(id, iWpn, 0);

	new Float:fTimer1
	get_entvar(iWpn, var_fuser1, fTimer1)

	if(!fTimer1) set_entvar(iWpn, var_fuser1, get_gametime())
	set_member(iWpn, m_Weapon_flTimeWeaponIdle, 2.03);
	return HAM_SUPERCEDE;
}

public Ham_CWeapon_PrimaryAttack_Pre(iWpn)
{
	if (is_nullent(iWpn) || !Had_Weapon(iWpn, WEAPON_CODE))
		return HAM_IGNORED;
	
	static iClip, id
	iClip = GetWeaponClip(iWpn);
	id = get_member(iWpn, m_pPlayer);

	if (!iClip)
	{
		ExecuteHam(Ham_Weapon_PlayEmptySound, iWpn);
		set_member(iWpn, m_Weapon_flNextPrimaryAttack, 0.2);
		return HAM_SUPERCEDE;
	}

	CWeapon_Fire(iWpn, id, iClip, g_config_speed);
	set_member(id, m_flNextAttack, g_config_speed);
	return HAM_SUPERCEDE;
}

public Ham_CWeapon_PrimaryAttack_Post(iWpn)
{
	if (is_nullent(iWpn) || !Had_Weapon(iWpn, WEAPON_CODE))
			return

	static id; id = get_member(iWpn, m_pPlayer);
	set_member(iWpn, m_Weapon_flAccuracy, g_flAccuracy[id]);
}

public CWeapon_Fire(iWpn, id, iClip, Float: flNextAttack)
{
	static bitsFlags, Float:velocity, Float:vecSrc[3], Float:vecAiming[3], iDamage, Float:fAccuracy[2], Float:fAccuracyRange[2], Float:fSpread[3], Float:fSpreadMul[3]
	Stock_GetEyePosition(id, vecSrc);
	Stock_GetAiming(id, vecAiming);
	bitsFlags = get_entvar(id, var_flags);
	velocity = GetVelocity2D(id);
	g_iShotsFired[id] = get_member(iWpn, m_Weapon_iShotsFired);
	g_flAccuracy[id] = get_member(iWpn, m_Weapon_flAccuracy);
	g_flSpread[id] = -0.000001;

	for(new i = 0; i < 3; i++) 
	{
		if(i < 2) 
		{
			fAccuracy[i] = ArrayGetCell(g_config_accuracy, i)
			fAccuracyRange[i] = ArrayGetCell(g_config_accuracy_range, i)
		}

		fSpread[i] = ArrayGetCell(g_config_spread, i)
		fSpreadMul[i] = ArrayGetCell(g_config_spread_mul, i)
	}

	// Update m_Weapon_iShotsFired for KickBack and Spread (reapi)
	if (!(bitsFlags & FL_ONGROUND)) g_flSpread[id] = fSpread[1] + g_flAccuracy[id] * fSpreadMul[1];
	else if (velocity > 0.0) g_flSpread[id] = fSpread[2] + g_flAccuracy[id] * fSpreadMul[2];
	else g_flSpread[id] = fSpread[0] + g_flAccuracy[id] * fSpreadMul[0];

	g_iShotsFired[id] += 1;
	g_flAccuracy[id] = ((g_iShotsFired[id] * g_iShotsFired[id] * g_iShotsFired[id]) / fAccuracy[0]) + fAccuracy[1]

	if (g_flAccuracy[id] < fAccuracyRange[0]) g_flAccuracy[id] = fAccuracyRange[0];
	else if (g_flAccuracy[id] > fAccuracyRange[1]) g_flAccuracy[id] = fAccuracyRange[1];
	
	if (LibraryExists(LIBRARY_ZP, LibType_Library))
		iDamage = ArrayGetCell(g_config_dmgbullet, 1)
	else 
		iDamage = ArrayGetCell(g_config_dmgbullet, 0)

	EnableHookChain(gl_HookChain_IsPenetrableEntity_Post);
	rg_fire_bullets3(iWpn, id, vecSrc, vecAiming, g_flSpread[id], 8192.0, 2, BULLET_PLAYER_556MM, iDamage, 0.9, false, get_member(id, random_seed));
	DisableHookChain(gl_HookChain_IsPenetrableEntity_Post);

	rg_set_animation(id, PLAYER_ATTACK1);
	SetWeaponClip(iWpn, --iClip);
	
	new Float:vecPunchAngle[3]
	get_entvar(id, var_punchangle, vecPunchAngle);

	vecPunchAngle[0] -= g_config_recoil; 
	vecPunchAngle[1] += random_float(-1.0*(g_config_recoil/2.0), (g_config_recoil/2.0))
	set_entvar(id, var_punchangle, vecPunchAngle);

	Stock_SendWeaponAnim(id, iWpn, 1);
	emit_sound(id, CHAN_WEAPON, SOUND_FIRE[0], VOL_NORM, ATTN_NORM, 0, random_num(95,120))
	
	MakeMuzzleFlash(id, iWpn, 1, 0, MF_1, FROSTBITE_MFNAME, 0.03)
	MakeMuzzleFlash(id, iWpn, 3, 1, MF_2, FROSTBITE_MFNAME, 0.03)
	set_entvar(iWpn, var_fuser1, 0.0)

	set_member(iWpn, m_Weapon_flTimeWeaponIdle, 1.03);
	set_member(iWpn, m_Weapon_flNextPrimaryAttack, flNextAttack);
}

public Ham_CWeapon_Spawn_Post(iWpn) 
{
	if (is_nullent(iWpn) || !Had_Weapon(iWpn, WEAPON_CODE))
		return;

	SetWeaponClip(iWpn, g_config_clip);
	set_member(iWpn, m_Weapon_iDefaultAmmo, g_config_bpammo);

	rg_set_iteminfo(iWpn, ItemInfo_pszName, weapon_spr);
	rg_set_iteminfo(iWpn, ItemInfo_iMaxClip, g_config_clip);
	rg_set_iteminfo(iWpn, ItemInfo_iMaxAmmo1, g_config_bpammo);
}

public Ham_CWeapon_Deploy_Post(iWpn) 
{
	if (is_nullent(iWpn) || !Had_Weapon(iWpn, WEAPON_CODE))
		return;

	static id; id = get_member(iWpn, m_pPlayer);
	set_entvar(id, var_viewmodel, V_FROSTBITE);
	set_entvar(id, var_weaponmodel, P_FROSTBITE);

	Stock_SendWeaponAnim(id, iWpn, 5);

	//ccx_custom_pmodel(id, CSW_FROSTBITE, P_FROSTBITE);
	//ccx_custom_cswpn(id, CSW_FROSTBITE)

	static iFlame
	iFlame = find_ent_by_class(id, FROSTBITE_MFNAME)
	
	if(!is_nullent(iFlame))
		set_entvar(iFlame, var_effects, get_entvar(iFlame, var_effects) &~ EF_NODRAW)
	
	//if (LibraryExists(LIBRARY_MD, LibType_Library))
	//	mdcsohud_regwpnhud(id, CSW_FROSTBITE, weapon_spr)

	set_entvar(iWpn, var_fuser1, get_gametime() + 1.03)
	set_member(iWpn, m_Weapon_flTimeWeaponIdle, 1.03);
	set_member(id, m_flNextAttack, 1.03);
}

public Ham_CWeapon_Reload_Post(iWpn)
{
	if (is_nullent(iWpn) || !Had_Weapon(iWpn, WEAPON_CODE))
		return;

	static id; id = get_member(iWpn, m_pPlayer);
	Stock_SendWeaponAnim(id, iWpn, 4);

	set_member(iWpn, m_Weapon_flTimeWeaponIdle, 2.0);
	set_member(id, m_flNextAttack, 2.0);
}

public Ham_CWeapon_AddToPlayer_Post(iWpn, id) 
{
	if (is_nullent(iWpn) || !Had_Weapon(iWpn, WEAPON_CODE))
		return;

	new szWeaponName[32]
	rg_get_iteminfo(iWpn, ItemInfo_pszName, szWeaponName, charsmax(szWeaponName))

	message_begin(MSG_ONE, get_user_msgid("WeaponList"), _, id)
	write_string(szWeaponName)
	write_byte(GetWeaponAmmoType(iWpn))
	write_byte(rg_get_iteminfo(iWpn, ItemInfo_iMaxAmmo1))
	write_byte(GetWeaponAmmo2Type(iWpn))
	write_byte(rg_get_iteminfo(iWpn, ItemInfo_iMaxAmmo2))
	write_byte(rg_get_iteminfo(iWpn, ItemInfo_iSlot))
	write_byte(rg_get_iteminfo(iWpn, ItemInfo_iPosition))
	write_byte(rg_get_iteminfo(iWpn, ItemInfo_iId))
	write_byte(rg_get_iteminfo(iWpn, ItemInfo_iFlags))
	message_end()
}

public Ham_CWeapon_PostFrame_Pre(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_connected(id) || !is_alive(id))
		return HAM_IGNORED
	if (is_nullent(ent) || !Had_Weapon(ent, WEAPON_CODE))
		return HAM_IGNORED	
	
	new Float:fTimer1
	get_entvar(ent, var_fuser1, fTimer1)

	if(fTimer1 && fTimer1 < get_gametime())
	{
		SendSound(id, CHAN_ITEM, SOUND_FIRE[3])
		set_entvar(ent, var_fuser1, get_gametime() + 5.2)
	}
	return HAM_IGNORED
}

public Ham_CWeapon_Holster_Post(ent) 
{
	static id; id = pev(ent, pev_owner)
	if(!is_connected(id) || !is_alive(id))
		return HAM_IGNORED
	if (is_nullent(ent) || !Had_Weapon(ent, WEAPON_CODE))
		return HAM_IGNORED	
	
	SendSound(id, CHAN_ITEM, "common/null.wav")
	return HAM_IGNORED
}

public RG_IsPenetrableEntity_Post(Float:vecStart[3], Float:vecEnd[3], id, pHit)
{
	static iPointContents
	iPointContents = engfunc(EngFunc_PointContents, vecEnd);

	if (iPointContents == CONTENTS_SKY)
		return;
	if (pHit && is_nullent(pHit) || (get_entvar(pHit, var_flags) & FL_KILLME) || !ExecuteHam(Ham_IsBSPModel, pHit))
		return;

	Stock_GunshotDecalTrace(pHit, vecEnd);

	if (iPointContents == CONTENTS_WATER)
		return;

	static Float: vecPlaneNormal[3]; global_get(glb_trace_plane_normal, vecPlaneNormal);
	xs_vec_mul_scalar(vecPlaneNormal, random_float(25.0, 30.0), vecPlaneNormal);

	message_begin_f(MSG_PAS, SVC_TEMPENTITY, vecEnd);
	write_byte(TE_STREAK_SPLASH);
	engfunc(EngFunc_WriteCoord, vecEnd[0]);
	engfunc(EngFunc_WriteCoord, vecEnd[1]);
	engfunc(EngFunc_WriteCoord, vecEnd[2]);
	engfunc(EngFunc_WriteCoord, vecPlaneNormal[0]);
	engfunc(EngFunc_WriteCoord, vecPlaneNormal[1]);
	engfunc(EngFunc_WriteCoord, vecPlaneNormal[2]);
	write_byte(4);
	write_short(random_num(10, 20));
	write_short(3);
	write_short(64);
	message_end();
}

/* =========================================
------- End of Weapon Core Function --------
========================================= */

/* =========================================
---------- Entities and Specials -----------
========================================= */

public fw_MF_Think(ent)
{
	if(is_nullent(ent))
		return
	
	static Classname[32]
	get_entvar(ent, var_classname, Classname, sizeof(Classname))
	
	if(equal(Classname, FROSTBITE_MFNAME))
	{
		static Float:fFrame, Float:fFrameMax,iType,iWpn, Float:fNext
		get_entvar(ent, var_frame, fFrame)
		iWpn = get_entvar(ent, var_iuser4)
		iType = get_entvar(ent, var_iuser1)
		get_entvar(ent, var_fuser1, fNext)
		
		fFrameMax = g_cache_frame_mf[iType]
			
		fFrame += 1.0
		set_entvar(ent, var_frame, fFrame)
		
		if(fFrame >= fFrameMax || !iWpn)
		{
			set_entvar(ent, var_flags, get_entvar(ent, var_flags) | FL_KILLME)
			return
		}
		set_entvar(ent, var_nextthink, get_gametime() + fNext)
		return
	}
}

public MakeMuzzleFlash(id, iEnt, body, typ, mdl[], name[], Float:fNext)
{
	static iMuz
	iMuz = Stock_CreateEntityBase(id, "env_sprite", MOVETYPE_FOLLOW, mdl, name, SOLID_NOT,fNext)
	set_entvar(iMuz, var_body, body)
	set_entvar(iMuz, var_rendermode, kRenderTransAdd)
	set_entvar(iMuz, var_renderamt, 255.0)
	set_entvar(iMuz, var_aiment, id)
	set_entvar(iMuz, var_scale, 0.07)
	set_entvar(iMuz, var_frame, 0.0)
	set_entvar(iMuz, var_animtime, get_gametime())
	set_entvar(iMuz, var_iuser1, typ)
	set_entvar(iMuz, var_iuser4, iEnt)
	set_entvar(iMuz, var_fuser1, fNext)
	set_entvar(iMuz, var_owner, id)
	dllfunc(DLLFunc_Spawn, iMuz)
	SetThink(iMuz, "fw_MF_Think");
}

stock Stock_CreateEntityBase(id, classtype[], mvtyp, mdl[], class[], solid, Float:fNext)
{
	new pEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, classtype))
	set_entvar(pEntity, var_movetype, mvtyp);
	set_entvar(pEntity, var_owner, id);
	engfunc(EngFunc_SetModel, pEntity, mdl);
	set_entvar(pEntity, var_classname, class);
	set_entvar(pEntity, var_solid, solid);
	set_entvar(pEntity, var_nextthink, get_gametime() + fNext)
	return pEntity
}

/* ========================================
------- End of Entities and Specials ------
=========================================== */

/* ======================================
------------------- Stocks --------------
========================================= */

stock SendSound(id, chan, sample[]) emit_sound(id, chan, sample, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

stock Stock_Get_Postion(id,Float:forw,Float:right, Float:up,Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	get_entvar(id, var_origin, vOrigin)
	get_entvar(id, var_view_ofs, vUp) //for player
	xs_vec_add(vOrigin, vUp, vOrigin)
	get_entvar(id, var_v_angle, vAngle) // if normal entity ,use var_angles
	
	engfunc(EngFunc_AngleVectors, vAngle, vForward, vRight, vUp)
	for(new i = 0; i < 3; i++) vStart[i] = vOrigin[i] + vForward[i] * forw + vRight[i] * right + vUp[i] * up
} 

stock Stock_GetSpeedVector(const Float:origin1[3], const Float:origin2[3], Float:speed, Float:new_velocity[3])
{
	xs_vec_sub(origin2, origin1, new_velocity)
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	xs_vec_mul_scalar(new_velocity, num, new_velocity)
}

stock can_damage(id1, id2)
{
	if(id1 <= 0 || id1 >= 33 || id2 <= 0 || id2 >= 33)
		return 1
		
	// Check team
	return(get_member(id1, m_iTeam) != get_member(id2, m_iTeam))
}

public Stock_Fake_KnockBack(id, iVic, Float:iKb)
{
	if(iVic > 32) return
	
	new Float:vAttacker[3], Float:vVictim[3], Float:vVelocity[3], flags
	get_entvar(id, var_origin, vAttacker)
	get_entvar(iVic, var_origin, vVictim)
	vAttacker[2] = vVictim[2] = 0.0
	flags = get_entvar(id, var_flags)
	
	xs_vec_sub(vVictim, vAttacker, vVictim)
	new Float:fDistance
	fDistance = xs_vec_len(vVictim)
	xs_vec_mul_scalar(vVictim, 1 / fDistance, vVictim)
	
	get_entvar(iVic, var_velocity, vVelocity)
	xs_vec_mul_scalar(vVictim, iKb, vVictim)
	xs_vec_mul_scalar(vVictim, 50.0, vVictim)
	vVictim[2] = xs_vec_len(vVictim) * 0.15
	
	if(flags &~ FL_ONGROUND)
	{
		xs_vec_mul_scalar(vVictim, 1.2, vVictim)
		vVictim[2] *= 0.4
	}
	if(xs_vec_len(vVictim) > xs_vec_len(vVelocity)) set_entvar(iVic, var_velocity, vVictim)
}	

stock IsAlive(pEntity)
{
	if (pEntity < 1)
		return 0;

	return (get_entvar(pEntity, var_deadflag) == DEAD_NO && get_entvar(pEntity, var_health) > 0);
}

stock IsPlayer(pEntity)
{
	if (pEntity <= 0 || !IsAlive(pEntity))
		return 0;

	return ExecuteHam(Ham_Classify, pEntity) == 2;
}

// By csbtedhan
stock Stock_Find_SubVic(id, ent, Float:origin[3], Float:fRange)
{
	new enemys, Float:dist, Float:distmin, Float:originT[3]
	
	for(new target = 0; target < get_maxplayers(); target++)
	{
		if (id == target || !IsPlayer(target) || get_entvar(target, var_flags) & FL_NOTARGET || ent == target)
			continue;
		if(!can_damage(ent, target) || !can_damage(id, target))
			continue
			
		dist = entity_range(ent, target)
		
		if(dist > fRange)
			continue;
			
		get_entvar(target, var_origin, originT)
		originT[2] += 15.0

		if ((!distmin || dist <= distmin) && Stock_CanSee(ent, target))
		{
			distmin = dist
			enemys = target
		}
	}

	new target = -1
	while((target = find_ent_in_sphere(target, origin, fRange)) != 0)
	{
		if (id == target || is_nullent(target) || !IsPlayer(target) || get_entity_flags(target) & FL_NOTARGET || ent == target)
			continue;
		if(!can_damage(ent, target) || !can_damage(id, target))
			continue
		
		dist = entity_range(ent, target)
		get_entvar(target, var_origin, originT)
		originT[2]+= 20.0

		if ((!distmin || dist <= distmin) && Stock_isClearLine(origin, originT))
		{
			distmin = dist
			enemys = target
		}	
	}
	return enemys
}

stock Stock_isClearLine(Float:ent_origin[3], Float:target_origin[3])
{
	new Float:hit_origin[3]
	trace_line(-1, ent_origin, target_origin, hit_origin)						

	if (!vector_distance(hit_origin, target_origin)) return 1;
	return 0;
}

stock bool:Stock_CanSee(entindex1, entindex2)
{
	if (!entindex1 || !entindex2)
		return false

	if (!is_nullent(entindex1) && !is_nullent(entindex1))
	{
		new flags = get_entvar(entindex1, var_flags)
		
		if (flags & EF_NODRAW)
			return false
		
		new Float:lookerOrig[3],Float:targetBaseOrig[3],Float:targetOrig[3],Float:temp[3],i
		get_entvar(entindex1, var_origin, lookerOrig)
		get_entvar(entindex1, var_view_ofs, temp)

		for(i = 0; i < 3; i++) lookerOrig[i] += temp[i]
		
		get_entvar(entindex2, var_origin, targetBaseOrig)
		get_entvar(entindex2, var_view_ofs, temp)
		for(i = 0; i < 3; i++) targetOrig[i] = targetBaseOrig[i] + temp[i]
		
		engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the had of seen player
		
		if (get_tr2(0, TraceResult:TR_InOpen) && get_tr2(0, TraceResult:TR_InWater)) return false
		else 
		{
			new Float:flFraction
			get_tr2(0, TraceResult:TR_flFraction, flFraction)
			
			if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2)) return true
			else
			{
				for(i = 0; i < 3; i++) targetOrig[i] = targetBaseOrig[i]
				engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the body of seen player
				get_tr2(0, TraceResult:TR_flFraction, flFraction)
				
				if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2)) return true
				else
				{
					targetOrig[0] = targetBaseOrig [0]
					targetOrig[1] = targetBaseOrig [1]
					targetOrig[2] = targetBaseOrig [2] - 17.0

					engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the legs of seen player
					get_tr2(0, TraceResult:TR_flFraction, flFraction)
					
					if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
						return true
				}
			}
		}
	}
	return false
}

stock SpawnBlood(const Float:vecOrigin[3], iColor, iAmount)
{
	if(iAmount == 0 || !iColor)
		return
	
	iAmount *= 2
	if(iAmount > 255) iAmount = 255
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin)
	write_byte(TE_BLOODSPRITE)
	engfunc(EngFunc_WriteCoord, vecOrigin[0])
	engfunc(EngFunc_WriteCoord, vecOrigin[1])
	engfunc(EngFunc_WriteCoord, vecOrigin[2])
	write_short(spr_blood_spray)
	write_short(spr_blood_drop)
	write_byte(iColor)
	write_byte(min(max(3, iAmount / 10), 16))
	message_end()
}

stock Float:GetVelocity2D(id)
{
	new Float:vecVelocity[3];
	get_entvar(id, var_velocity, vecVelocity);
	vecVelocity[2] = 0.0;
	return xs_vec_len(vecVelocity);
}

stock Stock_GetEyePosition(id, Float:vecEyeLevel[3])
{
	static Float: vecOrigin[3]; get_entvar(id, var_origin, vecOrigin);
	static Float: vecViewOfs[3]; get_entvar(id, var_view_ofs, vecViewOfs);
	xs_vec_add(vecOrigin, vecViewOfs, vecEyeLevel);
}

stock Stock_GetAiming(id, Float:vecAiming[3]) 
{
	static Float: vecViewAngle[3]; get_entvar(id, var_v_angle, vecViewAngle);
	static Float: vecPunchAngle[3]; get_entvar(id, var_punchangle, vecPunchAngle);

	xs_vec_add(vecViewAngle, vecPunchAngle, vecViewAngle);
	angle_vector(vecViewAngle, ANGLEVECTOR_FORWARD, vecAiming);
}

stock Stock_GunshotDecalTrace(pEntity, Float:vecOrigin[3])
{	
	new iDecalId = Stock_DamageDecal(pEntity);
	if (iDecalId == -1)
		return;

	message_begin_f(MSG_PAS, SVC_TEMPENTITY, vecOrigin);
	write_byte(TE_GUNSHOTDECAL);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_short(pEntity);
	write_byte(iDecalId);
	message_end();
}

stock Stock_DamageDecal(const pEntity)
{
	new iRenderMode = get_entvar(pEntity, var_rendermode);
	if (iRenderMode == kRenderTransAlpha)
		return -1;

	static iGlassDecalId; if (!iGlassDecalId) iGlassDecalId = engfunc(EngFunc_DecalIndex, "{bproof1");
	if (iRenderMode != kRenderNormal)
		return iGlassDecalId;

	static iShotDecalId; if (!iShotDecalId) iShotDecalId = engfunc(EngFunc_DecalIndex, "{shot1");
	return (iShotDecalId - random_num(0, 4));
}

stock Stock_GetWeaponBoxItem(const pWeaponBox)
{
	for (new iSlot, iWpn; iSlot < MAX_ITEM_TYPES; iSlot++)
	{
		if (!is_nullent((iWpn = get_member(pWeaponBox, m_WeaponBox_rgpPlayerItems, iSlot))))
			return iWpn;
	}
	return NULLENT;
}

stock Stock_SendWeaponAnim(id, iWpn, iAnim) 
{
	static iBody; iBody = get_entvar(iWpn, var_body);
	set_entvar(id, var_weaponanim, iAnim);

	message_begin(MSG_ONE, SVC_WEAPONANIM, .player = id);
	write_byte(iAnim);
	write_byte(iBody);
	message_end();

	if (get_entvar(id, var_iuser1))
		return;

	static i, iCount, pSpectator, aSpectators[MAX_PLAYERS];
	get_players(aSpectators, iCount, "bch");

	for (i = 0; i < iCount; i++)
	{
		pSpectator = aSpectators[i];

		if (get_entvar(pSpectator, var_iuser1) != OBS_IN_EYE)
			continue;
		if (get_entvar(pSpectator, var_iuser2) != id)
			continue;

		set_entvar(pSpectator, var_weaponanim, iAnim);

		message_begin(MSG_ONE, SVC_WEAPONANIM, .player = pSpectator);
		write_byte(iAnim);
		write_byte(iBody);
		message_end();
	}
}

stock Stock_PrecacheSoundsFromModel(const szModelPath[])
{
	new pFile;

	if (!(pFile = fopen(szModelPath, "rt")))
		return;
	
	new szSoundPath[64], iNumSeq, iSeqIndex, iEvent, iNumEvents, iEventIndex;
	fseek(pFile, 164, SEEK_SET);
	fread(pFile, iNumSeq, BLOCK_INT);
	fread(pFile, iSeqIndex, BLOCK_INT);
	
	for (new i = 0; i < iNumSeq; i++)
	{
		fseek(pFile, iSeqIndex + 48 + 176 * i, SEEK_SET);
		fread(pFile, iNumEvents, BLOCK_INT);
		fread(pFile, iEventIndex, BLOCK_INT);
		fseek(pFile, iEventIndex + 176 * i, SEEK_SET);
		
		for (new k = 0; k < iNumEvents; k++)
		{
			fseek(pFile, iEventIndex + 4 + 76 * k, SEEK_SET);
			fread(pFile, iEvent, BLOCK_INT);
			fseek(pFile, 4, SEEK_CUR);
			
			if (iEvent != 5004)
				continue;
			
			fread_blocks(pFile, szSoundPath, 64, BLOCK_CHAR);
			
			if (strlen(szSoundPath))
			{
				strtolower(szSoundPath);
			#if AMXX_VERSION_NUM < 190
				format(szSoundPath, charsmax(szSoundPath), "%s", szSoundPath);
				engfunc(EngFunc_PrecacheSound, szSoundPath);
			#else
				engfunc(EngFunc_PrecacheSound, fmt("%s", szSoundPath));
			#endif
			}
		}
	}
	
	fclose(pFile);
}

stock Stock_PrecacheFromWeaponList(const szWeaponList[])
{
	new szBuffer[128], pFile;
	format(szBuffer, charsmax(szBuffer), "sprites/%s.txt", szWeaponList);
	engfunc(EngFunc_PrecacheGeneric, szBuffer);

	if (!(pFile = fopen(szBuffer, "rb")))
		return;

	new szSprName[64], iPos;
	while (!feof(pFile)) 
	{
		fgets(pFile, szBuffer, charsmax(szBuffer));
		trim(szBuffer);

		if (!strlen(szBuffer)) 
			continue;
		if ((iPos = containi(szBuffer, "640")) == -1)
			continue;
				
		format(szBuffer, charsmax(szBuffer), "%s", szBuffer[iPos + 3]);		
		trim(szBuffer);

		strtok(szBuffer, szSprName, charsmax(szSprName), szBuffer, charsmax(szBuffer), ' ', 1);
		trim(szSprName);

	#if AMXX_VERSION_NUM < 190
		formatex(szBuffer, charsmax(szBuffer), "sprites/%s.spr", szSprName);
		engfunc(EngFunc_PrecacheGeneric, szBuffer);
	#else
		engfunc(EngFunc_PrecacheGeneric, fmt("sprites/%s.spr", szSprName));
	#endif
	}

	fclose(pFile);
}

/* ======================================
------------- End of Stocks -------------
========================================= */

/* ===============================
------------- SAFETY -------------
=================================*/
public Register_SafetyFunc()
{
	register_event("CurWeapon", "Safety_CurWeapon", "be", "1=1")
	
	RegisterHam(Ham_Spawn, "player", "fw_Safety_Spawn_Post", 1)
	RegisterHam(Ham_Killed, "player", "fw_Safety_Killed_Post", 1)
}

public Register_SafetyFuncBot(id)
{
	RegisterHamFromEntity(Ham_Spawn, id, "fw_Safety_Spawn_Post", 1)
	RegisterHamFromEntity(Ham_Killed, id, "fw_Safety_Killed_Post", 1)
}

public Safety_Connected(id)
{
	Set_BitVar(g_IsConnected, id)
	UnSet_BitVar(g_IsAlive, id)
	
	g_PlayerWeapon[id] = 0
}

public Safety_Disconnected(id)
{
	UnSet_BitVar(g_IsConnected, id)
	UnSet_BitVar(g_IsAlive, id)
	
	g_PlayerWeapon[id] = 0
}

public Safety_CurWeapon(id)
{
	if(!is_alive(id))
		return
		
	static CSW; CSW = read_data(2)
	if(g_PlayerWeapon[id] != CSW) g_PlayerWeapon[id] = CSW
}

public fw_Safety_Spawn_Post(id)
{
	if(!is_user_alive(id))
		return
		
	Set_BitVar(g_IsAlive, id)
}

public fw_Safety_Killed_Post(id)
{
	UnSet_BitVar(g_IsAlive, id)
}

public is_connected(id)
{
	if(!(1 <= id <= 32))
		return 0
	if(!Get_BitVar(g_IsConnected, id))
		return 0

	return 1
}

public is_alive(id)
{
	if(!is_connected(id))
		return 0
	if(!Get_BitVar(g_IsAlive, id))
		return 0
		
	return 1
}

public get_player_weapon(id)
{
	if(!is_alive(id))
		return 0
	
	return g_PlayerWeapon[id]
}
/* ===============================
--------- END OF SAFETY  ---------
=================================*/
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
