#include <amxmodx>
#include <amxmisc>
#include <reapi>
#include <engine>
#include <cstrike>
#include <hamsandwich>
#include <fakemeta>
#include <xp_module>
#include <kr_core>
#include <xs>

#define Get_BitVar(%1,%2)		(%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2)		(%1 |= (1 << (%2 & 31)));
#define UnSet_BitVar(%1,%2)		(%1 &= ~(1 << (%2 & 31)));

#define CLIP 10
#define Max_bpammo 90
#define WaeponIDs 10000 + 1
#define cost 4.0
#define DamageBase 120.0

#define V_MODEL "models/v_scout_2.mdl"
#define W_MODEL "models/w_scout_2.mdl"
#define P_MODEL "models/p_scout_3.mdl"
#define DefWModule "models/w_scout.mdl"

#define FlySound "nuke_fly.wav"
#define FlyModule "models/hvr.mdl"

#define cznh "weapon_scout"

new HasWaepon,Has_ZWaepon//紫N

new FW_OnFreeEntPrivateData

new g_Trail, g_Explosion,g_Explosion_Z

new waeponid
public plugin_init(){
    new plid = register_plugin("长征N号", "1.0", "Bing")
    RegisterHookChain(RG_CreateWeaponBox , "m_CreateWaeponBox_Post" , true)
    RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy , "m_DefaultDeploy")
    RegisterHookChain(RG_CBasePlayer_AddPlayerItem, "m_AddPlayerItem")
    register_event("HLTV", "event_roundstart", "a", "1=0", "2=0")
    
    RegisterHam(Ham_Weapon_PrimaryAttack , cznh , "Attack_post")
    
    RegisterHam(Ham_TraceAttack,"player","m_TraceAttack")
    RegisterHam(Ham_TraceAttack,"hostage_entity","m_TraceAttack")
    register_clcmd("say /buy_cznh", "Buycznh")
    waeponid = BulidWeaponMenu("长征N号", cost)
    BulidCrashGunWeapon("长征N号", W_MODEL , "FreeGive", plid)
}

public plugin_precache(){
    precache_model(V_MODEL)
    precache_model(W_MODEL)
    precache_model(P_MODEL)
    precache_model(FlyModule)

    g_Trail = precache_model("sprites/zbeam1.spr")
	g_Explosion = precache_model("sprites/zerogxplode.spr")

    precache_sound(FlySound)
}

public ItemSel_Post(id , items, Float:cost1){
    if(items == waeponid){
        Buycznh(id)
    }
}

public event_roundstart(){
    HasWaepon = 0
}

public client_disconnected(id){
    UnSet_BitVar(HasWaepon, id)
}

public Attack_post(const this){
    new playerid = get_member(this, m_pPlayer)
    new m_clips = get_member(this, m_Weapon_iClip)
    if(!Get_BitVar(HasWaepon, playerid) || is_nullent(playerid)){
        return HAM_IGNORED
    }
    if(m_clips <= 0)
        return HAM_IGNORED
    CreateFly(playerid)
}

public CreateFly(id){
    if(is_nullent(id))return 0
    new ent = rg_create_entity("info_target")
    if(!ent)return ent
    SetTouch(ent, "TouchFly")
    new Float:fAngles[3], Float:fOrigin[3]
    new const flyspeed = 1000
    set_entvar(ent, var_classname, "cznh_fly")
    set_entvar(ent, var_movetype, MOVETYPE_FLY)
    set_entvar(ent, var_solid, SOLID_BBOX)
    set_entvar(ent, var_owner, id)

    get_entvar(id, var_v_angle, fAngles)
    fAngles[0] *= -1.0
    get_position(id, 20.0, 0.0, 0.0, fOrigin)
    set_entvar(ent,var_origin, fOrigin)
    set_entvar(ent,var_angles, fAngles)
    new Float:fVel[3]
	velocity_by_aim(id, flyspeed, fVel)
    set_entvar(ent, var_velocity, fVel)	

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)	// Temp entity type
	write_short(ent)		// entity
	write_short(g_Trail)	// sprite index
	write_byte(25)	// life time in 0.1's
	write_byte(5)	// line width in 0.1's
	write_byte(224)	// red (RGB)
	write_byte(224)	// green (RGB)
	write_byte(255)	// blue (RGB)
	write_byte(255)	// brightness 0 invisible, 255 visible
	message_end()

    engfunc(EngFunc_SetModel, ent , FlyModule)
    engfunc(EngFunc_SetSize, ent, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0})
    emit_sound(ent, CHAN_AUTO, FlySound,1.0, ATTN_NORM, 0, PITCH_NORM)
}

public TouchFly(const this, const other){
    new Float:org[3]
    get_entvar(this, var_origin, org)
    MakeBoom(org)
    set_entvar(this, var_flags, FL_KILLME)
    new findent = NULLENT
    new owner = get_entvar(this, var_owner)
    while((findent = find_ent_in_sphere(findent, org, 300.0)) != 0){
        new Float:targetOrigin[3]
        if(get_entvar(findent, var_deadflag) == DEAD_DEAD|| get_entvar(findent , var_takedamage) == DAMAGE_NO)
            continue
        if(findent == owner)
            continue
        if(findent <= 32 && cs_get_user_team(findent) == cs_get_user_team(owner))
            continue
        get_entvar(findent, var_origin, targetOrigin)
        new Float:distance = vector_distance(org, targetOrigin)
        if(distance > 300.0)
            continue
        new DamageNew = DamageBase * (1.0 - distance / 300.0)
        ExecuteHamB(Ham_TakeDamage, findent, owner, owner, DamageNew, DMG_GENERIC)
    }
}

public m_TraceAttack(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits){
    if(!is_user_connected(Attacker)){
        return HAM_IGNORED
    }
    
    if(Get_BitVar(HasWaepon, Attacker) && get_user_weapon(Attacker) == CSW_MP5NAVY){
        SetHamParamFloat(3, Damage * 2.0)
    }
}

public OnEntityRemoved(const ent){
    new classname[32]
    get_entvar(ent, var_classname, classname, charsmax(classname))
    if(classname[0] == 'w' && equal(classname, cznh)){
        new playerid = get_member(ent, m_pPlayer)
        if(is_nullent(playerid)){
            return
        }
        UnSet_BitVar(HasWaepon, playerid)
        rg_give_item(playerid, cznh)//发放源武器
        if (HasWaepon == 0){
            unregister_forward(FM_OnFreeEntPrivateData, FW_OnFreeEntPrivateData)
        }
    }
}

public m_CreateWaeponBox_Post(const weaponent, const owner, modelName[], Float:origin[3], Float:angles[3], Float:velocity[3], Float:lifeTime, bool:packAmmo){
    if(!owner || !weaponent){
        return
    }
    new weaponbox = GetHookChainReturn(ATYPE_INTEGER)
    new classname[32]
    get_entvar(weaponbox,var_classname,classname,charsmax(classname))
    if(!equal(classname , "weaponbox")){
        return
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
    if(!equal(classname , cznh)){
        return
    }
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
    new wpn = rg_give_custom_item(id , cznh , GT_DROP_AND_REPLACE, WaeponIDs)
    Set_BitVar(HasWaepon, id)
    rg_set_iteminfo(wpn,ItemInfo_iMaxClip, CLIP)
    rg_set_iteminfo(wpn, ItemInfo_iMaxAmmo1, Max_bpammo)
    set_member(wpn, m_Weapon_iClip, CLIP)
    rg_set_user_bpammo(id,WEAPON_SCOUT,Max_bpammo)
}

public Buycznh(id){
    if(access(id ,ADMIN_KICK)){
        //管理员直接获取
        goto GetWpn
    }
    new bool:CanBuy
#if defined Usedecimal
	CanBuy = Dec_cmp(id , cost , ">=")
#else
	new Float:ammopak = GetAmmoPak(id)
	CanBuy = (ammopak >= cost)
#endif
    if(!CanBuy){
        m_print_color(id , "!g[冰桑提示] 您的大洋不足以购买")
        return
    }
    SubAmmoPak(id , cost)
GetWpn:
    new wpn = rg_give_custom_item(id , cznh , GT_DROP_AND_REPLACE, WaeponIDs)
    Set_BitVar(HasWaepon, id)
    rg_set_iteminfo(wpn,ItemInfo_iMaxClip, CLIP)
    rg_set_iteminfo(wpn, ItemInfo_iMaxAmmo1, Max_bpammo)
    set_member(wpn, m_Weapon_iClip, CLIP)
    rg_set_user_bpammo(id,WEAPON_SCOUT,Max_bpammo)
    client_print(id, print_center, "购买成功！攻击力+2.0倍")
}

stock get_position(id,Float:forw, Float:right, Float:up, Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

public MakeBoom(Float:iOrigin[3]){
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY, iOrigin)
	write_byte(TE_EXPLOSION)
	write_coord_f(iOrigin[0])
	write_coord_f(iOrigin[1])
	write_coord_f(iOrigin[2])
	write_short(g_Explosion)
	write_byte(30)
	write_byte(15)
	write_byte(0)
	message_end()
}
