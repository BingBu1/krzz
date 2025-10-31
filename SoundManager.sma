#include <amxmodx>
#include <engine>
#include <reapi>
#include <kr_core>

#define PlayAllCost 5.0

enum SoundsData{
    _:SoundPath[64],
    _:SoundName[32]
}

new Mp3Sounds[][SoundsData] = {
    {"Bing_Kr_Sound/Xiangpi.mp3", "天真的橡皮DJ"},
    {"Bing_Kr_Sound/yinghuacai.mp3", "樱华彩"},
    {"Bing_Kr_Sound/yoasobi.mp3" , "アイドル"},
}

new SelSound[33]

public plugin_init(){
    register_plugin("点歌系统" , "1.0" , "Bing")

    register_clcmd("say buysound" , "CreateSoundMenu")
    register_clcmd("buysound" , "CreateSoundMenu")
}

public plugin_precache(){
    for(new i = 0 ; i < sizeof Mp3Sounds ; i++){
        UTIL_Precache_Sound(Mp3Sounds[i][SoundPath])
    }
}

public client_disconnected(id){
    SelSound[id] = 0
}

public CreateSoundMenu(id){
    new menu = menu_create("点歌系统_歌曲菜单" , "OnSoundHandle")
    for(new i = 0 ; i < sizeof Mp3Sounds ; i++){
        menu_additem(menu , Mp3Sounds[i][SoundName])
    }
    menu_display(id , menu)
}

CreatePlayMenu(id){
    new PlayAllText[32]
    formatex(PlayAllText , charsmax(PlayAllText) , "大伙都听(%d大洋)" , floatround(PlayAllCost))
    new menu = menu_create("怎么放呢" , "OnPlaySound")
    menu_additem(menu , "给我自己放")
    menu_additem(menu , PlayAllText)
    menu_additem(menu , "停止播放")
    menu_display(id , menu)
}

public OnSoundHandle(id , menu , item){
    if(item == MENU_EXIT || !is_user_connected(id)){
        menu_destroy(menu)
        return
    }
    SelSound[id] = item
    CreatePlayMenu(id)
    menu_destroy(menu)
    return
}

public OnPlaySound(id , menu , item){
    if(item == MENU_EXIT || !is_user_connected(id)){
        menu_destroy(menu)
        return
    }
    switch(item){
        case 0 : PlayForMe(id)
        case 1 : PlayForAll(id)
        case 2 : Mp3Stop(id)
    }
    menu_destroy(menu)
    return
}

public PlayForMe(id){
    new Seled = SelSound[id]
    Mp3Play(id , Mp3Sounds[Seled][SoundPath])
}

public PlayForAll(id){
    new CanBuy = false
    #if defined Usedecimal
        CanBuy = Dec_cmp(id , PlayAllCost , ">=")
    #else
        new Float:NowAmmo = GetAmmoPak(id)
        CanBuy = (NowAmmo >= PlayAllCost)
    #endif
    if(!CanBuy){
        m_print_color(id , "!g[冰布提示]你的大洋不足")
        return
    }
    new Seled = SelSound[id]
    for(new i = 1 ; i < MaxClients ; i++){
        if(!is_user_connected(i))
            continue
        Mp3Play(i , Mp3Sounds[Seled][SoundPath])
    }
    new name[32]
    get_user_name(id , name , charsmax(name))
    m_print_color(0 , "!g[冰布提示]!t%s!y给大伙点了一首!t%s" , name , Mp3Sounds[Seled][SoundName])
}

stock ChangeMp3Vol(id , Float:vol){
    client_cmd(id , "MP3Volume %.0f" ,vol)
}

stock Mp3Play(id , Sound[]){
    client_cmd(id , "mp3 play sound/%s" , Sound)
    ChangeMp3Vol(id , 1.0)
}

stock Mp3Stop(id){
    client_cmd(id , "mp3 stop")
}