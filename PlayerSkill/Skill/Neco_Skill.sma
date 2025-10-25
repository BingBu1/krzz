#include <amxmodx>
#include <PlayerSkill>
#include <reapi>
#include <engine>
#include <fakemeta>
#include <kr_core>
#include <hamsandwich>
#include <xs>

new g_Explosion

public plugin_init(){
    new plid = register_plugin("角色技能-猫姬" , "1.0" , "Bing")
    RegPlayerSkill(plid , "NecoSKill" , "NecoArc" , 3.0)
}

public plugin_precache(){
    g_Explosion = precache_model("sprites/zerogxplode.spr")
    UTIL_Precache_Sound("kr_sound/necoact-Skill.wav")
}

// 猫姬技能
public NecoSKill(id){
    new username[32]
    get_user_name(id , username , charsmax(username))
    m_print_color(0 , "!g[冰布提示]!t%s释放了猫姬技能:@#!$" , username)
    UTIL_EmitSound_ByCmd(0 , "kr_sound/necoact-Skill.wav")
    CreateDaceNeco(id)
}
native CreateDanceEnt(id , Float:Origin[3])

CreateDaceNeco(id){
    new Float:EndOrigin[3]
    GetWatchEnd(id , EndOrigin)
    new DanceEnt = CreateDanceEnt(id , EndOrigin)
    set_task(3.0 , "BoomEnt" , DanceEnt + 1151)
}

public BoomEnt(ent){
    ent -= 1151
    if(!is_valid_ent(ent))
        return
    new Float:Origin[3]
    new AimEnt = get_entvar(ent , var_aiment)
    new master = get_entvar(ent , var_owner)
    rg_remove_entity(ent)
    rg_remove_entity(AimEnt)
    if(!is_user_connected(master) || !is_user_alive(master)){
        return
    }
    get_entvar(ent , var_origin , Origin)
    MakeBigBoom(Origin)
    rg_dmg_radius(Origin , master , master , 1500.0 , 800.0 , CLASS_PLAYER , DMG_GENERIC)
}

public MakeBigBoom(Float:Origin[3]){
    new iOrigin[3]
    FVecIVec(Origin , iOrigin)
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY, iOrigin)
    write_byte(TE_EXPLOSION)
    write_coord(iOrigin[0])
    write_coord(iOrigin[1])
    write_coord(iOrigin[2])
    write_short(g_Explosion)
    write_byte(200)
    write_byte(15)
    write_byte(0)
    message_end()
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
    fm_trace_line(player,StartOrigin,EndOrigin,hitorigin)
    xs_vec_copy(hitorigin, OutEndOrigin)
}

stock fm_trace_line(ignoreent, const Float:start[3], const Float:end[3], Float:ret[3]) {
	engfunc(EngFunc_TraceLine, start, end, ignoreent == -1 ? 1 : 0, ignoreent, 0);

	new ent = get_tr2(0, TR_pHit);
	get_tr2(0, TR_vecEndPos, ret);

	return pev_valid(ent) ? ent : 0;
}
