#include <amxmodx>
#include <engine>
#include <reapi>
#include <kr_core>

#define PlayAllCost 5.0

enum SoundsData{
    _:SoundPath[64],
    _:SoundName[64]
}

new Mp3Sounds[][SoundsData] = {
    {"Bing_Kr_Sound/Xiangpi.mp3", "天真的橡皮DJ"},
    {"Bing_Kr_Sound/yinghuacai.mp3", "樱华彩"},
    {"Bing_Kr_Sound/RunFree.mp3" , "Deep Chills-Run Free"},
    {"Bing_Kr_Sound/xytl.mp3" , "等下一个天亮"},
    {"Bing_Kr_Sound/Thatgirl.mp3" , "That Girl"},
    {"Bing_Kr_Sound/恋人.mp3" , "恋人-李荣浩"},
    {"Bing_Kr_Sound/黑色幽默.mp3" , "黑色幽默-周杰伦"},
    {"Bing_Kr_Sound/Centuries.mp3" , "Centuries"},
    {"Bing_Kr_Sound/yoasobi.mp3" , "アイドル"},
    {"Bing_Kr_Sound/sandstorm.mp3" , "sandstorm变奏"},
    {"Bing_Kr_Sound/goahead.mp3" , "イケナイGO AHEAD"},
    {"Bing_Kr_Sound/印度神曲.mp3" , "咖喱神曲"},
    {"Bing_Kr_Sound/明天消失.mp3" , "少女分形-即使明日世界消失"},
    {"Bing_Kr_Sound/Thanks.mp3" , "ありがとう-KOKIA"},
    {"Bing_Kr_Sound/Eutopia.mp3" , "法元明菜 - Eutopia"},
    {"Bing_Kr_Sound/Roselia-FIREBIRD.mp3" , "Roselia-FIREBIRD"},
}

new SelSound[33], Array:FindSoundArray ,Trie:FindSoundMap

public plugin_init(){
    register_plugin("点歌系统" , "1.0" , "Bing")

    register_clcmd("say buysound" , "CreateSoundMenu")
    register_clcmd("buysound" , "CreateSoundMenu")
    register_clcmd("say" , "FindSound")
    FindSoundArray = ArrayCreate(64)
    FindSoundMap = TrieCreate()
}

public plugin_precache(){
    for(new i = 0 ; i < sizeof Mp3Sounds ; i++){
        UTIL_Precache_Sound(Mp3Sounds[i][SoundPath])
    }
}

public client_disconnected(id){
    SelSound[id] = 0
}

public FindSound(id){
    new argc = read_argc()

    if(argc <= 1){
        m_print_color(id , "错误的格式")
        return
    }

    new param[50]

    read_argv(1 , param , charsmax(param))
    if(strfind(param , "*find" , true) == -1)
        return

    replace_string(param , charsmax(param) , " " , "")
    replace_string(param , charsmax(param) , "*find" , "")

    ArrayClear(FindSoundArray)
    TrieClear(FindSoundMap)

    for(new i = 0 ; i < sizeof Mp3Sounds ; i++){
        if(strfind(Mp3Sounds[i][SoundName], param , true) != -1){
            ArrayPushString(FindSoundArray , Mp3Sounds[i][SoundName])
            TrieSetCell(FindSoundMap , Mp3Sounds[i][SoundName] , i)
        }
    }

    new FindCount = ArraySize(FindSoundArray)
    if(FindCount <= 0){
        m_print_color(id , "没找到你想要的歌曲")
        return
    }

    new menu = menu_create("找到的歌曲" , "FindSoundHandle")
    for(new i = 0 ; i < FindCount ; i++){
        new Name[64] , info[10] , Key
        ArrayGetString(FindSoundArray , i , Name , charsmax(Name))
        TrieGetCell(FindSoundMap , Name , Key)
        num_to_str(Key , info , charsmax(info))
        menu_additem(menu , Name , info)
        log_amx("FindKey%s" , info)
    }
    menu_display(id , menu)
}

public FindSoundHandle(id , menu , item){
    if(item == MENU_EXIT){
        menu_destroy(menu)
        return
    }
    new acc , infos[32] , names[64]
    menu_item_getinfo(menu , item , acc , infos ,charsmax(infos) , names , charsmax(names))
    new SecKey = str_to_num(infos)
    if(SecKey > sizeof Mp3Sounds){
        log_amx("歌曲Key溢出")
        menu_destroy(menu)
        return
    }
    SelSound[id] = SecKey
    CreatePlayMenu(id)
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
    SubAmmoPak(id , 5.0)
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