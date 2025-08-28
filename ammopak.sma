#include <amxmodx>
#include <reapi>
#include <kr_core>
#include <props>
#include <fakemeta>
#include <sqlx>
#include <xp_module>
#define task_id 19190
new bool:IsSqlLoad

new Handle:g_SqlTuple

new Handle:g_SqlConnection

new Float:AmmoPak[33],IsLoad[33]
new bool:FirstInit[33]

public plugin_init(){
	register_plugin("弹药袋系统", "1.0", "Bing")

    register_concmd("Kr_AmmoAdd" , "AddAmmoAdmin" , ADMIN_RCON)
}

public AddAmmoAdmin(id, level, cid){
    if (read_argc() < 3){
        server_print("参数<id><ammo>");
        return PLUGIN_HANDLED
    }
    new pl_id = read_argv_int(1)
    new Float:addammo = read_argv_float(2)
    AddAmmoPak(pl_id , addammo)
}

public SqlInitOk(Handle:sqlHandle, Handle:ConnectHandle){
    g_SqlTuple = sqlHandle
    g_SqlConnection = ConnectHandle
    log_amx("弹药袋回调初始化数据库成功")
    IsSqlLoad = true
}

public plugin_natives(){
    register_native("AddAmmoPak", "native_AddAmmoPak")
    register_native("GetAmmoPak", "native_GetAmmoPak")
    register_native("SaveAmmo", "native_SaveAmmo")
    register_native("SetAmmo", "native_SetAmmo")
}

public client_putinserver(id){
    if(is_user_bot(id) || !IsSqlLoad)
        return
    QueryPlayerAmmo(id)
}

public client_disconnected(id){
    if(is_user_bot(id) || !IsLoad[id] || !IsSqlLoad){
        return
    }
    new username[32]
    get_user_name(id,username,charsmax(username))
    log_amx("%s玩家退出服务器，自动保存弹药袋数据。",username)
    SaveAmmo(id)

    AmmoPak[id] = 0.0
    IsLoad[id] = false
    FirstInit[id] = false
}

public QueryPlayerAmmo(id){
    new steamid[32],query[256],data[1]
    data[0] = id
    get_user_authid(id, steamid, charsmax(steamid))
    log_amx("玩家加入开始查询弹药袋。steamid : %s",steamid)
    formatex(query, charsmax(query),
    "SELECT steamid, pakammo \
    FROM ammopaks WHERE steamid = '%s'",
    steamid)
    SQL_ThreadQuery(g_SqlTuple, "OnQueryPlayerAmmo", query, data ,sizeof data)
}

public OnQueryPlayerAmmo(FailState,Handle:Query,Error[],Errcode,Data[],DataSize){
    if(FailState == TQUERY_CONNECT_FAILED){
        log_amx("链接数据库失败 [%d] %s", Errcode, Error)
    }
    else if(FailState == TQUERY_QUERY_FAILED){
        log_amx("查询失败 [%d] %s", Errcode, Error)
    }
    new id = Data[0]
    new steamid[32],name[32],querystr[256]
    if (is_user_connected(id) == false){
        return
    }
    get_user_authid(id, steamid, charsmax(steamid))
    get_user_name(id,name,charsmax(name))
    if(!SQL_NumResults(Query)){
        log_amx("%s不存在数据开始初始化 id : %s", name,steamid)
        formatex(querystr,charsmax(querystr),"INSERT INTO ammopaks (steamid,pakammo)\
        VALUES ('%s', 0.0)", steamid)
        SQL_ThreadQuery(g_SqlTuple, "OnInsertComplete", querystr, Data ,DataSize)
    }else{
        new flaot_string[32]
        SQL_ReadResult(Query , 1 ,flaot_string,charsmax(flaot_string))
        AmmoPak[id] = str_to_float(flaot_string)
        IsLoad[id] = true
        log_amx("加载成功: %s 弹药余额%.2f", steamid, AmmoPak[id])
        if(FirstInit[id] == true){
            set_task(3.0, "GiveAmmoFirst", id + 1000,.flags = "b")
        }
    }
}
public GiveAmmoFirst(ids){
    new id = ids - 1000
    if(FirstInit[id] == true && is_user_connected(id) && is_user_alive(id)){
        new name[32]
        get_user_name(id , name , 31)
        m_print_color(0, "!g[欢迎仪式] !y欢迎新玩家【%s】进入服务器，新玩家默认赠送1000大洋",
        name)
        AddAmmoPak(id , 1000.0)
        SaveAmmo(id)
        remove_task(ids)
    }
}
public OnInsertComplete(FailState,Handle:Query,Error[],Errcode,Data[],DataSize){
    new id = Data[0];
    log_amx("玩家数据初始化完成，开始重新查询弹药袋数据");
    
    // 重新查询，获取刚插入的数据
    FirstInit[id] = true
    new steamid[32];
    get_user_authid(id, steamid, charsmax(steamid));
    
    new querystr[256];
    formatex(querystr, charsmax(querystr),
    "SELECT steamid, pakammo \
    FROM ammopaks WHERE steamid = '%s'",
    steamid)
    
    SQL_ThreadQuery(g_SqlTuple, "OnQueryPlayerAmmo", querystr, Data, DataSize);
}

public native_AddAmmoPak(pl_id, num){
    if(!IsSqlLoad)
        return
    new id = get_param(1)
    new Float:amount = get_param(2)
    if(!is_user_connected(id))
        return
    AmmoPak[id] += amount
}

public native_GetAmmoPak(pl_id, num){
    if(!IsSqlLoad)
        return 0.0
    new id = get_param(1)
    if(!is_user_connected(id))
        return 0.0
    return AmmoPak[id]
}


public native_SaveAmmo(pl_id, num){
    if(!IsSqlLoad)
        return
    new data[1]
    data[0] = get_param(1)
    new id = get_param(1)
    new steamid[32],querystr[256]
    if(!is_user_alive(id))
        return
    get_user_authid(id, steamid, charsmax(steamid))

    formatex(querystr , charsmax(querystr) , "UPDATE ammopaks SET pakammo = %f WHERE steamid = '%s'" , AmmoPak[id] , steamid)

    SQL_ThreadQuery(g_SqlTuple,"PlayerUpdate",querystr,data,sizeof data)
}

public native_SetAmmo(pl_id, num){
    if(!IsSqlLoad)
        return
    new id = get_param(1)
    new Float:amount = get_param(2)
    if(!is_user_alive(id))
        return
    AmmoPak[id] = amount
}

public PlayerUpdate(FailState,Handle:Query,Error[],Errcode,Data[],DataSize){
    if(FailState == TQUERY_QUERY_FAILED)
    {
        log_amx("更新玩家数据失败 [%d] %s", Errcode, Error)
        SQL_FreeHandle(Query)
        return
    }

    client_print_color(Data[0],print_chat,"[^3冰布]^1保存大洋数据成功。")
}
