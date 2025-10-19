    #include <amxmodx>
    #include <PlayerSkill>
    #include <reapi>
    #include <engine>
    #include <fakemeta>
    #include <kr_core>
    #include <props>
    #include <hamsandwich>
    #include <fakemeta_util>


    #define var_NextFindTimer "Ntr"
    #define var_NextAttackTimer "AtTim"
    #define var_NextAttackFire "FirTim"
    #define var_NextSounds "SoundsN"
    #define var_Fireed "Fired"

    new sTrail , g_Explosion

    new PujingSkill[][]= {
        "models/Bing_Kr_res/Kr_Skill/apachef.mdl",
    }

    new Sounds[][]={
        "kr_sound/ap_rotor4.wav",
        "kr_sound/Rocket-1.wav",
        "kr_sound/turret-1.wav",
    }

    public plugin_init(){
        new plid = register_plugin("角色技能-普京" , "1.0" , "Bing")

        register_event("HLTV", "event_roundstart", "a", "1=0", "2=0")

        RegPlayerSkill(plid , "apache" , "pujing" , 60.0)
    }

    public event_roundstart(){
        new ent = -1
        while((ent = rg_find_ent_by_class(ent , "apache")) > 0){
            rg_remove_entity(ent)
        }
    }


    public plugin_precache(){
        for(new i = 0 ; i < sizeof PujingSkill ; i++){
            precache_model(PujingSkill[i])
        }
        for(new i = 0 ; i < sizeof Sounds ; i++){
            precache_sound(Sounds[i])
        }
        sTrail = precache_model("sprites/laserbeam.spr")
        g_Explosion = precache_model("sprites/zerogxplode.spr")

    }

    // 阿帕奇支援
    public apache(id){
        new username[32]
        new ent = rg_create_entity("info_target")
        if(is_nullent(ent))
            return
        new Float:fOrigin[3]
        get_entvar(id , var_origin , fOrigin)
        fOrigin[2] += 180.0
        get_user_name(id , username , charsmax(username))
        set_entvar(ent , var_classname , "apache")
        set_entvar(ent , var_origin , fOrigin)
        set_entvar(ent , var_fuser1 , get_gametime() + 40.0)
        set_entvar(ent , var_owner , id)
        set_entvar(ent, var_framerate, 1.0)
        engfunc(EngFunc_SetModel , ent , PujingSkill[0])
        m_print_color(0 , "!g[冰布提示]!t%s释放了普京技能，阿帕奇支援。" , username)

        SetThink(ent , "ApaqiThink")
        set_entvar(ent , var_nextthink , get_gametime() + 0.1)

        set_prop_float(ent , var_NextFindTimer , get_gametime() + random_float(1.0 , 1.5))
        set_prop_float(ent , var_NextAttackTimer , get_gametime())
        set_prop_float(ent , var_NextAttackFire , get_gametime())
        set_prop_float(ent , var_NextSounds , get_gametime())

        set_prop_int(ent , var_Fireed , 0)

    }

    public ApaqiThink(ent){
        new Float:fOrigin[3]
        new master = get_entvar(ent , var_owner)
        get_entvar(master , var_origin , fOrigin)
        fOrigin[2] += 500.0
        set_entvar(ent , var_origin , fOrigin)
        set_entvar(ent , var_nextthink , get_gametime() + 0.01)
        new Float:NextFindTimer = get_prop_float(ent , var_NextFindTimer)
        new Attack = -1
        if(get_gametime() > NextFindTimer){
            Attack = FindNearNpc(ent)
            set_prop_float(ent , var_NextFindTimer , get_gametime() + random_float(1.0 , 1.5))
        }
        
        if(Attack == -1){
            Attack = FindNearNpc(ent)
        }

        new Float:AttackTiner = get_prop_float(ent , var_NextAttackTimer)
        new Float:FireNext  = get_prop_float(ent , var_NextAttackFire)
        new Float:NextS  = get_prop_float(ent , var_NextSounds)
        new Fired = get_prop_int(ent , var_Fireed)
        if(Attack <= 0){
            new Float:newAngles[3]
            get_entvar(ent , var_angles , newAngles)
            newAngles[0] = 0.0
            set_entvar(ent , var_angles , newAngles)
        }

        if(Attack != -1 && get_gametime() > AttackTiner){
            new Float:TargetOrigin[3], Float:dir[3] ,Float:newAngles[3]
            get_entvar(Attack , var_origin , TargetOrigin)
            xs_vec_sub(TargetOrigin, fOrigin, dir)
            vector_to_angle(dir, newAngles)
            newAngles[0] = 0.0
            set_entvar(ent , var_angles , newAngles)

            MakeBullets(fOrigin , TargetOrigin)
            ExecuteHamB(Ham_TakeDamage , Attack , master , master , 120.0 , DMG_BULLET)

            set_prop_float(ent , var_NextAttackTimer , get_gametime() + 0.05)
            emit_sound(master, CHAN_AUTO, Sounds[2], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
        }

        if(Attack != -1 &&  get_gametime() > FireNext){
            new Boom = CreateTankBoom(ent , Attack)
            set_entvar(Boom , var_owner , master)
            
            if(Fired < 10){
                set_prop_float(ent , var_NextAttackFire , get_gametime() + 0.15)
            }else{
                set_prop_float(ent , var_NextAttackFire , get_gametime() + 5.0)
                Fired = 0
            }
            Fired++
            set_prop_int(ent , var_Fireed , Fired)
            emit_sound(master, CHAN_AUTO, Sounds[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
        }

        if(get_gametime() > NextS){
            emit_sound(master, CHAN_BODY, Sounds[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
            set_prop_float(ent , var_NextSounds , get_gametime() + 3.1)
        }
        

        if(get_gametime() > get_entvar(ent , var_fuser1)){
            rg_remove_entity(ent)
            return
        }
    }


    public FindNearNpc(Apaqi){
        new Float:fOrigin[3] ,Origin2D[3]
        new Float:TmpDis , Float:Dis = 99999.0
        new Float:Dis2d
        new target = -1
        new ent = -1
        get_entvar(Apaqi , var_origin , fOrigin)
        Origin2D[0] = fOrigin[0]
        Origin2D[1] = fOrigin[1]
        Origin2D[2] = 0.0
        while ((ent = rg_find_ent_by_class(ent , "hostage_entity" , true)) > 0){
            if(is_nullent(ent))continue
            if(KrGetFakeTeam(ent) == _:CS_TEAM_T) continue
            if(get_entvar(ent , var_deadflag) == DEAD_DEAD)continue

            get_entvar(ent , var_origin , fOrigin)
            
            TmpDis = fm_distance_to_boxent(Apaqi , ent)
            fOrigin[2] = 0.0
            Dis2d = vector_distance(Origin2D , fOrigin) 

            if(Dis2d > 500.0) continue

            if((TmpDis < Dis && get_entvar(ent , var_deadflag) == DEAD_NO)){
                target = ent
                Dis = TmpDis
            }
        }
        return target
    }

    stock MakeBullets(Float:Start[3] , Float:End[3]){
        message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
        write_byte(TE_TRACER)
        write_coord_f(Start[0])
        write_coord_f(Start[1])
        write_coord_f(Start[2])
        write_coord_f(End[0])
        write_coord_f(End[1])
        write_coord_f(End[2])
        message_end()
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
        set_entvar(tk_ent,var_movetype, MOVETYPE_NOCLIP)
        set_entvar(tk_ent , var_solid, SOLID_TRIGGER)
        set_entvar(tk_ent,var_origin,org)
        set_entvar(tk_ent,var_velocity,vec)
        set_entvar(tk_ent, var_classname,"tk_boom")
        set_entvar(tk_ent, var_rendermode,kRenderTransAdd)
        set_entvar(tk_ent, var_renderamt,255.0)
        set_entvar(tk_ent , var_nextthink , get_gametime() + 0.01)
        set_entvar(tk_ent , var_fuser1 , get_gametime() + 10.0)

        

        engfunc(EngFunc_SetModel,tk_ent, "sprites/blueflare1.spr")
        engfunc(EngFunc_SetSize,tk_ent,Float:{-1.0, -1.0, -1.0},Float:{1.0, 1.0, 1.0})

        SetTouch(tk_ent,"tk_Touch")
        SetThink(tk_ent,"tk_Think")

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

    public tk_Think(this){
        new Float:fOrigin[3]
        get_entvar(this, var_origin, fOrigin)
        new master = get_entvar(this , var_owner)
        if(get_entvar(master , var_deadflag) == DEAD_DEAD){
            rg_remove_entity(this)
            return
        }

        new ent = -1
        while((ent = find_ent_in_sphere(ent , fOrigin , 55.0)) > 0){
            if(ent != this && get_entvar(ent , var_flags) & FL_MONSTER){
                new Float:org[3]
                get_entvar(ent, var_origin, org)
                MakeBoom(org)  // 生成爆炸效果
                // 标记删除
                set_entvar(this, var_flags, FL_KILLME)
                rg_dmg_radius(org , master , master , 300.0 , 350.0 , CLASS_PLAYER , DMG_BLAST)
                break
            }
        }
        set_entvar(this ,var_nextthink, get_gametime() + random_float(0.1,0.3))
        new Attack = FindNearNpc(this)
        if(Attack > 0){
            lerp(this , Attack)
        }
        if(get_gametime() > get_entvar(this , var_fuser1)){
            rg_remove_entity(this)
            return
        }
    }

    public lerp(ent , target){
        new Float:vel[3],Float:org[3],Float:targetorg[3],Float:dir[3]
	    get_entvar(ent, var_velocity, vel)
	    get_entvar(ent, var_origin, org)
	    get_entvar(target, var_origin, targetorg)
	    targetorg[2] += 30.0
	    xs_vec_sub(targetorg, org, dir)
	    xs_vec_normalize(dir, dir)

	    // 当前速度转为单位方向
        new Float:curdir[3]
        xs_vec_normalize(vel, curdir)

	    new Float:newdir[3]
	    xs_vec_lerp(curdir, dir, 1.0, newdir)
	    xs_vec_normalize(newdir, newdir)

	    new Float:new_angles[3]
	    vector_to_angle(newdir, new_angles)   // 把方向向量转换成角度 (pitch, yaw, roll)
	    set_entvar(ent, var_angles, new_angles)
    

	    new Float:new_vel[3]
	    xs_vec_mul_scalar(newdir, 1000.0, new_vel)
	    set_entvar(ent, var_velocity, new_vel)

	    set_entvar(ent, var_nextthink, get_gametime() + 0.15)
    }

    public tk_Touch(this , other){
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
        rg_dmg_radius(org , master , master , 230.0 , 300.0 , CLASS_PLAYER , DMG_BLAST)
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

    stock xs_vec_lerp(const Float:a[3], const Float:b[3], Float:factor, Float:out[3]) {
    for (new i = 0; i < 3; i++) {
        out[i] = a[i] + (b[i] - a[i]) * factor
    }
}