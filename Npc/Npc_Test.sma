#include <kr_core>
#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <Npc_Manager>
#include <animation>

new Reg_Npcid , Moduleid

public plugin_init(){
    register_plugin("测试Npc行为" , "1.0" , "Bing")
    Reg_Npcid = NpcRegister(200.0 , Moduleid ,1000.0 , 0.2, 45.0, 0.0, 0, 6, 18, 24, 51, 3.0, 1.0 , NpcMode_Ranged)
    NpcSetNameAndLevel(Reg_Npcid , "士兵" , 1)
}

public plugin_precache(){
    Moduleid = precache_model("models/Bing_Kr_res/Kr_npcs/officer.mdl")
    precache_sound("weapons/mp5-1.wav")
}

public HandleAnimEvent(const id, event, const event_option[], len_option){
    server_print("npcTest : id %d event %d" , id , event)
}

public NpcOnCreate(Npcid ,Regid){
    if(Regid == Reg_Npcid){
        SetBodyGroup(Npcid , 2  , 5)
    }
}

public NpcDoAttack(Npcid , Target){
    if(get_prop_int(Npcid , var_npcid) != Reg_Npcid){
        return
    }
    new Float:fOrigin[3] , Float:TarOrigin[3]
    get_entvar(Npcid , var_origin , fOrigin)
    get_entvar(Target , var_origin , TarOrigin)
    fOrigin[2] += 30.0
    TarOrigin[2] += 30.0
    MakeBullets(fOrigin , TarOrigin)
    NpcTakeDamge(Npcid , Target )
    emit_sound(Npcid, CHAN_WEAPON, "weapons/mp5-1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
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

stock CreateLove(Npcid){

}