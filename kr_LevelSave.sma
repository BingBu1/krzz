#include <amxmodx>
#include <kr_core>
#include <json>
#include <reapi>

new RoundNums , IsNeedCheck
new IsLoad
new Float:StartRoundTime
public plugin_init(){
    register_plugin("难度存档" , "1.0" , "Bing")
    register_logevent("EventRoundEnd", 2, "1=Round_End")
    register_event("HLTV", "event_roundstart", "a", "1=0", "2=0")

    register_clcmd("kr_CheckLv" , "Check")
}


public client_disconnected(id , bool:drop){
    new nums = get_playersnum()
    if(nums == 0)
        IsLoad = false
}

public plugin_end(){
    if(IsLoad){
        SaveLv_Json()
    }
}

public Check(id){
    new SubRoundText[20]
    if(IsNeedCheck){
        num_to_str(20 - RoundNums , SubRoundText , charsmax(SubRoundText))
    }else{
        copy(SubRoundText , charsmax(SubRoundText) , "无限制")
    }
    
    new lv = Getleavel()
    m_print_color(0 , "!g[冰布提示]!y当前难度为:!t%d , !y当!t%s!y回合后掉!t%d!y难度" , lv ,
        SubRoundText , (IsNeedCheck ? LevelSubGet() : 0)
    )
}


public OnLevelChange_Post(Lv){
    if(Lv > 100)
        IsNeedCheck = true
    else
        IsNeedCheck = false

    if(!IsNeedCheck)
        return
    if(!SaveLv_Json())
        log_amx("存档难度失败。")
}

public event_roundstart(){
    if(!IsLoad){
        LoadLv_Json()
        IsLoad = true
    }
    new lv = Getleavel()
    StartRoundTime = get_gametime()
    if(lv > 50){
        IsNeedCheck = true
    }
    if(RoundNums <= 20 || !IsNeedCheck)
        return
    if(lv < 50)
        return
    new SubLvNum = LevelSubGet()
    Setleavel(lv - SubLvNum)
    RoundNums = 0
}

public EventRoundEnd(){
    if(!IsNeedCheck || !IsLoad)
        return
    if(get_gametime() - StartRoundTime < 60.0)
        return
    RoundNums++
    SaveLv_Json()
}

public bool:SaveLv_Json(){
    new ConfigPath[256]
    GetSavePath(ConfigPath , charsmax(ConfigPath))
    new JSON:jsonRoot = json_init_object()
    json_object_set_number(jsonRoot , "Level" , Getleavel())
    json_object_set_number(jsonRoot , "Rounds" , RoundNums)

    new bool:result = json_serial_to_file(jsonRoot, ConfigPath, true)
    json_free(jsonRoot)
    log_amx("LevelSaveing Lv %d round %d" , Getleavel() , RoundNums)
    return result
}

public LoadLv_Json(){
    new ConfigPath[256]
    GetSavePath(ConfigPath , charsmax(ConfigPath))
    new JSON:jsonRoot = json_parse(ConfigPath, true)
    if(jsonRoot == Invalid_JSON){
        json_free(jsonRoot)
        log_amx("读取存档失败，可能是第一次运行")
        return
    }
    new lv = json_object_get_number(jsonRoot, "Level")
    RoundNums = json_object_get_number(jsonRoot, "Rounds")
    Setleavel(lv)
    json_free(jsonRoot)
}

stock GetSavePath(path[] , len){
    new ConfigPath[256]
    get_localinfo("amxx_configsdir", ConfigPath, charsmax(ConfigPath))
    add(ConfigPath, charsmax(ConfigPath), "/LevelSave")
    if (!dir_exists(ConfigPath))
        mkdir(ConfigPath)
    formatex(path , len , "%s/SaveJson.json" , ConfigPath)
}

stock LevelSubGet(){
    new lv = Getleavel()
    if(lv >= 100 && lv < 200){
        return lv
    }
    else if(lv >= 200 && lv < 500){
        return 200
    }
    else if(lv >= 500 && lv < 800){
        return 300
    }
    else if(lv >= 800 && lv <= 1300){
        return 400
    }else if(lv > 1300){
        return Getleavel()
    }
    return 0
}