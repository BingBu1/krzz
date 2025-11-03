#include <amxmodx>
#include <PlayerSkill>
#include <reapi>
#include <engine>
#include <fakemeta>
#include <kr_core>
#include <props>
#include <hamsandwich>
#include <fakemeta_util>

#define TouchMax 25

new sTrail , g_Explosion

public plugin_init(){
    new plid = register_plugin("角色技能-斯大林" , "1.0" , "Bing")
    register_event("HLTV", "event_roundstart", "a", "1=0", "2=0")
    RegPlayerSkill(plid , "SiDaLin_Skill" , "bing_sidalin" , 5.0)
}

public event_roundstart(){
    new ent = -1
    while((ent = rg_find_ent_by_class(ent , "SiDaLin_SkillThink_ent")) > 0){
        rg_remove_entity(ent)
    }
}

public plugin_precache(){
    sTrail = precache_model("sprites/laserbeam.spr")
    g_Explosion = precache_model("sprites/zerogxplode.spr")
    precache_model("sprites/blueflare1.spr")
}

// 轰炸
public SiDaLin_Skill(id){  
    new username[32]
    get_user_name(id , username , charsmax(username))
    m_print_color(0 , "!g[冰布提示]!t%s释放了斯大林技能压缩磁道炮。" , username)
    
    CreateBoomNew(id , 0.0)
    CreateBoomNew(id , 15.0)
    CreateBoomNew(id , -15.0)
}

stock CreateBoomNew(id , Float:AnlgeDifs){
    new tk_ent = rg_create_entity("info_target")
    if(!tk_ent)
        return NULLENT
    new Float:org[3] ,Float:ViewOfs[3], Float:Dir[3] , Float:VelSpped[3] , Float:Angles[3]
    get_entvar(id, var_v_angle, Angles)
    get_entvar(id, var_origin, org)
    get_entvar(id, var_view_ofs , ViewOfs)

    xs_vec_add(org, ViewOfs, org)

    Angles[1] += AnlgeDifs
    angle_vector(Angles , ANGLEVECTOR_FORWARD , Dir)

    xs_vec_mul_scalar(Dir, 500.0, VelSpped)

    set_entvar(tk_ent, var_movetype, MOVETYPE_FLY)
    set_entvar(tk_ent, var_solid, 5)
    set_entvar(tk_ent, var_origin, org)
    set_entvar(tk_ent, var_velocity, VelSpped)
    set_entvar(tk_ent, var_classname,"tk_boom")
    set_entvar(tk_ent, var_rendermode,kRenderTransAdd)
    set_entvar(tk_ent, var_renderamt, 255.0)
    set_entvar(tk_ent, var_nextthink, get_gametime() + 0.01)
    set_entvar(tk_ent, var_fuser1, get_gametime() + 10.0)
    set_entvar(tk_ent, var_scale, 5.0)
    set_entvar(tk_ent, var_iuser1, 0)
    set_entvar(tk_ent, var_owner, id)
    
    engfunc(EngFunc_SetModel,tk_ent, "sprites/blueflare1.spr")
    engfunc(EngFunc_SetSize,tk_ent,Float:{-25.0, -25.0, -10.0},Float:{25.0, 25.0, 10.0})
    SetTouch(tk_ent,"tk_Touch")
    SetThink(tk_ent,"tk_Think")
    set_prop_int_array_length(tk_ent , "Touched" , 1)
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
    write_byte(TE_BEAMFOLLOW) // Temporary entity ID
    write_short(tk_ent) // Entity
    write_short(sTrail) // Sprite index
    write_byte(10) // Life
    write_byte(3) // Line width
    write_byte(255) // Red
    write_byte(255) // Green
    write_byte(255) // Blue
    write_byte(255) // Alpha
    message_end() 
    return tk_ent
}
stock CreateBoomThink(id){
        new ent = rg_create_entity("info_target")
        if(is_nullent(ent))
            return NULLENT
        set_entvar(ent , var_movetype , MOVETYPE_NONE)
        set_entvar(ent , var_solid , SOLID_NOT)
        set_entvar(ent , var_owner , id)
        set_entvar(ent , var_classname , "SiDaLin_SkillThink_ent")
        set_entvar(ent , var_nextthink , get_gametime() + 0.1)
        SetThink(ent , "SkillCreateBoomThink")
        return ent
}

stock SkillCreateBoomThink(ent){
        new master = get_entvar(ent , var_owner)
        if(!is_user_alive(master) || !is_user_connected(master)){
            SetThink(ent , "")
            rg_remove_entity(ent)
        }
        new target = -1
        while((target = rg_find_ent_by_class(target , "hostage_entity" , true)) > 0){
            if(is_nullent(target))continue
            if(KrGetFakeTeam(target) == CS_TEAM_T) continue
            if(get_entvar(target , var_deadflag) == DEAD_DEAD)continue

            new Boom = CreateTankBoom(target , target)
            set_entvar(Boom , var_owner , master)
        }
        set_entvar(ent , var_nextthink , get_gametime() + 2.0)
}

stock CreateTankBoom(ent , target){
    new tk_ent = rg_create_entity("info_target")
    if(!tk_ent)
        return 0
    new Float:org[3], Float:tarorg[3]
    get_entvar(ent,var_origin,org)
    get_entvar(target,var_origin,tarorg)
    org[2] += 300.0
    new Float:vec[3]
    xs_vec_sub(tarorg, org, vec)
    xs_vec_normalize(vec, vec)
    xs_vec_mul_scalar(vec, 50.0, vec)
    xs_vec_add(org, vec, org)
    xs_vec_mul_scalar(vec, 12.0, vec)
    set_entvar(tk_ent,var_movetype, MOVETYPE_NOCLIP)
    set_entvar(tk_ent , var_solid, SOLID_TRIGGER)
    set_entvar(tk_ent,var_origin,org)
    set_entvar(tk_ent,var_velocity,vec)
    set_entvar(tk_ent, var_classname,"tk_boom")
    set_entvar(tk_ent, var_rendermode,kRenderTransAdd)
    set_entvar(tk_ent, var_renderamt,255.0)
    set_entvar(tk_ent , var_nextthink , get_gametime() + 0.01)
    set_entvar(tk_ent , var_fuser1 , get_gametime() + 10.0)
    
    engfunc(EngFunc_SetModel,tk_ent, "sprites/blueflare1.spr")
    engfunc(EngFunc_SetSize,tk_ent,Float:{-1.0, -1.0, -1.0},Float:{1.0, 1.0, 1.0})
    SetTouch(tk_ent,"tk_Touch")
    SetThink(tk_ent,"tk_Think")
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
    write_byte(TE_BEAMFOLLOW) // Temporary entity ID
    write_short(tk_ent) // Entity
    write_short(sTrail) // Sprite index
    write_byte(10) // Life
    write_byte(3) // Line width
    write_byte(255) // Red
    write_byte(255) // Green
    write_byte(255) // Blue
    write_byte(255) // Alpha
    message_end() 
    return tk_ent
}

public tk_Think(this){
    new Float:fOrigin[3]
    get_entvar(this, var_origin, fOrigin)
    new master = get_entvar(this , var_owner)
    if(get_entvar(master , var_deadflag) == DEAD_DEAD){
        rg_remove_entity(this)
        return
    }
}

stock lerp(ent , target){
    new Float:vel[3],Float:org[3],Float:targetorg[3],Float:dir[3]
    get_entvar(ent, var_velocity, vel)
    get_entvar(ent, var_origin, org)
    get_entvar(target, var_origin, targetorg)
    targetorg[2] += 30.0
    xs_vec_sub(targetorg, org, dir)
    xs_vec_normalize(dir, dir)
    // 当前速度转为单位方向
    new Float:curdir[3]
    xs_vec_normalize(vel, curdir)
    new Float:newdir[3]
    xs_vec_lerp(curdir, dir, 1.0, newdir)
    xs_vec_normalize(newdir, newdir)
    new Float:new_angles[3]
    vector_to_angle(newdir, new_angles)   // 把方向向量转换成角度 (pitch, yaw, roll)
    set_entvar(ent, var_angles, new_angles)
    
    new Float:new_vel[3]
    xs_vec_mul_scalar(newdir, 1000.0, new_vel)
    set_entvar(ent, var_velocity, new_vel)
    set_entvar(ent, var_nextthink, get_gametime() + 0.15)
}

public tk_Touch(this , other){
    new master = get_entvar(this , var_owner)
    if(get_entvar(master , var_deadflag) == DEAD_DEAD){
        rg_remove_entity(this)
        return
    }
    if(get_entvar(other , var_solid) == SOLID_BSP || FClassnameIs(other , "worldspawn")){
        TkBoom(this)
        return
	}
    new master_team = get_member(master , m_iTeam)
    if(ExecuteHam(Ham_IsPlayer , other) && get_member(other , m_iTeam) == master_team){
        return
    }
    if(GetIsNpc(other) && KrGetFakeTeam(other) == CsTeams:master_team){
        return
    }
    // if(IsTouched(this , other))
    //     return
    // new Length = get_prop_array_length(this , "Touched")
    // new Data[1]
    // Data[0] = other
    // insert_prop_int_array(this , "Touched" , Length , 1 , Data)

    // new Touched = get_entvar(this , var_iuser1)

    // if(Touched >= TouchMax){
    //     TkBoom(this)
    //     return
    // }

    // set_entvar(this , var_iuser1 , (Touched + 1))
    ExecuteHamB(Ham_TakeDamage , other , master , master , 180.0 , DMG_BULLET)
}

stock TkBoom(const TkEnt){
    new Float:org[3]
    new master = get_entvar(TkEnt , var_owner)
    get_entvar(TkEnt, var_origin, org)
    MakeBoom(org , 120)
    rg_dmg_radius(org , master , master , 2800.0 , 560.0 , CLASS_PLAYER , DMG_BULLET)
    rg_remove_entity(TkEnt)
}

stock IsTouched(this , pToucher){
    new Length = get_prop_array_length(this , "Touched")
    for(new i = 0 ; i < Length ; i++){
    	if(get_prop_int_array_elem(this , "Touched" , i) == pToucher)
    		return true
    }
    return false
}

stock MakeBoom(Float:iOrigin[3] , ScaleByte = 0){
    message_begin_f(MSG_BROADCAST, SVC_TEMPENTITY, iOrigin)
    write_byte(TE_EXPLOSION)
    write_coord_f(iOrigin[0])
    write_coord_f(iOrigin[1])
    write_coord_f(iOrigin[2])
    write_short(g_Explosion)
    write_byte(30)
    write_byte(ScaleByte != 0 ? ScaleByte : 15)
    write_byte(0)
    message_end()
}

stock xs_vec_lerp(const Float:a[3], const Float:b[3], Float:factor, Float:out[3]) {
    for (new i = 0; i < 3; i++) {
        out[i] = a[i] + (b[i] - a[i]) * factor
    }
}