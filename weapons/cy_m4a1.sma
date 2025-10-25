#include <amxmodx>
#include <amxmisc>
#include <reapi>
#include <engine>
#include <cstrike>
#include <hamsandwich>
#include <fakemeta>
#include <xp_module>
#include <kr_core>
#include <props>
#include <xs>

#define Get_BitVar(%1,%2)		(%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2)		(%1 |= (1 << (%2 & 31)));
#define UnSet_BitVar(%1,%2)		(%1 &= ~(1 << (%2 & 31)));

#define SetEntFireing(%1,%2) set_prop_int(%1 , "cy_fire" , %2) 
#define GetEntFireing(%1) get_prop_int(%1 , "cy_fire")
#define HasFireProp(%1) prop_exists(%1 , "cy_fire")

#define SetEntFireMaster(%1,%2) set_prop_int(%1 , "cymst_f" , %2) 
#define GetEntFireMaster(%1) get_prop_int(%1 , "cymst_f")
#define SetEntFireDmgTimer(%1,%2) set_prop_float(%1 , "cyfiredmg" , %2) 
#define GetEntFireDmgTimer(%1) get_prop_float(%1 , "cyfiredmg")

#define CLIP 60
#define Max_bpammo 300
#define WaeponIDs 10000 + 6
#define cost 165.0
#define DamageBase 600.0

#define V_MODEL "models/v_m4a1_a1.mdl"
#define W_MODEL "models/w_m4a1_a1.mdl"
#define P_MODEL "models/p_m4a1_a1.mdl"
#define DefWModule "models/w_m4a1.mdl"

#define FlyModule "models/Onions.mdl"

#define cznh "weapon_m4a1"

new WEAPON_SOUNDS[][]={
    "weapons/cart_ldraw.wav",
    "weapons/cart_lclipout.wav",
    "weapons/cart_lclipin.wav",
    "weapons/cart_hclipout.wav",
    "weapons/cart_hhit.wav",
    "weapons/cart_spindown.wav",
    "weapons/cart_hdraw.wav",
    "weapons/cart_turn.wav",
    "weapons/cart_yaho.wav",
    "weapons/cart_jump.wav",
    "weapons/cart_foley5.wav",
    "weapons/cart_foley4.wav",
    "weapons/cart_foley3.wav",
    "weapons/cart_foley2.wav",
    "weapons/cart_foley1.wav",
    "kr_sound/zq_Multi1.wav",
    "kr_sound/zq_Multi2.wav",
}

new HasWaepon

new FW_OnFreeEntPrivateData

new g_Trail, g_Explosion , Fire_Spr

new waeponid , bool:IsMiku[33]

public plugin_init(){
    register_plugin("初音甩葱枪", "1.0", "Bing")
    RegisterHookChain(RG_CreateWeaponBox , "m_CreateWaeponBox_Post" , true)
    RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy , "m_DefaultDeploy")
    // RegisterHookChain(RG_CBasePlayerWeapon_DefaultReload , "m_Reload")
    RegisterHookChain(RG_CBasePlayer_AddPlayerItem, "m_AddPlayerItem")
    register_event("HLTV", "event_roundstart", "a", "1=0", "2=0")
    
    RegisterHam(Ham_Weapon_PrimaryAttack , cznh , "Attack_post")
    
    RegisterHam(Ham_TraceAttack,"player","m_TraceAttack")
    RegisterHam(Ham_TraceAttack,"hostage_entity","m_TraceAttack")
    register_clcmd("gvcygun", "FreeGive" , ADMIN_RCON)
    waeponid = BulidWeaponMenu("初音甩葱枪", cost)
    // BulidCrashGunWeapon("初音甩葱枪", W_MODEL , "FreeGive", plid)

    RegisterHam(Ham_Think, "hostage_entity", "Ent_Fire_Think")
    RegisterHam(Ham_Think, "player", "Ent_Fire_Think")
}

public plugin_precache(){
    precache_model(V_MODEL)
    precache_model(W_MODEL)
    precache_model(P_MODEL)
    precache_model(FlyModule)

    for(new i = 0 ; i < sizeof WEAPON_SOUNDS ; i++){
        UTIL_Precache_Sound(WEAPON_SOUNDS[i])
    }

    g_Trail = precache_model("sprites/laserbeam.spr")
    g_Explosion = precache_model("sprites/zerogxplode.spr")
    Fire_Spr = precache_model("sprites/fire.spr")
}

public OnModelChange(id , name[]){
    if(!strcmp(name , "Miku")){
        IsMiku[id] = true
        return
    }
    IsMiku[id] = false
}

public ItemSel_Post(id , items, Float:cost1){
    if(items == waeponid){
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
        SubAmmoPak(id , cost1)
        FreeGive(id)
    }
}

public event_roundstart(){
    HasWaepon = 0
    remove_entity_name("cy_fly")
}

public client_disconnected(id){
    UnSet_BitVar(HasWaepon, id)
}

public m_Reload(const this, iClipSize, iAnim, Float:fDelay){
    new Player = get_member(this, m_pPlayer)
    if(is_entity(this) && is_user_alive(Player) && Get_BitVar(HasWaepon, Player)){
        // UTIL_EmitSound_ByCmd(Player , WEAPON_SOUNDS[1])
    }
    return HC_CONTINUE
}

public Attack_post(const this){
    new playerid = get_member(this, m_pPlayer)
    new m_clips = get_member(this, m_Weapon_iClip)
    if(!Get_BitVar(HasWaepon, playerid) || is_nullent(playerid)){
        return HAM_IGNORED
    }
    if(m_clips <= 0)
        return HAM_IGNORED
    new Float:fOrigin[3]
    const Float:ForwardDis = 10.0
    new bool:FireDoudle = UTIL_RandFloatEvents(0.3)
    new M4a1_WeaponState = get_member(this , m_Weapon_iWeaponState)
    if(!(M4a1_WeaponState & _:WPNSTATE_M4A1_SILENCED) && UTIL_RandFloatEvents(IsMiku[playerid] ? 1.0 : 0.45)){
        if(!FireDoudle){
            get_position(playerid, ForwardDis, 0.0, 0.0, fOrigin)
            CreateFly(playerid , fOrigin)
        }else{
            if(IsMiku[playerid]){
                get_position(playerid, ForwardDis, -15.0, 0.0, fOrigin)
                CreateFly(playerid , fOrigin)
                get_position(playerid, ForwardDis, 15.0, 0.0, fOrigin)
                CreateFly(playerid , fOrigin)
                get_position(playerid, ForwardDis, 0.0, 15.0, fOrigin)
                CreateFly(playerid , fOrigin)
            }else{
                get_position(playerid, ForwardDis, -15.0, 0.0, fOrigin)
                CreateFly(playerid , fOrigin)
                get_position(playerid, ForwardDis, 15.0, 0.0, fOrigin)
                CreateFly(playerid , fOrigin)
            }
        }
    }else if (M4a1_WeaponState & _:WPNSTATE_M4A1_SILENCED && UTIL_RandFloatEvents(IsMiku[playerid] ? 0.45 :0.1)){
        get_position(playerid, ForwardDis, 0.0, 0.0, fOrigin)
        CreateFly(playerid , fOrigin , true)
    }
    return HAM_IGNORED
}

CreateFly(id , Float:Origin[3] , isFireFly = false){
    if(is_nullent(id))
    return 0
    new ent = rg_create_entity("info_target")
    if(!ent)return ent
    new Float:fAngles[3]
    new const flyspeed = 1500
    set_entvar(ent, var_classname, "cy_fly")
    set_entvar(ent, var_movetype, MOVETYPE_FLY)
    set_entvar(ent, var_solid, SOLID_BBOX)
    set_entvar(ent, var_owner, id)

    get_entvar(id, var_v_angle, fAngles)
    fAngles[0] *= -1.0
    set_entvar(ent,var_origin, Origin)
    set_entvar(ent,var_angles, fAngles)
    new Float:fVel[3]
    velocity_by_aim(id, flyspeed, fVel)
    set_entvar(ent, var_velocity, fVel)
    set_entvar(ent, var_gravity , 0.5)	
    set_entvar(ent , var_fuser1 , get_gametime() + 10.0)
    isFireFly ?  SetTril(ent , 255 , 0 , 0) : SetTril(ent , 0 , 150 , 255)
    engfunc(EngFunc_SetModel, ent , FlyModule)
    engfunc(EngFunc_SetSize, ent, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0})
    isFireFly ? SetTouch(ent, "TouchFireFly") : SetTouch(ent, "TouchFly")
    SetThink(ent, "TouchThink")
    return ent
}

public SetTril(ent , r , g , b){
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
    write_byte(TE_BEAMFOLLOW)	// Temp entity type
    write_short(ent)		// entity
    write_short(g_Trail)	// sprite index
    write_byte(2)	// life time in 0.1's
    write_byte(5)	// line width in 0.1's
    write_byte(r)	// red (RGB)
    write_byte(g)	// green (RGB)
    write_byte(b)	// blue (RGB)
    write_byte(255)	// brightness 0 invisible, 255 visible
    message_end()
}

public TouchFly(const this, const other){
    new Float:org[3]
    get_entvar(this, var_origin, org)
    MakeBoom(org)
    set_entvar(this, var_flags, FL_KILLME)
    new owner = get_entvar(this, var_owner)
    rg_dmg_radius(org , owner , owner , DamageBase , 250.0 , CLASS_PLAYER , DMG_GENERIC)
}

public TouchFireFly(const this , const other){
    new Float:org[3]
    get_entvar(this, var_origin, org)
    set_entvar(this, var_flags, FL_KILLME)
    Make_Beamcylinder(org , 150 , 255 , 0 ,0)
    new ent = -1
    new owner = get_entvar(this , var_owner)
    if(!is_user_connected(owner) || !is_user_alive(owner)){
        SetTouch(this , "")
        rg_remove_entity(this)
        return
    }
    new m_team = get_member(owner , m_iTeam)
    while((ent = find_ent_in_sphere(ent , org , 150.0)) > 0){
        if(get_entvar(ent , var_takedamage) == DAMAGE_NO 
            || get_entvar(ent , var_deadflag) == DEAD_DEAD)
            continue
        if(is_user_bot(ent))
            continue
        if(ExecuteHam(Ham_IsPlayer , ent) && get_member(ent , m_iTeam) == m_team)
            continue
        if(GetIsNpc(ent) && KrGetFakeTeam(ent) == CsTeams:m_team)
            continue
        SetEntFireing(ent , true)
        SetEntFireMaster(ent , owner)
        SetEntFireDmgTimer(ent , get_gametime())
    }
}

public Ent_Fire_Think(ent){
    if(!HasFireProp(ent))
        return
    if(!GetEntFireing(ent))
        return
    if(get_gametime() > GetEntFireDmgTimer(ent)){
        new Float:monster_Heal = get_entvar(ent , var_max_health)
        new master = GetEntFireMaster(ent)
        if(!is_user_connected(master) || !is_user_alive(master)){
            SetEntFireing(ent , false)
        }   
        SetEntFireDmgTimer(ent , get_gametime() + 0.3)
        new bool:Miku = IsMiku[master]
        new Float:AddDamage = GetLvDamageReduction() // 最高减防0.65
        new Float:TakeDamge = monster_Heal <= 200.0 ? 50.0: floatmax(monster_Heal * 0.02 , 5.0)
        if(Miku){
            TakeDamge = TakeDamge / (1.0 - AddDamage)
        }
        TakeDamge = floatmin(TakeDamge , Miku ? 10000.0 : 1500.0)
        ExecuteHamB(Ham_TakeDamage , ent , master ,master , TakeDamge , DMG_BURN)
        CreateSpr(Fire_Spr , ent)
        monster_Heal = get_entvar(ent , var_health)
        if(monster_Heal <= 0.0){
            SetEntFireing(ent , false)
        }
    }
}

public TouchThink(ent){
    if(get_entvar(ent , var_fuser1) < get_gametime())
        rg_remove_entity(ent)
    set_entvar(ent , var_nextthink , get_gametime() + 0.1)
}

public m_TraceAttack(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits){
    if(!is_user_connected(Attacker)){
        return HAM_IGNORED
    }
    
    if(Get_BitVar(HasWaepon, Attacker) && get_user_weapon(Attacker) == CSW_MP5NAVY){
        SetHamParamFloat(3, Damage * 3.0)
    }
    return HAM_IGNORED
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
    new WeaponIdType:wpnid = any:rg_get_iteminfo(wpn , ItemInfo_iId)
    rg_set_user_bpammo(id, wpnid , Max_bpammo)

    new sound = random_num(0 , 1)
    UTIL_EmitSound_ByCmd(id , sound ? "kr_sound/zq_Multi1.wav" : "kr_sound/zq_Multi2.wav")
}

public Buymlxg(id){
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
    new wpn = rg_give_custom_item(id , cznh , GT_DROP_AND_REPLACE, WaeponIDs)
    Set_BitVar(HasWaepon, id)
    rg_set_iteminfo(wpn,ItemInfo_iMaxClip, CLIP)
    rg_set_iteminfo(wpn, ItemInfo_iMaxAmmo1, Max_bpammo)
    set_member(wpn, m_Weapon_iClip, CLIP)
    new WeaponIdType:wpnid = any:rg_get_iteminfo(wpn , ItemInfo_iId)
    rg_set_user_bpammo(id,wpnid,Max_bpammo)
    client_print(id, print_center, "购买成功！攻击力+3.0倍")
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
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
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


stock Make_Beamcylinder(Float:iOrigin[3], Radius, r, g, b){
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
    write_byte(TE_BEAMCYLINDER)
    write_coord(floatround(iOrigin[0]))          // center x
    write_coord(floatround(iOrigin[1]))          // center y
    write_coord(floatround(iOrigin[2]))          // center z
    write_coord(floatround(iOrigin[0] ))        // axis x (水平半径)
    write_coord(floatround(iOrigin[1]))          // axis y
    write_coord(floatround(iOrigin[2]) + Radius)          // axis z
    write_short(g_Trail)   // sprite
    write_byte(0)          // startframe
    write_byte(0)         // framerate
    write_byte(10)         // life (50 = 5 秒)
    write_byte(40)          // width
    write_byte(0)          // noise
    write_byte(r)          // r
    write_byte(g)          // g
    write_byte(b)          // b
    write_byte(255)        // brightness
    write_byte(0)         // speed
    message_end()
}

stock CreateSpr(sprid , DeadEnt , scale = 15){
    new Float:fOrigin[3] , iOrigin[3]
    get_entvar(DeadEnt , var_origin , fOrigin)
    iOrigin[0] = floatround(fOrigin[0])
    iOrigin[1] = floatround(fOrigin[1])
    iOrigin[2] = floatround(fOrigin[2])
    message_begin(0 , SVC_TEMPENTITY)
    write_byte(TE_SPRITE)
    write_coord(iOrigin[0])
    write_coord(iOrigin[1])
    write_coord(iOrigin[2] + 35 )
    write_short(sprid)
    write_byte(scale) // scale
    write_byte(200) // alpha
    message_end()
}
