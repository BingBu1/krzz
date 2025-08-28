#include <amxmodx>
#include <fakemeta>
#include <cstrike>
#include <reapi>
#include <kr_core>
#include <props>
#include <fakemeta_util>
#include <xp_module>
#include <roundrule>
enum TankModle_e{
    Tk_alive,
    Tk_die
}

new has_tank

new CurrentTankEnt

new TankModle[][]={
"models/rainych/krzz/tank.mdl",
"models/rainych/krzz/tank_died.mdl"
}

new firesound[][]={
    "weapons/357_shot1.wav",
    "weapons/357_shot2.wav"
}

new g_Explosion,sTrail

new BossNpc

new TankBoom[] = "sprites/blueflare1.spr"

new const GRENADE_TRAIL[] = "sprites/laserbeam.spr"

public plugin_init(){
    register_plugin("特殊日本Npc", "1.0", "Bing")
    register_event("HLTV", "event_roundstart", "a", "1=0", "2=0")
}

public plugin_precache(){
    precache_model(TankModle[Tk_alive])
    precache_model(TankModle[Tk_die])

    for(new i = 0 ; i <sizeof firesound ; i++){
        precache_sound(firesound[i])
    }
    g_Explosion = precache_model("sprites/zerogxplode.spr")
    sTrail = precache_model(GRENADE_TRAIL)
    precache_model(TankBoom)
}

public plugin_natives(){
    register_native("is_tank" , "native_is_tank")
    register_native("GetTankNpcEnt" , "native_GetTankNpcEnt")
}

public native_GetTankNpcEnt(){
    return CurrentTankEnt
}

public NPC_CreatePost(ent){
    new Judian_num = GetJuDianNum()
    new level = Getleavel()
    if(level > 30 && Judian_num < 7 && BossNpc < 3){
        //尝试产出精英
        if(RandFloatEvents(0.01) ){
            new Float:Heal = 100.0 + (60.0 * float(level))
            Heal = floatmin(Heal , 15000.0)
            new Float:Color[3]= {255.0,255.0,255.0}
            set_entvar(ent, var_renderfx, kRenderFxGlowShell)
            set_entvar(ent, var_rendercolor, Color)
            set_entvar(ent ,var_renderamt , 1.0)
            set_entvar(ent, var_health, Heal)
            set_entvar(ent, var_max_health, Heal)
            set_entvar(ent, var_iuser1 , 1)
            BossNpc++
        }
    }
    if(Judian_num == 8 && !has_tank){
        //如果不存在坦克创建
        new Float:Heal = 5000.0 + (250.0 * float(level))
        
        engfunc(EngFunc_SetModel , ent , TankModle[Tk_alive])
        //重置size
        dllfunc(DLLFunc_Spawn, ent)

        set_entvar(ent , var_health, Heal)
        set_entvar(ent, var_max_health , Heal)
        set_entvar(ent, var_body, 0)
        set_prop_int(ent , "istank" , 1)
        set_prop_int(ent, "CanStop", 1)  //无法被武器定身，和出现受伤动画

        CurrentTankEnt = ent
        has_tank = true
        return
    }
    if(GetJuDianNum() == 8){
        new Float:maxHeal = 2000.0//基础血量
        maxHeal = maxHeal + (150.0 * float(level))
        set_entvar(ent , var_max_health, maxHeal)
        set_entvar(ent , var_health, maxHeal)
    }
    if(GetRiJunRule() == JAP_RULE_Tank_Rampage && UTIL_RandFloatEvents(0.01)){
        engfunc(EngFunc_SetModel , ent , TankModle[Tk_alive])
        //重置size
        dllfunc(DLLFunc_Spawn, ent)

        set_prop_int(ent , "istank" , 1)
        set_prop_int(ent, "CanStop", 1)  //无法被武器定身，和出现受伤动画
    }
}

public NPC_ThinkPost(ent){
    new Judian_num = GetJuDianNum()
    new hitent
    new follent
    new Float:origin[3], Float:targetorigin[3],Float:hitorigin[3]
    //小于7不存在开枪的特殊兵种
    if(GetRiJunRule() == JAP_RULE_Tank_Rampage && is_tank(ent)){
        follent = cs_get_hostage_foll(ent)
        if(!follent )
            return 0
        get_entvar(ent,var_origin,origin)
        get_entvar(follent,var_origin,targetorigin)
        hitent = fm_trace_line(ent,origin,targetorigin,hitorigin)
        goto TankAi;
    }
    if(Judian_num < 7)
        return 0
    new body = get_entvar(ent , var_body)
    new istank = is_tank(ent)
    
    follent = cs_get_hostage_foll(ent)
    if(!follent )
        return 0
    get_entvar(ent,var_origin,origin)
    get_entvar(follent,var_origin,targetorigin)
    hitent = fm_trace_line(ent,origin,targetorigin,hitorigin)
    if(body == 7){
        //处理开枪
        if(hitent != follent)
            return 0
        InitAttack2Timer(ent,3.0,8.0)
        new Float:attacktimer = get_prop_float(ent,"attackfire")
        if(get_gametime() > attacktimer){
            set_msg_block(get_user_msgid("DeathMsg"), BLOCK_ONCE)
            FireBullets(ent,follent)
            set_msg_block(get_user_msgid("DeathMsg"), BLOCK_NOT)
            ResetAttack2(ent,3.0,8.0)
        }
    }else if (Judian_num == 8 && !istank){
        //军官 开枪 手榴弹逻辑
        if(hitent != follent)
            return 0
        InitAttack2Timer(ent,3.0,8.0)
        new Float:attacktimer = get_prop_float(ent,"attackfire")
        if(get_gametime() > attacktimer){
            new randattack = random_num(0,1)
            set_msg_block(get_user_msgid("DeathMsg"), BLOCK_ONCE)
            if(randattack == 1){
                FireBullets(ent,follent,5.0)
            }else{
                ThrowHeGrenade(ent)
            }
            set_msg_block(get_user_msgid("DeathMsg"), BLOCK_NOT)
            ResetAttack2(ent,3.0,10.0)
        }
    }else if(Judian_num == 8 && istank){
        TankAi:
        //坦克 开炮 机枪逻辑
        if(hitent != follent)
            return 0
        InitAttack2Timer(ent,3.0,8.0)
        new Float:attacktimer = get_prop_float(ent,"attackfire")
        if(get_gametime() > attacktimer){
            new randattack = random_num(0,1)
            CreateTankBoom(ent,follent)
            ResetAttack2(ent,3.0,10.0)
        }
    }
}

public event_roundstart(){
    has_tank = false
    CurrentTankEnt = 0
    BossNpc = 0
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

public NPC_Killed(this , killer){
    if(get_entvar(this,var_iuser1) == 1){
        new lv = Getleavel()
        new baseaddxp = 100 + random_num(0 , lv * 5)
        AddXp(killer, baseaddxp)
        m_print_color(killer , "!g[击杀]击杀精英额外获得%d积分", baseaddxp)
        set_entvar(this, var_iuser1, 0)
        BossNpc--
    }
    if(has_tank && this == CurrentTankEnt){
        new origin[3]
        get_entvar(this,var_origin,origin)
        engfunc(EngFunc_SetModel , this , TankModle[Tk_die])
        MakeBoom(origin)
        AddKillTank(killer)
        KillTank_reward(killer)
    }
}

public KillTank_reward(id){
    if(!is_user_connected(id))
        return
    new Randreward = random_num(0,1)
    //大洋奖励
    new name[32]
    get_user_name(id, name, 31)
    if(Randreward == 0) {
        new const Float:Base = 1.0
        new Float:MinAmmo = 1.0 + float(Getleavel()) / 0.5
        new Float:MaxAmmo = (Base + float(Getleavel())) * 2.0
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
}

public MakeBoom(Float:iOrigin[3]){
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY, iOrigin)
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
    set_entvar(tk_ent,var_movetype,MOVETYPE_FLY)
    set_entvar(tk_ent , var_solid, SOLID_BBOX)
    set_entvar(tk_ent,var_origin,org)
    set_entvar(tk_ent,var_velocity,vec)
    set_entvar(tk_ent, var_classname,"tk_boom")
    set_entvar(tk_ent, var_rendermode,kRenderTransAdd)
    set_entvar(tk_ent, var_renderamt,255.0)

    

    engfunc(EngFunc_SetModel,tk_ent,TankBoom)
    engfunc(EngFunc_SetSize,tk_ent,Float:{-1.0, -1.0, -1.0},Float:{-1.0, 1.0, 1.0})

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

    new maxPlayers = get_maxplayers()
    for (new i = 1; i <= maxPlayers; i++) {
        if (!is_user_alive(i) || !is_user_connected(i))
            continue
        if (get_user_team(i) != CS_TEAM_T)
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


stock bool:RandFloatEvents(Float:Probability){
    if(Probability >=1.0)
        return true
    new Float:randnum = random_float(0.0,1.0)
    if(randnum <= Probability)
        return true
    return false
}
