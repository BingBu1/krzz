#include <amxmodx>
#include <amxmisc>
#include <reapi>
#include <hamsandwich>
#include <fakemeta_util>
#include <engine>
#include <cstrike>
#include <kr_core>
#include <xp_module>
#include <xs>

#define Get_BitVar(%1,%2)		(%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2)		(%1 |= (1 << (%2 & 31)));
#define UnSet_BitVar(%1,%2)		(%1 &= ~(1 << (%2 & 31)));

#define CLIP 500
#define Max_bpammo 1500
#define WaeponIDs 10000 +5
#define cost 0.1

#define V_MODEL "models/HeroGun/v_m249.mdl"
#define W_MODEL "models/w_m249.mdl"
#define P_MODEL "models/p_m249.mdl"
#define DefWModule "models/w_m249.mdl"

#define HeroGun "weapon_m249"
#define FireCoolDown 0.07

#define Expspr "sprites/thanatos5_explode2.spr"

#define FireDamage 50
#define ExpDamage 1000.0

new HasWaepon

new FW_OnFreeEntPrivateData

new Weaponid

new Sounds[][] ={
    "weapons/HeroGun/m249-1.wav",
    "weapons/HeroGun/m249-2.wav",
    "AVV10/Vortigaunt/avv10_explode2.wav"
}

new KickBackHandle, FireBulletsHandle, ExpSprId

new bool:FireKickBack
public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle)
{
    new wpn = get_member(Player , m_pActiveItem)
    if(is_nullent(wpn))
        return FMRES_IGNORED
	if(!is_user_alive(Player) || get_entvar(wpn , var_impulse) == WaeponIDs) {
        return FMRES_IGNORED
    }
        
	set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001)
	return FMRES_IGNORED
}
public plugin_init(){
    new plid = register_plugin("英雄机枪", "1.0", "Bing")
    RegisterHookChain(RG_CreateWeaponBox , "m_CreateWaeponBox_Post" , true)
    RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy , "m_DefaultDeploy")
    RegisterHookChain(RG_CBasePlayer_AddPlayerItem, "m_AddPlayerItem")
    KickBackHandle = RegisterHookChain(RG_CBasePlayerWeapon_KickBack, "m_KickBack")
    FireBulletsHandle = RegisterHookChain(RG_CBaseEntity_FireBullets3, "m_FireBullets3")

    register_forward(FM_UpdateClientData , "fw_UpdateClientData_Post")

    register_event("HLTV", "event_roundstart", "a", "1=0", "2=0")
    
    RegisterHam(Ham_TraceAttack,"player","m_TraceAttack")

    RegisterHam(Ham_Weapon_PrimaryAttack , HeroGun , "m_PrimaryAttack")
    RegisterHam(Ham_Weapon_PrimaryAttack , HeroGun , "m_PrimaryAttack_Post" , true)

    // register_forward(FM_EmitSound , "fw_EmitSound")
    
    register_clcmd("GiveHeroGun", "GiveHeroGunFunc")
    //register_clcmd("say /buy_HeroGun", "BuyHeroGun")
    //Weaponid = BulidWeaponMenu("速杀阴魔", cost)
    //BulidCrashGunWeapon("速杀银魔", W_MODEL , "FreeGive", plid)
}

public plugin_precache(){
    precache_model(V_MODEL)
    precache_model(W_MODEL)
    precache_model(P_MODEL)
    ExpSprId = precache_model(Expspr)

    UTIL_Precache_Sound("weapons/HeroGun/m249-1.wav")
    UTIL_Precache_Sound("weapons/HeroGun/m249-2.wav")
    UTIL_Precache_Sound("AVV10/Vortigaunt/avv10_explode1.wav")
}

public client_disconnected(id){
    UnSet_BitVar(HasWaepon, id)
}

public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch){
    if(!is_user_connected(id))
        return FMRES_IGNORED
    log_amx("sound is %s" , sample)
    if(Get_BitVar(HasWaepon, id) && get_user_weapon(id) == CSW_M249){
        if(sample[14] == 'm' && sample[15] == '2' &&sample[16] == '4' && sample[18] == '-'){
            //开枪声
            return FMRES_SUPERCEDE
        }
    }
    return FMRES_IGNORED
}


public m_TraceAttack(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits){
    if(!is_user_connected(Attacker)){
        return HAM_IGNORED
    }
    
    if(Get_BitVar(HasWaepon, Attacker) && get_user_weapon(Attacker) == CSW_M249){
        SetHamParamFloat(3, 200.0)//速杀 1.5x
    }
}
public event_roundstart(){
    HasWaepon = 0
}

public OnEntityRemoved(const ent){
    new classname[32]
    get_entvar(ent, var_classname, classname, charsmax(classname))
    if(equal(classname, HeroGun)){
        new playerid = get_member(ent, m_pPlayer)
        if(is_nullent(playerid)){
            return
        }
        UnSet_BitVar(HasWaepon, playerid)
        rg_give_item(playerid, HeroGun)//发放源武器
        if (HasWaepon == 0){
            unregister_forward(FM_OnFreeEntPrivateData, FW_OnFreeEntPrivateData)
        }
    }
}

public m_CreateWaeponBox_Post(const weaponent, const owner, modelName[], Float:origin[3], Float:angles[3], Float:velocity[3], Float:lifeTime, bool:packAmmo){
    if(!owner || !weaponent){
        return HC_CONTINUE
    }
    new weaponbox = GetHookChainReturn(ATYPE_INTEGER)
    new classname[32]
    get_entvar(weaponbox,var_classname,classname,charsmax(classname))
    if(!equal(classname , "weaponbox")){
        return HC_CONTINUE
    }
    new wpn = get_member(owner, m_pActiveItem)
    if(equal(modelName , DefWModule) && Get_BitVar(HasWaepon , owner)){
        set_entvar(weaponent, var_impulse, WaeponIDs)
        UnSet_BitVar(HasWaepon, owner)
        engfunc(EngFunc_SetModel , weaponbox, W_MODEL)
    }
}

public m_DefaultDeploy(const this, szViewModel[], szWeaponModel[], iAnim, szAnimExt[], skiplocal){
    new classname[32]
    get_entvar(this, var_classname, classname, charsmax(classname))
    if(!equal(classname , HeroGun)){
        return
    }
    // new wpn = get_member(get_member(this, m_pPlayer), m_pActiveItem)
    new playerid = get_member(this, m_pPlayer)
    if(Get_BitVar(HasWaepon, playerid)){
        SetHookChainArg(2,ATYPE_STRING, V_MODEL)
        SetHookChainArg(3,ATYPE_STRING, P_MODEL)
    }
}

public m_AddPlayerItem (const this, const pItem){
    if(is_nullent(this)){
        return HC_CONTINUE
    }
    if(get_entvar(pItem,var_impulse) == WaeponIDs){
        Set_BitVar(HasWaepon, this)
        set_entvar(pItem, var_impulse, 0)
        FW_OnFreeEntPrivateData = register_forward(FM_OnFreeEntPrivateData, "OnEntityRemoved", false)
    }
    return HC_CONTINUE
}

public FreeGive(id){
    new wpn = rg_give_custom_item(id , HeroGun , GT_DROP_AND_REPLACE, WaeponIDs)
    Set_BitVar(HasWaepon, id)
    rg_set_iteminfo(wpn,ItemInfo_iMaxClip, CLIP)
    rg_set_iteminfo(wpn, ItemInfo_iMaxAmmo1, Max_bpammo)
    set_member(wpn, m_Weapon_iClip, CLIP)
    rg_set_user_bpammo(id,WEAPON_MP5N,Max_bpammo)
    client_print(id, print_center, "购买成功！攻击力+1.5倍")
}

public BuyHeroGun(id){
    if(access(id ,ADMIN_KICK)){
        //管理员直接获取
        goto GetWpn
    }
    new Float:ammopak = GetAmmoPak(id)
    if(ammopak < cost){
        m_print_color(id , "!g[冰桑提示] 您的大洋不足以购买")
        return
    }
    SetAmmo(id , ammopak - cost)
GetWpn:
    new wpn = rg_give_custom_item(id , HeroGun , GT_DROP_AND_REPLACE, WaeponIDs)
    Set_BitVar(HasWaepon, id)
    rg_set_iteminfo(wpn,ItemInfo_iMaxClip, CLIP)
    rg_set_iteminfo(wpn, ItemInfo_iMaxAmmo1, Max_bpammo)
    set_member(wpn, m_Weapon_iClip, CLIP)
    rg_set_user_bpammo(id,WEAPON_MP5N,Max_bpammo)
    client_print(id, print_center, "购买成功！攻击力+1.5倍")
}

public GiveHeroGunFunc(id){
    new wpn = rg_give_custom_item(id , HeroGun , GT_DROP_AND_REPLACE, WaeponIDs)
    Set_BitVar(HasWaepon, id)
    rg_set_iteminfo(wpn,ItemInfo_iMaxClip, CLIP)
    rg_set_iteminfo(wpn, ItemInfo_iMaxAmmo1, Max_bpammo)
    set_member(wpn, m_Weapon_iClip, CLIP)
    rg_set_user_bpammo(id,WEAPON_M249,Max_bpammo)
}

public m_PrimaryAttack_Post(this){
    static Player;Player = get_member(this , m_pPlayer)
    if(!Get_BitVar(HasWaepon , Player))
        return HAM_IGNORED
    new Float:NextAttackTime = get_member(this , m_Weapon_flNextPrimaryAttack)
    if(NextAttackTime > 0.0){
        set_member(this , m_Weapon_flNextPrimaryAttack , FireCoolDown)
        set_member(this , m_Weapon_flNextSecondaryAttack , FireCoolDown)
        set_member(this , m_Weapon_flTimeWeaponIdle , FireCoolDown)
        set_member(this, m_Weapon_flPrevPrimaryAttack , FireCoolDown)
    }
    if(UTIL_RandFloatEvents(0.15)){
        new Float:EndOrigin[3]
        GetWatchEnd(Player, EndOrigin)
        CreateExp(Player , EndOrigin)
        UTIL_EmitSound_ByCmd(Player , Sounds[2])
    }
    new Cilp = get_member(this , m_Weapon_iClip)
    if(Cilp){
        FireKickBack = false
        rg_weapon_kickback(this, 0.02 ,0.02,0.1,0.025,0.35,0.5,9)
    }
    Stock_SendWeaponAnim(Player , this , 1)
    return HAM_IGNORED
}

public m_PrimaryAttack(this){
    new Player = get_member(this , m_pPlayer)
    if(!Get_BitVar(HasWaepon , Player))
        return HAM_IGNORED
    set_member(this , m_Weapon_flAccuracy, 0.0) //阻止精度下降
    new Cilp = get_member(this , m_Weapon_iClip)
    if(Cilp){
        FireKickBack = true
    }
    set_member(this, m_Weapon_iClip , 100)
    return HAM_IGNORED
}

public m_KickBack(const this, Float:up_base, Float:lateral_base, Float:up_modifier, Float:lateral_modifier, Float:p_max, Float:lateral_max, direction_change){
    new player = get_member(this, m_pPlayer)
    if(!is_user_connected(player) || !Get_BitVar(HasWaepon, player)){
        return HC_CONTINUE
    }
    if(FireKickBack){
         return HC_SUPERCEDE
    }
   return HC_CONTINUE
}

public m_FireBullets3(pEntity, Float:vecSrc[3], Float:vecDirShooting[3], Float:vecSpread, Float:flDistance, iPenetration, iBulletType, iDamage, Float:flRangeModifier, pevAttacker, bool:bPistol, shared_rand){
    if(!is_user_connected(pEntity) || !Get_BitVar(HasWaepon, pEntity) || get_user_weapon(pEntity) != CSW_M249){
        return HC_CONTINUE
    }
    SetHookChainArg(8 , ATYPE_INTEGER , FireDamage)
    return HC_CONTINUE
}

stock CreateExp(const id , const Float:Origin[3]){
    message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(ExpSprId)	// sprite index
	write_byte(20)	// scale in 0.1's
	write_byte(10)	// framerate
	write_byte(TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NODLIGHTS)	// flags
	message_end()

    rg_radius_damage(Origin, id, id, ExpDamage, 350.0, DMG_BULLET)
}

stock GetWatchEnd(player , Float:OutEndOrigin[3]){
    new Float:hitorigin[3]
    new Float:StartOrigin[3],Float:EndOrigin[3],Float:Eyes[3]
    new Float:angles[3], Float:fwd[3];
    get_entvar(player, var_origin , StartOrigin)
    get_entvar(player, var_view_ofs, Eyes)
    xs_vec_add(StartOrigin, Eyes, StartOrigin)
    get_entvar(player, var_v_angle, angles)
    engfunc(EngFunc_MakeVectors, angles)
    global_get(glb_v_forward, fwd)
    xs_vec_mul_scalar(fwd, 8192.0, EndOrigin)
    xs_vec_add(StartOrigin,EndOrigin,EndOrigin)
	new hitent = fm_trace_line(player,StartOrigin,EndOrigin,hitorigin)
    xs_vec_copy(hitorigin, OutEndOrigin)
}

stock rg_radius_damage(const Float:origin[3], attacker, inflictor, Float:damage, Float:radius, dmg_bits)
{
    new ent = -1
    new Float:target_origin[3]
    new Float:distance
    new Float:final_damage
	new Float:Origin_[3]
	new Float:Heal;
	//server_print("%f %f %f rg_radius_damage in put" , origin[0],origin[1],origin[2]);
	// get_entvar(inflictor, var_origin, Origin_)

    while ((ent = find_ent_in_sphere(ent, origin, radius)) != 0)
    {
        if (!is_valid_ent(ent)) continue
		if(pev(ent,pev_takedamage) == DAMAGE_NO) continue

		new deadflag
		pev(ent , pev_deadflag,deadflag)
		
		if(deadflag != DEAD_NO) continue

        get_entvar(ent, var_origin, target_origin)
        distance = vector_distance(origin, target_origin)

        // ���Եݼ��˺���ԽԶԽ�ͣ�
        final_damage = damage * (1.0 - (distance / radius))
        if (final_damage <= 0.0) continue;

		if(ent == attacker) continue;

		if(is_user_alive(ent) && cs_get_user_team(ent) == cs_get_user_team(attacker))continue;

		get_entvar(ent , var_health , Heal);

		new kill = Heal - final_damage;
		set_pev(ent, pev_dmg_inflictor, attacker)
		ExecuteHamB(Ham_TakeDamage, ent, inflictor, attacker, final_damage, dmg_bits)
    }
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