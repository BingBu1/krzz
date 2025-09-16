#include <amxmodx>
#include <PlayerSkill>
#include <reapi>
#include <engine>
#include <fakemeta>
#include <kr_core>
#include <hamsandwich>

new JinZhengEnSkillSpr[][]= {
    "models/Kr_Skill/ef_gatlingex_fireball.spr",
    "models/Kr_Skill/ef_gatlingex_explosion.spr"
}

public plugin_init(){
    new plid = register_plugin("角色技能-金正恩" , "1.0" , "Bing")
    RegPlayerSkill(plid , "SunCall" , "jinzhengen" , 80.0)
}

public plugin_precache(){
    for(new i = 0 ; i < sizeof JinZhengEnSkillSpr ; i++){
        precache_model(JinZhengEnSkillSpr[i])
    }
    UTIL_Precache_Sound("kr_sound/gatlingex-2_exp.wav")
}

// 金正恩太阳技能
public SunCall(id){
    new username[32]
    new ent = rg_create_entity("info_target")
    if(is_nullent(ent))
        return
    new Float:fOrigin[3]
    get_entvar(id , var_origin , fOrigin)
    fOrigin[2] += 180.0
    get_user_name(id , username , charsmax(username))
    set_entvar(ent , var_classname , "Sun")
    set_entvar(ent , var_origin , fOrigin)
    set_entvar(ent, var_rendermode, kRenderTransAdd)
    set_entvar(ent, var_renderamt, 255.0)
    set_entvar(ent , var_fuser1 , get_gametime() + 20.0)
    set_entvar(ent , var_scale  , 3.0)
    set_entvar(ent , var_owner , id)
    SetThink(ent , "SunThink")
    set_entvar(ent , var_nextthink , get_gametime() + 0.1)
    engfunc(EngFunc_SetModel , ent , JinZhengEnSkillSpr[0])
    m_print_color(0 , "!g[冰布提示]!t%s释放了金正恩技能：太阳！" , username)
}

public SunThink(ent){
    static Float:flFrame;
    new Float:GameTime = get_gametime()
    new bool:isDeadSun = get_entvar(ent , var_iuser1)
    if(isDeadSun == false){
        get_entvar(ent, var_frame, flFrame);
	    flFrame = (flFrame >= 29.0) ? 0.0 : flFrame + 1.0;
	    set_entvar(ent, var_frame, flFrame);
    }
    
    if(GameTime > get_entvar(ent ,var_fuser1) && isDeadSun == false){
        engfunc(EngFunc_SetModel , ent , JinZhengEnSkillSpr[1])
        set_entvar(ent, var_frame, 0.0);
        set_entvar(ent , var_iuser1 , 1)
    }else if(isDeadSun == true){
        get_entvar(ent, var_frame, flFrame);
        if(flFrame == 0.0){
            UTIL_EmitSound_ByCmd(0 , "kr_sound/gatlingex-2_exp.wav")
        }
	    flFrame = flFrame + 1.0;
	    set_entvar(ent, var_frame, flFrame);
        if(flFrame  >= 39.0){
            rg_remove_entity(ent)
        }
    }
    set_entvar(ent , var_nextthink , GameTime + 0.033)
    new Float:FullThink = get_entvar(ent , var_fuser2)
    if(GameTime < FullThink || isDeadSun){
        return
    }
    set_entvar(ent , var_fuser2 , GameTime + 0.5)
    new getent = -1 , owner = get_entvar(ent , var_owner)
    while((getent = rg_find_ent_by_class(getent ,"hostage_entity" , true)) > 0){
        if(get_entvar(getent , var_deadflag) == DEAD_DEAD )continue
        if(KrGetFakeTeam(getent) == CS_TEAM_T) continue
        ExecuteHamB(Ham_TakeDamage , getent , owner , owner , 350.0 , 0)
    }
}