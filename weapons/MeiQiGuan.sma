#include <amxmodx>
#include <reapi>
#include <hamsandwich>
#include <engine>
#include <animation>
#include <kr_core>

#define Gas "weapon_hegrenade"

new GasModels[][]={
    "models/w_gas.mdl",
    "models/v_gas.mdl"
}

new GasCount[33] , HasGas[33]

new BoomSpr , wpnid

#define cost 15.0

public plugin_init(){
    new pl_id = register_plugin("煤气罐" , "1.0" , "Bing")

    RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy , "m_DefaultDeploy")
    RegisterHookChain(RG_CBasePlayer_Spawn,"PlayerSpawn_Post",true)
    RegisterHookChain(RG_ThrowHeGrenade , "ShootTimed2" , true)
    RegisterHookChain(RG_CGrenade_ExplodeHeGrenade , "ExplodeHeGrenade")

    RegisterHam(Ham_Weapon_WeaponIdle , Gas , "GasIdel")

    register_clcmd("give_gas" , "Give_Gas")
    BulidCrashGunWeapon("煤气罐" , GasModels[0] , "Give_Gas" , pl_id)
    BulidWeaponMenu("煤气罐" , cost)
}

public ItemSel_Post(id , items , Float:cont){
    if(items != wpnid)
        return
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
    Give_Gas(id)
}

public plugin_precache(){
    for(new i = 0 ; i < sizeof GasModels ; i++){
        precache_model(GasModels[i])
    }
    BoomSpr = precache_model("sprites/ef_sbmine_explosion.spr")
}

public plugin_natives(){
    register_native("GiveGas", "native_GiveGas")
}

public client_disconnected(id){
    RemoveGas(id)
}

public client_putinserver(id){
    RemoveGas(id)
}

public PlayerSpawn_Post(this){
    RemoveGas(this)
}

public native_GiveGas(plid , nums){
    new id = get_param(1)
    if(!is_user_alive(id) || !is_valid_ent(id))
        return

}

public Give_Gas(id){
    if(!is_user_alive(id) || !is_valid_ent(id))
        return
    GasCount[id]++
    HasGas[id] = true
    new hegrenade_num = get_member(id , m_rgAmmo , 12)
    if(hegrenade_num == 0){
        rg_give_item(id, "weapon_hegrenade")
    }else{
        set_member(id ,m_rgAmmo , hegrenade_num + 1 , 12)
    }
    engclient_cmd(id, "weapon_hegrenade")
}

public m_DefaultDeploy(const this, szViewModel[], szWeaponModel[], iAnim, szAnimExt[], skiplocal){
    new any:i_id = rg_get_iteminfo(this , ItemInfo_iId)
    new player = get_member(this , m_pPlayer)
    if(!HasGas[player] || !GasCount[player] || i_id != WEAPON_HEGRENADE)
        return HC_CONTINUE
    SetHookChainArg(2 , ATYPE_STRING ,GasModels[1])
    SetHookChainArg(3 , ATYPE_STRING ,GasModels[0])
    return HC_CONTINUE
} 

public GasIdel(this){
    new player = get_member(this , m_pPlayer)
    if(!HasGas[player] || !GasCount[player]){
        set_entvar(player , var_viewmodel , "models/v_hegrenade.mdl")
        RemoveGas(player)
        return HAM_IGNORED
    }
    set_entvar(player , var_viewmodel , GasModels[1])
    set_entvar(player , var_weaponmodel , GasModels[0])
    if(GasCount[player] <= 0){
        RemoveGas(player)
    }
    return HAM_IGNORED   
}

public ShootTimed2(const index, Float:vecStart[3], Float:vecVelocity[3], Float:time, const team, const usEvent){
    if(!HasGas[index] || !GasCount[index]){
        return HC_CONTINUE
    }
    new pGrenade = GetHookChainReturn(ATYPE_INTEGER)
    entity_set_model(pGrenade , GasModels[0])
    set_entvar(pGrenade , var_iuser1 , 1)
    GasCount[index]--
    return HC_CONTINUE
}

public ExplodeHeGrenade(const this, tracehandle, const bitsDamageType){
    // new index = get_entvar(this , var_owner)
    if(!get_entvar(this , var_iuser1)){
        return HC_CONTINUE
    }
    SendGasEffs(this)
    GasDamge(this)
    rg_remove_entity(this)
    return HC_SUPERCEDE
}


stock RemoveGas(id){
    GasCount[id] = 0
    HasGas[id] = false
}

stock SendGasEffs(GasEnt){
    new Float:Origin[3]
    get_entvar(GasEnt , var_origin , Origin)

    message_begin_f(MSG_PAS , SVC_TEMPENTITY , Origin)
    write_byte(TE_EXPLOSION)
    write_coord_f(Origin[0])
    write_coord_f(Origin[1])
    write_coord_f(Origin[2] + 20.0)
    write_short(BoomSpr)
    write_byte(200)
    write_byte(10)
    write_byte(TE_EXPLFLAG_NONE)
    message_end()
}

stock GasDamge(GasEnt){
    new Float:Origin[3],master
    get_entvar(GasEnt , var_origin , Origin)
    master = get_entvar(GasEnt , var_owner)
    rg_dmg_radius(Origin , master,master, 10000.0 , 1000.0 , CLASS_PLAYER , DMG_BULLET)
}