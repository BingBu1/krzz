#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <reapi>
#include <kr_core>
new Float:g_PlayerCmdTime[33];
new Float:g_PlayerUpdateRate[33];
new Float:Hacking[33]
new playerhack[33]
public plugin_init(){
    register_plugin("反加速作弊" , "1.0" , "Bing")
    register_forward(FM_CmdStart, "fw_CmdStart")
    register_event("HLTV", "event_roundstart", "a", "1=0", "2=0")
}

public event_roundstart(){
    new maxplayer = get_maxplayers()
    for(new i = 0 ; i < maxplayer; i++){
        if(playerhack[i] == 6){
            playerhack[i] == 5
        }
    }
}

public plugin_precache(){
    precache_model("models/player/chick/chick.mdl")
}

public client_putinserver(id){
    g_PlayerCmdTime[id] = 0.0
    g_PlayerUpdateRate[id] = 0.0
    Hacking[id] = 0.0
    playerhack[id] = 0
}

public client_disconnected(id){
    g_PlayerCmdTime[id] = 0.0
    g_PlayerUpdateRate[id] = 0.0
    Hacking[id] = 0.0
    playerhack[id] = 0
}

public fw_CmdStart(id, uc_handle, seed){
    new Float:curtime = get_gametime()
    if(curtime > g_PlayerCmdTime[id]){
        g_PlayerUpdateRate[id] = curtime - g_PlayerCmdTime[id] //加速卡顿会导致更新时间变长
        g_PlayerCmdTime[id] = curtime;
    }

    if(g_PlayerUpdateRate[id] > 0.4 && playerhack[id] < 5){
        playerhack[id]++
    }
    if(playerhack[id] == 5){
        playerhack[id] = 6
        new playername[32]
        get_user_name(id , playername , 31)
        rg_remove_all_items(id)
        set_view(id, CAMERA_3RDPERSON)
        rg_set_user_model(id, "chick")
        client_print(id, print_chat, "你被检测到加速作弊，惩罚成为小鸡。")
        m_print_color(id , "!g[提示]%s因作弊已被惩罚变为小鸡。",playername)
    }else if(playerhack[id] == 6){
        rg_remove_all_items(id)
        rg_set_user_model(id, "chick")
    }
}

public Clear(id){
    Hacking[id] = 0.0
}
