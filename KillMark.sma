#include <amxmodx>
#include <amxmisc>
#include <kr_core>
#include <bmod>

new KillMark[][] = {
    "sprites/KillMark/killmark_25s2TR.spr"
}

new KillSpr_1

public plugin_init(){
    register_plugin("击杀特效" , "1.0" , "冰桑")
    register_clcmd("TestEvent" , "Test")
}

public Test(id){

}

public plugin_precache(){
    KillSpr_1 = precache_model(KillMark[0])
}

public NPC_Killed(this , killer){
    if(is_user_admin(killer)){
        CreateKillSpr(KillSpr_1 , this)
    }
}


public CreateKillSpr(sprid , DeadEnt){
    new Float:fOrigin[3] , iOrigin[3]
    get_entvar(DeadEnt , var_origin , fOrigin)
    iOrigin[0] = floatround(fOrigin[0])
    iOrigin[1] = floatround(fOrigin[1])
    iOrigin[2] = floatround(fOrigin[2])
    message_begin(0 , SVC_TEMPENTITY)
    write_byte(TE_SPRITE)
    write_coord(iOrigin[0])
    write_coord(iOrigin[1])
    write_coord(iOrigin[2] + 35)
    write_short(sprid)
    write_byte(1) // scale
    write_byte(200) // alpha
    message_end()
}