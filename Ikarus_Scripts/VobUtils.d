// Gothic 2 only

const int zCVob___CreateNewInstance = 6281536; //0x5FD940
const int zCWorld__AddVob = 6440976; //0x624810
const int zCVob__SetVisual__zCVisual = 6300912; //0x6024F0
const int zCVob__GetPositionWorld__void = 5430416; //0x52DC90
const int zCVob__SetOnFloor = 7852256; //0x77D0E0
const int zCVob__RemoveVobFromWorld = 6298688; //0x601C40
const int zCVob__Move = 6402784; //0x61B2E0

func int Vob_GetPositionWorld(var int ptr) {
    var int pos[3];
    CALL_PtrParam(_@(pos));
    CALL__thiscall(ptr, zCVob__GetPositionWorld__void);
    return CALL_RetValAsInt();
};

func int Vob_CreateNewInstance() {
    CALL__stdcall(zCVob___CreateNewInstance);
    var int ptr; ptr = Call_RetValAsInt();
    CALL_PtrParam(ptr);
    CALL__thiscall(_@(MEM_World), zCWorld__AddVob);
    return ptr;
};

func int Vob_CopyNpc(var int oCNpcPtr) {
    var int ptr; ptr = Vob_CreateNewInstance();
    var oCNpc her; her = _^(oCNpcPtr);
    CALL_PtrParam(her._zCVob_visual);
    CALL__thiscall(ptr, zCVob__SetVisual__zCVisual);
    CALL_PtrParam(Vob_GetPositionWorld(_@(her)));
    CALL__thiscall(ptr, zCVob__SetOnFloor);
    MEM_CopyBytes(_@(her)+60,   ptr+60,   64);
    return ptr;
};

func void Vob_Move(var int ptr, var int x, var int y, var int z) {
    CALL_FloatParam(x);
    CALL_FloatParam(y);
    CALL_FloatParam(z);
    CALL__thiscall(ptr, zCVob__Move);
};

func void Vob_Delete(var int ptr)  {
    CALL__thiscall(ptr, zCVob__RemoveVobFromWorld);
};