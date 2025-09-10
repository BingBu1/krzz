#include <amxmodx>
#include <reapi>
#include <kr_core>
#include <props>
#include <fakemeta>
#include <sqlx>
#include <xp_module>
#include <bigint>

#define XpKey "%d_XP"
#define XpNeedKey "%d_XPNeed"

new bool:PlayerLoad[33]
new PlayerXp[33],PlayerLeavl[33],PlayerXpNeeded[33]
new k_civilian[33],k_soldier[33],k_officer[33],k_tank[33]
new Handle:g_SqlTuple
new Handle:g_SqlConnection
new IsSqlLoad
#define defaultXp 10
#define MaxXp 10000
public plugin_init(){
	register_plugin("Xp系统抗日", "1.0", "Bing")
    register_concmd("AddLv" , "AddPlayerLv")
    //SqlInit()
}

public AddPlayerLv(){
    new argc = read_argc()
    if(argc >= 2){
        static NeedxpStr[50]
        new ent = read_argv_int(1)
        new buff[20]
        GetXpNeedKey(ent , buff , 19)
        GetNextLevelXpBigInt(ent , NeedxpStr , charsmax(NeedxpStr))
        MapGetNums("Lv" , NeedxpStr , 49)
        log_amx("计算为%s" , NeedxpStr)
    }
        
}

public SqlInitOk(Handle:sqlHandle, Handle:ConnectHandle){
    g_SqlTuple = sqlHandle
    g_SqlConnection = ConnectHandle
    log_amx("回调初始化数据库成功")
    IsSqlLoad = true
}

public client_disconnected(id){
    if(PlayerLoad[id]){
        new username[32]
        get_user_name(id,username,charsmax(username))
        SavePlayer(id)
        log_amx("%s玩家退出服务器，自动保存数据。Lv:%d",username,PlayerLeavl[id])
    }
    PlayerXp[id] = 0
    PlayerLeavl[id] = 0
    PlayerXpNeeded[id] = 0
    k_civilian[id] = 0
    k_soldier[id]=0
    k_officer[id]=0
    k_tank[id]=0
    PlayerLoad[id] = false
}

public client_putinserver(id){
    if(is_user_bot(id) || !IsSqlLoad)
        return
    QueryPlayerInfo(id)
}

public QueryPlayerInfo(id){
    new steamid[32],query[256],data[1]
    data[0] = id
    get_user_authid(id, steamid, charsmax(steamid))
    log_amx("玩家加入开始查询。steamid : %s",steamid)
    formatex(query, charsmax(query),
    "SELECT steamid, userlevel, current_xp, xp_needed, \
    kills_civilian, kills_soldier, kills_officer, kills_tank \
    FROM xp_table WHERE steamid = '%s'",
    steamid)
    SQL_ThreadQuery(g_SqlTuple, "OnQueryPlayerInfo", query, data ,sizeof data)
}

// 插入完成后的回调
public OnInsertComplete(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
    new id = Data[0];
    log_amx("玩家数据初始化完成，开始重新查询");

    // 重新查询，获取刚插入的数据
    new steamid[32];
    get_user_authid(id, steamid, charsmax(steamid));

    new querystr[256];
    formatex(querystr, charsmax(querystr),
    "SELECT steamid, userlevel, current_xp, xp_needed, \
    kills_civilian, kills_soldier, kills_officer, kills_tank \
    FROM xp_table WHERE steamid = '%s'",
    steamid)

    SQL_ThreadQuery(g_SqlTuple, "OnQueryPlayerInfo", querystr, Data, DataSize);
}

public OnQueryPlayerInfo(FailState,Handle:Query,Error[],Errcode,Data[],DataSize){
    if(FailState == TQUERY_CONNECT_FAILED)
    {
        log_amx("链接数据库失败 [%d] %s", Errcode, Error)
    }
    else if(FailState == TQUERY_QUERY_FAILED)
    {
        log_amx("查询失败 [%d] %s", Errcode, Error)
    }
    new id = Data[0]
    new steamid[32],name[32],querystr[256]
    get_user_authid(id, steamid, charsmax(steamid))
    get_user_name(id,name,charsmax(name))
    if(!SQL_NumResults(Query)){
        log_amx("%s不存在数据开始初始化 id : %s", name,steamid)
        formatex(querystr, charsmax(querystr),
        "INSERT INTO xp_table (steamid, userlevel, current_xp, xp_needed, total_xp)\
        VALUES ('%s', 1, 0, 10, 0)",
        steamid)
        SQL_ThreadQuery(g_SqlTuple, "OnInsertComplete", querystr, Data ,DataSize)
    }else{
        new steamid[32] , BigXp[32], XpNeeded[32] , Keys[32]
        SQL_ReadResult(Query,0,steamid,charsmax(steamid))

        PlayerLeavl[id] = SQL_ReadResult(Query,1)
        PlayerXp[id] = SQL_ReadResult(Query,2)
        PlayerXpNeeded[id] = SQL_ReadResult(Query,3)
        k_civilian[id]       = SQL_ReadResult(Query, 4)
        k_soldier[id]        = SQL_ReadResult(Query, 5)
        k_officer[id]        = SQL_ReadResult(Query, 6)
        k_tank[id]           = SQL_ReadResult(Query, 7)

        SQL_ReadResult(Query,2,BigXp,charsmax(BigXp))
        SQL_ReadResult(Query,3,XpNeeded,charsmax(XpNeeded)) 

        PlayerLoad[id] = true

        formatex(Keys , charsmax(Keys) , XpKey , id)
        InitByMap(Keys , BigXp)
        formatex(Keys , charsmax(Keys) , XpNeedKey , id)
        InitByMap(Keys , XpNeeded)
        log_amx("%s 大数加载测试Xp %s Need %s" , steamid , BigXp , XpNeeded)
        log_amx("加载成功: %s 等级: %d XP: %d/%d", steamid, PlayerLeavl[id], PlayerXp[id], PlayerXpNeeded[id])
    }
}

public IgnoreHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize){
    SQL_FreeHandle(Query)
    return PLUGIN_HANDLED
}

public plugin_natives(){
    register_native("GetXpNeed","native_GetXpNeed")
    register_native("GetLv","native_GetLv")
    register_native("GetXp","native_GetXp")
    register_native("GetXpBingInt","native_GetXp2")
    register_native("GetXpNeedBingInt","native_GetXpNeed2")
    register_native("AddXp","native_AddXp")

    register_native("AddKillRiMin","native_AddKillRiMin")
    register_native("AddKillRiBenJunGuan","native_AddKillRiBenJunGuan")
    register_native("AddKillRiBing","native_AddKillRiBing")
    register_native("AddKillTank","native_AddKillTank")

    register_native("GetKillRiMin","native_GetKillRiMin")
    register_native("GetKillRiBenJunGuan","native_GetKillRiBenJunGuan")
    register_native("GetKillRiBing","native_GetKillRiBing")
    register_native("GetKillTank","native_GetKillTank")

    register_native("SavePlayer","native_SavePlayer")
    
    register_native("GetSqlHandle","native_GetSqlHandle")
    register_native("GetSqlConnection","native_GetSqlConnection")
    register_native("GetIsSqlLoad", "native_IsSqlLoad")
}

public native_IsSqlLoad(id,nums){
    return IsSqlLoad
}

public native_GetSqlConnection(id,nums){
    return g_SqlConnection
}

public native_GetSqlHandle(id,nums){
    return g_SqlTuple
}

public GetNextLevelNeedXp(ent){
    new Lv = PlayerLeavl[ent]
    return (defaultXp * Lv * Lv)
}

stock GetNextLevelXpBigInt(ent , value[] , len){
    static bool:IsInit
    if(!IsInit){
        InitByMap("Lv" , "0")
    }
    MapSetValue("Lv" , 10)
    new Lv = PlayerLeavl[ent]
    new BaseMul = Lv * Lv
    MapValueMulSave("Lv" , BaseMul)
    MapGetNums("Lv" , value , len)
}

public CheckXpCanUp(ent){
    new xpkey[10] , xpneedkey[10]
    GetXpNeedKey(ent , xpneedkey, 9)
    GetXpKey(ent , xpkey, 9)
    if(MapCmpByChars(xpkey , xpneedkey , ">=")){
        PlayerLeavl[ent]++
        MapValueSubSaveByKey(xpkey , xpneedkey) //减去
        static NeedxpStr[50]
        GetNextLevelXpBigInt(ent , NeedxpStr , charsmax(NeedxpStr))
        MapSetValueByStr(xpneedkey , NeedxpStr)
    }
    // new xp = PlayerXp[ent]
    // new xpneed = PlayerXpNeeded[ent]
    // if(xp >= xpneed){
    //     PlayerLeavl[ent]++
    //     PlayerXp[ent] = xp - xpneed
    //     PlayerXpNeeded[ent] = GetNextLevelNeedXp(ent)
    //     if(PlayerXp[ent] >= PlayerXpNeeded[ent]){
    //         //如果经验依然溢出递归
    //         CheckXpCanUp(ent)
    //     }
    // }
}

public native_GetXpNeed(id,nums){
    new ent = get_param(1)
    return PlayerXpNeeded[ent]
}

public native_GetXp2(id,nums){
    new ent = get_param(1)
    new len = get_param(3)
    new buff[20]
    static OutPut[50]
    GetXpKey(ent ,buff , charsmax(buff))
    MapGetNums(buff , OutPut , 49)
    set_string(2, OutPut , len)
}

public native_GetXpNeed2(id,nums){
    new ent = get_param(1)
    new len = get_param(3)
    new buff[20]
    static OutPut[50]
    GetXpNeedKey(ent ,buff , charsmax(buff))
    MapGetNums(buff , OutPut , 49)
    set_string(2, OutPut , len)
}

public native_GetLv(id,nums){
    new ent = get_param(1)
    return PlayerLeavl[ent]
}

public native_GetXp(id,num){
    new ent = get_param(1)
    return PlayerXp[ent]
}

public native_AddXp(id,nums){
    new ent = get_param(1)
    new addxp = get_param(2)
    if(ent < 33 && is_user_connected(ent)){
        new key[10]
        GetXpKey(ent , key , 9)
        MapValueAddSave(key , addxp)
        PlayerXp[ent] += addxp
        CheckXpCanUp(ent)
    }
}

public native_AddKillRiMin(id,nums){
    new ent = get_param(1)
    k_civilian[ent]++
}

public native_AddKillRiBenJunGuan(id,nums){
    new ent = get_param(1)
    k_officer[ent]++
}

public native_AddKillRiBing(id,nums){
    new ent = get_param(1)
    k_soldier[ent]++
}

public native_AddKillTank(id,nums){
    new ent = get_param(1)
    k_tank[ent]++
}

public native_GetKillRiMin(id,nums){
    new ent = get_param(1)
    return k_civilian[ent]
}

public native_GetKillRiBenJunGuan(id,nums){
    new ent = get_param(1)
    return k_officer[ent]
}

public native_GetKillRiBing(id,nums){
    new ent = get_param(1)
    return k_soldier[ent]
}

public native_GetKillTank(id,nums){
    new ent = get_param(1)
    return k_tank[ent]
}

public native_SavePlayer(id,nums){
    new ent = get_param(1)
    new data[1]
    new querystr[255]
    new szSteamID[32]
    new key[10] , Xp[40], XpNeed[40]
    new fmtstr[]= "UPDATE xp_table SET userlevel = %d, current_xp = %s, xp_needed = %s, kills_civilian = %d, kills_soldier = %d, kills_officer = %d, kills_tank = %d WHERE steamid = '%s'"
    data[0] = ent
    get_user_authid(ent, szSteamID, charsmax(szSteamID))
    GetXpKey(ent , key , 9)
    MapGetNums(key , Xp , 39)
    GetXpNeedKey(ent , key , 9)
    MapGetNums(key , XpNeed , 39)
    // formatex(querystr, charsmax(querystr), fmtstr, PlayerLeavl[ent], PlayerXp[ent], PlayerXpNeeded[ent], k_civilian[ent], k_soldier[ent], k_officer[ent], k_tank[ent], szSteamID);
    formatex(querystr, charsmax(querystr), fmtstr, PlayerLeavl[ent], Xp, XpNeed, k_civilian[ent], k_soldier[ent], k_officer[ent], k_tank[ent], szSteamID);
    SQL_ThreadQuery(g_SqlTuple,"PlayerUpdate",querystr,data,sizeof data)
}

public PlayerUpdate(FailState,Handle:Query,Error[],Errcode,Data[],DataSize){
    if(FailState == TQUERY_QUERY_FAILED)
    {
        log_amx("更新玩家数据失败 [%d] %s", Errcode, Error)
        SQL_FreeHandle(Query)
        return
    }

    client_print_color(Data[0],print_chat,"[^3冰布]^1保存数据成功。")
}




stock GetXpKey(id , buff[] , len){
    formatex(buff , len , XpKey , id)   

}
stock GetXpNeedKey(id , buff[] , len){
    formatex(buff , len , XpNeedKey , id)   
}
