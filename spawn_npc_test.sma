#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <cstrike>
#include <fakemeta>
#include <swnpc>
#include <newmenus>
#include <reapi>
#include <xs>
#include <Jap_Npc>
#include <props>
#include <json>

#define AMXX_VERSION_STR "1.9"

#define Max_judian 8

#define Tostr(%0) #%0

new NpcMenu;

new laserbeam;

new CurrentBulidWall[33] , building[33]

new Stack:Lastwall,Stack:LastNpc

new judian_wall = 2 ,npcbody = 1, npc_bulidlistnum = 10

new const XiaoRiBen[][]={
    "models/rainych/krzz/Japanese4.mdl",
    "models/rainych/krzz/wall/kangri_wall.mdl",
    "models/rainych/krzz/tank.mdl"
}

new PlayerModule[][]={
    "models/player/vip/vip.mdl"
}

new SpawnPonitNum[8]

new LastNpcmenus

enum swn_MenuId{
    swn_Cam3 = 0,
    swn_Cam1,
    swn_Swapn_Baga1,
    swm_Swapn_Baga2,
    swn_Swapn_TestWall,
    swn_Swapn_Npc,
    swn_Save_Wall,
    swn_LoadTest
};

public plugin_init(){
    register_plugin("npcTest", AMXX_VERSION_STR, "Bing")
    NpcMenu = menu_create("Npc生成Test Bing","MenuHander")
    register_clcmd("use", "OnMenuShow")

    register_forward(FM_PlayerPreThink, "on_PreThink")
    Lastwall = CreateStack()
    LastNpc = CreateStack()
}
public plugin_end(){
    DestroyStack(Lastwall)
    DestroyStack(LastNpc)
    menu_destroy(NpcMenu)
}

public plugin_precache(){
    for(new i =0; i < sizeof XiaoRiBen;i++){
        precache_model(XiaoRiBen[i])
    }
    for(new i =0; i < sizeof PlayerModule;i++){
        precache_model(PlayerModule[i])
    }
    
    laserbeam = precache_model("sprites/laserbeam.spr")
}

public plugin_cfg(){
    CreateSwaponMenu()
    CreateWallMenu()
    CreateNpcMenu()
}

public CreateSwaponMenu(){
    menu_additem(NpcMenu,"第三人称","0")
    menu_additem(NpcMenu,"第一人称","1")

    menu_additem(NpcMenu,"生成日本暴民","2")
    menu_additem(NpcMenu,"生成日本Type2","3")
    menu_additem(NpcMenu,"创建抗日Wall","4")
    menu_additem(NpcMenu,"日本Npc生成点放置","5")

    menu_additem(NpcMenu, "保存当前存储设置","6")
    menu_additem(NpcMenu, "加载测试","7")
    menu_setprop(NpcMenu,MPROP_EXITNAME,"退出")
    menu_setprop(NpcMenu,MPROP_NEXTNAME,"下一页")
}

public CreateWallMenu(){
    new judian[32]
    new WallMenu = menu_create("墙体测试" , "WallHandle")


    menu_additem(WallMenu , "建造")
    menu_additem(WallMenu , "旋转")
    menu_additem(WallMenu , "切换body")
    formatex(judian,charsmax(judian),"设置为%i据点删除墙体",judian_wall)
    menu_additem(WallMenu , judian)
    menu_additem(WallMenu , "切换据点墙")
    menu_additem(WallMenu , "删除上一个")
    return WallMenu
}

public CreateNpcMenu(){
    new SpawnNpcMenu = menu_create("Npc重生点放置" , "NpcHandle")
    new CureentNpcType[33],listnum[20]
    new npcname[32]
    menu_additem(SpawnNpcMenu , "放置")
    menu_additem(SpawnNpcMenu , "放置一列")
    menu_additem(SpawnNpcMenu , "旋转")
    menu_additem(SpawnNpcMenu , "删除上一个")
    Npc_GetName(npcbody -1 , npcname, charsmax(npcname))
    formatex(CureentNpcType,charsmax(CureentNpcType),"当前:%s",npcname)
    menu_additem(SpawnNpcMenu,CureentNpcType)
    formatex(listnum , charsmax(listnum),"创建列:%i",npc_bulidlistnum)
    menu_additem(SpawnNpcMenu,listnum)
    menu_additem(SpawnNpcMenu,"重生点测试")
    menu_additem(SpawnNpcMenu, "玩家新重生位")
    return SpawnNpcMenu
}

public ShowWallMenu(id){
    if(!is_user_alive(id))
        return PLUGIN_HANDLED;
    new WallMenu = CreateWallMenu()
    menu_display(id, WallMenu);
    return PLUGIN_HANDLED;
}

public OnMenuShow(id){
    if(!is_user_alive(id))
        return PLUGIN_HANDLED;
    menu_display(id, NpcMenu);
    return PLUGIN_HANDLED;
}

public ShowNpcMenu(id){
    if(!is_user_alive(id))
        return PLUGIN_HANDLED;
    new NpcCreateMenu = CreateNpcMenu()
    menu_display(id, NpcCreateMenu,LastNpcmenus/7);
    return PLUGIN_HANDLED;
}

public SetCam(id, Cam){
    if(is_user_alive(id) && is_user_connected(id)){
        set_view(id,Cam)
    }
}

public MenuHander(id, menu, item)
{
    if (item == MENU_EXIT || item < 0 || !is_user_alive(id))
    {
        return PLUGIN_HANDLED;
    }

    new info[32], name[32], access

    menu_item_getinfo(menu,item,access,info,charsmax(info),name,charsmax(name))

    new sel = str_to_num(info)

    switch(sel)
    {
        case swn_Cam3:
            SetCam(id, CAMERA_3RDPERSON);
        case swn_Cam1:
            SetCam(id, CAMERA_NONE);
        case swn_Swapn_Baga1:
            SpawnRiben(1, id);
        case swm_Swapn_Baga2:
            SpawnRiben(2, id);
        case swn_Swapn_TestWall:
            CreateFakeWall(id);
        case swn_Swapn_Npc:
            CreateFakeNpc(id);
        case swn_Save_Wall:
            SaveAll();
        case swn_LoadTest:
            LoadJsonTest();
    }
    return PLUGIN_HANDLED;
}

public LoadPreClear(){
    new ent = -1
    while(ent = rg_find_ent_by_class(ent,"riben_wall")){
        rg_remove_entity(ent)
    }
    ent = -1
    while ((ent = rg_find_ent_by_class(ent,"riben_respawnponit")) > 0){
        rg_remove_entity(ent)
    }
    ent = -1
    while ((ent = rg_find_ent_by_class(ent,"PlayerSpawn")) > 0){
        rg_remove_entity(ent)
    }
}

public LoadJsonTest(){
    new mapname[32]
    new savepath[255]
    
    get_mapname(mapname , charsmax(mapname))

    formatex(savepath,254,
    "addons/amxmodx/configs/krzz/%s.json",
    mapname)

    new JSON:root = json_parse(savepath,true)
    if(root == Invalid_JSON){
        log_amx("[%s]Curennt Map don't has json",__BINARY__)
        return
    }
    LoadPreClear()
    LoadWall(root)
    LoadNpcSpawnPonit(root)
    LoadPlayerSpawn(root)
    json_free(root)
}

public SaveAll(){
    new mapname[32]
    new savepath[255]
    
    get_mapname(mapname , charsmax(mapname))

    formatex(savepath,254,
    "addons/amxmodx/configs/krzz/%s.json",
    mapname)

    new JSON:root = json_init_object()

    SaveWall(root)
    SaveNpcs(root)
    SavePlayerSpawn(root)

    json_serial_to_file(root,savepath,true)
    json_free(root)
}

public LoadPlayerSpawn(JSON:root){
    new JSON:Spawner = json_object_get_value(root,"PlayerSpawnPonit")
    new size = json_array_get_count(Spawner)
    for (new i = 0; i < size; i++){
        new JSON:ponit = json_array_get_value(Spawner, i)
        new JSON:origin_j = json_object_get_value(ponit, "origin")
        new JSON:angles_j = json_object_get_value(ponit, "angles")
        new Float:origin[3], Float:angles[3]
        origin[0] = json_array_get_real(origin_j, 0)
        origin[1] = json_array_get_real(origin_j, 1)
        origin[2] = json_array_get_real(origin_j, 2)

        angles[0] = json_array_get_real(angles_j, 0)
        angles[1] = json_array_get_real(angles_j, 1)
        angles[2] = json_array_get_real(angles_j, 2)
        new ent = CreatePlayerSpawn2(origin,angles)
        set_prop_int(ent,"TestEnt",1)
        json_free(ponit)
        json_free(origin_j)
        json_free(angles_j)
    }
    json_free(Spawner)
}

public LoadNpcSpawnPonit(JSON:root){
    new JSON:Spawner = json_object_get_value(root,"NpcSwapn_points")
    new size = json_array_get_count(Spawner)
    for (new i = 0; i < size; i++){
        new JSON:ponit = json_array_get_value(Spawner, i)
        if (ponit == Invalid_JSON)
            continue
        new JSON:origin_j = json_object_get_value(ponit, "origin")
        new JSON:angles_j = json_object_get_value(ponit, "angles")
        new Float:origin[3], Float:angles[3]
        origin[0] = json_array_get_real(origin_j, 0)
        origin[1] = json_array_get_real(origin_j, 1)
        origin[2] = json_array_get_real(origin_j, 2)

        angles[0] = json_array_get_real(angles_j, 0)
        angles[1] = json_array_get_real(angles_j, 1)
        angles[2] = json_array_get_real(angles_j, 2)

        new body = json_object_get_number(ponit, "body")
        SpawnPonitNum[body-1]++
        new ent = CreateNpcPonit(body, origin, angles)
        set_prop_int(ent,"TestEnt",1)
        json_free(ponit)
        json_free(origin_j)
        json_free(angles_j)
    }
    json_free(Spawner)
}

public LoadWall(JSON:root){
    new JSON:Walls = json_object_get_value(root,"Walls")
    new size = json_array_get_count(Walls)
    for (new i = 0; i < size; i++){
        new JSON:wall = json_array_get_value(Walls, i)
        if (wall == Invalid_JSON)
            continue
        new JSON:origin_j = json_object_get_value(wall, "origin")
        new JSON:angles_j = json_object_get_value(wall, "angles")

        new Float:origin[3], Float:angles[3]
        origin[0] = json_array_get_real(origin_j, 0)
        origin[1] = json_array_get_real(origin_j, 1)
        origin[2] = json_array_get_real(origin_j, 2)

        angles[0] = json_array_get_real(angles_j, 0)
        angles[1] = json_array_get_real(angles_j, 1)
        angles[2] = json_array_get_real(angles_j, 2)

        new del = json_object_get_number(wall, "DelOn")
        new wallent = CreateWall(random_num(1,8),origin,angles,del)
        set_prop_int(wallent,"TestEnt",1)
        json_free(wall)
        json_free(origin_j)
        json_free(angles_j)
    }
    json_free(Walls)
}

public SaveWall(JSON:root){
    new wallent = -1
    new JSON:Walls = json_init_array()
    while((wallent = rg_find_ent_by_class(wallent,"riben_wall")) > 0){
        new del = get_prop_int(wallent , "judian_remove")
        new JSON:wall = json_init_object()
        new JSOM:origin_j = json_init_array()
        new JSOM:angles_j = json_init_array()
        if(!GetIsTestEnt(wallent))
            continue

        new Float:origin[3],Float:angles[3]
        get_entvar(wallent,var_origin,origin)
        get_entvar(wallent,var_angles,angles)

        json_array_append_real(origin_j,origin[0])
        json_array_append_real(origin_j,origin[1])
        json_array_append_real(origin_j,origin[2])
        json_object_set_value(wall,"origin",origin_j)
        json_free(origin_j)

        json_array_append_real(angles_j,angles[0])
        json_array_append_real(angles_j,angles[1])
        json_array_append_real(angles_j,angles[2])
        json_object_set_value(wall,"angles",angles_j)
        json_free(angles_j)

        json_object_set_number(wall,"DelOn",del)

        json_array_append_value(Walls,wall)
        json_free(wall)
    }
    json_object_set_value(root,"Walls",Walls)
    json_free(Walls)
}

public SaveNpcs(JSON:root){
    new npc_spawner = -1
    new JSON:NpcSpawnPonits = json_init_array()
    while ((npc_spawner = rg_find_ent_by_class(npc_spawner,"riben_respawnponit")) > 0){
        new JSON:Ponint = json_init_object()
        new JSOM:origin_j = json_init_array()
        new JSOM:angles_j = json_init_array()
        new Float:origin[3],Float:angles[3]
        new body
        get_entvar(npc_spawner,var_origin,origin)
        get_entvar(npc_spawner,var_angles,angles)
        body = get_entvar(npc_spawner,var_body)

        

        json_array_append_real(origin_j,origin[0])
        json_array_append_real(origin_j,origin[1])
        json_array_append_real(origin_j,origin[2])
        json_object_set_value(Ponint,"origin",origin_j)
        json_free(origin_j)

        json_array_append_real(angles_j,angles[0])
        json_array_append_real(angles_j,angles[1])
        json_array_append_real(angles_j,angles[2])
        json_object_set_value(Ponint,"angles",angles_j)
        json_free(angles_j)

        json_object_set_number(Ponint,"body",body)
        json_array_append_value(NpcSpawnPonits,Ponint)
        json_free(Ponint)
    }
    json_object_set_value(root,"NpcSwapn_points",NpcSpawnPonits)
    json_free(NpcSpawnPonits)
}

public SavePlayerSpawn(JSON:root){
    new PlayerSpawn = -1
    new JSON:Player = json_init_array()
    while((PlayerSpawn = rg_find_ent_by_class(PlayerSpawn,"PlayerSpawn"))>0){
        new JSON:Ponint = json_init_object()
        new Float:origin[3],Float:angles[3]
        new JSOM:origin_j = json_init_array()
        new JSOM:angles_j = json_init_array()
        get_entvar(PlayerSpawn,var_origin,origin)
        get_entvar(PlayerSpawn,var_angles,angles)

        json_array_append_real(origin_j,origin[0])
        json_array_append_real(origin_j,origin[1])
        json_array_append_real(origin_j,origin[2])
        json_object_set_value(Ponint,"origin",origin_j)
        json_free(origin_j)

        json_array_append_real(angles_j,angles[0])
        json_array_append_real(angles_j,angles[1])
        json_array_append_real(angles_j,angles[2])
        json_object_set_value(Ponint,"angles",angles_j)
        json_free(angles_j)

        json_array_append_value(Player,Ponint)
        json_free(Ponint)
    }
    json_object_set_value(root,"PlayerSpawnPonit",Player)
    json_free(Player)
}

public SpawnRiben(Type , ownerid){
    new Float:PlayerOrigin[3] , Float:angles[3],Float:vForward[3],Float:forward_add[3];
    
    get_entvar(ownerid, var_origin, PlayerOrigin);
    get_entvar(ownerid, var_angles, angles);
    angle_vector(angles, ANGLEVECTOR_FORWARD, vForward);
    xs_vec_mul_scalar(vForward, 300.0, forward_add);
    xs_vec_add(PlayerOrigin, forward_add, forward_add);

    new ent = CreateJpNpc(ownerid,CS_TEAM_CT,forward_add,angles,Type);
    if(ent <= 0)
        return;
}

public CreateRealNpc(Float:Origin[3] , Float:angles[3], bodytype){
    new ent = CreateJpNpc(0,CS_TEAM_CT,Origin,angles,bodytype)
    if(ent <= 0)
        return;
}

public CreateFakeNpc(id){
    new ent = rg_create_entity("info_target")
    if(!ent || !is_valid_ent(ent))
        return
    if(!is_user_alive(id)){
        rg_remove_entity(ent)
        return
    }
    set_entvar(ent , var_classname , "riben_npc")
    set_entvar(ent,  var_solid, SOLID_BBOX)
    set_entvar(ent , var_movetype, MOVETYPE_FLY)
    set_entvar(ent , var_rendermode , kRenderTransColor)
    set_entvar(ent , var_renderamt , 180.0)
    set_entvar(ent, var_body, npcbody)
    set_entvar(ent , var_angles , Float:{0.0,0.0,0.0})

    engfunc(EngFunc_SetModel,ent,XiaoRiBen[0])
    engfunc(EngFunc_SetSize, ent, Float:{-10.0,-10.0,0.0}, Float:{10.0,10.0,62.0})     
    CurrentBulidWall[id] = ent
    building[id] = true

    ShowNpcMenu(id)
}

public CreateFakeWall(id){
    new ent = cs_create_entity("info_target")
    if(!ent || !is_valid_ent(ent))
        return
    if(!is_user_alive(id))
        return 
    new Float:Color[] = {100, 200, 255}
    set_entvar(ent , var_classname , "riben_wall")
    set_entvar(ent, var_solid, SOLID_BBOX)
    set_entvar(ent , var_movetype, MOVETYPE_FLY)
    set_entvar(ent , var_rendermode , kRenderTransColor)
    set_entvar(ent , var_renderamt , 180.0)
    // set_entvar(ent , var_rendercolor , Color)
    set_entvar(ent, var_body, 1)
    set_entvar(ent , var_angles , Float:{0.0,0.0,0.0})

    engfunc(EngFunc_SetModel,ent,XiaoRiBen[1])
    engfunc(EngFunc_SetSize, ent, Float:{0.0,0.0,0.0}, Float:{0.0,0.0,0.0})

    CurrentBulidWall[id] = ent
    building[id] = true
    set_prop_int(ent , "judian_remove" , 0)
    ShowWallMenu(id)
}

public RemoveLastEntByStack(Stack:RmStatck){
    if(IsStackEmpty(RmStatck)){
        return
    }
    new last
    PopStackCell(RmStatck,last)
    if(last && is_valid_ent(last)){
        remove_entity(last)
    }
}

public BulidWall(ent,id){
    building[id] = false
    CurrentBulidWall[id] = 0
    new del = get_prop_int(ent,"judian_remove")
    if(del > 0){
        new Float:Color[3]={255.0,0.0,0.0}
        set_entvar(ent,var_renderfx,kRenderFxGlowShell)
        set_entvar(ent,var_rendercolor,Color)
    }
    set_entvar(ent , var_renderamt , 255.0)
    set_entvar(ent, var_solid, SOLID_BBOX)
    
    new Float:mins[3] = {-200.0, -8.0, -100.0},
    Float:maxs[3] = {200.0, 8.0, 100.0}

    new Float:angles[3]
    get_entvar(ent , var_angles, angles)
    set_prop_int(ent,"TestEnt",1)
    if(angles[1] == 0.0 || angles[1] == 180.0){
        new Float:newmin[3],Float:newmax[3]
        newmin[0] = mins[1],newmin[1] = mins[0],
        newmin[2] = mins[2]

        newmax[0] = maxs[1],newmax[1] = maxs[0],
        newmax[2] = maxs[2]
        engfunc(EngFunc_SetSize, ent , newmin , newmax)
        goto End
    }
    

    engfunc(EngFunc_SetSize, ent , mins , maxs)
End:
    PushStackCell(Lastwall,ent)
    draw_bbox_lines(ent, {255,0,0}, 100.0)
}

public BulidNpc(ent,id){
    building[id] = false
    CurrentBulidWall[id] = 0
    set_prop_int(ent,"TestEnt",1)
    set_entvar(ent , var_solid , SOLID_NOT)
    set_entvar(ent , var_classname , "riben_respawnponit")
    PushStackCell(LastNpc , ent)
    draw_bbox_lines(ent, {255,0,0}, 9999.0)
}

public BulidNpcList(ent , count,id){
    new Float:pading = 28.0
    new Float:angles[3],Float:origin[3]
    new Float:Vforwards[3]
    get_entvar(CurrentBulidWall[id] , var_angles , angles)
    get_entvar(CurrentBulidWall[id] , var_origin , origin)
    angle_vector(angles, ANGLEVECTOR_FORWARD, Vforwards)
    for(new i = 0 ; i < count; i++){
        new Float:new_origin[3]
        new_origin[0] = origin[0] + Vforwards[0] * pading * float(i)
        new_origin[1] = origin[1] + Vforwards[1] * pading * float(i)
        new_origin[2] = origin[2]

        new newent = rg_create_entity("info_target")
        if(!newent || !is_valid_ent(newent))
            break
         set_prop_int(newent,"TestEnt",1)
        set_entvar(newent , var_classname , "riben_respawnponit")
        set_entvar(newent,  var_solid, SOLID_NOT)
        set_entvar(newent , var_movetype, MOVETYPE_FLY)
        set_entvar(newent , var_rendermode , kRenderTransColor)
        set_entvar(newent , var_renderamt , 180.0)
        set_entvar(newent, var_body, npcbody)
        set_entvar(newent , var_angles , angles)

        engfunc(EngFunc_SetModel,newent,XiaoRiBen[0])
        engfunc(EngFunc_SetSize, newent, Float:{-10.0,-10.0,0.0}, Float:{10.0,10.0,62.0})     

        set_entvar(newent , var_origin , new_origin)
        draw_bbox_lines(ent, {255,0,0}, 999.0)
        PushStackCell(LastNpc , newent)
    }
}
public CreateNpcPonit(Npcbody, Float:origins[3], Float:angles[3]){
    new newent = rg_create_entity("info_target")
    if(!newent || !is_valid_ent(newent))
        return 0
    set_prop_int(newent,"TestEnt",1)
    set_entvar(newent , var_classname , "riben_respawnponit")
    set_entvar(newent,  var_solid, SOLID_NOT)
    set_entvar(newent , var_movetype, MOVETYPE_FLY)
    set_entvar(newent , var_rendermode , kRenderTransColor)
    set_entvar(newent , var_renderamt , 180.0)
    set_entvar(newent, var_body, Npcbody)
    set_entvar(newent , var_angles , angles)
    set_entvar(newent , var_origin , origins)
    engfunc(EngFunc_SetModel,newent,XiaoRiBen[0])
    engfunc(EngFunc_SetSize, newent, Float:{-10.0,-10.0,0.0}, Float:{10.0,10.0,62.0})
    return newent
}

public RoolEnt(ent, id){
    new Float:angles[3]
    get_entvar(ent,var_angles,angles)
    angles[1]+= 90.0
    if(angles[1] > 360.0){
        angles[1] = 0.0
    }
    set_entvar(ent,var_angles,angles)
    return 1
}

public ChangeWallBody(ent , id){
    new MaxBody = 11 , MinBody = 1
    static currentbody = 1
    get_entvar(ent,var_body,currentbody)
    if(currentbody >= MaxBody || currentbody < MinBody){
        set_entvar(ent , var_body , MinBody)
        currentbody = 1
    }else{
        currentbody++
        set_entvar(ent , var_body , currentbody)
    }
    return 1
}

public Setjudian_RemoveWall(ent){
    set_prop_int(ent , "judian_remove" , judian_wall)
    return 1
}

public Change_RemoveWall_judian(){
    judian_wall++
    if(judian_wall > Max_judian - 1){
        judian_wall = 2
    }
    return 1
}

public DelAndShowMenu(id, MenuId , MenuHandleName[]){
    menu_destroy(MenuId)
    if(equal(MenuHandleName , "ShowWallMenu")){
        ShowWallMenu(id)
    }else if(equal(MenuHandleName , "ShowNpcMenu")){
        ShowNpcMenu(id)
    } 
    
}

public WallHandle(id, menu, item){
    if (item == MENU_EXIT || item < 0 || !is_user_alive(id))
    {
        remove_entity(CurrentBulidWall[id])
    End:
        CurrentBulidWall[id] = 0
        building[id] = false
        menu_destroy(menu)
        return
    }
    new CurrentEnt = CurrentBulidWall[id]
    switch(item){
        case 0:{
            BulidWall(CurrentEnt,id)
            CreateFakeWall(id)
        }
        case 1:{
            RoolEnt(CurrentEnt, id)
            DelAndShowMenu(id,menu, Tostr(ShowWallMenu))
        }
        case 2:{
            ChangeWallBody(CurrentEnt,id)
            DelAndShowMenu(id,menu, Tostr(ShowWallMenu))
        }
        case 3:{
            if(Setjudian_RemoveWall(CurrentEnt)){
                DelAndShowMenu(id,menu, Tostr(ShowWallMenu))
            }
        } 
        case 4:{
            if(Change_RemoveWall_judian()){
                DelAndShowMenu(id,menu, Tostr(ShowWallMenu))
            }
        }
        case 5:{
            RemoveLastEntByStack(Lastwall)
            DelAndShowMenu(id,menu, Tostr(ShowWallMenu))
        }
    }
}

public NpcHandle(id, menu, item){
    if (item == MENU_EXIT || item < 0 || !is_user_alive(id))
    {
        remove_entity(CurrentBulidWall[id])
    End:
        CurrentBulidWall[id] = 0
        building[id] = false
        menu_destroy(menu)
        return
    }
    new CurrentEnt = CurrentBulidWall[id]
    LastNpcmenus = item
    switch(item){
        case 0: 
        {
            BulidNpc(CurrentEnt,id)
            goto End
        }
        case 1: {
            BulidNpcList(CurrentEnt,npc_bulidlistnum,id)
            DelAndShowMenu(id,menu, Tostr(ShowNpcMenu))
        }
        case 2: {
            RoolEnt(CurrentEnt,id)
            DelAndShowMenu(id,menu, Tostr(ShowNpcMenu))
        }
        case 3: {
            RemoveLastEntByStack(LastNpc)
            DelAndShowMenu(id,menu, Tostr(ShowNpcMenu))
        }
        case 4: {
            ChangeJudian(id)
            DelAndShowMenu(id,menu, Tostr(ShowNpcMenu))
        }
        case 5: {
            ChangeListnum()
            DelAndShowMenu(id,menu, Tostr(ShowNpcMenu))
        }
        case 6 :{
            TestNpcSpawnPonit()
            DelAndShowMenu(id,menu, Tostr(ShowNpcMenu))
        }
        case 7 :{
            CreatePlayerSpawn(id,CurrentEnt)
            DelAndShowMenu(id,menu, Tostr(ShowNpcMenu))
        }
    }
    
}

public CreatePlayerSpawn(id, FakeNpcEnt){
    new newent = rg_create_entity("info_target")
    if(!newent || !is_valid_ent(newent)){
        return
    }
    new Float:origin[3],Float:angles[3]
    get_entvar(FakeNpcEnt,var_origin,origin)
    get_entvar(FakeNpcEnt, var_angles,angles)

    set_entvar(newent , var_classname , "PlayerSpawn")
    set_entvar(newent,  var_solid, SOLID_NOT)
    set_entvar(newent , var_movetype, MOVETYPE_FLY)
    set_entvar(newent , var_rendermode , kRenderTransColor)
    set_entvar(newent , var_renderamt , 180.0)
    set_entvar(newent, var_origin, origin)
    set_entvar(newent, var_angles, angles)

    engfunc(EngFunc_SetModel,newent,PlayerModule[0])
    engfunc(EngFunc_SetSize, newent, Float:{-10.0,-10.0,0.0}, Float:{10.0,10.0,62.0})     
    PushStackCell(LastNpc , newent)
}
public CreatePlayerSpawn2(Float:origin[3] , Float:angles[3]){
    new newent = rg_create_entity("info_target")
    if(!newent || !is_valid_ent(newent)){
        return 0
    }
    set_entvar(newent , var_classname , "PlayerSpawn")
    set_entvar(newent,  var_solid, SOLID_NOT)
    set_entvar(newent , var_movetype, MOVETYPE_FLY)
    set_entvar(newent , var_rendermode , kRenderTransColor)
    set_entvar(newent , var_renderamt , 180.0)
    set_entvar(newent, var_origin, origin)
    set_entvar(newent, var_angles, angles)

    engfunc(EngFunc_SetModel,newent,PlayerModule[0])
    engfunc(EngFunc_SetSize, newent, Float:{-10.0,-10.0,0.0}, Float:{10.0,10.0,62.0})     
    PushStackCell(LastNpc , newent)
    return newent
}

public ChangeJudian(id){
    if(is_nullent(CurrentBulidWall[id]))
        return
    npcbody++
    if(npcbody > 8){
        npcbody = 1
    }
    set_entvar(CurrentBulidWall[id] , var_body , npcbody)
}

public ChangeListnum(){
    npc_bulidlistnum = npc_bulidlistnum >= 10 ? 1 : npc_bulidlistnum + 1
}
public TestNpcSpawnPonit(){
    new ent = -1
    while((ent = rg_find_ent_by_class(ent , "riben_respawnponit")) > 0){
        new body = get_entvar(ent , var_body)
        new Float:origins[3],Float:angles[3]
        get_entvar(ent , var_origin , origins)
        get_entvar(ent , var_angles , angles)
        CreateRealNpc(origins , angles , body)
    }
}

public on_PreThink(id){
    if(!CurrentBulidWall[id] && !building[id])
        return FMRES_IGNORED
    
    if(is_user_bot(id))
        return FMRES_IGNORED
    
    new Float:origin[3], Float:angles[3], Float:forwards[3]
    get_entvar(id , var_origin,origin)
    get_entvar(id , var_v_angle,angles)

    get_aim_origin_vector(id , 150.0, 0.0, 0.0,origin)

    set_entvar(CurrentBulidWall[id] , var_origin , origin)

    
    return FMRES_IGNORED
}

public draw_bbox_lines(ent, color[3] , Float:duration) {
    if(!pev_valid(ent)) return;

    new Float:absmin[3], Float:absmax[3];
    pev(ent, pev_absmin, absmin);
    pev(ent, pev_absmax, absmax);
    
    // 计算8个顶点
    new Float:points[8][3];
    for(new i = 0; i < 8; i++) {
        points[i][0] = (i & 1) ? absmax[0] : absmin[0];
        points[i][1] = (i & 2) ? absmax[1] : absmin[1];
        points[i][2] = (i & 4) ? absmax[2] : absmin[2];
    }
    
    // 绘制12条边
    draw_line(laserbeam,points[0], points[1], color, duration); // 底边1
    draw_line(laserbeam,points[0], points[2], color, duration); // 底边2
    draw_line(laserbeam,points[3], points[1], color, duration); // 底边3
    draw_line(laserbeam,points[3], points[2], color, duration); // 底边4
    
    draw_line(laserbeam,points[4], points[5], color, duration); // 顶边1
    draw_line(laserbeam,points[4], points[6], color, duration); // 顶边2
    draw_line(laserbeam,points[7], points[5], color, duration); // 顶边3
    draw_line(laserbeam,points[7], points[6], color, duration); // 顶边4
    
    draw_line(laserbeam,points[0], points[4], color, duration); // 竖边1
    draw_line(laserbeam,points[1], points[5], color, duration); // 竖边2
    draw_line(laserbeam,points[2], points[6], color, duration); // 竖边3
    draw_line(laserbeam,points[3], points[7], color, duration); // 竖边4
}

stock get_aim_origin_vector(iPlayer, Float:forw, Float:right, Float:up, Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(iPlayer, pev_origin, vOrigin)
	pev(iPlayer, pev_view_ofs, vUp)
	xs_vec_add(vOrigin, vUp, vOrigin)
	pev(iPlayer, pev_v_angle, vAngle)
	
	angle_vector(vAngle, ANGLEVECTOR_FORWARD, vForward)
	angle_vector(vAngle, ANGLEVECTOR_RIGHT, vRight)
	angle_vector(vAngle, ANGLEVECTOR_UP, vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

//画线
stock draw_line(spr,Float:start[3], Float:end[3], color[3], Float:life) {
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_BEAMPOINTS);
    write_coord_f(start[0]);
    write_coord_f(start[1]);
    write_coord_f(start[2]);
    write_coord_f(end[0]);
    write_coord_f(end[1]);
    write_coord_f(end[2]);
    write_short(spr); // 光束精灵
    write_byte(0); // 起始帧
    write_byte(0); // 帧率
    write_byte(floatround(life * 10.0)); // 持续时间 (帧)
    write_byte(5); // 线宽
    write_byte(0); // 噪声
    write_byte(color[0]); // R
    write_byte(color[1]); // G
    write_byte(color[2]); // B
    write_byte(200); // 亮度
    write_byte(0); // 滚动速度
    message_end();
}

public GetIsTestEnt(id){
    if(!prop_exists(id,"TestEnt"))
        return false
    new isOnlyTest = get_prop_int(id,"TestEnt")
    return isOnlyTest
}
