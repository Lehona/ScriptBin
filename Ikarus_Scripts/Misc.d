// Gothic 2 only (except Mob_RemoveItems)

func void ShowManabar(var int bool) {
    var int tmp;

    MemoryProtectionOverride(/*0x006C33EC*/7091180, 4);

    if (bool) {
        tmp = 227218667; //00 00 00 EB
    }
    else {
        tmp = 227218549; //00 00 00 75
    };

    MEM_WriteInt(/*0x006C33EC*/ 7091180, tmp);
};

//  1 = ShowInFight
//  0 = ShowOutFight
// -1 = Normal
func void ShowManabarInFight(var int cond) {
    var int tmp;
    MemoryProtectionOverride(7091193, 8);

    if (cond == 1) {
        tmp = /*0x0F00F883*/ 251721859;
        MEM_WriteInt(7091193, tmp);
        tmp = /*0x00AB840F*/ 11240463;
        MEM_WriteInt(7091196, tmp);
    }
    else if (cond == 0) {
        tmp = /*0x0F00F883*/ 251721859;
        MEM_WriteInt(7091193, tmp);
        tmp = /*0x00AB850F*/ 11240719;
        MEM_WriteInt(7091196, tmp);
    }
    else if (cond == -1) {
        tmp = /*0F07F883*/ 252180611;
        MEM_WriteInt(7091193, tmp);
        tmp = /*0x00AB850F*/ 11240719;
        MEM_WriteInt(7091196, tmp);
    };
};

func int Log_GetTopicStatus(var string name) {
	const int logMan = 11191608; //0xaac538
    var zCList list; list = _^(logMan);
    
    while(list.next);
        list = _^(list.next);
        
        if (list.data) {
            if (Hlp_StrCmp(MEM_ReadString(list.data), name)) {
                return MEM_ReadInt(list.data + 24);
            };
        };
    end;
    
    return -1;
};

func void ChangeWorld (var string world, var string waypoint) 
{
    CALL_zStringPtrParam (waypoint);
    CALL_zStringPtrParam (world);
    CALL__thiscall (MEM_InstToPtr (MEM_Game), 7109360);
};


func void Mob_RemoveItems(var int mobPtr, var int instance, var int amount) {
    var oCMobContainer mob; mob = _^(mobPtr);
    var oCNpc helper; helper = Hlp_GetNpc(MEM_Helper);
	var int tmpInv; tmpInv = helper.inventory2_inventory_next;
    helper.inventory2_inventory_next = mob.containList_next;
    mob.containList_next = 0;
    Npc_RemoveInvItems(helper, instance, amount);
    mob.containList_next = helper.inventory2_inventory_next;
    helper.inventory2_inventory_next = tmpInv;
};

const int MUSIC_ORIGINAL = -1;
const int MUSIC_NORMAL = 0;
const int MUSIC_THREAT = 1;
const int MUSIC_FIGHT = 2;

func void SetMusicType(var int type) {
    if (type < MUSIC_ORIGINAL || type > MUSIC_FIGHT) {
        MEM_Error(ConcatStrings("SetMusicType: Invalid Music Type: ", IntToString(type)));
		return;
	};

    MemoryProtectionOverride(7089424, 6);
    if (type == MUSIC_ORIGINAL) { 
		MEM_WriteByte(7089424, 161);
		MEM_WriteByte(7089425, 132);
		MEM_WriteByte(7089426, 38);
		MEM_WriteByte(7089427, 171);
		MEM_WriteByte(7089428, 0);
		MEM_WriteByte(7089429, 86);
    } else {
		MEM_WriteByte(7089424, 184);
		MEM_WriteByte(7089425, type);
		MEM_WriteByte(7089426, 0);
		MEM_WriteByte(7089427, 0);
		MEM_WriteByte(7089428, 0);
		MEM_WriteByte(7089429, 195);
    };
};

func void GetPositionWorldVec(var int vobPtr, var int vecPtr) {
    var zCVob vob; vob = MEM_PtrToInst(vobPtr);
    MEM_WriteIntArray(vecPtr, 0, vob.trafoObjToWorld[3]);
    MEM_WriteIntArray(vecPtr, 1, vob.trafoObjToWorld[7]);
    MEM_WriteIntArray(vecPtr, 2, vob.trafoObjToWorld[11]);
};

func void SetPositionWorldVec(var int vobPtr, var int vecPtr) {
    const int zCVob_SetPositionWorld = 6404976; //0x61BB70

    CALL_PtrParam(vecPtr);
    CALL__thiscall(vobPtr, zCVob_SetPositionWorld);
};

func void VobPositionUpdated(var int vobPtr) {
    var int pos[3];
    GetPositionWorldVec(vobPtr, _@(pos));
    SetPositionWorldVec(vobPtr, _@(pos));
};

func void Npc_TeleportToWP(var C_Npc npc, var string wpname) 
{
	var oCNpc givenNpc; givenNpc = Hlp_GetNpc(npc);
	var zCWaypoint wp; wp = _^(SearchWaypointByName(wpname));
    GivenNpc._zCVob_trafoObjToWorld[zCVob_trafoObjToWorld_X] = wp.pos[0];
    GivenNpc._zCVob_trafoObjToWorld[zCVob_trafoObjToWorld_Y]  = wp.pos[1];
    GivenNpc._zCVob_trafoObjToWorld[zCVob_trafoObjToWorld_Z]  = wp.pos[2];
    VobPositionUpdated (_@(GivenNpc));
};

// Prevents Resetting of the player's ghost flag during/after a dialog... I think
func void disableGhostDisabling() { // Toller Name
	MemoryProtectionOverride(4871339, 35);
	const int fourNop = -1869574000; // 90909090h
	MEM_WriteInt(4871339, fourNop);
	MEM_WriteByte(4871343, 144);
	MEM_WriteByte(4871344, 144);
	MEM_WriteByte(4871345, 144);
		
	MEM_WriteInt(4871352, fourNop);
	MEM_WriteInt(4871356, fourNop);
	MEM_WriteByte(4871360, 144);
	MEM_WriteByte(4871361, 144);
};

/*
 * Check the inheritance of a zCObject against a zCClassDef. Emulating zCObject::CheckInheritance() at 0x476E30 in G2.
 * This function is used in Wld_StopEffect_Ext(). (mud-freak)
 */
func int objCheckInheritance(var int objPtr, var int classDef) {
    if (!objPtr) || (!classDef) {
        return 0;
    };

    const int zCClassDef_baseClassDef_offset = 60;  //0x003C

    // Iterate over base classes
    var int curClassDef; curClassDef = MEM_GetClassDef(objPtr);
    while((curClassDef) && (curClassDef != classDef));
        curClassDef = MEM_ReadInt(curClassDef+zCClassDef_baseClassDef_offset);
    end;

    return (curClassDef == classDef);
};
// (mud-freak)
func void stopAllSounds() {
    MEM_InitAll();

    const int zsound_G1 =  9236044; //0x8CEE4C 
    const int zsound_G2 = 10072124; //0x99B03C
    const int zCSndSys_MSS__RemoveAllActiveSounds_G1 = 5112224; //0x4E01A0 
    const int zCSndSys_MSS__RemoveAllActiveSounds_G2 = 5167008; //0x4ED7A0

    var int zsoundPtr; zsoundPtr = MEMINT_SwitchG1G2(MEM_ReadInt(zsound_G1), MEM_ReadInt(zsound_G2));
    const int call = 0;
    if (CALL_Begin(call)) {
        CALL__thiscall(_@(zsoundPtr), MEMINT_SwitchG1G2(zCSndSys_MSS__RemoveAllActiveSounds_G1,
                                                        zCSndSys_MSS__RemoveAllActiveSounds_G2));
        call = CALL_End();
    };
};

// Call this once per session with "false" to make rain not pass through vobs
func void rainThroughVobs(var int bool) {
    MemoryProtectionOverride(6169210, 4);
    if (!bool) {
        // bool == false -> Es regnet nicht mehr durch
        MEM_WriteByte(6169210, 224);
    } else {
        MEM_WriteByte(6169210, 226);
	};
};