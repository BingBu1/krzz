#include <kr_core>
#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <cstrike>
#include <Npc_Manager>
#include <animation>

new Reg_Npcid , Moduleid

public plugin_init(){
    register_plugin("雪域BOSS" , "1.0" , "Bing")
    Reg_Npcid = NpcRegister(500.0 , Moduleid ,100.0 , 1.8, 0.0, 0.0, 1, 3, 2, 7, 28)
    
    NpcSetNameAndLevel(Reg_Npcid , "秘密" , 500)
    // SetNpcHasSkill(Reg_Npcid)
}

public plugin_precache(){
    // Moduleid = precache_model("models/Kr_npcs/officer.mdl")
    Moduleid = precache_model("models/Kr_npcs/envy_zavist.mdl")
}

public NpcOnCreate(Npcid , Regid){
    if(Reg_Npcid == Regid){
        SetBodyGroup(Npcid , 2  , 1)
    }
}

public NpcDoAttack(Npcid , Target){
    if(get_prop_int(Npcid , var_npcid) != Reg_Npcid){
        return
    }
    new Float:Health = get_entvar(Npcid , var_health)
    new master = get_prop_int(Npcid , var_master)
    new Float:fOrigin[3]
    get_entvar(Npcid , var_origin , fOrigin)
    NpcRadiusDamge(fOrigin , master, Npcid ,  random_float(300.0 , 600.0) , 200.0 , DMG_GENERIC)
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

