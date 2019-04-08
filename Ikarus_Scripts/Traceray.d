// See http://forum.worldofplayers.de/forum/threads/1094284-Release-Irrwichtel
// Made by Sektenspinner
//
// Gothic 2 only!
 
/* Traceray-Flags (e.g. for zCWorld::TraceRayNearestHit)
 * Die Flags die übergeben werden können sollten folgende Bedeutung haben: */
const int zTRACERAY_VOB_IGNORE_NO_CD_DYN    = 1<<0;     //Vobs ohne Kollision ignorieren
const int zTRACERAY_VOB_IGNORE              = 1<<1;     //Alle Vobs ignorieren (nur statisches Mesh beachten)
const int zTRACERAY_VOB_BBOX                = 1<<2;     //Test auf Boundingboxen von Vobs (schneller als "richtiger" Schnitttest)
 
const int zTRACERAY_STAT_IGNORE             = 1<<4;     //Statische Welt ignorieren (nur Vobs beachten)
const int zTRACERAY_STAT_POLY               = 1<<5;     //Ein Zeiger auf das Schnittpolygon (falls es eines gibt) wird im Tracerayreport abgelegt.
const int zTRACERAY_STAT_PORTALS            = 1<<6;     //Schnitte mit Portalen werden auch als Schnitte gewertet
 
const int zTRACERAY_POLY_NORMAL             = 1<<7;     //Ermittle auch normale des Schnittpolygons
const int zTRACERAY_POLY_IGNORE_TRANSP      = 1<<8;     //Ignoriere Materialien mit Alphatextur
const int zTRACERAY_POLY_TEST_WATER         = 1<<9;     //Auch Wasser ist ein Schnitt.
const int zTRACERAY_POLY_2SIDED             = 1<<10;    //Kein Backfaceculling
const int zTRACERAY_VOB_IGNORE_CHARACTER    = 1<<11;    //Ignoriere Npcs
const int zTRACERAY_FIRSTHIT                = 1<<12;    //Irgendein Schnittpunkt genügt. Schneller als den nächsten Schnittpunkt ausrechnen.
const int zTRACERAY_VOB_TEST_HELPER_VISUALS = 1<<13;    //Auch Helpervisuals können getroffen werden
const int zTRACERAY_VOB_IGNORE_PROJECTILES  = 1<<14;    //Ignoriere Projektile
 
func int TraceRay(var int startVec, var int dirVec, var int flags) {
    const int zCWorld__TraceRayNearestHit = 6429568; //621B80
 
    //int __fastcall (class zVEC3 const &, class zVEC3 const &, class zCArray<class zCVob *> const *, int)
    CALL_IntParam(flags);
    CALL_PtrParam(0); //ignore no vobs
    CALL_PtrParam(dirVec);
 
    CALL__fastcall(MEM_InstGetOffset(MEM_World), startVec, zCWorld__TraceRayNearestHit);
    return CALL_RetValAsInt();
};