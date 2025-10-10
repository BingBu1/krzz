#include <amxmodx>
#include <amxmisc>
#include <kr_core>
#include <xp_module>
#include <easy_http>

#define Vip_Flags ADMIN_RESERVATION
new IsVip[33]
public plugin_init(){
    register_plugin("Vip管理模块" , "1.0" , "Bing")
}

public plugin_natives(){
    register_native("IsPlayerVip" , "native_IsPlayerVip")
}

public client_putinserver(id){
    if(is_user_bot(id))
        return
    VipBySteamid_Http(id)
}

public native_IsPlayerVip(){
    new id = get_param(1)
    if(access(id , Vip_Flags) || IsVip[id])
        return true
    return false
}

public VipBySteamid_Http(id){
    new Steamid [32]
    get_user_authid(id , Steamid , charsmax(Steamid))
    new Http[] = "http://127.0.0.1:8888/vip/%s"
    new PostHttp[255]
    new data[1]
    data[0] = id
    new EzHttpOptions:options = ezhttp_create_options()
    ezhttp_option_set_user_data(options , data , sizeof data)
    formatex(PostHttp , charsmax(PostHttp) , Http , Steamid)
    ezhttp_get(PostHttp , "VipStatusGet" , options)
}

public VipStatusGet(EzHttpRequest:request_id ){
    if(ezhttp_get_error_code(request_id) != EZH_OK){
        new error[64]
        ezhttp_get_error_message(request_id, error, charsmax(error))
        server_print("Vip请求失败 %s " , error);
        return
    }
    new req_data[512] , data[1]
    ezhttp_get_data(request_id , req_data , charsmax(req_data))
    ezhttp_get_user_data(request_id , data)
    server_print("Response data: %s , data is %d", req_data , data[0])
}
