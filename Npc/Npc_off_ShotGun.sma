#include <kr_core>
#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <Npc_Manager>
#include <animation>

new Reg_Npcid , Moduleid

public plugin_init(){
    register_plugin("Npc士兵" , "1.0" , "Bing")
    Reg_Npcid = NpcRegister(200.0 , Moduleid , 400.0 , 0.8, 200.0, 0.0, 0, 6, 18, 23, 51, 3.0, 3.5 , NpcMode_Ranged)
    NpcSetNameAndLevel(Reg_Npcid , "士兵-ShotGun" , 50)
}

public plugin_precache(){
    Moduleid = precache_model("models/Bing_Kr_res/Kr_npcs/officer.mdl")
    UTIL_Precache_Sound("weapons/sbarrel1.wav")
    UTIL_Precache_Sound("weapons/sshell1.wav")
}

public HandleAnimEvent(const id, event, const event_option[], len_option){
    server_print("npcTest : id %d event %d" , id , event)
}

public NpcOnCreate(Npcid ,Regid){
    if(Regid == Reg_Npcid){
        SetBodyGroup(Npcid , 2  , 3)
    }
}

public NpcDoAttack(Npcid , Target){
    if(get_prop_int(Npcid , var_npcid) != Reg_Npcid){
        return
    }
    new Float:fOrigin[3] , Float:TarOrigin[3] , Float:angles[3], Float:Dir[3]
    get_entvar(Npcid , var_origin , fOrigin)
    get_entvar(Target , var_origin , TarOrigin)
    get_entvar(Npcid , var_v_angle , angles)
    fOrigin[2] += 30.0
    TarOrigin[2] += 30.0
    new master = get_prop_int(Npcid , var_master)
    new Float:Damage = NpcGetRegDamage(Npcid)

    angle_vector(angles , ANGLEVECTOR_FORWARD , Dir)
    MakeShotBullets(fOrigin , Dir , 7)
    NpcRadiusDamge(TarOrigin , master , Npcid , Damage , 30.0)
    UTIL_EmitSound_ByCmd2(Npcid , "weapons/sbarrel1.wav" , 550.0)
}

public NpcOnSkill(Npcid , target){
    set_prop_float(Npcid , var_skillcd , get_gametime() + 5.0)
}

stock MakeBullets(Float:Start[3] , Float:End[3]){
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
    write_byte(TE_TRACER)
    write_coord_f(Start[0])
    write_coord_f(Start[1])
    write_coord_f(Start[2])
    write_coord_f(End[0])
    write_coord_f(End[1])
    write_coord_f(End[2])
    message_end()
}

stock MakeShotBullets(Float:Start[3] , Float:Dir[3] , count , speed = 2048){
    message_begin_f(MSG_BROADCAST , SVC_TEMPENTITY)
    write_byte(TE_STREAK_SPLASH)
    write_coord_f(Start[0])
    write_coord_f(Start[1])
    write_coord_f(Start[2])
    write_coord_f(Dir[0])
    write_coord_f(Dir[1])
    write_coord_f(Dir[2])
    write_byte(4)
    write_short(count)
    write_short(speed)
    write_short(128)
    message_end()
}