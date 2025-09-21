#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <cstrike>
#include <reapi>
#include <json>
#include <engine>
#include <kr_core>
#include <roundrule>
#include <hamsandwich>
#include <xp_module>
#include <props>
#include <xs>

#define judian_max 8

#define ShowHudid 1121

#define var_Spawnid var_iuser1
#define var_master var_skin
#define var_Master "maste"
#define Set_Master(%1 ,%2) set_member(%1 , maxammo_buckshot ,%2)
#define Get_Master(%1) get_member(%1 , maxammo_buckshot)

#define GameName "抗日战争v1.1"

enum EndSoundEnum{
    ChineseWin,
    RiBenWin,
    RiBenWin2,
    JudianGo,
    JudianGo2,
    EndJudian,
    Type,
    cnDie1,
    cnDie2,
    cnGoTr,
    cnGoTr2,
}

new Jp_EndRoundSound[][] = {
    "rainych/krzz/cn_win.wav",
    "rainych/krzz/jp_go.wav",
    "rainych/krzz/jp_wangsui.wav",
    "rainych/krzz/hit_jp.wav",
    "rainych/krzz/hit_jp2.wav",
    "rainych/krzz/last_duty.wav",
    "rainych/krzz/Type.wav",
    "rainych/krzz/cn_die.wav",
    "rainych/krzz/cn_die2.wav",
    "rainych/krzz/traitor_go.wav",
    "rainych/krzz/traitor_go2.wav",
}

new LvName[][]={
    "抗日新兵",
    "战场老兵",
    "抗日班长",
    "抗日连长",
    "抗日营长",
    "抗日团长",
    "抗日旅长",
    "抗日师长",
    "抗日军长",
    "军中传奇",
    "司令员",
    "国副统领",
    "一国领袖",
    "精神领袖",
    "抗战之光",
    "华夏脊梁",
    "历史丰碑",
    "时代楷模",
    "万世楷模",
    "永恒光辉",
    "千秋伟业",
    "历史丰碑",
}

new const g_remove_entities[][] = { "func_bomb_target", "info_bomb_target", "info_vip_start", "func_vip_safetyzone", "func_escapezone", "hostage_entity",
		"monster_scientist", "func_hostage_rescue", "info_hostage_rescue", "env_fog", "env_rain", "env_snow", "armoury_entity" }

new const hint[][] = {
    "!t[游戏提示]本服务器可以砸枪，部分枪械为隐藏枪械只有砸枪可以产出哦。",
    "!t[游戏提示]本服务器拥有随机规则，不同规则下搭配不同，请慢慢探索",
    "!t[游戏提示]当抗日伙伴攻击日军时，会传播仇恨请注意搭配。",
    "!t[游戏提示]砸枪产物和扔掉的武器有时间限制，注意提示不要被大妈扫走了哦。",
    "!t[游戏提示]英雄是每局开局时选出的特殊人物，拥有强力武器",
    "!t[游戏提示]积分加成会随着难度而提升，但注意难度高时很难通关哦",
    "!t[游戏提示]难度越高击杀精英和坦克产出物也会越多。",
}

new gameconfigdir[] = "addons/amxmodx/configs/krzz"
//当前据点剩余npc,据点等级,当前据点Npc有多少个重生点
new CurrentNpsMaxnum,judian_leavel,NpcNum_level,CanSpawnNum

new call_forwards[kr_forwads]
//8个据点分别默认是几个npc,根据放置的来
new SpawnPonitNpcNum[8]
//当前据点
new Current_judian , CurrentNpcs
new Hud_sync,Hud_ShowJudianUp,Hud_Damage,Hud_xp
new DontHasOtherJudian[8]
new bool:Json_Faild

new Float:TakeDamge[33] , Float:XpDamage[33]//每人共造成多少伤害
new bool:FirstShow[33]

new Float:ProectPlayerTime//开局保护玩家不被直接突脸
//前面为origin后面为angles
new Float:NewSpawn[33][6],NewSpawnNums

new rgSpawn,lvadd

new p_floodtime

new Float:ClearWaeponTime

new IsHanJian[33]

public plugin_init(){
    register_plugin("抗日核心", "1.0", "Bing")
    
    RegisterHookChain(RG_RoundEnd, "EventRoundEnd_Reapi", true)
    RegisterHookChain(RG_CBasePlayer_AddAccount, "Player_AddAccount")
    RegisterHookChain(RG_CBasePlayer_Spawn,"PlayerSpawn_Post",true)
    RegisterHookChain(RG_CSGameRules_CheckMapConditions , "m_CheckMap",true)
    RegisterHookChain(RG_CSGameRules_RestartRound, "NewRound", true)

    RegisterHam(Ham_TakeDamage , "player" , "m_TakePlayerDamge")

    register_message(get_user_msgid("TextMsg") , "OnTextMsg")
    
    register_event("TeamInfo", "event_TeamInfo", "a")
    register_event("HLTV", "event_roundstart", "a", "1=0", "2=0")
    register_event("ResetHUD","eventHud","b")

    unregister_forward(FM_Spawn, rgSpawn) 
    register_forward( FM_GetGameDescription, "GameDesc" )

    register_clcmd("jointeam","NoReTeam")
    register_clcmd("say /save","SavePlayer_Buy")
    register_clcmd("say /me","ShowPlayerInfo")
    register_concmd("KR_GoToCt", "ChangTeamToCt")
    register_concmd("Kr_EndRound", "KrEndRound")

    bind_pcvar_float(register_cvar("clear_weaponbox","120.0"), ClearWaeponTime)    

    set_cvar_num("mp_freezetime", 0)
    set_cvar_num("mp_roundover", 1)
    set_cvar_float("mp_roundtime",10.0)
    set_cvar_float("amx_flood_time", 0.0)
    set_cvar_float("mp_buytime", 0.1)
    p_floodtime = get_cvar_pointer("amx_flood_time")
    hook_cvar_change(p_floodtime, "ChangeFlood")
    Hud_sync = CreateHudSyncObj()
    Hud_ShowJudianUp = CreateHudSyncObj()
    Hud_Damage = CreateHudSyncObj()
    Hud_xp = CreateHudSyncObj()
    set_task(1.0,"ShowHud",.flags = "b")
    set_task(30.0,"Qa",.flags = "b")

    reg_forward()
    LoadMapconfig()
    FuckMapTank()
}

public Qa(){
    static CurHits
    if(CurHits >= sizeof hint){
        CurHits = 0
    }
    set_hudmessage(200, 0 , 0 , 0.6 , 0.8,.holdtime = 5.0 , .fadeouttime = 1.0)
    show_hudmessage(0 ,hint[CurHits])
    m_print_color(0 , hint[CurHits])
    CurHits++
}

public FuckMapTank(){
    new ent = -1
    while((ent = rg_find_ent_by_class(ent , "func_tankmortar")) > 0){
        fm_set_kvd(ent , "bullet_damage" , "10" )
    }
    ent = -1
    while((ent = rg_find_ent_by_class(ent , "func_tank")) > 0){
        fm_set_kvd(ent , "bullet_damage" , "10" )
        // fm_set_kvd(ent , "firerate" , "1" )
    }
}

public KrEndRound(){
    remove_entity_name("hostage_entity")
    ChangeJudian()
}

public SavePlayers(){
    new maxplayer = get_maxplayers()
    for(new i = 1 ;i < maxplayer; i++){
        if(!is_user_connected(i) || is_user_bot(i))
            continue
        SavePlayer(i)
        SaveAmmo(i)
    }
}

public ClearWaeponBox(){
    m_print_color(0, "!g[提醒]扫地大妈还有10秒清除扫地产物。")
    set_task(1.0 , "TimerShow" , 9 + 100)
}

public TimerShow(Timer){
    new RealTimer = Timer - 100
    if(RealTimer == 0 || RealTimer < 0){
        ClearWeaponBox()
        return
    }
    m_print_color(0, "!g[提醒]扫地大妈还有%d秒清除扫地产物。" , RealTimer)
    RealTimer--
    set_task(1.0, "TimerShow", RealTimer + 100)
}

public ClearWeaponBox(){
    new entid = -1
    while ((entid = rg_find_ent_by_class(entid, "weaponbox"))) {
        remove_weaponbox_pakitem(entid)
        rg_remove_entity(entid)
    }
    remove_entity_name("mbox")
    m_print_color(0, "!g[提醒]扫地大妈清除了地上的所有武器，和砸枪产物。")
}

public ChangeFlood(PointerCvar, const OldValue[], const NewValue[])
{
	set_pcvar_float(PointerCvar, 0.0)
}

public plugin_natives(){
    register_native("GetJuDianNum","native_GetJuDianNum")
    register_native("GetCurrentNpcs","native_GetCurrentNpcs")
    register_native("Getleavel","native_Getleavel")
    register_native("Setleavel","native_Setleavel")
}

public plugin_precache(){
    rgSpawn = register_forward(FM_Spawn, "fwSpawn")
    for (new i = 0; i < sizeof Jp_EndRoundSound; i++){
        UTIL_Precache_Sound(Jp_EndRoundSound[i])
    }
}

public reg_forward(){
    call_forwards[kr_On_judian_Change_Post] = CreateMultiForward("On_judian_Change_Post",ET_STOP,FP_CELL)
    call_forwards[kr_OnLevelChange_Post] = CreateMultiForward("OnLevelChange_Post", ET_STOP,FP_CELL)
}

public NPC_KillPlayer(this , killer){
	CreateHanJianMenu(this)
}

CreateHanJianMenu(id){
    new newTConut = get_member_game(m_iNumTerrorist)
    if(newTConut == 1 || get_user_team(id) == _:CS_TEAM_CT){
        return
    }
    new menu = menu_create("大日本黄军俘虏了你" , "HanjianHandle")
    menu_additem(menu , "成为汉奸")
    menu_additem(menu , "誓死不从")
    menu_additem(menu , "出卖机密")
    menu_setprop(menu , MPROP_EXIT , MEXIT_NEVER)
    menu_display(id , menu)
}

public HanjianHandle(id, menu ,item){
    if(item == MENU_EXIT){
    	menu_destroy(menu)
    	return
    }
    switch(item){
        case 0 : server_cmd("KR_GoToCt %d" , id)
        case 1 : CnDie(id)
        case 2 : SellBoss(id)
    }
}

public m_TakePlayerDamge(const this , const Attack_1 , const Attack_2 , Float:Damge , DamgeBit){
    new Team = get_member(this , m_iTeam)
    if(Team != _:TEAM_CT)
        return
    new Float:Health = get_entvar(this , var_health)
    if(Damge > Health){
        SetHamParamFloat(4 , 10.0)
    }else{
        new const Float:TARGET_LEVEL = 500.0;
        new const Float:LEVEL_COEFFICIENT = 0.65 / TARGET_LEVEL
        new Float:COEFFICIENT= floatmin(float(Getleavel()) * LEVEL_COEFFICIENT, 0.65)
        SetHamParamFloat(4 , Damge * (1.0 - COEFFICIENT))
    }
}

CnDie(id){
    new username[32]
    get_user_name(id , username , 31)
    UTIL_EmitSound_ByCmd(0 , Jp_EndRoundSound[random_num(_:cnDie1 , _:cnDie2)])
    m_print_color(id , "!g[冰布提示]%s誓死不从，奖励1大洋" , username)
    AddAmmoPak(id , 1.0) 
}

SellBoss(id){
    new username[32]
    get_user_name(id , username , 31)
    m_print_color(id , "!g[冰布提示]该死的%s向日军出卖我军机密(本局可能出现BOSS)" , username)
    AddAmmoPak(id , 2.0)
}

public SavePlayer_Buy(id){
    if(!is_user_connected(id))
        return
    new mn = cs_get_user_money(id)
    if(mn < 10000){
        m_print_color(id , "【!g提示】!y保存至少需要!g10000!y元,你的金钱不足 /save保存积分")
        return
    }
    cs_set_user_money(id,mn - 10000)
    SavePlayer(id)
    SaveAmmo(id)
}

public GameDesc(){
    forward_return( FMV_STRING, GameName ); 
    return FMRES_SUPERCEDE
}

public fwSpawn(iEntity){
    if(!pev_valid(iEntity)) 
	    return FMRES_IGNORED
	
	static classname[33]
    pev(iEntity , pev_classname , classname , charsmax(classname))
	for(new i = 0; i < sizeof g_remove_entities; ++i)
	{
	    if(strcmp(classname, g_remove_entities[i]))
	    continue
	
	    rg_remove_entity(iEntity)
	    return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}

public m_CheckMap(this){
    set_member_game(m_bMapHasBombTarget,true)
    set_member_game(m_bMapHasBombZone,true)
    return FMRES_SUPERCEDE
}

public client_putinserver(id){
    FirstShow[id] = true
    IsHanJian[id] = false
    set_task(3.0, "ShowPlayerInfo", id)
}

public client_disconnected(id){
    TakeDamge[id] = 0.0
    FirstShow[id] = false
    IsHanJian[id] = false
    if(GetAliveTPlayer(id) == 0){
        rg_round_end(3.0 , WINSTATUS_NONE , ROUND_GAME_RESTART)
    }
}

public GetAliveTPlayer(id){
    new players = get_maxplayers()
    new nums = 0
    for(new i =1 ; i < players ; i++){
        if(i == id)
            continue
        if(is_user_connected(i) && cs_get_user_team(i) == CS_TEAM_T){
            nums++
        }
    }
    return nums
}

public NoReTeam(id){
    if(id == GetFakeClient()){
        return PLUGIN_CONTINUE
    }
    if(is_valid_ent(id)){
        new team = get_user_team(id) 
        if (team == CS_TEAM_CT || team == CS_TEAM_T){
            return PLUGIN_HANDLED
        }
        
    }
    return PLUGIN_CONTINUE
}

public ChangTeamToCt(){
    new id
    new buff[6]
    new argc = read_argc()
    if(argc == 1){
        log_amx("本指令需指定id" )
        return
    }
    read_args(buff , charsmax(buff))
    id = str_to_num(buff)
    if(is_user_connected(id) && is_entity(id)){
        static name [32]
        cs_set_user_team(id , CS_TEAM_CT)
        get_user_name(id , name , charsmax(name))
        IsHanJian[id] = true
        m_print_color(0 , "!g【提醒】!t%s!y没顶住日军的折磨，成为了汉奸" , name)
        UTIL_EmitSound_ByCmd(0 , Jp_EndRoundSound[random_num(cnGoTr , cnGoTr2)])
    }
}

public event_roundstart(){
    Current_judian = 0;
    NpcNum_level = SpawnPonitNpcNum[Current_judian];
    CurrentNpsMaxnum = GetCurrentJuDianMaxSpawn();
    CanSpawnNum = CurrentNpsMaxnum;
    CurrentNpcs = CurrentNpsMaxnum;
    ProectPlayerTime = get_gametime() + 3.0;

    //玩家相关
    arrayset(TakeDamge,0,sizeof(TakeDamge))
    new i = 0
    while (i < 33){
        if(is_user_connected(i) && is_user_alive(i)){
            rg_give_default_items(i)
        }
        i++
    }
    set_task(ClearWaeponTime, "ClearWaeponBox",1121, .flags = "b")
    set_task(60.0, "SavePlayers",1122, .flags = "b")
    // set_task(0.5,"MakeBommer")
}

public NewRound(){
    new timer = get_member_game(m_iRoundTime)
    timer += Getleavel() * 15
    set_member_game(m_iRoundTime, timer)
}

public event_TeamInfo(){
    new id = read_data(1);                // 玩家 ID
    new szTeam[3];
    read_data(2, szTeam, charsmax(szTeam))
    if(id == GetFakeClient() || IsHanJian[id]){
        return
    }
    switch(szTeam[0]){
        case 'C':{
            cs_set_user_team(id , CS_TEAM_T, .send_teaminfo = false)
        }
    }
}

public LoadMapconfig(){
    new mapname[32]
    new savepath[255]
    
    get_mapname(mapname , charsmax(mapname))

    formatex(savepath,254,"%s/%s.json",gameconfigdir,mapname)

    new JSON:root = json_parse(savepath , true)
    if(root == Invalid_JSON){
        set_task(1.0,"NoHasJson",.flags="b")
        Json_Faild = true
        return
    }
    LoadNpcPonit(root)
    LoadWalls(root)
    LoadPlayerNewSpawn(root)
}

public NoHasJson(){
    static sync
    if(!sync)
        sync = CreateHudSyncObj()
    set_hudmessage(255,255,0,.y=0.05,.holdtime = 1.5)

    ShowSyncHudMsg(0,sync,"本图不存在任何数据无法游玩^n请大胆骂sb冰桑")
}

public ShowHud(){
    if(Json_Faild){
        task_exists(ShowHudid)
        return
    }
    set_hudmessage(0,255,20,.y=0.05,.holdtime = 1.5)
    static HuManRuleText[64],RiJunRuleText[64]
    GetRuleAllText(RoundRuleType:RULE_HUMAN, HuManRuleText, charsmax(HuManRuleText))
    GetRuleAllText(RoundRuleType:RULE_RIJUN, RiJunRuleText, charsmax(RiJunRuleText))
    ShowSyncHudMsg(0,Hud_sync,"当前难度 %d级 | 当前据点攻占%d/8 | 剩余日本鬼子 %d^n\
    当前难度积分加成%d^n\
    八路规则:%s ^n日军规则: %s" ,
    judian_leavel, Current_judian + 1 , CurrentNpcs, 
    lvadd,
    HuManRuleText, RiJunRuleText
    )

    new playernums = get_maxplayers()
    for (new i = 1; i < playernums; i++){
        if(!is_user_connected(i) || is_user_bot(i))
            continue
        if(is_nullent(i) || is_valid_ent(i)){
            set_hudmessage(0,255,100,-1.0,0.88,.holdtime = 2.0)
            ShowSyncHudMsg(i,Hud_Damage,"伤害计数: %.1f" , TakeDamge[i])

            new lv,xp,XpNeed
            new Float:Ammo
            new name[32]
            lv = GetLv(i)
            xp = GetXp(i)
            // XpNeed = GetXpNeed(i) - GetXp(i)
            Ammo = GetAmmoPak(i)
            new xpstr[50],xpneedstr[50]
            GetXpBingInt(i , xpstr , 49)
            GetXpNeedBingInt(i , xpneedstr , 49)
            new const MaxLen = sizeof LvName
            copy(name, 31 , LvName[min(lv/50 , MaxLen - 1)])
            set_hudmessage(0,255,100,-1.0,0.9,.holdtime = 2.0)
            ShowSyncHudMsg(i,Hud_xp,
            "【当前等级】: %d 【当前积分】:%s 【需求积分】:%s^n【你的大洋】:%.2f 【军衔】:%s" , 
            lv,xpstr,xpneedstr,Ammo,name
            )
            
        }
    }
}

public LoadNpcPonit(JSON:root){
    new JSON:Spawner = json_object_get_value(root,"NpcSwapn_points")
    if(Spawner == Invalid_JSON){
        log_amx("地图不存在NpcPoint")
        return
    }
    new size = json_array_get_count(Spawner)
    if(size<=0){
        return
    }
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
        SpawnPonitNpcNum[body-1]++
        CreateNpcSpawnPonit(body, origin, angles)
        json_free(ponit)
        json_free(origin_j)
        json_free(angles_j)
    }
    json_free(Spawner)
    for(new i = 1 ; i < sizeof SpawnPonitNpcNum ; i++){
        if(SpawnPonitNpcNum[i] == 0 && i != 7){
            SpawnPonitNpcNum[i] = SpawnPonitNpcNum[0] + SpawnPonitNpcNum[0] / 2
            DontHasOtherJudian[i] = true
        }else if(i == 7 && SpawnPonitNpcNum[i] == 0){
            SpawnPonitNpcNum[7] = 5
            DontHasOtherJudian[i] = true
        }
    }
}

public LoadWalls(JSON:root){
    new JSON:Walls = json_object_get_value(root,"Walls")
    if(Walls == Invalid_JSON){
        log_amx("地图不存在Wall")
        return
    }
    new size = json_array_get_count(Walls)
    if(size<=0){
        return
    }
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
        CreateWall(random_num(1,10),origin,angles,del)
        json_free(wall)
        json_free(origin_j)
        json_free(angles_j)
    }
    json_free(Walls)
}

public LoadPlayerNewSpawn(JSON:root){
    new JSON:NewSpawns = json_object_get_value(root,"PlayerSpawnPonit")
    if(NewSpawns == Invalid_JSON){
        log_amx("地图不存在玩家新复活点")
        return
    }
    new size = json_array_get_count(NewSpawns)
    if(size<=0){
        return
    }
    for (new i = 0; i < size; i++){
        new JSON:wall = json_array_get_value(NewSpawns, i)
        if (wall == Invalid_JSON)
            continue
        new JSON:origin_j = json_object_get_value(wall, "origin")
        new JSON:angles_j = json_object_get_value(wall, "angles")

        NewSpawn[NewSpawnNums][0] = json_array_get_real(origin_j, 0)
        NewSpawn[NewSpawnNums][1] = json_array_get_real(origin_j, 1)
        NewSpawn[NewSpawnNums][2] = json_array_get_real(origin_j, 2)

        NewSpawn[NewSpawnNums][3] = json_array_get_real(angles_j, 0)
        NewSpawn[NewSpawnNums][4] = json_array_get_real(angles_j, 1)
        NewSpawn[NewSpawnNums][5] = json_array_get_real(angles_j, 2)
        NewSpawnNums++
    }
}

public EventRoundEnd_Reapi(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay){
	remove_task(1121)
	remove_task(1122)
    arrayset(IsHanJian , 0 , sizeof IsHanJian)
    if(status == WINSTATUS_TERRORISTS){
        if(event == ROUND_TERRORISTS_WIN){
            WinSound()
        }
    }

    if(status == WINSTATUS_CTS && event == ROUND_CTS_WIN){
        FaildSound()
    }
    switch(event){
        case ROUND_TARGET_SAVED,ROUND_HOSTAGE_NOT_RESCUED,ROUND_GAME_OVER
         :{
            FaildSound()
            ShowFailHud2()
            KillAllT()
        }
    }
    ChangeAllPlayerTeam(CS_TEAM_T)
}

public ChangeAllPlayerTeam(team){
    new playermax = get_maxplayers()
    for(new i = 1 ; i < playermax ; i++){
        if(!is_user_connected(i))
            continue
        new user_team = cs_get_user_team(i)
        if(is_user_bot(i) && user_team != team && user_team != CS_TEAM_SPECTATOR)
            continue
        cs_set_user_team(i , CS_TEAM_T)
    }
}

public eventHud(id){

}

/**
 * 重置玩家重生位置
 */
public PlayerSpawn_Post(this){
    if(!is_entity(this) || !is_user_connected(this) || is_user_bot(this))
        return HC_CONTINUE
    new lv = GetLv(this) //因为默认等级为1
    new Float:MaxHeal = 255.0
    new Float:newheal = 100.0 + float(lv)
    newheal = newheal > MaxHeal ? MaxHeal : newheal
    set_entvar(this , var_health , newheal)
    set_entvar(this, var_max_health , newheal)

    //不存在自定义重生点不运行一下逻辑
    if(!NewSpawnNums){
        return HC_CONTINUE
    }
    new CsTeams:team = cs_get_user_team(this)
    switch(team){
        case CS_TEAM_T:{
            new Float:Get[6],Float:Origin[3],Float:Angles[3]
            Get = NewSpawn[random_num(0,NewSpawnNums-1)]
            Origin[0] = Get[0]
            Origin[1] = Get[1]
            Origin[2] = Get[2]
            Angles[0] = Get[3]
            Angles[1] = Get[4]
            Angles[2] = Get[5]
            set_entvar(this,var_origin,Origin)
            set_entvar(this,var_angles,Angles)
        }
        case CS_TEAM_CT:{
            new ent = -1
            while ((ent = rg_find_ent_by_class(ent , "riben_respawnponit")) > 0){
                if(GetJuDianNum() == get_entvar(ent ,var_body)){
                    new Float:Origin[3]
                    get_entvar(ent , var_origin,Origin)
                    Origin[2] += 90.0
                    set_entvar(this, var_origin , Origin)
                    break
                }
            }
        }
    }
    return HC_CONTINUE
    
}
/**
 * 阻止原版函数检查钱数上限。无限制增加
 */
public Player_AddAccount(const this, amount, RewardType:type, bool:bTrackChange){
    new currentmoney
    if(!is_valid_ent(this))
        return HC_CONTINUE
    currentmoney = cs_get_user_money(this)
    currentmoney += amount
    cs_set_user_money(this,currentmoney)
    return HC_SUPERCEDE
}

public OnTextMsg(){
    new TextStr[256]
    get_msg_arg_string(2,TextStr,127)
    if(equal(TextStr,"#CTs_Win")){
        client_print(0 ,print_center , "日军获胜!")
        ShowFailHud()
        return PLUGIN_HANDLED
    }else if(equal(TextStr,"#Hostages_Not_Rescued")){
        client_print(0 ,print_center , "日军获胜!")
        ShowFailHud()
        return PLUGIN_HANDLED
    }else if(equal(TextStr,"#Terrorists_Win")){
        client_print(0 ,print_center , "抗日军获胜!")
        ShowWinHud()
        return PLUGIN_HANDLED
    }else if (equal(TextStr,"#Target_Saved")){
        client_print(0 ,print_center , "日军获胜!")
        return PLUGIN_HANDLED
    }else if (equal(TextStr, "#Round_Over")){
        client_print(0 ,print_center , "日军获胜!")
        return PLUGIN_HANDLED
    }
    return PLUGIN_CONTINUE
}

public ShowFailHud(){
    set_hudmessage(255,255,0,-1.0,-1.0,0,.holdtime = 6.0)
    ShowSyncHudMsg(0,Hud_ShowJudianUp,"居然连日军都打不过统统一帮废物^n回家种地吧！")
}

public ShowFailHud2(){
    set_hudmessage(255,255,0,-1.0,-1.0,0,.holdtime = 6.0)
    ShowSyncHudMsg(0,Hud_ShowJudianUp,"《没时间了》^n^n这么久都打不下日军据点^n你们一帮废物干什么吃的^n你们对不起人民的期待统统枪毙")
}

public ShowWinHud(){
    set_hudmessage(255,255,0,-1.0,-1.0,0,.holdtime = 6.0)
    ShowSyncHudMsg(0,Hud_ShowJudianUp,"你们攻占了所有日军据点，干得好！^n^n每人奖励8000元")
    GiveMoney(8000)
}

public GiveMoney(mon){
    new playernums = get_maxplayers()
    for (new i = 1; i < playernums; i++){
        if(is_user_bot(i))continue
        if(get_user_team(i) == CS_TEAM_T && is_user_alive(i) && is_user_connected(i)){
           new new_m = cs_get_user_money(i) + mon
           cs_set_user_money(i,new_m)
        }
    }
}
public KillAllT(){
    new playernums = get_maxplayers()
    for (new i = 1; i < playernums; i++){
        if(is_user_bot(i))continue
        if(get_user_team(i)==CS_TEAM_T && is_user_alive(i) && is_user_connected(i)){
            user_kill(i, 1)
        }
    }
}

public FaildSound(){
    new soundnum = random_num(RiBenWin,RiBenWin2)
    EmitSoundToall( Jp_EndRoundSound[soundnum])
    Setleavel(judian_leavel - 1)
}

public WinSound(){
    new Rand[2] = {EndJudian , ChineseWin}
    new Emit = Rand[random_num(0,1)]
    EmitSoundToall( Jp_EndRoundSound[Emit])
    Setleavel(judian_leavel + 1)
}

public EmitSoundToall(Sound[]){
    
    for(new i = 0 ; i < MAX_PLAYERS;i++){
        if(!is_valid_ent(i) || ! is_user_connected(i)){
            continue
        }
        client_cmd(i, "spk %s", Sound)
    }
}

public CreateNpcSpawnPonit(Npcbody, Float:origins[3], Float:angles[3]){
    new newent = rg_create_entity("info_target")
    if(!newent || !is_valid_ent(newent))
        return
    
    set_entvar(newent , var_classname , "riben_respawnponit")
    set_entvar(newent,  var_solid, SOLID_NOT)
    set_entvar(newent , var_movetype, MOVETYPE_FLY)
    set_entvar(newent, var_body, Npcbody)
    set_entvar(newent , var_angles , angles)
    set_entvar(newent , var_origin , origins)
    set_entvar(newent, var_effects , EF_NODRAW)
    set_entvar(newent , var_nextthink, get_gametime()+ 0.05)

    SetThink(newent,"Npc_SpawnThink")
}

public CanSpawn(){
    if(CanSpawnNum > 0){
        return true
    }
    return false
}

public NPC_Killed(this , killer){
    if(KrGetFakeTeam(this) != CS_TEAM_T){
        CurrentNpcs--
        ReSpawnEnt(this)
        if(CurrentNpcs == 0 && GetJuDianNum() <= 7){
            set_task(3.0 , "ChangeJudian")
        }else if(CurrentNpcs <= 0 && GetJuDianNum() == 8){
            set_task(0.1 , "ChangeJudian")
        }
        new lv = Current_judian
        switch(lv){
            case 0 .. 5 : AddKillRiMin(killer)
            case 6 , 7 : AddKillRiBing(killer)
        }
        if(!is_tank(this)){
            AddKillRiBenJunGuan(killer)
            return
        }
    }
}

public ChangeJudian(){
    Current_judian ++
    ExecuteForward(call_forwards[kr_On_judian_Change_Post], _ , Current_judian)
    new iEntity = -1
    while ((iEntity = rg_find_ent_by_class(iEntity, "hostage_entity")) > 0){
        if(KrGetFakeTeam(iEntity) == CS_TEAM_CT)
            rg_remove_entity(iEntity)
    }//移除上个据点npc
    set_hudmessage(255,255,0,-1.0,-1.0,2,3.0,6.0)
    switch(GetJuDianNum()){
        case 1 .. 7:{
            CurrentNpcs = GetCurrentJuDianMaxSpawn()
            CanSpawnNum = CurrentNpcs
            GiveMoney(3000)
            EmitSoundToall(Jp_EndRoundSound[Type])
            ChangeFakeName(Current_judian)
            show_hudmessage(0,"干得好成功攻占日军据点^n每人奖励军饷3000!")
            HanJianSpawn()
            return
        }
        case 8 :{
            CanSpawnNum = SpawnPonitNpcNum[Current_judian]
            CurrentNpcs = SpawnPonitNpcNum[Current_judian]
            GiveMoney(8000)
            EmitSoundToall(Jp_EndRoundSound[random_num(JudianGo,JudianGo2)])
            ChangeFakeName(Current_judian)
            show_hudmessage(0,"为了胜利冲啊！！！！^n每人不惜代价奖励军饷6000!^n冲锋！！！")
            HanJianSpawn()
            return
        }
    }
    //据点全部攻破结算
    server_cmd("endround 1")
}

public HanJianSpawn(){
    new playersnum = get_maxplayers()
    for(new i = 1 ; i < playersnum ; i++){
        if(is_user_connected(i) && cs_get_user_team(i) == CS_TEAM_CT && !is_user_bot(i)){
            ExecuteHamB(Ham_CS_RoundRespawn , i)
        }
    }
}

public HanJianRePonit(id){
    new ent = -1
    while ((ent = rg_find_ent_by_class(ent , "riben_respawnponit")) > 0){
        if(GetJuDianNum() == get_entvar(ent ,var_body)){
            new Float:Origin[3]
            get_entvar(ent , var_origin,Origin)
            Origin[2] += 90.0
            set_entvar(id, var_origin , Origin)
            break
        }
    }
}

stock isDeadNpc(Npcid){
    if(is_nullent(Npcid) || GetIsNpc(Npcid) == false)
        return true
    if(get_entvar(Npcid, var_deadflag) == DEAD_DEAD || get_entvar(Npcid , var_health) <= 0.0){
        return true
    }
    return false
}

public Npc_SpawnThink(ent){
    new body = get_entvar(ent,var_body)
    new ownerid = get_entvar(ent , var_Spawnid)
    new Float:Origin[3],Float:Angles[3]
    new spawnent , CurrentSpawnbody
    get_entvar(ent , var_origin,Origin)
    get_entvar(ent , var_angles, Angles)
    CurrentSpawnbody = Current_judian + 1
    new TrueJudian = min(Current_judian , 7)
    new lastnpc = get_entvar(ent , var_Spawnid)
    if(!CanSpawn()){
        set_entvar(ent , var_nextthink, get_gametime() + 0.5)
        return
    }
    if (ownerid && isDeadNpc(ownerid)) {
        ownerid = 0
        set_entvar(ent, var_Spawnid, 0)
    }
    if(ownerid){
        set_entvar(ent , var_nextthink, get_gametime() + 0.05)
        return
    }
    if(body != CurrentSpawnbody && !DontHasOtherJudian[TrueJudian]){
        //如果当前据点没有其他据点则不生成
        set_entvar(ent , var_nextthink, get_gametime() + 0.05)
        return
    }
    //初始化
    new bool:isOccupied = IsSpawnPointOccupied(Origin, ent)
    if(isOccupied){
        //尝试往高处生产
        Origin[2] += 75.0
        isOccupied = IsSpawnPointOccupied(Origin, ent)
    }
    if(body == CurrentSpawnbody && !isOccupied){
        spawnent = CreateJpNpc(0,CS_TEAM_CT, Origin, Angles, CurrentSpawnbody)
    }
    //如果不存在其他据点默认使用据点一的位置进行生成！
    else if(DontHasOtherJudian[TrueJudian] && body == 1 && !isOccupied){
        spawnent = CreateJpNpc(0,CS_TEAM_CT, Origin ,Angles, CurrentSpawnbody)
    }
    if(spawnent > 0){
        Set_Master(spawnent , ent)
        if(GetRiJunRule() == JAP_RULE_Physical_Enhancement){
            new Float:Heal = get_entvar(spawnent , var_health)//体魄强化
            Heal +=  30.0
            set_entvar(spawnent , var_health , Heal)
            set_entvar(spawnent , var_max_health , Heal)
        }
        set_entvar(ent, var_Spawnid, spawnent)
        set_entvar(ent , var_nextthink, get_gametime() + 0.05)
        CanSpawnNum--
        return
    }
    set_entvar(ent , var_nextthink, get_gametime() + 0.2)
    return
}

ReSpawnEnt(jpid){
    new Float:Origin[3]
    new owner = Get_Master(jpid)
    if(owner <= 0 || !CanSpawn()){
        rg_remove_entity(jpid)
        return
    }
    get_entvar(owner , var_origin , Origin)
    new bool:isOccupied = IsSpawnPointOccupied(Origin, owner)
    if(isOccupied){
        //尝试往高处生产
        Origin[2] += 75.0
        isOccupied = IsSpawnPointOccupied(Origin, owner)
        if(isOccupied){
            rg_remove_entity(jpid)
            return
        }
    }
    ReSpawnJpNpc(jpid , Origin)
    CanSpawnNum--
}

public NPC_ThinkPre(id){
    if(get_gametime() < ProectPlayerTime){
        return PLUGIN_HANDLED
    }
    return 0
}

//仅做伤害记录
public Npc_OnDamagePost(this,attacker,Float:Damage){
    static PlayerDamgeInc[33]
    if(is_valid_ent(attacker) && is_user_alive(attacker)){
        new Float:New_Damage = floatmin(Damage, 20000.0) //禁止伤害非常高的逆天万一

        TakeDamge[attacker] += New_Damage
        XpDamage[attacker] += New_Damage
        new lv = Getleavel()
        static AddxpBase = 1
        if( lv < 90){
            AddxpBase = 1
            lvadd = (Getleavel() / 10)  * AddxpBase
        }else if(lv < 500){
            AddxpBase = 4
            lvadd = (Getleavel() / 10)  * AddxpBase
        }else if(lv < 999){
             AddxpBase = 6
             lvadd = (Getleavel() / 10)  * AddxpBase
        }else if(lv >= 1000){
            AddxpBase = 8
            lvadd = (Getleavel() / 10)  * AddxpBase
        }

        if(XpDamage[attacker] >= 1000.0){
            new daminc = floatround(XpDamage[attacker]) / 1000
            new RealAddxp = 3 + lvadd
            RealAddxp *= daminc
            RealAddxp *= floatround(GetPlayerMul(attacker))
            XpDamage[attacker] -= float(daminc) * 1000.0
            AddXp(attacker, RealAddxp)
            AddAmmoPak(attacker, 0.01 * float(daminc))
            PlayerDamgeInc[attacker] += daminc
            if(PlayerDamgeInc[attacker] >= 20){
                AddXp(attacker , 100)
                PlayerDamgeInc[attacker] = 0
                m_print_color(attacker , "!g[积分奖励]!t您达到积分奖励条件奖励100积分")
            }
        }
    }
}

public native_GetJuDianNum(){
    return Current_judian + 1
}

public native_GetCurrentNpcs(){
    return CurrentNpcs
}

public native_Getleavel(){
    return judian_leavel
}

public native_Setleavel(){
    new Maxlv = get_cvar_num("Kr_MaxLv")
    new SetLv = get_param(1)
    if(get_param(1) > Maxlv){
        judian_leavel = Maxlv
    }else{
        judian_leavel = SetLv
    }
    
    ExecuteForward(call_forwards[kr_OnLevelChange_Post],_,judian_leavel)
    //加时间
    new timer = get_member_game(m_iRoundTime)
    timer += Getleavel() * 15
    set_member_game(m_iRoundTime, timer)
}


public GetCurrentJuDianMaxSpawn(){
    new TrueJudian = min(Current_judian , 7)
    new level = judian_leavel
    if(judian_leavel < 0){
        level = 0
    }
    new c_NpcNum_level = SpawnPonitNpcNum[TrueJudian]
    c_NpcNum_level = c_NpcNum_level + (c_NpcNum_level * level) / 2
    c_NpcNum_level = min(c_NpcNum_level , 32000)
    if(GetRiJunRule() == JAP_RULE_Japanese_Mobilization){
        c_NpcNum_level = floatround(float(c_NpcNum_level) * 1.20)
    }
    return c_NpcNum_level
}


public ShowPlayerInfo(id){
    if(!is_user_connected(id))
        return
    new name[32], LvName_[32]
    new showid = 0
    new lv = GetLv(id)
    copy(LvName_,31,LvName[min(lv/50,14-1)])
    get_user_name(id, name,31)
    set_hudmessage(0, 255, 255, 0.8, 0.75, 1,_, 5.0, 1.0, 1.0, 1)
    if(!FirstShow[id])
        showid = id
    show_hudmessage(showid, "%s %s 登场^n积分%d 等级%d^n还差%d积分就可以升到%d等级^n\
    杀日民:%d 杀日兵:%d 杀日官:%d^n摧毁坦克:%d", 
    LvName_, name, GetXp(id), GetLv(id),GetXpNeed(id) - GetXp(id),GetLv(id)+1,
    GetKillRiMin(id),GetKillRiBing(id),GetKillRiBenJunGuan(id),GetKillTank(id)
    )
    FirstShow[id] = false
}

/**
 * 使用 TraceHull 判断一个位置是否被碰撞盒占据。
 * @param origin 要检查的位置（通常是实体的脚部中心）。
 * @return 如果位置被任何固体（地图或实体）占用，返回 true；否则返回 false。
 */
stock bool:IsSpawnPointOccupied(const Float:origin[3] , pentToSkip)
{   
    new tr = create_tr2()
    static Float:CheckPoint[3]
    static Float:CheckPoint2[3]
    xs_vec_copy(origin, CheckPoint)
    xs_vec_copy(origin, CheckPoint2)
    CheckPoint2[2] -= 50.0
    CheckPoint[2] += 60.0
    engfunc(EngFunc_TraceHull, CheckPoint, CheckPoint2, DONT_IGNORE_MONSTERS, HULL_HUMAN, pentToSkip, tr)
    new Float:TR_flFractions
    new touchent
    if(get_tr2(tr , TR_AllSolid) || get_tr2(tr, TR_StartSolid) || !get_tr2(tr, TR_InOpen)){
        free_tr2(tr)
        return true
    }
    get_tr2(tr,TR_flFraction, TR_flFractions)
    touchent = get_tr2(tr , TR_pHit)
    if(TR_flFractions < 1.0){
        if(touchent < 0){
            free_tr2(tr)
            return false
        }
        new flags = get_entvar(touchent, var_flags)
        if(flags & FL_MONSTER || flags & FL_CLIENT){
            free_tr2(tr)
            return true
        }
        if(GetIsNpc(touchent) == true){
            free_tr2(tr)
            return true
        }
        free_tr2(tr)
        return false
    }
    free_tr2(tr)
    return false
}

stock CheckStuck(iEntity, Float:fMin[3], Float:fMax[3])
{
    new Float:testorigin[3]
    get_entvar(iEntity, var_origin, testorigin) // 获取实体的原点（通常是脚底中心）

    new Float:Origin_F[3], Float:Origin_R[3], Float:Origin_L[3], Float:Origin_B[3]
    xs_vec_copy(testorigin, Origin_L) ; xs_vec_copy(testorigin, Origin_F)
    xs_vec_copy(testorigin, Origin_B) ; xs_vec_copy(testorigin, Origin_R)

    // 基于实体的原点和提供的碰撞盒边缘，计算四个方向上的点
    // 注意：fMax[0] 对应 X 轴正向，fMin[0] 对应 X 轴负向
    // fMax[1] 对应 Y 轴正向，fMin[1] 对应 Y 轴负向
    Origin_F[0] += fMax[0] // 前 (X轴正向)
    Origin_B[0] += fMin[0] // 后 (X轴负向)
    Origin_L[1] += fMax[1] // 左 (Y轴正向)
    Origin_R[1] += fMin[1] // 右 (Y轴负向)

    // 检查这四个点的内容
    if(engfunc(EngFunc_PointContents, Origin_F) != CONTENTS_EMPTY ||
       engfunc(EngFunc_PointContents, Origin_R) != CONTENTS_EMPTY ||
       engfunc(EngFunc_PointContents, Origin_L) != CONTENTS_EMPTY ||
       engfunc(EngFunc_PointContents, Origin_B) != CONTENTS_EMPTY)
    {
        return 0 // 如果任何一个点不是空的（即被实体或地图占据），返回 0（卡住）
    }

    return 1 // 如果所有四个点都是空的，返回 1（没有卡住）
}

stock remove_weaponbox_pakitem(boxid){
    for(new i = 0 ; i < 6; i++){
        new Items = get_member(boxid, m_WeaponBox_rgpPlayerItems, i)
        if(Items != -1){
            rg_remove_entity(Items)
        }
    }
}

stock fm_set_kvd(entity, const key[], const value[], const classname[] = "") {
	if (classname[0])
		set_kvd(0, KV_ClassName, classname);
	else {
		new class[32];
		pev(entity, pev_classname, class, sizeof class - 1);
		set_kvd(0, KV_ClassName, class);
	}

	set_kvd(0, KV_KeyName, key);
	set_kvd(0, KV_Value, value);
	set_kvd(0, KV_fHandled, 0);

	return dllfunc(DLLFunc_KeyValue, entity, 0);
}