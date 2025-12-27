#include <amxmodx>
#include <PlayerSkill>
#include <reapi>
#include <engine>
#include <fakemeta>
#include <kr_core>
#include <cstrike>
#include <hamsandwich>
#include <props>

new Float:g_OldDamageValue

new DonkGun[33]

new g_DeadMsg

#define DonkGunId 1919010

#define isDonkGun(%1) get_entvar(%1 , var_impulse) == DonkGunId

public plugin_init(){
    new plid = register_plugin("角色技能-Donk" , "1.0" , "Bing")
    RegPlayerSkill(plid , "DonkSkill" , "cs2" , 160.0)
    g_DeadMsg = get_user_msgid("DeathMsg")
}

public plugin_precache(){
    UTIL_Precache_Sound("kr_sound/headshot.wav")
}


// 戈登
public DonkSkill(id){
    new username[32]
    get_user_name(id , username , charsmax(username))
    m_print_color(0 , "!g[冰布提示]!t%s释放了Donk技能:育苗小学" , username)
    GiveDonkGun(id)
}


public GiveDonkGun(id){
    new weapon = rg_give_custom_item(id , "weapon_ak47" , GT_APPEND , DonkGunId)
    if(is_nullent(weapon)){
        SetSkillCd(id , 0.0)
        m_print_color(id , "!g[冰布提示]!tAk47已被占用,技能释放失败。")
        return
    }
    SetThink(weapon , "DonkGunThink")
    set_entvar(weapon , var_nextthink , get_gametime() + 0.1)
    DonkGun[id] = weapon
    set_task(60.0 , "RemoveDonkGun" , id + DonkGunId)
    engclient_cmd(id , "weapon_ak47")
    set_member(weapon , m_Weapon_iClip , 60)
    rg_set_iteminfo(weapon , ItemInfo_iMaxClip , 60)
    rg_set_user_bpammo(id , WEAPON_AK47 , 99999)
}

public RemoveDonkGun(id){
    new player = id - DonkGunId
    if(!is_user_connected(player))
        return
    new wpn = DonkGun[player]
    if(is_entity(wpn) && is_valid_ent(wpn))
        rg_remove_entity(wpn)
    DonkGun[player] = 0
}

public DonkGunThink(wpn){
    new owner = get_member(wpn , m_pPlayer)
    new current_weapon = 0
    if(!is_user_connected(owner) || !is_user_alive(owner)){
        rg_remove_entity(wpn)
        return
    }
    set_entvar(wpn , var_nextthink , get_gametime() + 0.4)
    current_weapon = get_member(owner , m_pActiveItem)
    if(!isDonkGun(current_weapon))
        return
    new Clip = set_member(current_weapon , m_Weapon_iClip , 60)
    // if(Clip <= 0 ){
    //     return
    // }
    new Array:g_DonkAttackList = ArrayCreate()

    FindAttack(owner , g_DonkAttackList)

    if(ArraySize(g_DonkAttackList) <= 0){
        ArrayDestroy(g_DonkAttackList)
        return
    }
    DonkAttack(owner , current_weapon, g_DonkAttackList)
    ArrayDestroy(g_DonkAttackList)
}


DonkAttack(player , wpn , Array:ArrayHandle){
    new len = ArraySize(ArrayHandle)
    for(new i = 0 ; i < len ; i++){
        new ent = ArrayGetCell(ArrayHandle , i)
        if(!is_valid_ent(ent))
            continue
        new isTank = is_tank(ent)
        new is_special = get_entvar(ent, var_renderfx) == kRenderFxGlowShell
        new Float:damage = get_entvar(ent , var_health)
        new dmgtype = DMG_NOARMOR
        ExecuteHam(Ham_Weapon_PrimaryAttack , wpn)

        ChangeFireTime(player , -1.0 , -0.001)

        if(isTank || is_special){
            dmgtype = DMG_BULLET
            damage = get_entvar(ent , var_max_health) * 0.3
        }
        set_msg_block(g_DeadMsg , MSG_BLOCK_SET)
        ExecuteHamB(Ham_TakeDamage , ent , player , player , damage , dmgtype)
        new Float:heal = get_entvar(ent , var_health)
        if(heal <= 0.0){
            SendDeathMessage(player)
        }
        set_msg_block(g_DeadMsg , MSG_BLOCK_NOT)
    }
    UTIL_EmitSound_ByCmd2(player , "kr_sound/headshot.wav" , 500.0)
}

public SendDeathMessage(attacker){
    new vim = GetFakeClient()
	if(!is_valid_ent(vim) || !is_valid_ent(attacker))
		return
	if(vim <= 0 || vim >= MaxClients)
		return
	if(!ExecuteHam(Ham_IsPlayer , attacker) || !is_user_connected(attacker))
		return
	new waeponname [32]
	new wpnid = cs_get_user_weapon(attacker)
	if(wpnid){
		get_weaponname(wpnid, waeponname, charsmax(waeponname))
	}else{
		copy(waeponname , 31 , "NoWeapon")
	}
	
	replace_all(waeponname, charsmax(waeponname), "weapon_" , "")
	message_begin(MSG_BROADCAST, g_DeadMsg)
	write_byte(attacker)
	write_byte(vim)
	write_byte(1)
	write_string(waeponname)
	message_end()
}

FindAttack(player , Array:ArrayHandle){
    if(!is_user_alive(player))
        return NULLENT
    new CsTeams:team = cs_get_user_team(player)
    new ent = -1
    while((ent = rg_find_ent_by_class(ent , "hostage_entity" , true)) > 0){
        if(GetIsNpc(ent) && KrGetFakeTeam(ent) == team)
            continue
        new TrHit = 0
        if(cs_get_hostage_foll(ent) == player && TraceCanSee(ent , player , TrHit)){
            ArrayPushCell(ArrayHandle , ent)
            continue
        }
    }

}


ChangeFireTime(Player , Float:Prtime , Float:SecTime){
    for(new i = 0 ; i < MAX_ITEM_TYPES; i++){
        new PPlayetItem = get_member(Player , m_rgpPlayerItems , i)
        while(PPlayetItem > 0){
            new Float:flNextPrimaryAttack = get_member(PPlayetItem , m_Weapon_flNextPrimaryAttack)
            new Float:flNextSecondaryAttack = get_member(PPlayetItem , m_Weapon_flNextSecondaryAttack)
            flNextPrimaryAttack = floatmax(Prtime, -1.0)
            flNextSecondaryAttack = floatmax(SecTime, -0.001)
            set_member(PPlayetItem , m_Weapon_flNextPrimaryAttack , flNextPrimaryAttack)
            set_member(PPlayetItem , m_Weapon_flNextSecondaryAttack , flNextSecondaryAttack)
            PPlayetItem = get_member(PPlayetItem , m_pNext)
        }
    }
    new Float:NextAttack = get_member(Player , m_flNextAttack)
    NextAttack = floatmax(SecTime , -0.001)
    set_member(Player , m_flNextAttack , NextAttack)
}

stock bool:TraceCanSee(entindex1, entindex2 , &TrHit){

	new flags = get_entvar(entindex1, var_flags)
	TrHit = 0
	if (flags & EF_NODRAW){
        return false
    }
	
	new Float:lookerOrig[3],Float:targetBaseOrig[3],Float:targetOrig[3],Float:temp[3],i
	get_entvar(entindex1, var_origin, lookerOrig)
	get_entvar(entindex1, var_view_ofs, temp)
	for(i = 0; i < 3; i++) lookerOrig[i] += temp[i]
	
	get_entvar(entindex2, var_origin, targetBaseOrig)
	get_entvar(entindex2, var_view_ofs, temp)
	for(i = 0; i < 3; i++) targetOrig[i] = targetBaseOrig[i] + temp[i]
	
	engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the had of seen player
	
	if (get_tr2(0, TraceResult:TR_InOpen) && get_tr2(0, TraceResult:TR_InWater)) return false
	else 
	{
		new Float:flFraction
		get_tr2(0, TraceResult:TR_flFraction, flFraction)
		TrHit = get_tr2(0, TraceResult:TR_pHit)
		if (flFraction == 1.0 ||  TrHit == entindex2){
             return true
        }
		else
		{
			for(i = 0; i < 3; i++) targetOrig[i] = targetBaseOrig[i]
			engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the body of seen player
			get_tr2(0, TraceResult:TR_flFraction, flFraction)
			TrHit = get_tr2(0, TraceResult:TR_pHit)
			if (flFraction == 1.0 || TrHit == entindex2){
                return true
            }
			else
			{
				targetOrig[0] = targetBaseOrig [0]
				targetOrig[1] = targetBaseOrig [1]
				targetOrig[2] = targetBaseOrig [2] - 17.0
				engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the legs of seen player
				get_tr2(0, TraceResult:TR_flFraction, flFraction)
				TrHit = get_tr2(0, TraceResult:TR_pHit)
				if (flFraction == 1.0 ||  TrHit == entindex2)
					return true
			}
		}
	}
	return false
}