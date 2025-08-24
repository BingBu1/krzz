#include <amxmodx>
#include <fakemeta>
#include <cstrike>
#include <reapi>
#include <kr_core>

new PlayerSelWeapom[33]
new WeaponNames[][]={
    "weapon_m4a1",
    "weapon_ak47",
    "weapon_scout",
    "weapon_awp",
    "weapon_sg550",
    "weapon_g3sg1",
    "weapon_m3",
    "weapon_xm1014",
    "weapon_aug",
    "weapon_sg552",
    "weapon_m249"

}
new MenuWpnName[][]={
    "\rM4a1卡宾枪",
    "\rAk47突击步枪",
    "\rScout轻便狙击枪",
    "\rAwp狙击枪",
    "\rSg550连狙",
    "\rG3sg1连狙",
    "\rM3霰弹枪",
    "\rXm1014霰弹枪",
    "\rAug突击步枪",
    "\rSg552突击步枪",
    "\rM249机关枪"
}

public plugin_init(){
    register_plugin("抗日开局菜单", "1.0", "Bing")
    register_event("HLTV", "event_roundstart", "a", "1=0", "2=0")
    RegisterHookChain(RG_CBasePlayer_Spawn, "PlayerSpawn_Post", true)

    register_clcmd("say givewpn","spawnwpnmenu")
}

public event_roundstart(){
    arrayset(PlayerSelWeapom,0,sizeof PlayerSelWeapom)
}

public PlayerSpawn_Post(this){
    if(is_user_bot(this))
        return HC_CONTINUE
    if(!is_nullent(this) && is_user_alive(this)){
        OpenWeaponMenu(this)
    }
    return HC_CONTINUE
}

public spawnwpnmenu(id){
    if(PlayerSelWeapom[id]){
        client_print_color(id , print_chat ,"【^4冰桑提示】 ^1你已选择过武器无法再次打开菜单")
        return PLUGIN_HANDLED
    }
    OpenWeaponMenu(id)
    return PLUGIN_HANDLED
}

public OpenWeaponMenu(id){
    new WaeponMenu = menu_create("发放抗日装备", "WaeponHandle")
    new itemnum[5]
    for(new i = 0;i<sizeof MenuWpnName;i++){
        num_to_str(i,itemnum,charsmax(itemnum))
        menu_additem(WaeponMenu, MenuWpnName[i],itemnum)
    }
    menu_display(id,WaeponMenu)
}

public WaeponHandle(id,menu,item){
    if (item == MENU_EXIT || item < 0 || !is_user_alive(id)){
       menu_destroy(menu)
       return 0
    }
    
    new info[32], name[32], access
    menu_item_getinfo(menu,item,access,info,charsmax(info),name,charsmax(name))
    new infonum = str_to_num(info)
    if(infonum > sizeof(WeaponNames)){
        log_amx("武器选择超出最大值")
    }
    log_amx("Selinfonum %d",infonum)
    new wpn = rg_give_item(id, WeaponNames[infonum],GT_DROP_AND_REPLACE)
    if(is_entity(wpn)){
        PlayerSelWeapom[id] = true
        new wpnid = rg_get_weapon_info(WeaponNames[infonum],WI_ID)
        new maxammo = rg_get_iteminfo(wpn,ItemInfo_iMaxAmmo1)
        rg_set_user_bpammo(id,wpnid,maxammo * 3)
        rg_set_user_armor(id, 100, ARMOR_VESTHELM)
    }
    menu_destroy(menu)
    return 0
}
