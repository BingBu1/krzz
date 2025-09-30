#include <kr_core>
#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <cstrike>
#include <Npc_Manager>
#include <animation>

new Reg_Npcid , Moduleid

public plugin_init(){
    register_plugin("测试Npc行为" , "1.0" , "Bing")
    Reg_Npcid = NpcRegister(500.0 , Moduleid ,100.0 , 1.8, 30.0, 0.0, 0, 6, 18, 9, 23 )
    
    NpcSetNameAndLevel(Reg_Npcid , "嗜血狗" , 500)
}

public plugin_precache(){
    // Moduleid = precache_model("models/Kr_npcs/officer.mdl")
    Moduleid = precache_model("models/Bing_Kr_res/Kr_npcs/Small_Boss.mdl")
}

public NpcOnCreate(Npcid , RegId){
    if(RegId == Reg_Npcid){
        // SetBodyGroup(Npcid , 2  , 5)
    }
}

public NpcDoAttack(Npcid , Target){
    if(get_prop_int(Npcid , var_npcid) != Reg_Npcid){
        return
    }
    new Float:Health = get_entvar(Npcid , var_health)
    new master = get_prop_int(Npcid , var_master)
    new Float:fOrigin[3]
    get_entvar(Npcid , var_origin , fOrigin)
    NpcRadiusDamge(fOrigin , master, Npcid ,  random_float(300.0 , 600.0) , 200.0 , DMG_GENERIC)
    if( Health < 500.0){
        Health += 5.0
        set_entvar(Npcid , var_health , Health)
    }
}

public NpcOnSkill(Npcid , target){

    set_prop_float(Npcid , var_skillcd , get_gametime() + 5.0)
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

stock rg_radius_damage(const Float:origin[3], attacker, inflictor, Float:damage, Float:radius, dmg_bits)
{
    new ent = -1
    new Float:target_origin[3]
    new Float:distance
    new Float:final_damage
	new Float:Origin_[3]
	new Float:Heal;

    while ((ent = find_ent_in_sphere(ent, origin, radius)) != 0)
    {
        if (!is_valid_ent(ent)) continue
		if(pev(ent,pev_takedamage) == DAMAGE_NO) continue
        if(!FClassnameIs(ent , "hostage_entity")) continue

		new deadflag
		pev(ent , pev_deadflag,deadflag)
		
		if(deadflag != DEAD_NO) continue

        get_entvar(ent, var_origin, target_origin)
        distance = vector_distance(origin, target_origin)

        // ���Եݼ��˺���ԽԶԽ�ͣ�
        final_damage = damage

		if(ent == attacker) continue;

		get_entvar(ent , var_health , Heal);

		new kill = Heal - final_damage;

        NpcTakeDamge(inflictor , ent , final_damage)
    }
}