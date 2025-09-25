#include <amxmodx>
#include <roundrule>
#include <kr_core>
#include <hamsandwich>
#include <engine>
#include <fakemeta_util>
#include <reapi>
#include <cstrike>
#include <xs>

#include <animation>
#include <xp_module>

new const HumanRule[][] = {
    "掷弹兵",
    "痛苦强化",
    "主武器精通",
    "副武器精通",
    "爆炸弹药",
    "随机武器",
    "英雄出现",
    "急行军",
    "跳跃精英",
    "最后一发",
    "吸血",
    "火焰净化",
    "无限火力",
    "幸运儿",
    "贫铀弹头",
    "尖刺护甲",
    "九命猫"
}

new const RiJunRule[][]={
    "日军:刺刀加长",
    "日军:体魄强化",
    "日军:日军动员",
    "日军:致命暴击",
    "日军:伤害减免",
    "日军:坦克狂潮",
    "日军:兴奋剂",
    "日军:自爆",
    "日军:致命节奏",
    "日军:殊死反击",
    "日军:玉碎冲锋"
}

new const HUNMAN_RULE_Text[][]= {
    "手雷伤害提升，并一次投掷出三颗",
    "血量低于70时伤害提升100%",
    "主武器伤害提升25%",
    "副武器5%概率秒杀敌人",
    "子弹概率发出爆炸伤害",
    "随机获取武器",
    "所有人成为英雄",
    "大幅度提升移速",
    "跳跃时伤害提升50%",
    "最后一发子弹打出核弹轰炸",
    "血量低于150时攻击可以吸血伤害的1%",
    "投掷手雷时将投掷出燃烧瓶",
    "武器无限弹夹无需换单",
    "砸枪生成枪械概率大幅度提升",
    "伤害无视防御10%,并可穿透9层墙体",
    "受到伤害时向周围造成伤害",
    "受到致死伤害时强制抵挡9次"
}

new const RIJUN_RULE_Text[][]= {
    "攻击距离提升",
    "血量提高30",
    "日军兵力提升20%",
    "日军攻击5%概率造成暴击",
    "日军受到伤害降低5%",
    "平常波次有概率生成坦克",
    "50%概率无法被武器打出控制",
    "死亡时10%概率自爆",
    "攻击速度变快",
    "血量低于50时伤害提高",
    "抵御一次致死并将血量提升为50",
}

new CurrentHunManRule = -1
new CurrentRiJunRule = -1

new HumManText[64]
new RiJunText[64]

new bool:RuleInitOk

new HookChain:HOOK_ThrowHeGrenade

new g_Explosion ,JpBoomSpr

new BuyNextRule

new NineLivesCat[33]

native CreateNade(const id, const item, const Float:vecSrc[3], const Float:vecThrow[3], const Float:time)
native CreateBlast(const id)

public plugin_init(){
    register_plugin("抗日随机规则", "1.0", "Bing")
    register_event("HLTV", "event_roundstart", "a", "1=0", "2=0")
    HOOK_ThrowHeGrenade = RegisterHookChain(RG_ThrowHeGrenade , "m_ThrowHeGrenade")
    RegisterHookChain(RG_CBasePlayer_ThrowGrenade, "CBasePlayer_ThrowGrenade_Pre", _:false);
    RegisterHookChain(RG_CBaseEntity_FireBullets3 , "m_FireBullets")
    RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed , "m_MaxSpeed")
    RegisterHam(Ham_TakeDamage, "hostage_entity" , "RULE_HostageTakeDamage")
    RegisterHam(Ham_TakeDamage, "player" , "RULE_PlayerTakeDamage")

    register_concmd("KR_ReRoundRule" , "RoundRule")
    register_clcmd("say /buyrule" , "CreateBuyNextRule")
}

public plugin_precache(){
    g_Explosion = precache_model("sprites/zerogxplode.spr")
    JpBoomSpr = precache_model("sprites/ef_zbs93boss_explo.spr")
}


public plugin_natives(){
    register_native("GetHunManRule", "native_GetHunManRule")
    register_native("GetRiJunRule", "native_GetRiJunRule")
    register_native("GetRuleAllText", "native_GetRuleAllText")
}


public event_roundstart(){
    RuleInitOk = false
    server_cmd("mp_infinite_ammo 0")
    RoundRule()
    new Human_Rules:Rule = GetHunManRule()
    if(Rule == HUMAN_RULE_Hero_Appearance){
        set_task(0.5, "AllHero")
    }else if (Rule == HUMAN_RULE_Random_Weapon){
        set_task(0.5, "RandomWeapon")
    }
    SpelicRule(Rule)
    arrayset(NineLivesCat , 0 , sizeof NineLivesCat)
}

stock SpelicRule(const any:Rule){
    switch(Rule){
        case HUMAN_RULE_InfAmmo : server_cmd("mp_infinite_ammo 1")
    }
}


public NPC_Killed( this ,  killer){
    new Rule = GetRiJunRule()
    if(Rule == JAP_RULE_Boom){
        if(UTIL_RandFloatEvents(0.1)){
            JpBoom(this)
        }
    }
}

public RandomWeapon(){
    new maxplayer = get_maxplayers()
    for(new i = 1 ; i < maxplayer ; i++){
        if(!is_user_connected(i) || !is_user_alive(i))
            continue
        if(UTIL_RandFloatEvents(0.5)){
            RandNorWpn(i)
        }else{
            RandCrashWeapon(i)
        }
    }
}

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

public RandNorWpn(const id){
    rg_give_item(id , WeaponNames[random_num(0,sizeof WeaponNames - 1)])
}

public RandCrashWeapon(const id){
    RandGiveWeapon(id)
}

public CreateBuyNextRule(const id){
    new menu = menu_create("购买下局规则" , "BuyRule")
    new const size = sizeof HumanRule
    new info[8] ,text[33]

    for(new i = 0 ; i < size ; i++){
        num_to_str(i , info , charsmax(info))
        formatex(text , charsmax(text) , "\r%s [10.0大洋]" , HumanRule[i])
        menu_additem(menu , text, info)
    }
    menu_display(id , menu)
}

public BuyRule(id , menu , item){
    if(!is_user_connected(id) || item == MENU_EXIT){
        menu_destroy(menu)
        return
    }
    new Float:ammo = GetAmmoPak(id)
    if(ammo < 10.0){
        m_print_color(id , "!g[提示]!y您的大洋不足")
        menu_destroy(menu)
        return
    }
    if(BuyNextRule > 0){
        m_print_color(id , "!g[提示]!y已有人购买了下一局的规则，不能重复购买。")
        menu_destroy(menu)
        return
    }
    new acc , info[8] , ruleid , name[33]
    menu_item_getinfo(menu , item , acc , info , charsmax(info))
    get_user_name(id , name , charsmax(name))
    ruleid = str_to_num(info)
    BuyNextRule  = ruleid + 1
    SubAmmoPak(id , 10.0)
    m_print_color(0 , "!g[冰布提示]%s购买了下一局的规则，下一局规则将为%s" , name , HumanRule[ruleid])
    menu_destroy(menu)
}

public AllHero(){
    new maxplayer = get_maxplayers()
    for(new i = 1 ; i < maxplayer ; i++){
        if(is_nullent(i) || !is_user_connected(i) || cs_get_user_team(i) == CS_TEAM_CT)
            continue
        Make_Hero(i)
    }
}

public RoundRule(){
    //随机每局的随机规则
    CurrentHunManRule = random_num(0,sizeof HumanRule - 1)
    CurrentRiJunRule = random_num(0,sizeof RiJunRule - 1)
    if(BuyNextRule){
        CurrentHunManRule = BuyNextRule - 1
        BuyNextRule = 0
    }
    // CurrentHunManRule = HUMAN_RULE_Random_Weapon
    //获取说明文本
    GetRuleText(RoundRuleType:RULE_HUMAN, HumManText, charsmax(HumManText))
    GetRuleText(RoundRuleType:RULE_RIJUN, RiJunText, charsmax(RiJunText))

    log_amx("本局八路规则:%s %s" ,HumanRule[CurrentHunManRule] , HumManText)
    log_amx("本局日军规则:%s %s", RiJunRule[CurrentRiJunRule], RiJunText)

    RuleInitOk = true
}
/**
 * 获取规则说明
 */
public GetRuleText(RuleType , Name[] , len){
    if(RuleType == RULE_HUMAN){
        copy(Name, len , 
        HUNMAN_RULE_Text[CurrentHunManRule])
    }else{
        copy(Name, len , 
        RIJUN_RULE_Text[CurrentRiJunRule])
    }
}
/**
 * 获取当前人类规则
 */
public native_GetHunManRule(id, num){
    return CurrentHunManRule
}
/**
 * 获取当前日军规则
 */
public native_GetRiJunRule(id, num){
    return CurrentRiJunRule
}

public native_GetRuleAllText(id, nums){
    if(!RuleInitOk)
        return
    new RuleType = get_param(1)
    new AllText[64]
    if(RuleType == RULE_HUMAN){
        formatex(AllText, charsmax(AllText), "%s %s", HumanRule[CurrentHunManRule] , HumManText)
        set_string(2, AllText, get_param(3))
        return
    }else{
        formatex(AllText, charsmax(AllText), "%s %s", RiJunRule[CurrentRiJunRule], RiJunText)
        set_string(2, AllText, get_param(3))
        return
    }
}

public CBasePlayer_ThrowGrenade_Pre(const id, const item, const Float:vecSrc[3], const Float:vecThrow[3], const Float:time, const const usEvent) {
	new Rule = GetHunManRule()
    if(Rule == HUMAN_RULE_Fire){
        new grenade = CreateNade(id, item, vecSrc, vecThrow, 30.0);

	    SetHookChainReturn(ATYPE_INTEGER, grenade);

	    return HC_SUPERCEDE;
    }
}

public m_ThrowHeGrenade(const index, Float:vecStart[3], Float:vecVelocity[3], Float:time, const team, const usEvent){
    new Rule = GetHunManRule()
    if(GetIsNpc(index))
        return HC_CONTINUE
    switch(Rule){
        case HUMAN_RULE_Grenadier:{
            DisableHookChain(HOOK_ThrowHeGrenade)
            new grenade_ent
            grenade_ent = rg_spawn_grenade(WEAPON_HEGRENADE,index,vecStart,vecVelocity,time,team,usEvent)
            if(grenade_ent){
                set_entvar(grenade_ent, var_dmg, 200.0)
            }
            vecStart[2] += 20.0
            grenade_ent = rg_spawn_grenade(WEAPON_HEGRENADE,index,vecStart,vecVelocity,time,team,usEvent)
            if(grenade_ent){
                set_entvar(grenade_ent, var_dmg, 200.0)
            }
            vecStart[2] += 20.0
            grenade_ent = rg_spawn_grenade(WEAPON_HEGRENADE,index,vecStart,vecVelocity,time,team,usEvent)
            if(grenade_ent){
                set_entvar(grenade_ent, var_dmg, 200.0)
            }
            EnableHookChain(HOOK_ThrowHeGrenade)
            SetHookChainReturn(ATYPE_INTEGER , grenade_ent)
            return HC_SUPERCEDE
        }
        default:{
            return HC_CONTINUE
        }
    }
    return HC_CONTINUE
}

public RULE_PlayerTakeDamage(this, idinflictor, idattacker, Float:damage, damagebits){
    if(idattacker > get_maxplayers())
        return HAM_IGNORED
    new Rule = GetHunManRule()
    switch(Rule){
        case HUMAN_RULE_Spiked_Armor:{
            CreateBlast(this)
            client_cmd(this , "spk weapons/chainsr_exp.wav")
            new Float:fOrigin[3]
            new ent = -1
            new userteam = cs_get_user_team(this)
            get_entvar(this , var_origin , fOrigin)
            while((ent = find_ent_in_sphere(ent , fOrigin , 100.0)) > 0){
                if(!is_valid_ent(ent) || get_entvar(ent ,var_deadflag))continue
                if(ExecuteHam(Ham_IsPlayer , ent) && is_user_alive(ent) && cs_get_user_team(ent) == userteam)continue
                ExecuteHamB(Ham_TakeDamage , ent , 0 , this , 100.0 , DMG_BULLET)
            }
        }
        case HUMAN_RULE_Nine_Lives:{
            new Float:Health = get_entvar(this , var_health)
            if(Health < damage && get_entvar(this , var_takedamage) != DAMAGE_NO && NineLivesCat[this] < 9){
                set_entvar(this , var_health , 1.0)
                set_entvar(this , var_takedamage , DAMAGE_NO)
                set_task(3.0 , "UnGod" , this + 1212)
                switch(++NineLivesCat[this]){
                    case 8 :client_print(this , print_center , "九命猫只剩最后一条尾巴。请珍惜")
                    case 9 :client_print(this , print_center , "九命猫耗尽所有尾巴。为你提供最后的庇佑。")
                    default :client_print(this , print_center , "九命猫断掉了一支尾巴保护了你,你将获得无敌3秒")
                }
                return HAM_SUPERCEDE
            }
        }
        case HUMAN_RULE_Grenadier:{
            if(idattacker == this && damagebits == DMG_GRENADE){
                return HAM_SUPERCEDE;
            }
        }
    }
}
public UnGod(id){
    new player = id -1212
    set_entvar(player , var_takedamage , DAMAGE_YES)
}

public RULE_HostageTakeDamage(this, idinflictor, idattacker, Float:damage, damagebits){
    if(ExecuteHam(Ham_IsPlayer , idattacker) == false)
        return HAM_IGNORED
    if(!is_valid_ent(idattacker) || cs_get_user_team(idattacker) != CS_TEAM_T)
        return HAM_IGNORED
    new Rule = GetHunManRule()
    switch(Rule){
        case HUMAN_RULE_Pain_Enhancement:{
            new Float:heal = get_entvar(idattacker, var_health)
            if(heal < 70.0){
                SetHamParamFloat(4, damage * 2.0)
            }
        }
        case HUMAN_RULE_Primary_Weapon_Mastery,HUMAN_RULE_Secondary_Weapon_Mastery:{
            new wpn = get_member(idattacker, m_pActiveItem)
            if(wpn <= 0)
                return HAM_IGNORED
            new slot = rg_get_iteminfo(wpn, ItemInfo_iSlot)
            if(Rule == HUMAN_RULE_Primary_Weapon_Mastery){
                if(slot != 0)
                    return HAM_IGNORED
                SetHamParamFloat(4 , damage * 1.25)
            }else{
                if(slot != 1 || !UTIL_RandFloatEvents(0.05))
                    return HAM_IGNORED
                new Float:heal = get_entvar(this , var_max_health)
                SetHamParamFloat(4 , heal*2) //副武器秒杀
                rg_spawn_random_gibs(this , 1)
            }
        }
        case HUMAN_RULE_Vampirism:{
            if(get_entvar(idattacker, var_health) < 150.0){
                new Float:addheal = damage * 0.01
                new Float:health = get_entvar(idattacker, var_health)
                if(addheal < 1.0){
                    addheal = 1.0
                }
                if(health + addheal > 150.0){
                    health = 150.0
                }
                set_entvar(idattacker, var_health , health + addheal)
            }
        }
        case HUMAN_RULE_Jumping_Elite:{
            if((get_entvar(idattacker, var_flags) & FL_ONGROUND) == 0){
                SetHamParamFloat(4, damage * 1.5)
            }
        }
    } 
    return HAM_IGNORED
}

public GetWpnIs_semiautomatic(const wpn){
    new wpnid = rg_get_iteminfo(wpn , ItemInfo_iId)
    if(wpnid == CSW_GLOCK18 || wpnid == CSW_DEAGLE || wpnid == CSW_ELITE ||
        wpnid == CSW_P228 || wpnid == CSW_USP
    ){
        return true
    }
    return false
}

public m_FireBullets(pEntity, Float:vecSrc[3], Float:vecDirShooting[3], Float:vecSpread, Float:flDistance, iPenetration, iBulletType, iDamage, Float:flRangeModifier, pevAttacker, bool:bPistol, shared_rand){
    if(is_nullent(pEntity) || cs_get_user_team(pEntity) != CS_TEAM_T)
        return HC_CONTINUE
    new wpn = get_member(pEntity, m_pActiveItem)
    new Rule = GetHunManRule()
    new Clip = get_member(wpn, m_Weapon_iClip)
    switch(Rule){
        case HUMAN_RULE_Depleted_Uranium:{
            SetHookChainArg(6 , ATYPE_INTEGER , 9)
        }
        case HUMAN_RULE_Last_Shot:{
            if(Clip == 0){
                new Float:EndOrigin[3]
                GetWatchEnd(pEntity, EndOrigin)
                CreateGroundSprite(pEntity, EndOrigin , 3 , 1.0)
                return HC_CONTINUE
            }
        }
        case HUMAN_RULE_Explosive_Ammunition:{
            new bool:isCreate = UTIL_RandFloatEvents(0.5) //50%
            if(!isCreate)
                return HC_CONTINUE
            new Float:EndOrigin[3]
            GetWatchEnd(pEntity, EndOrigin)
            new iOrigin[3]
  	        iOrigin[0] = floatround(EndOrigin[0])
	        iOrigin[1] = floatround(EndOrigin[1])
	        iOrigin[2] = floatround(EndOrigin[2])

	        message_begin(MSG_BROADCAST, SVC_TEMPENTITY, iOrigin)
	        write_byte(TE_EXPLOSION)
	        write_coord(iOrigin[0])
	        write_coord(iOrigin[1])
	        write_coord(iOrigin[2])
	        write_short(g_Explosion)
	        write_byte(10)
	        write_byte(15)
	        write_byte(0)
	        message_end()

            rg_radius_damage(EndOrigin, pEntity, pEntity, 150.0, 210.0, DMG_BULLET)
        }
    }
    return HC_CONTINUE
}

public m_MaxSpeed(const this){
    if(GetHunManRule() == HUMAN_RULE_Forced_March){
        new wpn = get_member(this , m_pActiveItem)
        if(is_entity(wpn)){
            new Float:speed
            ExecuteHam(Ham_CS_Item_GetMaxSpeed , wpn , speed)
            speed += 50.0
            set_entvar(this , var_maxspeed , 600.0)
            return HC_SUPERCEDE
        }
    }
    return HC_CONTINUE
}

public m_DefaultDeploy(const this, szViewModel[], szWeaponModel[], iAnim, szAnimExt[], skiplocal){
    if(GetHunManRule() == HUMAN_RULE_Forced_March){
        new Float:speed = get_member(this , m_Weapon_fMaxSpeed)
        if(is_nullent(this))
            return HC_CONTINUE
        speed += 50.0
        set_member(this , m_Weapon_fMaxSpeed , speed)
        // set_entvar(player, var_maxspeed, get_entvar(player,var_maxspeed) + 50.0)
    }
    return HC_CONTINUE
} 


stock GetWatchEnd(player , Float:OutEndOrigin[3]){
    new Float:hitorigin[3]
    new Float:StartOrigin[3],Float:EndOrigin[3],Float:Eyes[3]
    new Float:angles[3], Float:fwd[3];
    get_entvar(player, var_origin , StartOrigin)
    get_entvar(player, var_view_ofs, Eyes)
    xs_vec_add(StartOrigin, Eyes, StartOrigin)
    get_entvar(player, var_v_angle, angles)
    engfunc(EngFunc_MakeVectors, angles)
    global_get(glb_v_forward, fwd)
    xs_vec_mul_scalar(fwd, 8192.0, EndOrigin)
    xs_vec_add(StartOrigin,EndOrigin,EndOrigin)
	new hitent = fm_trace_line(player,StartOrigin,EndOrigin,hitorigin)
    xs_vec_copy(hitorigin, OutEndOrigin)
}




stock rg_radius_damage(const Float:origin[3], attacker, inflictor, Float:damage, Float:radius, dmg_bits)
{
    new ent = -1
    new Float:target_origin[3]
    new Float:distance
    new Float:final_damage
	new Float:Origin_[3]
	new Float:Heal;
	//server_print("%f %f %f rg_radius_damage in put" , origin[0],origin[1],origin[2]);
	// get_entvar(inflictor, var_origin, Origin_)

    while ((ent = find_ent_in_sphere(ent, origin, radius)) != 0)
    {
        if (!is_valid_ent(ent)) continue
        if(ent == attacker) continue;
		if(get_entvar(ent , var_takedamage) == DAMAGE_NO) continue
        if(get_entvar(ent , pev_deadflag) == DEAD_DEAD) continue

        get_entvar(ent, var_origin, target_origin)
        distance = vector_distance(origin, target_origin)

        final_damage = damage * (1.0 - (distance / radius))
        if (final_damage <= 0.0) continue;

		if(ExecuteHam(Ham_IsPlayer , ent) && is_user_alive(ent) && cs_get_user_team(ent) == cs_get_user_team(attacker))continue;

		ExecuteHamB(Ham_TakeDamage, ent, inflictor, attacker, final_damage, dmg_bits)
    }
}

stock JpBoom(Npc){
    if(!GetIsNpc(Npc))
        return
    new ent = -1 , Float:fOrigin[3]
    new const explosionRadius = 200.0
    new const Float:maxDamage = 30.0           // 爆炸中心的最大伤害
    new const Float:minDamage = 10.0           // 爆炸边缘的最小伤害
    get_entvar(Npc , var_origin , fOrigin)
    while ((ent = find_ent_in_sphere(ent, fOrigin, explosionRadius)) > 0){
        if(FClassnameIs(ent , "player") || FClassnameIs(ent , "hostage_entity")){
            if(get_entvar(ent ,var_deadflag) == DEAD_DEAD) continue
            new Float:targetOrigin[3]
            get_entvar(ent, var_origin, targetOrigin)
            new Float:distance = get_distance_f(fOrigin, targetOrigin)
            new Float:damageFactor = 1.0 - (distance / explosionRadius)
            if(damageFactor < 0.0)
                damageFactor = 0.0
            new Float:actualDamage = minDamage + (maxDamage - minDamage) * damageFactor
            ExecuteHamB(Ham_TakeDamage , ent , Npc, GetFakeClient() , actualDamage , DMG_CRUSH)
        }
    }
    new iOrigin[3]
    iOrigin[0] = floatround(fOrigin[0])
    iOrigin[1] = floatround(fOrigin[1])
    iOrigin[2] = floatround(fOrigin[2])
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	write_coord(iOrigin[0])
	write_coord(iOrigin[1])
	write_coord(iOrigin[2])
	write_short(JpBoomSpr)
	write_byte(30)
	write_byte(15)
	write_byte(0)
	message_end()
}
