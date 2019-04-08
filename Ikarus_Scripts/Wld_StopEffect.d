// Extended functionality for Wld_StopEffect()
// See https://forum.worldofplayers.de/forum/threads/1495001-Scriptsammlung-ScriptBin?p=25548652&viewfull=1#post25548652
// Made by mud-freak (@szapp) 2017-08-05 (modified 2017-08-09)
//
// Compatible with Gothic 1 and Gothic 2
// Requirements: Ikarus 1.2




/*
 * Emulate the Gothic 2 external function Wld_StopEffect(), with additional settings: Usually it is not clear which
 * effect will be stopped, leading to effects getting "stuck". Here, Wld_StopEffect is extended with additional checks
 * for origin and/or target vob and whether to stop all matching FX or only the first one found (like in Wld_StopEffect)
 * The function returns the number of stopped effects, or zero if none was found or an error occurred.
 * Compatible with Gothic 1 and Gothic 2. This means there is finally the possibility to stop effects in Gothic 1!
 *
 * Examples:
 *  var C_NPC Diego; Diego = Hlp_GetNpc(PC_ThiefOW);
 *  Wld_PlayEffect("SPELLFX_SLEEPER_FIREBALL", self, Diego, 2, 150, DAM_FIRE, TRUE);
 *  Wld_PlayEffect("SPELLFX_SLEEPER_FIREBALL", self, hero,  2, 150, DAM_FIRE, TRUE);
 *  Wld_StopEffect_Ext("SPELLFX_SLEEPER_FIREBALL", 0, Diego, 0); // Stops only the first effect
 *
 *  Calling Wld_StopEffect("EFFECT_1") corresponds to Wld_StopEffect_Ext("EFFECT_1", 0, 0, 0).
 *
 * Big parts if this function are taken from Wld_StopEffect. Gothic 2: sub_006E32B0() 0x6E32B0
 */
func int Wld_StopEffect_Ext(var string effectName, var int originInst, var int targetInst, var int all) {
    // Gothic 1 addresses and offsets
    const int zCVob__classDef_G1                =  9269976; //0x8D72D8
    const int zCWorld__SearchVobListByClass_G1  =  6249792; //0x5F5D40
    const int oCVisualFX__classDef_G1           =  8822272; //0x869E00
    const int oCVisualFX__Stop_G1               =  4766512; //0x48BB30
    const int oCVisualFX_originVob_offset_G1    =     1112; //0x0458
    const int oCVisualFX_targetVob_offset_G1    =     1120; //0x0460
    const int oCVisualFX_instanceName_offset_G1 =     1140; //0x0474

    // Gothic 2 addresses and offsets
    const int zCVob__classDef_G2                = 10106072; //0x9A34D8
    const int zCWorld__SearchVobListByClass_G2  =  6439504; //0x624250
    const int oCVisualFX__classDef_G2           =  9234008; //0x8CE658
    const int oCVisualFX__Stop_G2               =  4799456; //0x493BE0
    const int oCVisualFX_originVob_offset_G2    =     1192; //0x04A8
    const int oCVisualFX_targetVob_offset_G2    =     1200; //0x04B0
    const int oCVisualFX_instanceName_offset_G2 =     1220; //0x04C4

    var int zCVob__classDef;
    var int zCWorld__SearchVobListByClass;
    var int oCVisualFX__classDef;
    var int oCVisualFX__Stop;
    var int oCVisualFX_originVob_offset;
    var int oCVisualFX_targetVob_offset;
    var int oCVisualFX_instanceName_offset;
    zCVob__classDef                = MEMINT_SwitchG1G2(zCVob__classDef_G1,
                                                       zCVob__classDef_G2);
    zCWorld__SearchVobListByClass  = MEMINT_SwitchG1G2(zCWorld__SearchVobListByClass_G1,
                                                       zCWorld__SearchVobListByClass_G2);
    oCVisualFX__classDef           = MEMINT_SwitchG1G2(oCVisualFX__classDef_G1,
                                                       oCVisualFX__classDef_G2);
    oCVisualFX__Stop               = MEMINT_SwitchG1G2(oCVisualFX__Stop_G1,
                                                       oCVisualFX__Stop_G2);
    oCVisualFX_originVob_offset    = MEMINT_SwitchG1G2(oCVisualFX_originVob_offset_G1,
                                                       oCVisualFX_originVob_offset_G2);
    oCVisualFX_targetVob_offset    = MEMINT_SwitchG1G2(oCVisualFX_targetVob_offset_G1,
                                                       oCVisualFX_targetVob_offset_G2);
    oCVisualFX_instanceName_offset = MEMINT_SwitchG1G2(oCVisualFX_instanceName_offset_G1,
                                                       oCVisualFX_instanceName_offset_G2);

    var int worldPtr; worldPtr = _@(MEM_World);
    if (!worldPtr) {
        return 0;
    };

    // Create array from all oCVisualFX vobs
    var int vobArrayPtr; vobArrayPtr = MEM_ArrayCreate();
    var zCArray vobArray; vobArray = _^(vobArrayPtr);
    const int call = 0; var int zero;
    if (CALL_Begin(call)) {
        CALL_PtrParam(_@(zero));                 // Vob tree (0 == globalVobTree)
        CALL_PtrParam(_@(vobArrayPtr));          // Array to store found vobs in
        CALL_PtrParam(_@(oCVisualFX__classDef)); // Class definition
        CALL__thiscall(_@(worldPtr), zCWorld__SearchVobListByClass);
        call = CALL_End();
    };

    if (!vobArray.numInArray) {
        MEM_ArrayFree(vobArrayPtr);
        return 0;
    };

    effectName = STR_Upper(effectName);

    var zCPar_Symbol symb;

    // Validate origin vob instance
    if (originInst) {
        // Get pointer from instance symbol
        if (originInst > 0) && (originInst < MEM_Parser.symtab_table_numInArray) {
            symb = _^(MEM_ReadIntArray(contentSymbolTableAddress, originInst));
            originInst = symb.offset;
        } else {
            originInst = 0;
        };

        if (!objCheckInheritance(originInst, zCVob__classDef)) {
            MEM_Warn("Wld_StopEffect_Ext: Origin is not a valid vob");
            return 0;
        };
    };

    // Validate target vob instance
    if (targetInst) {
        // Get pointer from instance symbol
        if (targetInst > 0) && (targetInst < MEM_Parser.symtab_table_numInArray) {
            symb = _^(MEM_ReadIntArray(contentSymbolTableAddress, targetInst));
            targetInst = symb.offset;
        } else {
            targetInst = 0;
        };

        if (!objCheckInheritance(targetInst, zCVob__classDef)) {
            MEM_Warn("Wld_StopEffect_Ext: Target is not a valid vob");
            return 0;
        };
    };

    // Search all vobs for the matching name
    var int stopped; stopped = 0; // Number of FX stopped
    repeat(i, vobArray.numInArray); var int i;
        var int vobPtr; vobPtr = MEM_ArrayRead(vobArrayPtr, i);
        if (!vobPtr) {
            continue;
        };

        // Search for FX with matching name
        if (!Hlp_StrCmp(effectName, "")) {
            var string effectInst; effectInst = MEM_ReadString(vobPtr+oCVisualFX_instanceName_offset);
            if (!Hlp_StrCmp(effectInst, effectName)) {
                continue;
            };
        };

        // Search for a specific origin vob
        if (originInst) {
            var int originVob; originVob = MEM_ReadInt(vobPtr+oCVisualFX_originVob_offset);
            if (originVob != originInst) {
                continue;
            };
        };

        // Search for a specific target vob
        if (targetInst) {
            var int targetVob; targetVob = MEM_ReadInt(vobPtr+oCVisualFX_targetVob_offset);
            if (targetVob != targetInst) {
                continue;
            };
        };

        // Stop the oCVisualFX
        const int call2 = 0; const int one = 1;
        if (CALL_Begin(call2)) {
            CALL_PtrParam(_@(one));
            CALL__thiscall(_@(vobPtr), oCVisualFX__Stop);
            call2 = CALL_End();
        };
        stopped += 1;

        if (!all) {
            break;
        };
    end;
    MEM_ArrayFree(vobArrayPtr);

    return stopped;
};