// Gothic 2 only! It'd be much appreciated if someone can look up the addresses for G1

const int phi = 1070141312; // PI/2

func int atan2f(var int x, var int y) {
    const int _atan2f = 8123804; //0x7BF59C
    const int call = 0;
    var int ret;
    if (Call_Begin(call)) {
        CALL_FloatParam(_@(x));
        CALL_FloatParam(_@(y));
        CALL_RetValisFloat();
        CALL_PutRetValTo(_@(ret));
        CALL__cdecl(_atan2f);

        call = CALL_End();
    };
    return +ret;
};


func int sinf(var int angle) {
    const int _sinf = 8123910; //0x7BF606
    const int call = 0;
    var int ret;
    if (Call_Begin(call)) {
        CALL_FloatParam(_@(angle));
        CALL_RetValisFloat();
        CALL_PutRetValTo(_@(ret));
        CALL__cdecl(_sinf);

        call = CALL_End();
    };
    return +ret;
};

func int acosf(var int cosine) {
    const int _acosf = 8123794; //0x7BF592
    const int call = 0;
    var int ret;
    if (Call_Begin(call)) {
        CALL_FloatParam(_@(cosine));
        CALL_RetValisFloat();
        CALL_PutRetValTo(_@(ret));
        CALL__cdecl(_acosf);

        call = CALL_End();
    };
    return +ret;
};

func int asinf(var int sine) {
    return +subf(phi, acosf(sine));
};


func int cosf(var int angle) {
    return +sinf(subf(phi, angle));
};