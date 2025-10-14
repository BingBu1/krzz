#include <amxmodx>
#include <PlayerSkill>
#include <reapi>
#include <engine>
#include <fakemeta>
#include <kr_core>
#include <hamsandwich>
#include <xs>

new Float:LastSpeedMax
new p_sv_autobunnyhopping , p_sv_enablebunnyhopping
new bool:HasHev[33]

new HevModel [] = "models/w_suit.mdl"

public plugin_init(){
    new plid = register_plugin("角色技能-戈登" , "1.0" , "Bing")
    RegPlayerSkill(plid , "GorDon" , "gordon" , 280.0)

    
    RegisterHookChain(RG_PM_AirMove , "AirMove")
    RegisterHookChain(RG_PM_AirMove , "AirMove_Post" , 1)
    RegisterHookChain(RG_PM_Jump , "PM_JUMP")
    RegisterHookChain(RG_PM_Jump , "PM_JUMP_POST" , 1)
    RegisterHookChain(RG_CBasePlayerWeapon_KickBack, "m_KickBack")

    RegisterHam(Ham_TakeDamage , "player" , "DamgePlayer_Pre")

    register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")

    p_sv_autobunnyhopping = get_cvar_pointer("sv_autobunnyhopping")
    p_sv_enablebunnyhopping = get_cvar_pointer("sv_enablebunnyhopping")
}

public plugin_precache(){
    UTIL_Precache_Sound("kr_sound/hev_aax.wav")
    precache_model(HevModel)
}

public Event_NewRound(){
    arrayset(HasHev , 0 ,sizeof HasHev)
}

// 戈登
public GorDon(id){
    new username[32]
    get_user_name(id , username , charsmax(username))
    m_print_color(0 , "!g[冰布提示]!t%s释放了戈登弗里曼技能:Hev防护服" , username)
    CreateHev(id)
}

public CreateHev(id){
    new Entity = rg_create_entity("info_target")
    if(is_nullent(Entity))
        return

    new Float:origin[3];
    
    GetWatchEnd(id , origin , 8192.0)
    set_entvar(Entity , var_classname , "Hev")
    set_entvar(Entity , var_solid , SOLID_TRIGGER)
    set_entvar(Entity , var_movetype , MOVETYPE_TOSS)
    set_entvar(Entity , var_gravity , 0.5)
    set_entvar(Entity , var_nextthink , get_gametime() + 0.1)
    set_entvar(Entity , var_iuser1 , id) //1代表未被拾取
    set_entvar(Entity , var_fuser1 , get_gametime() + 120.0) //1代表未被拾取
    set_entvar(Entity , var_origin , origin)
    SetTouch(Entity , "HevTouch")

    engfunc(EngFunc_SetModel , Entity , HevModel)
}

public HevTouch(this , touched){
    if(!ExecuteHam(Ham_IsPlayer , touched) || !is_user_alive(touched))
        return
    new master = get_entvar(this , var_iuser1)
    new name[32]
    get_user_name(touched , name , charsmax(name))
    if(touched != master)
        m_print_color(0 , "!t哦不戈登弗里曼的HEV防护服被%s占有。" , name)
    else
        m_print_color(0 , "!t物理学博士穿上了他的HEV,日军也许要品尝到联合军被揍的滋味了.")
    rg_remove_entity(this)
    HasHev[touched] = true

    set_member(touched , m_fLongJump , 1)
    rg_set_user_armor(touched , 200 , ARMOR_VESTHELM)

    UTIL_EmitSound_ByCmd(touched , "kr_sound/hev_aax.wav")
}

public m_KickBack(const this, Float:up_base, Float:lateral_base, Float:up_modifier, Float:lateral_modifier, Float:p_max, Float:lateral_max, direction_change){
    new player = get_member(this, m_pPlayer)

    if(HasHev[player]){
         return HC_SUPERCEDE
    }
    return HC_CONTINUE
}

public AirMove(const playerid){
    if(!HasHev[playerid])
        return HC_CONTINUE
    LastSpeedMax = get_pmove(pm_maxspeed)
    set_pmove(pm_maxspeed , 9999.0)
    return HC_CONTINUE
}

public AirMove_Post(const playerid){
    if(!HasHev[playerid])
        return HC_CONTINUE
    set_pmove(pm_maxspeed , LastSpeedMax)
    return HC_CONTINUE
}

public PM_JUMP(const playerid){
    if(!HasHev[playerid])
        return HC_CONTINUE
    set_pcvar_num(p_sv_autobunnyhopping , 1)
    set_pcvar_num(p_sv_enablebunnyhopping , 1)
    return HC_CONTINUE
}

public PM_JUMP_POST(const playerid){
    if(!HasHev[playerid])
        return HC_CONTINUE
    set_pcvar_num(p_sv_autobunnyhopping , 0)
    set_pcvar_num(p_sv_enablebunnyhopping , 0)
    return HC_CONTINUE
}


public DamgePlayer_Pre(this , attack1 , attacker , Float:Damage , dmg_bit){
    if(!HasHev[this])
        return HAM_IGNORED
    if(Damage > 10.0 && rg_get_user_armor(this) > 0){
        SetHamParamFloat(4 , 10.0)
        client_print(this , print_center , "Hev抵御了这次高额伤害。")
    }
    return HAM_IGNORED
}

stock GetWatchEnd(player , Float:OutEndOrigin[3] , Float:Distance){
    new Float:hitorigin[3]
    new Float:StartOrigin[3],Float:EndOrigin[3],Float:Eyes[3]
    new Float:angles[3], Float:fwd[3];
    get_entvar(player, var_origin , StartOrigin)
    get_entvar(player, var_view_ofs, Eyes)
    xs_vec_add(StartOrigin, Eyes, StartOrigin)
    get_entvar(player, var_v_angle, angles)
    engfunc(EngFunc_MakeVectors, angles)
    global_get(glb_v_forward, fwd)
    xs_vec_mul_scalar(fwd, Distance, EndOrigin)
    xs_vec_add(StartOrigin,EndOrigin,EndOrigin)
    fm_trace_line(player, StartOrigin, EndOrigin, hitorigin)
    xs_vec_copy(hitorigin, OutEndOrigin)
}

stock fm_trace_line(ignoreent, const Float:start[3], const Float:end[3], Float:ret[3]) {
	engfunc(EngFunc_TraceLine, start, end, ignoreent == -1 ? 1 : 0, ignoreent, 0);

	new ent = get_tr2(0, TR_pHit);
	get_tr2(0, TR_vecEndPos, ret);

	return pev_valid(ent) ? ent : 0;
}