#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <kr_core>
#include <reapi>
#include <xp_module>



public plugin_init(){
    register_plugin("难度菜单", "1.0", "Bing")

    register_clcmd("say /lv", "CreateMenu")

    create_cvar("Kr_MaxLv" , "1300" , .min_val = 100.0)
}

public CreateMenu(id){
    new Menus = menu_create("难度菜单","LvHandle")
    menu_additem(Menus,"增加难度1\r(免费)","0")
    menu_additem(Menus,"增加难度10\r(免费)","1")
    menu_additem(Menus,"重置当前难度\r(免费)","2")

    menu_addblank2(Menus)

    menu_additem(Menus,"增加难度1\r(20大洋)","3")
    menu_additem(Menus,"增加难度10\r(200大洋)","4")
    menu_additem(Menus,"增加难度100\r(1800大洋)","5")

    menu_display(id, Menus)
}

public LvHandle(id,menu,item){
    if(item == MENU_EXIT){
        menu_destroy(menu)
        return
    }
    new acc,info[10],name[50]
    menu_item_getinfo(menu, item, acc, info, 9, name, 49)
    new infonum = str_to_num(info)
    switch(infonum){
        case 0 :{
            FreeAddLv(id , 1)
        }
        case 1:{
            FreeAddLv(id , 10)
        }
        case 2 :{
            ReLv(id)
        }
        case 3 :{
            AddLvByAmmo(id,20.0,1)
        }
        case 4 :{
            AddLvByAmmo(id,200.0,10)
        }
        case 5 :{
            AddLvByAmmo(id,1800.0,100)
        }
    }
    CreateMenu(id)
    menu_destroy(menu)
}

public FreeAddLv(id, add){
    new const Max_Free = 50
    new lv =  Getleavel()
    new addval = lv + add
    if(addval > Max_Free && lv < Max_Free){
        Setleavel(Max_Free)
        return
    }else if(addval >= Max_Free && lv >= Max_Free){
        m_print_color(id, "!g[冰布提醒] 免费难度最多升级到%d您超过了" , Max_Free)
        return
    }
    Setleavel(lv + add)
    new username[32]
    get_user_name(id, username, 31)
    m_print_color(id, "!g[冰布提醒] !y%s将当前难度提升了!g%d!y等级(%d当前等级)",username, add,Getleavel())
}
public ReLv(id){
    new playernum
    new maxplayer = get_maxplayers()
    for(new i = 0 ; i < maxplayer; i++){
        if(is_user_connected(i) && !is_user_bot(i) && is_entity(i)){
            playernum++
        }
    }
    if(playernum == 1){
        Setleavel(0)
        return
    }
    m_print_color(id, "!g[冰布提醒] !y重置难度只有您一人时才可以")
}

public AddLvByAmmo(id, Float:NeedAmmo, AddLv){
    new Float:Ammo = GetAmmoPak(id)
    if(NeedAmmo > Ammo){
        m_print_color(id, "!g[冰布提醒] !y您的大洋不足")
        return
    }
    new lv = Getleavel()
    new setlv = lv + AddLv
    new MaxLv = get_cvar_num("Kr_MaxLv")
    static username[32]
    get_user_name(id, username, 31)

    if(setlv > MaxLv && lv < MaxLv){
        new Float:Rt_Ammo = NeedAmmo / float(AddLv)
        Rt_Ammo *= float(setlv - MaxLv)
        NeedAmmo -= Rt_Ammo
        setlv = MaxLv
        SetAmmo(id, Ammo - NeedAmmo)
        Setleavel(setlv)
        m_print_color(id, "!g[冰布提醒] !t难度最大支持1300,已返回多余%f弹药袋" , Rt_Ammo)
        m_print_color(0, "!g[冰布提醒] !y%s将当前难度提升了!g%d!y等级(%d当前等级)",username, AddLv,Getleavel())
        return
    }else if (setlv > MaxLv && lv >= MaxLv){
        m_print_color(id, "!g[冰布提醒] !t难度最大支持%d" , MaxLv)
        return
    }
    SetAmmo(id, Ammo - NeedAmmo)
    Setleavel(setlv)
    m_print_color(0, "!g[冰布提醒] !y%s将当前难度提升了!g%d!y等级(%d当前等级)",username, AddLv,Getleavel())
}
