#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <reapi>
#include <kr_core>
#include <xp_module>
#include <props>

public plugin_init(){
    register_plugin("武器积分倍率管理", "1.0", "Bing")
}

public plugin_natives(){
    register_native("GetWpnXpMul","native_GetWpnXpMul")
    register_native("SetWpnXpMul","native_SetWpnXpMul")
    register_native("GetPlayerMul","native_GetPlayerMul")
}

public native_GetWpnXpMul(id,nums){
    new wpn = get_param(1)
    if (!prop_exists(wpn, "xpmul"))
        return 1.0
    return get_prop_float(wpn , "xpmul")
}

public native_SetWpnXpMul(id, nums){
    new wpn = get_param(1)
    new Float:MulFloat = get_param_f(2)
    if(is_nullent(wpn))
        return
    set_prop_float(wpn , "xpmul" , MulFloat)
}

public native_GetPlayerMul(id, nums){
    new Playerid = get_param(1)
    new Float:RetMul
    if(!is_user_alive(Playerid) || !is_user_connected(Playerid))
        return 1.0
    for(new i = 0 ; i < 6 ; i++){
        new PlayerItem = get_member(Playerid , m_rgpPlayerItems , i)
        while (PlayerItem > 0){
            new Gun = PlayerItem
            new Float:MulFLoat = GetWpnXpMul(Gun)
            if(MulFLoat == 1.0){
                PlayerItem = get_member(PlayerItem , m_pNext)
                continue
            }
            RetMul += MulFLoat
            PlayerItem = get_member(PlayerItem , m_pNext)
        }
    }
    return RetMul < 1.0 ? 1.0 : RetMul
}
