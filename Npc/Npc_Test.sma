#include <kr_core>
#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <Npc_Manager>
#include <animation>

new Npcid , Moduleid

public plugin_init(){
    register_plugin("测试Npc行为" , "1.0" , "Bing")
    Npcid = NpcRegister(200.0 , Moduleid ,500.0 , 0.5, 30.0, 0.0, 0, 6, 18, 24, 51, 3.0, 1.0)
    NpcSetNameAndLevel(Npcid , "管家" , 0)
}

public plugin_precache(){
    Moduleid = precache_model("models/Kr_npcs/officer.mdl")
}

public NpcOnCreate(Npcid){
    SetBodyGroup(Npcid , 2  , 5)
}