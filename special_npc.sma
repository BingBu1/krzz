#include <amxmodx>
#include <fakemeta>
#include <cstrike>
#include <reapi>
#include <kr_core>
#include <props>
#include <fakemeta_util>
#include <xp_module>
#include <roundrule>
#include <engine>
#include <hamsandwich>
#include <Npc_Manager>

#define MaxGold 1

#define LootModel "models/supplybox_Newyear.mdl"

#define SpawnTimer 60.0 * 3

#define GetNextSkillCD(%1) get_prop_float(%1 , "El_Cd")

#define SetNextSkillCD(%1,%2) set_prop_float(%1 , "El_Cd",%2)

new EliteNeedKilled = 50

enum TankModle_e{
    Tk_alive,
    Tk_die
}

enum Elite_Var{
    Elite_White = 1,
    Elite_Green,
    Elite_Blue,
    Elite_Red,
    Elite_Purple,
    Elite_Gold
}

new has_tank

new CurrentTankEnt , SpawnGold

new Float:StartTime , CurrentKill

new TankModle[TankModle_e][]={
"models/rainych/krzz/tank.mdl",
"models/rainych/krzz/tank_died.mdl"
}

new firesound[][]={
    "weapons/357_shot1.wav",
    "weapons/357_shot2.wav"
}

new LootSound[][]= {
    "Kr_sound/supply_box_drop.wav",
    "Kr_sound/get_box.wav" //1
}

new g_Explosion, sTrail

new BossNpc

new TankBoom[] = "sprites/blueflare1.spr"

new const GRENADE_TRAIL[] = "sprites/laserbeam.spr"

new MaxBossNpc , KilledNpcNum

public plugin_init(){
    register_plugin("特殊日本Npc", "1.0", "Bing")
    register_event("HLTV", "event_roundstart", "a", "1=0", "2=0")

    register_forward(FM_AddToFullPack , "Fw_AddToFullPack")

    RegisterHam(Ham_TakeDamage , "hostage_entity" , "Hostage_Dmg")

    MaxBossNpc = 3
}

public OnLevelChange_Post(lv){
    MaxBossNpc = CalcMaxBossNpc()
}

public event_roundstart(){
    has_tank = false
    CurrentTankEnt = 0
    BossNpc = 0
    SpawnGold = 0
    StartTime = get_gametime()
    CurrentKill = 0
    remove_entity_name("HBar")
    remove_entity_name("FuDai")
    MaxBossNpc = CalcMaxBossNpc()
    if(GetHunManRule() == HUMAN_RULE_Elite_Scatter){
        MaxBossNpc = max(MaxBossNpc - 3 , 1)
    }
    
}

CalcMaxBossNpc(){
    new lv = Getleavel()
    new BossMax = 125
    if(lv <= 300){
        EliteNeedKilled = 125
        BossMax =  3
    }else if( lv <= 550){
        EliteNeedKilled = 88
        BossMax = 4
    }else if(lv <= 880){
        EliteNeedKilled = 60
        BossMax = 5
    }else if(lv <= 1300){
        EliteNeedKilled = 30
        BossMax = 10
    }
    server_print("当前难度刷新精英需击杀%d精英上限%d" , EliteNeedKilled ,BossMax)
    return BossMax
}

public plugin_precache(){
    precache_model(TankModle[Tk_alive])
    precache_model(TankModle[Tk_die])

    for(new i = 0 ; i <sizeof firesound ; i++){
        precache_sound(firesound[i])
    }
    for(new i = 0 ; i <sizeof LootSound ; i++){
        UTIL_Precache_Sound(LootSound[i])
    }
    g_Explosion = precache_model("sprites/zerogxplode.spr")
    sTrail = precache_model(GRENADE_TRAIL)
    precache_model("sprites/zb_healthbar.spr")
    precache_model("models/supplybox_Newyear.mdl")
    precache_model(TankBoom)
}

public plugin_natives(){
    register_native("is_tank" , "native_is_tank")
    register_native("GetTankNpcEnt" , "native_GetTankNpcEnt")
    register_native("CreateLoot_Cso" , "native_CreateLoot")
}

public On_judian_Change_Post(juidan){
    remove_entity_name("HBar")
    BossNpc = 0
}

public native_GetTankNpcEnt(){
    return CurrentTankEnt
}

public Fw_AddToFullPack(const es, e, ent, HOST, hostflags, player, set){
    if(player)
        return FMRES_IGNORED    
    new spr = get_entvar(ent , var_impulse)

    if(!spr || !is_valid_ent(spr))
        return FMRES_IGNORED 

    if(get_entvar(ent , var_deadflag) == DEAD_DEAD){
        rg_remove_entity(spr)
        return FMRES_IGNORED
    }

    new Float:PlayerOrigin[3] , Float:Health ,Float:MaxHealth
    get_entvar(ent , var_origin , PlayerOrigin)
    Health = get_entvar(ent , var_health)
    MaxHealth = get_entvar(ent , var_max_health)    
    PlayerOrigin[2] += 72.0
    engfunc(EngFunc_SetOrigin, spr, PlayerOrigin)
    new Float:ratio = (Health / MaxHealth) * 99.0
    if(ratio < 0.0) ratio = 0.0
    set_entvar(spr , var_frame , ratio) 
    set_es( es, ES_MoveType, MOVETYPE_FOLLOW )
    set_es( es, ES_RenderMode, kRenderNormal )
    set_es( es, ES_RenderAmt, 220 )

    return FMRES_IGNORED
}

public CreateHealBar(Npc){
    new spr = rg_create_entity("env_sprite")
    if(is_nullent(spr) && spr <= 0)
        return 0
    set_entvar(spr , var_classname , "HBar")
    set_entvar(spr, var_renderamt, 255.0)
    set_entvar(spr, var_frame, 0.0)
    set_entvar(spr, var_animtime, get_gametime())
    set_entvar(spr , var_scale , 0.5)
    set_entvar(spr , var_owner , Npc)
    set_entvar(spr, var_spawnflags, SF_SPRITE_STARTON)

    //--
    set_entvar(Npc , var_impulse , spr)
    
    engfunc(EngFunc_SetModel , spr , "sprites/zb_healthbar.spr")
    return spr
}

public CreateEliteNpc(ent , lv , Judian){
    new const Float:colors[][3] = {
        {255.0, 255.0, 255.0}, // White
        {0.0, 255.0, 0.0},     // Green
        {0.0, 0.0, 255.0},     // Blue
        {255.0, 0.0, 0.0},      // Red
        {255.0, 0.0, 255.0},     // Purple
    }
    if(KilledNpcNum < EliteNeedKilled)
        return false
    new Float:baseHeal[] = {500.0, 1000.0, 1500.0, 2000.0 , 2500.0};
    new Float:healScale[] = {30.0, 50.0, 100.0, 130.0 , 135.0};  // 对应白、绿、蓝、红
    new Float:healMax[] = {15000.0, 25000.0, 78000.0, 150000.0 , 178000.0};
    new Elite_Var:EliteIds[] = {Elite_White, Elite_Green, Elite_Blue, Elite_Red , Elite_Purple};
    new bool:SetProp[] = {false, false, true, true , true};
    new levelThreshold[] = {30, 150, 300, 500 , 800}; // 对应白、绿、蓝、红

    new available[sizeof EliteIds], count = 0;
    for(new i = 0; i < sizeof EliteIds; i++)
    {
        if(lv >= levelThreshold[i])
        {
            available[count++] = i;
        }
    }

    if(count == 0) return false;

    new index = available[random_num(0, count-1)];

    new Float:chance[] = {0.1, 0.02, 0.05, 0.01 , 0.008}; // 白、绿、蓝、红

    if(!RandFloatEvents(chance[index])){
        KilledNpcNum = 0
        return false
    }

    new Float:Heal = floatmin(baseHeal[index] + lv * healScale[index], healMax[index]);
    set_entvar(ent, var_renderfx, kRenderFxGlowShell);
    set_entvar(ent, var_rendercolor, colors[index]);
    set_entvar(ent, var_renderamt, 10.0);
    set_entvar(ent, var_health, Heal);
    set_entvar(ent, var_max_health, Heal);
    set_entvar(ent, var_iuser1, EliteIds[index]);

    if(SetProp[index]) set_prop_int(ent, "CanStop", 1);

    BossNpc++;
    KilledNpcNum = 0
    return true;
}

public NPC_CreatePost(ent){
    if(is_nullent(ent) || !is_valid_ent(ent))
        return
    new Judian_num = GetJuDianNum()
    new level = Getleavel()
    if(level > 30 && Judian_num <= 7 && BossNpc < MaxBossNpc){
        new bool:IsCreate = bool:CreateEliteNpc(ent , level , Judian_num)
        if(IsCreate){
            new spr = CreateHealBar(ent)
            if(!spr){
                log_error(AMX_ERR_NONE , "创建血条实体失败。")
            }
        }
    }
    if(Judian_num < 8 && SpawnGold < MaxGold && level > 100 && 
        CurrentKill >= 800 && (get_gametime() - StartTime) > SpawnTimer
    ){
        if(UTIL_RandFloatEvents(0.005)){
            new Float:Color[3]= {255.0,215.0,0.0}
            set_entvar(ent, var_renderfx, kRenderFxGlowShell)
            set_entvar(ent, var_rendercolor, Color)
            set_entvar(ent ,var_renderamt , 255.0)
            set_entvar(ent, var_health, 50000.0)
            set_entvar(ent, var_max_health, 50000.0)
            set_entvar(ent, var_iuser1 , Elite_Gold)
            m_print_color(0 , "!t[冰布提示] 出现了黄金精英怪物，击杀可掉落战利品！")
            client_print(0 , print_center , "[冰布提示] 出现了黄金精英怪物，击杀可掉落战利品！")
            CreateHealBar(ent)
            SpawnGold++
        }
        CurrentKill = 0
    }
    if(Judian_num == 8 && !has_tank){
        //如果不存在坦克创建
        new Float:Heal = 5000.0 + (250.0 * float(level))
        
        engfunc(EngFunc_SetModel , ent , TankModle[Tk_alive])
        //重置size
        dllfunc(DLLFunc_Spawn, ent)

        set_entvar(ent , var_health, Heal)
        set_entvar(ent, var_max_health , Heal)
        // set_entvar(ent, var_body, 0)
        set_prop_int(ent , "istank" , 1)
        set_prop_int(ent, "CanStop", 1)  //无法被武器定身，和出现受伤动画

        CurrentTankEnt = ent
        has_tank = true
        new spr = CreateHealBar(ent)
        if(!spr){
            log_error(AMX_ERR_NONE , "创建血条实体失败。")
        }
        return
    }
    if(GetJuDianNum() == 8){
        new Float:fOrigin[3]
        new Float:maxHeal = 2000.0//基础血量
        maxHeal = maxHeal + (150.0 * float(level))
        set_entvar(ent , var_max_health, maxHeal)
        set_entvar(ent , var_health, maxHeal)
        get_entvar(ent , var_origin , fOrigin)
        set_prop_int(ent, "CanStop", 1)
        new spr = CreateHealBar(ent)
        if(!spr){
            log_error(AMX_ERR_NONE , "创建血条实体失败。")
        }
    }
    if(GetRiJunRule() == JAP_RULE_Tank_Rampage && UTIL_RandFloatEvents(0.01)){
        engfunc(EngFunc_SetModel , ent , TankModle[Tk_alive])
        //重置size
        dllfunc(DLLFunc_Spawn, ent)
        // new Float:maxHeal = 2000.0//基础血量
        // maxHeal = maxHeal + (150.0 * float(level))
        // set_entvar(ent , var_max_health, maxHeal)
        // set_entvar(ent , var_health, maxHeal)
        set_prop_int(ent , "istank" , 1)
        set_prop_int(ent, "CanStop", 1)  //无法被武器定身，和出现受伤动画
    }
}

EliteThink(ent , EliteLevle){
    switch(EliteLevle){
        case Elite_Red:{

        }
        case Elite_Purple:{
            PuperNpcSkill(ent)
        }
    }
}

public NPC_ThinkPost(ent){
    new Judian_num = GetJuDianNum()
    new hitent
    new follent
    new Float:origin[3], Float:targetorigin[3],Float:hitorigin[3]
    new Elite = get_entvar(ent,var_iuser1)
    if(Elite){
        EliteThink(ent , Elite)
    }
    //小于7不存在开枪的特殊兵种
    if(Judian_num < 7 && GetRiJunRule() != JAP_RULE_Tank_Rampage)
        return 0
    new body = get_entvar(ent , var_body)
    new istank = is_tank(ent)
    
    follent = cs_get_hostage_foll(ent)
    if(!follent)
        return 0
    get_entvar(ent,var_origin,origin)
    get_entvar(follent,var_origin,targetorigin)
    hitent = fm_trace_line(ent,origin,targetorigin,hitorigin)
    InitAttack2Timer(ent, 3.0, 8.0)
    if(hitent == 0)
        return 0
    new Float:attacktimer = get_prop_float(ent,"attackfire")
    if(get_gametime() < attacktimer)
        return 0
    set_msg_block(get_user_msgid("DeathMsg"), BLOCK_ONCE)
    switch(body){
        case 7:{
            FireBullets(ent, follent)
            ResetAttack2(ent, 3.0, 8.0)
        }
        case 8:{
            if(istank){
                //坦克 开炮 机枪逻辑
                CreateTankBoom(ent,follent)
                ResetAttack2(ent,1.0 , 5.0)
            }else{
                new randattack = random_num(0,1)
                if(randattack)
                    FireBullets(ent, follent, 5.0)
                else
                    ThrowHeGrenade(ent)
                ResetAttack2(ent, 1.0 , 5.0)
            }
        }
        default:{
            if(istank){
                //坦克 开炮 机枪逻辑
                CreateTankBoom(ent,follent)
                ResetAttack2(ent,1.0 , 5.0)
            }
        }
    }
    set_msg_block(get_user_msgid("DeathMsg"), BLOCK_NOT)
    return 0
}

public Hostage_Dmg(this , ack1 , attacker , Float:Damage , dmgbit){
    if(GetRiJunRule() != JAP_RULE_Tank_Rampage)
        return HAM_IGNORED
    new istank = is_tank(this)
    new judian_Count = GetJuDianNum()
    if(!istank || judian_Count > 7)
        return HAM_IGNORED
    if(Damage > 10.0)
        SetHamParamFloat(4 , 10.0)
    return HAM_IGNORED
}

public native_is_tank(){
    new ent = get_param(1)
    if(is_nullent(ent))
        return false
    if(!prop_exists(ent,"istank")){
        return false
    }
    new istank = get_prop_int(ent,"istank")
    return istank
}

public native_CreateLoot(id , nums){
    new Float:CreateOrigin[3]
    get_array_f(1 , CreateOrigin , 3)
    CreateLoot(CreateOrigin)
}

CreateLoot(Float:KilledOrigin[3]){
    new Players = get_member_game(m_iNumTerrorist)
    if(Players < 1)
        return
    UTIL_EmitSound_ByCmd(0 , LootSound[0])
    for(new i = 1 ; i < MaxClients ; i++){
        if(!is_user_connected(i) || !is_user_alive(i))
            continue
        if(cs_get_user_team(i) != CS_TEAM_T)
            continue
        CreateLootEntity(i , KilledOrigin)
    }
}

CreateLootEntity(const master , Float:KilledOrigin[3]){
    new Entity = rg_create_entity("info_target")
    if(is_nullent(Entity))
        return
    new Float:origin[3];
    origin[0] = KilledOrigin[0];
    origin[1] = KilledOrigin[1];
    origin[2] = KilledOrigin[2];

    // 随机偏移 ±50 单位
    origin[0] += random_float(-20.0, 20.0);
    origin[1] += random_float(-20.0, 20.0);
    origin[2] += 10.0; // 可选稍微抬高一点
    set_entvar(Entity , var_classname , "FuDai")
    set_entvar(Entity , var_solid , SOLID_TRIGGER)
    set_entvar(Entity , var_movetype , MOVETYPE_TOSS)
    set_entvar(Entity , var_gravity , 0.5)
    set_entvar(Entity , var_nextthink , get_gametime() + 0.1)
    set_entvar(Entity , var_iuser1 , master) //1代表未被拾取
    // set_entvar(Entity , var_fuser1 , get_gametime() + 120.0) //1代表未被拾取
    set_entvar(Entity , var_origin , origin)
    SetThink(Entity , "LootThink")
    SetTouch(Entity , "LootTouch")

    engfunc(EngFunc_SetModel , Entity , LootModel)
}

public LootThink(const Lootindex){
    new master = get_entvar(Lootindex , var_iuser1)
    if(!is_user_connected(master)){
        rg_remove_entity(Lootindex)
        return
    }
    set_entvar(Lootindex , var_nextthink , get_gametime() + 0.1)
}

public LootTouch(const Lootindex , const Toucher){
    new master = get_entvar(Lootindex , var_iuser1)
    if(master != Toucher)
        return
    new name[32]
    get_user_name(Toucher, name, 31)
    UTIL_EmitSound_ByCmd(Toucher , LootSound[1])
    new Float:AddAmmo = random_float(20.0 , 20.0 + (Getleavel() / 3))
    AddAmmoPak(Toucher , AddAmmo)
    m_print_color(0 , "!g[提示] %s获得了战利品,获得了%f大洋" , name, AddAmmo)
    rg_remove_entity(Lootindex)
}

public NPC_Killed(this , killer){
    KilledNpcNum++
    new spr = get_entvar(this , var_impulse)
    if(spr > 0){
        set_entvar(this , var_impulse , 0)
        rg_remove_entity(spr)
    }
    if(get_entvar(this,var_iuser1) >= Elite_White){
        BossNpc--
        if(!ExecuteHam(Ham_IsPlayer , killer)){
            set_entvar(this, var_iuser1, 0)
            set_entvar(this, var_renderfx, kRenderFxNone)
            set_entvar(this, var_rendercolor, Float:{0.0,0.0,0.0})
            set_entvar(this ,var_renderamt , 1.0)
            return
        }
        new MonsterLv = get_entvar(this, var_iuser1)
        new lv = Getleavel()
        new Lastmoney , money = cs_get_user_money(killer)
        new baseaddxp
        Lastmoney = money
        switch(MonsterLv){
            case Elite_White :{
                money += 3000
                baseaddxp = 100 + random_num(100 , lv * 5)
            }
            case Elite_Green:{
                money += 5000
                baseaddxp = 350 + random_num(300 , lv * (5 + MonsterLv))
            }
            case Elite_Blue:{
                baseaddxp = 500 + random_num(250 , lv * (5 + MonsterLv))
                money += 8000
            }
            case Elite_Red :{
                baseaddxp = 1000 + random_num(500 , lv * (5 + MonsterLv))
                money += 15000
            }
            case Elite_Purple:{
                baseaddxp = 1000 + random_num(500 , lv * (5 + MonsterLv))
                money += 18000
            }
            case Elite_Gold:{
                new Float:origin[3]
                get_entvar(this, var_origin,origin)
                money += 30000
                baseaddxp = 1000 + random_num(500 , lv * (5 + MonsterLv))
                m_print_color(0 , "!t[冰布提示] 黄金精英被击杀，战利品掉落完毕！")
                client_print(0 , print_center , "[冰布提示] 黄金精英被击杀，战利品掉落完毕！")
                CreateLoot(origin)
            }
        }
        m_print_color(killer , "!g[击杀]击杀精英额外获得%d积分,金钱%d", baseaddxp , money - Lastmoney)
        cs_set_user_money(killer , money)
        baseaddxp *= MonsterLv 
        AddXp(killer, baseaddxp)
        set_entvar(this, var_iuser1, 0)
        set_entvar(this, var_renderfx, kRenderFxNone)
        set_entvar(this, var_rendercolor, Float:{0.0,0.0,0.0})
        set_entvar(this ,var_renderamt , 1.0)
    }
    new Float:origin[3]
    get_entvar(this, var_origin, origin)
    if(has_tank && this == CurrentTankEnt){
        engfunc(EngFunc_SetModel , this , TankModle[Tk_die])
        MakeBoom(origin)
        AddKillTank(killer)
        KillTank_reward(killer)
    }
    if (get_entvar(this , var_body) == 8 && GetJuDianNum() == 8 && this != CurrentTankEnt){
        if(UTIL_RandFloatEvents(0.05)){
            CreateLoot(origin)
        }
    }
    CurrentKill++
}

public KillTank_reward(id){
    if(!is_user_connected(id))
        return
    new Randreward = UTIL_RandFloatEvents(0.2)
    //大洋奖励
    new name[32]
    get_user_name(id, name, 31)
    if(Randreward == 0) {
        new const Float:Base = 1.0
        new Float:MinAmmo = 20.0
        new Float:MaxAmmo = 20.0 + (Base + float(Getleavel() / 3))
        new Float:Rand = random_float(MinAmmo, MaxAmmo)
        AddAmmoPak(id, Rand)
        m_print_color(0, "!g[冰布提示] %s 击败了坦克获取到了奖励%f大洋" ,name , Rand)
    }else if (Randreward == 1){ //积分奖励
        new const Base = 100
        new Min = (Base + Getleavel()) * 2
        new Max = (Base + Getleavel()) * 20
        Max = min(Max , 20000)
        new Rand = random_num(Min, Max)

        AddXp(id, Rand)
        m_print_color(0, "!g[冰布提示] %s 击败了坦克获取到了奖励%d额外积分" ,name , Rand)
    }
    set_prop_int(id , "istank" , 0)
}

public MakeBoom(Float:iOrigin[3]){
    message_begin_f(MSG_BROADCAST, SVC_TEMPENTITY)
    write_byte(TE_EXPLOSION)
    write_coord_f(iOrigin[0])
    write_coord_f(iOrigin[1])
    write_coord_f(iOrigin[2])
    write_short(g_Explosion)
    write_byte(30)
    write_byte(15)
    write_byte(0)
    message_end()
}

public MakeBullets(Float:Start[3] , Float:End[3]){
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
    write_byte(TE_TRACER)
    write_coord_f(Start[0])
    write_coord_f(Start[1])
    write_coord_f(Start[2])
    write_coord_f(End[0])
    write_coord_f(End[1])
    write_coord_f(End[2])
    message_end()

    emit_sound(0,CHAN_AUTO,firesound[random_num(0,1)],1.0,ATTN_NONE,0, PITCH_NORM)
}

stock FireBullets(this , target , Float:Damage = 1.0){
    if(!is_user_connected(target))
        return
    new Float:origin[3], Float:targetorigin[3] , Float:hitorigin[3]
    get_entvar(this,var_origin,origin)
    get_entvar(target,var_origin,targetorigin)
    if(vector_distance(origin,targetorigin) > 200.0)
        return
    new hitent = fm_trace_line(this,origin,targetorigin,hitorigin)
    MakeBullets(origin,hitorigin)
    if(hitent == target){
        rg_multidmg_add(GetFakeClient(), target, Damage, DMG_CRUSH)
        rg_multidmg_apply(target, GetFakeClient())
        new Float:heal
        heal = get_entvar(target,var_health)
        if(heal <=0.0){
            MakeDie(target,"被biu死了")
            ExecNpcKillCallBack(target , this)
        }
    }
}

public ThrowHeGrenade(ownid){
    new Float:origin[3],Float:angles[3],Float:forwards[3]
    new Float:vecls[3]
    get_entvar(ownid,var_origin,origin)
    get_entvar(ownid,var_angles,angles)
    angle_vector(angles,ANGLEVECTOR_FORWARD,forwards)
    xs_vec_mul_scalar(forwards,300.0,vecls)

    xs_vec_mul_scalar(forwards, 100.0, forwards)
    xs_vec_add(origin, forwards, origin)
    origin[2]+= 30.0
    new heg = rg_spawn_grenade(
        WEAPON_HEGRENADE,GetFakeClient(),origin,vecls,5.0,
        TEAM_CT,0
    )
    return heg
}

stock npc_aim_at_player(npc, player, Float:start[3], Float:end[3])
{
    get_entvar(npc, var_origin, start)
    get_entvar(player, var_origin, end)

    // 提高目标点高度（瞄头/胸部）
    end[2] += 20.0
}

public InitAttack2Timer(ent, Float:Min,Float:Max){
    if(prop_exists(ent,"attackfire"))
        return
    set_prop_float(ent, "attackfire", get_gametime() + random_float(Min,Max))
    return
}

public ResetAttack2(ent , Float:Min,Float:Max){
    set_prop_float(ent, "attackfire", get_gametime() + random_float(Min,Max))
}

public MakeDie(beattack , DieStr[]){
    new g_msgDeathMsg = get_user_msgid("DeathMsg");
    message_begin(MSG_BROADCAST, g_msgDeathMsg);
    write_byte(GetFakeClient());
    write_byte(beattack);
    write_byte(0);
    write_string(DieStr);
    message_end();
}

stock CreateTankBoom(ent , target){
    new tk_ent = rg_create_entity("info_target")
    if(!tk_ent)
        return 0
    new Float:org[3], Float:tarorg[3]
    get_entvar(ent,var_origin,org)
    get_entvar(target,var_origin,tarorg)

    new Float:vec[3]
    xs_vec_sub(tarorg, org, vec)
    xs_vec_normalize(vec, vec)
    xs_vec_mul_scalar(vec, 50.0, vec)
    xs_vec_add(org, vec, org)
    xs_vec_mul_scalar(vec, 12.0, vec)
    set_entvar(tk_ent,var_movetype, MOVETYPE_FLY)
    set_entvar(tk_ent , var_solid, SOLID_BBOX)
    set_entvar(tk_ent,var_origin,org)
    set_entvar(tk_ent,var_velocity,vec)
    set_entvar(tk_ent, var_classname,"tk_boom")
    set_entvar(tk_ent, var_rendermode,kRenderTransAdd)
    set_entvar(tk_ent, var_renderamt,255.0)
    set_entvar(tk_ent , var_owner , ent)

    

    engfunc(EngFunc_SetModel,tk_ent,TankBoom)
    engfunc(EngFunc_SetSize,tk_ent,Float:{-1.0, -1.0, -1.0},Float:{1.0, 1.0, 1.0})

    SetTouch(tk_ent,"tk_Touch")

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
    write_byte(TE_BEAMFOLLOW) // Temporary entity ID
    write_short(tk_ent) // Entity
    write_short(sTrail) // Sprite index
    write_byte(10) // Life
    write_byte(3) // Line width
    write_byte(255) // Red
    write_byte(255) // Green
    write_byte(255) // Blue
    write_byte(255) // Alpha
    message_end() 
    return tk_ent
}

public tk_Touch(const this, const other) {
    new Float:org[3]
    get_entvar(this, var_origin, org)

    MakeBoom(org)  // 生成爆炸效果

    // 标记删除
    set_entvar(this, var_flags, FL_KILLME)
    new master = get_entvar(this , var_owner)
    if(get_entvar(master , var_deadflag) == DEAD_DEAD){
        rg_remove_entity(this)
        return
    }
    rg_radius_damage(org , master, master , 200.0 , 200.0, DMG_GRENADE)

    new maxPlayers = get_maxplayers()
    for (new i = 1; i <= maxPlayers; i++) {
        if (!is_user_alive(i) || !is_user_connected(i))
            continue
        if (cs_get_user_team(i) != CS_TEAM_T)
            continue

        new Float:playerorg[3]
        get_entvar(i, var_origin, playerorg)

        new Float:distance = vector_distance(org, playerorg)
        if (distance > 200.0)
            continue

        set_msg_block(get_user_msgid("DeathMsg"), BLOCK_ONCE)

        new Float:DamBase = random_float(50.0, 100.0)
        new Float:damage_multiplier = 1.0 - (distance / 200.0)
        if (damage_multiplier <= 0.0)
            continue

        DamBase *= damage_multiplier
        DamBase = floatmax(DamBase, 20.0)

        // 添加伤害
        rg_multidmg_add(GetFakeClient(), i, DamBase, DMG_CRUSH)
        rg_multidmg_apply(i, GetFakeClient())

        // 立即判断是否死亡
        new Float:heal
        get_entvar(i, var_health, heal)
        if (heal <= 0.0) {
            MakeDie(i, "坦克炸成了灰")
        }

        set_msg_block(get_user_msgid("DeathMsg"), BLOCK_NOT)
    }
}


stock get_aim_origin_vector(iPlayer, Float:forw, Float:right, Float:up, Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(iPlayer, var_origin, vOrigin)
	pev(iPlayer, var_view_ofs, vUp)
	xs_vec_add(vOrigin, vUp, vOrigin)
	pev(iPlayer, var_v_angle, vAngle)
	
	angle_vector(vAngle, ANGLEVECTOR_FORWARD, vForward)
	angle_vector(vAngle, ANGLEVECTOR_RIGHT, vRight)
	angle_vector(vAngle, ANGLEVECTOR_UP, vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}


stock bool:RandFloatEvents(Float:Probability){
    if(Probability >= 1.0)
        return true
    new Float:randnum = random_float(0.0,1.0)
    if(randnum <= Probability)
        return true
    return false
}

stock rg_radius_damage(const Float:origin[3], attacker, inflictor, Float:damage, Float:radius, dmg_bits)
{
    new ent = -1
    new CsTeams:CurTmea = KrGetFakeTeam(attacker)
    while ((ent = find_ent_in_sphere(ent, origin, radius)) > 0)
    {
        if(ent == attacker) continue;
        if(!is_valid_ent(ent) || is_nullent(ent)) continue
        if(get_entvar(ent , var_takedamage) == DAMAGE_NO) continue
        if(get_entvar(ent , var_deadflag) == DEAD_DEAD) continue
        if(ExecuteHam(Ham_IsPlayer , ent))continue
        if(CurTmea == KrGetFakeTeam(ent))continue

        ExecuteHamB(Ham_TakeDamage, ent, inflictor, attacker, damage, dmg_bits);
    }
}

stock PuperNpcSkill(ent){
    if(!prop_exists(ent , "El_Cd")){
        SetNextSkillCD(ent , get_gametime() + 20.0)
    }
    if(GetNextSkillCD(ent) > get_gametime()){
        return
    }
    SetNextSkillCD(ent , get_gametime() + 40.0) //技能冷却时间10秒
    if (!is_entity(ent)) return;
    if (get_entvar(ent, var_iuser1) != Elite_Purple) return;
    new Float:ent_origin[3];
    get_entvar(ent, var_origin, ent_origin);

    new maxPlayers = get_maxplayers();
    for (new id = 1; id <= maxPlayers; id++)
    {
        if (!is_user_alive(id))
            continue;

        // 玩家位置
        new Float:pl_origin[3];
        get_entvar(id, var_origin, pl_origin);

        // 向精英方向的向量
        new Float:dir[3];
        dir[0] = ent_origin[0] - pl_origin[0];
        dir[1] = ent_origin[1] - pl_origin[1];
        dir[2] = ent_origin[2] - pl_origin[2];

        // 单位化（得到方向）
        new Float:len = floatsqroot(dir[0]*dir[0] + dir[1]*dir[1] + dir[2]*dir[2]);
        if (len == 0.0)
            continue;

        dir[0] /= len;
        dir[1] /= len;
        dir[2] /= len;

        // 设置吸引速度
        new Float:speed = 400.0; // 吸引强度，可调
        new Float:vel[3];
        vel[0] = dir[0] * speed;
        vel[1] = dir[1] * speed;
        vel[2] = 400.0;

        set_entvar(id, var_velocity, vel);
    }
    m_print_color(0 , "!t[冰布提示] 紫色精英正在吸引附近玩家，请小心接近！")
}