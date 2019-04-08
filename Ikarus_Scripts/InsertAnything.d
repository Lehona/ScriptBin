// See https://forum.worldofplayers.de/forum/threads/1299679-Skriptpaket-Ikarus-4?p=24882187&viewfull=1#post24882187
// Made by mud-freak
//
// Gothic 2 only!

/*****************************************************************************

    Insert Anything into World

Fügt einfache Vobs, Items oder Objekte der oCMob- und der zCTrigger-Familie an
Weltkoordinaten (inkl. Rotation) oder einem Waypoint (inkl. Blickrichtung) mit
entsprechenden Eigenschaften sauber in die Welt ein.
Optional lassen sich die Objekte auch automatisch am Boden ausrichten, sodass
sie nicht in der Luft schweben.
Die Parameter sind ziemlich selbsterklärend. Ein Blick in die Mobdatenbank, in
die Kommentare der Funktionen oder in die Klassendefinitionen in oCMob.d,
zCTrigger.d und oCItem.d hilft weiter für erwartete Datentypen und beispiel-
hafte Werte. Weitere Erklärungen sind in den Inline-Kommentaren.
Es gibt einige Hilfsfunktionen, die auch sonst nützlich ein könnten.

Folgende Funktionen geben jeweils den Zeiger auf das erstellte Objekt zurück.
 InsertVobAt             InsertVobWP                    = oCVob
 InsertItemAt            InsertItemWP                   = oCItem
 InsertMobAt             InsertMobWP                    = oCMob
 InsertMobInterAt        InsertMobInterWP               = oCMobInter
 InsertMobLockableAt     InsertMobLockableWP            = cCMobLockable
 InsertMobContainerAt    InsertMobContainerWP           = oCMobContainer
 InsertMobDoorAt         InsertMobDoorWP                = oCMobDoor
 InsertMobFireAt         InsertMobFireWP                = oCMobFire
 InsertTrigger                                          = zCTrigger,zCMover,..

Für Items und Vobs gibt es noch PileOf-Funktionen, um um eine Position herum
eine bestimmte Anzahl davon zu erstellen. Die Items/Vobs gleichen sich der da-
runterliegenden Oberfläche an. Praktisch für eine Schüssel voller Gold oder
vor allem für Pflanzen-Respawn-Skripte an unebenen Orten.

Hilfsfunktion, die auch sonst nützlich sein könnten:
 NormVec           = Normalisiert Vektor
 LevelVec          = Setzt Vektor parallel zur X/Z Ebene aus (waagerecht)
 NewTrafo          = Gibt eine "leere" Traformationsmatrix zurück
 PosToTrf          = Vektor (pos und dir) zu Traformationsmatrix
 TrfToPos          = Traformationsmatrix zu Vektor (pos und dir)
 GetGroundAtTrf    = Bodenhöhe des Levelmesh an bestimmter Position (Trafo)
 GetGroundAtPos    = Bodenhöhe des Levelmesh an bestimmter Position (Vektor)
 GetTrafoFromWP    = Traformationsmatrix von Waypoint
 AlignWPToFloor    = Korrigiert Bodenhöhe eines Waypoints
 AlignVobAt        = Positioniert ein Objekt an Trafo
 AlignVobToFloor   = Setzt Objekt auf den Boden (damit es nicht schwebt)
 AlignVobToWP      = Setzt Objekt auf Waypoint
 RemoveVobSafe     = Sichere Variante Weltobjekte zu löschen (Vobtree, ..)
 VobSetVisual      = Setzt Visual

Weitere Funktionen nicht von Belang (sollten nicht separat aufgerufen werden).
 InsertMobSuper, InsertVobIntoWorld

Beispielanwednung
 InsertMobInterWP( "WP_01",     Waypoint
                         0,     VobTree (zCTree)   0 = global Vobtree
            "INSERTED_MOB",     Vobname            vgl. MEM_SearchVobByName()
             "LAB_PSI.ASC",     Visual             *.3ds, *.asc, *.mdl
             "MOBNAME_LAB",     Focusname          vgl. Content\Story\Text.d
              "ITMI_FLASK",     useWithItem        Benutzungsitem
           "POTIONALCHEMY",     onStateFuncName    z.B. Dialog_Mobsis
                        "");    triggerTarget

*****************************************************************************/

//const int sizeof_zCVob                 = 288;
const int sizeof_ocItem                = 840;
const int sizeof_oCMob                 = 392;
const int sizeof_oCMobInter            = 564;
const int sizeof_oCMobLockable         = 608;
const int sizeof_oCMobDoor             = 628;
const int sizeof_oCMobContainer        = 644;
const int sizeof_oCMobFire             = 608;
const int sizeof_zCTrigger             = 360;
const int sizeof_oCTriggerScript       = 380;
const int sizeof_oCTriggerChangeLevel  = 400;
// const int sizeof_zCMover            = 624;

/****************************
   NormVec
 ****************************
  Normalisiert einen Vektor (zVEC3).
  Diese Funktion gibt nichts zurück, sondern verändert die Instanz selbst!
 */
func void NormVec(var int vecPtr) {
    const int zVEC3__Normalize = 4787872; //0x490EA0
    CALL__thiscall(vecPtr, zVEC3__Normalize);
};

/****************************
   LevelVec
 ****************************
  Passt einen Vektor (zVEC3) waagerecht (parallel zur globalen X/Z-Ebene) an.
  Diese Funktion gibt nichts zurück, sondern verändert die Instanz selbst!
 */
func void LevelVec(var int vecPtr) {
    MEM_WriteInt(vecPtr + 4, FLOATNULL); // Zweite Koordinate ist 0
    NormVec(vecPtr);
};

/****************************
   NewTrafo
 ****************************
  Gibt einen Zeiger auf eine "leere" Trafomationsmatrix (zMATRIX4) zurück.
  Leer bedeutet hier, die Ausrichtung und andere Felder angepasst sind.
 */
func int NewTrafo() {
    var int trafo[16];
    trafo[ 3] = FLOATNULL;
    trafo[ 7] = FLOATNULL;
    trafo[11] = FLOATNULL;
    trafo[15] = FLOATEINS; // <- Sehr wichtig!
    // RightVector           UpVector                 OutVector
    trafo[ 0] = FLOATEINS;   trafo[ 1] = FLOATNULL;   trafo[ 2] = FLOATNULL;
    trafo[ 4] = FLOATNULL;   trafo[ 5] = FLOATEINS;   trafo[ 6] = FLOATNULL;
    trafo[ 8] = FLOATNULL;   trafo[ 9] = FLOATNULL;   trafo[10] = FLOATEINS;
    trafo[12] = FLOATNULL;   trafo[13] = FLOATNULL;   trafo[14] = FLOATNULL;
    return _@(trafo);
};

/****************************
   TrfToPos
 ****************************
  Nimmt Traformationsmatrix und gibt Zeiger auf pos[6] (Position[3] und Richt-
  ung[3]) zurück. Gegenteil von PosToTrf (siehe unten).
 */
func int TrfToPos(var int trfPtr) {
    var int pos[6]; var int trafo[16]; MEM_CopyWords(trfPtr, _@(trafo), 16);
    // Blickrichtung              Position
    pos[3] = trafo[ 2];           pos[0] = trafo[ 3];
    pos[4] = trafo[ 6];           pos[1] = trafo[ 7];
    pos[5] = trafo[10];           pos[2] = trafo[11];
    return _@(pos);
};

/****************************
   RemoveVobSafe
 ****************************
  Das hier scheint die einzige unter den etlichen "RemoveVob" Methoden, die
  das Objekt wirklich komplett aus der Welt und sämtlichen Tables/Vobtress
  löscht. PurgeChildren entscheidet, ob die Kinder im Subtree des Vobs besteh-
  en bleiben oder mit gelöscht werden.
  Achtung: Sicherzustellen, dass ein Mob gerade nicht in Benutzung ist muss
  vorher manuell geschehen; Darauf wird hier nicht Rücksicht genommern!
 */
func void RemoveoCVobSafe(var int vobPtr, var int purgeChildren) {
    if (!vobPtr) { return; };
    if (purgeChildren) {
        var int vobtree; vobtree = MEM_ReadInt(vobPtr+36);
        // Lösche gesamten Subtree (und Inhalt) vom Vob
        const int zCWorld__DisposeVobs = 6437216; //0x623960
        CALL_PtrParam(vobtree);
        CALL__thiscall(_@(MEM_World), zCWorld__DisposeVobs);
        return;
    };
    const int oCWorld__RemoveVob = 7864512; //0x7800C0
    CALL_PtrParam(vobPtr);
    CALL__thiscall(_@(MEM_World), oCWorld__RemoveVob);
};
/* Das gleiche nur für zCVobs anstatt für oCVobs */
func void RemovezCVobSafe(var int vobPtr, var int purgeChildren) {
    if (!vobPtr) { return; };
    if (purgeChildren) {
        var int vobtree; vobtree = MEM_ReadInt(vobPtr+36);
        // Lösche gesamten Subtree (und Inhalt) vom Vob
        const int zCWorld__DisposeVobs = 6437216; //0x623960
        CALL_PtrParam(vobtree);
        CALL__thiscall(_@(MEM_World), zCWorld__DisposeVobs);
        return;
    };
    const int zCWorld__RemoveVob = 6441840; //0x624B70
    CALL_PtrParam(vobPtr);
    CALL__thiscall(_@(MEM_World), zCWorld__RemoveVob);
};

/****************************
   VobSetVisual
 ****************************/
func void VobSetVisual(var int vobPtr, var String visual) {
    if (!vobPtr) { return; };
    const int zCVob__SetVisual = 6301312; //0x602680
    CALL_zStringPtrParam(visual);
    CALL__thiscall(vobPtr, zCVob__SetVisual);
};

/****************************
   AlignVobAt
 ****************************
  Richtet bestehendes Vob an einer Transformationsmatrix aus.
 */
func int AlignVobAt(var int vobPtr, var int trfPtr) {
    if (!vobPtr) { MEM_Warn("AlignVobAt: Vob-pointer invalid."); return 0; };
    if (!trfPtr) { MEM_Info("AlignVobAt: Trafo-pointer invalid."); return 0;};
    // Zum Bewegen Kollision aufheben
    var zCVob vob; vob = _^(vobPtr);
    var int collBits; collBits = (zCVob_bitfield0_collDetectionStatic +
    /* Betroffene Bits */         zCVob_bitfield0_collDetectionDynamic);
    var int bitbackup; bitbackup = vob.bitfield[0] & (collBits); // Backupbits
    vob.bitfield[0] = vob.bitfield[0] & ~ (collBits);
    // Kopiere Traformationsmatrix aufs Vob
    MEM_CopyWords(trfPtr, vobPtr+60, 16);
    // Position updaten und Bits zurücksetzen
    const int zCVob__SetPositionWorld = 6404976; //0x61BB70
    CALL_PtrParam(TrfToPos(vobPtr+60));
    CALL__thiscall(vobPtr, zCVob__SetPositionWorld);
    vob.bitfield[0] = vob.bitfield[0] | (bitbackup);
    return 1;
};

/****************************
   InsertVobIntoWorld
 ****************************
  Nimmt einen Zeiger auf ein bereits existierendes Objekt und fügt es sauber
  in die Welt ein. In diesem Kontext dient sie hier nur als Hilfsfunktion und
  als Grundlage. für dieses Skript. Es gibt keinen Grund, dass sie ausserhalb
  dieses Skripts aufgerufen werden sollte.
  Die Funtion oCWorld::AddVobAsChild() wird auch von Wld_InsertObject() (in
  MEM_InsertVob()) aufgerufen. Ohne AddVobAsChild wird das Vob nicht in den
  Vobtree eingetragen.
  AddVobAsChild erwartet Objekte, die mit ihrem richtigen Konstruktor ini-
  tialisiert wurden (also z.B. oCMobInter::oCMobInter()). Andernfalls erschei-
  nen die Vobs zwar in der Welt, aber lass sich nicht über MEM_SearchVobByName
  finden und gehen verloren!
  Das Objekt wird Child das globalen Vobtrees oder von vtreePtr.
 */
func int InsertoCVobIntoWorld(var int vobPtr, var int trfPtr,
        var int vtreePtr, var String objectName, var String visual) {
    if (!vobPtr)
        { MEM_Warn("InsertVobIntoWorld: Vob-pointer invalid."); return 0; };
    if (!vtreePtr) { vtreePtr = _@(MEM_Vobtree); }; // Global
    // Setze Namen (Kann nun auch mit MEM_SearchVobByName gefunden werden.)
    var zCVob vob; vob = _^(vobPtr); // Name muss vorm Einfügen gesetzt werden
    vob._zCObject_objectName = objectName;
    // Sauberers Einfügen in die Welt
    const int oCWorld__AddVobAsChild = 7863856; //0x77FE30
    CALL_PtrParam(vtreePtr);
    CALL_PtrParam(vobPtr);
    CALL__thiscall(_@(MEM_World), oCWorld__AddVobAsChild);
    // Visual setzen (Die Abfrage hier ist wichtig, siehe InsertVobAt)
    if (!Hlp_StrCmp(visual, "")) { VobSetVisual(vobPtr, visual); };
    // Bewege das Vob zur Position und richte es aus.
    if (!AlignVobAt(vobPtr, trfPtr)) {
        MEM_Warn("InsertVobIntoWorld: Could not place vob at position.");
        return 0; };
    return 1; // Success
};
/* Das gleiche nur für zCVobs anstatt für oCVobs */
func int InsertzCVobIntoWorld(var int vobPtr, var int trfPtr,
        var int vtreePtr, var String objectName, var String visual) {
    if (!vobPtr)
        { MEM_Warn("InsertVobIntoWorld: Vob-pointer invalid."); return 0; };
    if (!vtreePtr) { vtreePtr = _@(MEM_Vobtree); }; // Global
    // Setze Namen (Kann nun auch mit MEM_SearchVobByName gefunden werden.)
    var zCVob vob; vob = _^(vobPtr); // Name muss vorm Einfügen gesetzt werden
    vob._zCObject_objectName = objectName;
    // Sauberers Einfügen in die Welt
    const int zCWorld__AddVobAsChild = 6440352; //0x6245A0
    CALL_PtrParam(vtreePtr);
    CALL_PtrParam(vobPtr);
    CALL__thiscall(_@(MEM_World), zCWorld__AddVobAsChild);
    // Visual setzen (Die Abfrage hier ist wichtig, siehe InsertVobAt)
    if (!Hlp_StrCmp(visual, "")) { VobSetVisual(vobPtr, visual); };
    // Bewege das Vob zur Position und richte es aus.
    if (!AlignVobAt(vobPtr, trfPtr)) {
        MEM_Warn("InsertVobIntoWorld: Could not place vob at position.");
        return 0; };
    return 1; // Success
};


/****************************
   AlignVobToFloor
 ****************************
  Richtet bestehendes Vob am Boden/darunter stehendem Kollisionsobjekt aus.
  Die Enginefunktion ist nicht sehr sorgfältig und lässt 4 cm Luft. Das wird
  hier korrigiert.
 */
func void AlignVobToFloor(var int vobPtr) {
    if (!vobPtr) { return; }; // Kein Grund sich zu beschweren (MEM_Warn).
    var zCVob vob; vob = _^(vobPtr);
    var int vec1[3];
    vec1[0] = vob.trafoObjToWorld[ 3];
    vec1[1] = addf(vob.trafoObjToWorld[ 7], mkf(150)); // Erst über den Boden
    vec1[2] = vob.trafoObjToWorld[11];
    const int oCVob__SetOnFloor = 7852256; //0x77D0E0
    CALL_PtrParam(_@(vec1)); // World position
    CALL__thiscall(vobPtr, oCVob__SetOnFloor);
    // Korrigiere 4cm nach unten (sonst etwas unschön).
    vob.trafoObjToWorld[ 7] = subf(vob.trafoObjToWorld[ 7], mkf(4));
    AlignVobAt(vobPtr, vobPtr+60);
};

/****************************
   InsertVobAt
 ****************************
  Erstellt ein Vob und fügt es in die zu den Koordinaten in die Welt ein.
  Als Position nimmt sie eine Traformationsmatrix (zMATRIX4).
 */
func int InsertVobAt(var int trfPtr, var int setToGround, var int vtreePtr,
        var String objectName, var String visual, var int staticVob,
        var int collStat, var int collDyn, var int showVisual) {
    /* Neue zCVob Instanz mittels richtigem Konstruktor
      AddVobAsChild (siehe InsertVobIntoWorld()) erlaubt keine andere Art von
      Initialisierung, sonst lässt sich das Object nachher nicht über
      MEM_SearchVobByName finden und geht verloren! */
    var int vobPtr; vobPtr = MEM_Alloc(288); // 288 is sizeof(zCVob)
    const int oCVob__oCVob = 7845536; //0x77B6A0
    CALL__thiscall(vobPtr, oCVob__oCVob);
    var int onBits; var int offBits; var zCVob vob; vob = _^(vobPtr);
    onBits =  ( showVisual * zCVob_bitfield0_showVisual +
                staticVob  * zCVob_bitfield0_staticVob +
                collStat   * zCVob_bitfield0_collDetectionStatic +
                collDyn    * zCVob_bitfield0_collDetectionDynamic);
    offBits = (!showVisual * zCVob_bitfield0_showVisual +
               !staticVob  * zCVob_bitfield0_staticVob +
               !collStat   * zCVob_bitfield0_collDetectionStatic +
               !collDyn    * zCVob_bitfield0_collDetectionDynamic);
    /* Setze Visual schon vorm Einfügen, um ggf. showVisual auf 0 zu setzen.
     Ansonsten überschreibt der spätere SetVisual-Aufruf das showVisual-Bit!
     Das ist nur in dieser Funktion von Nöten um Vobs unsichtbar einzugefügen.
     Bei anderen Objekten (z.B. Mobs mit Fokusnamen) macht das keinen Sinn. */
    VobSetVisual(vobPtr, visual);
    vob.bitfield[0] = vob.bitfield[0] |  (onBits);
    vob.bitfield[0] = vob.bitfield[0] & ~ (offBits);
    if (!InsertoCVobIntoWorld(vobPtr, trfPtr, vtreePtr, objectName, "")) {
        MEM_Warn("InsertVobAt: Could not insert vob.");
        RemoveoCVobSafe(vobPtr, 1); return 0; };
    if (setToGround) { AlignVobToFloor(vobPtr); };
    return vobPtr;
};

/****************************
   GetGroundAtPos
 ****************************
  Passt einen Vektor (zVEC3) am Boden des Levelmeshs an. Damit bspw. Vobs
  nicht in der Luft schweben, sondern mit dem Boden abschliessen. Diese Funk-
  tion gibt den korrigierten Y-Wert (Höhe) als Int (zREAL) zurück.
  Kleiner Hack, damit wir an die korrekte Höhe vom Boden des Levelmeshs ran-
  kommen: Erstelle einen temporären Vob und lasse ihn automatisch am Boden
  ausrichten, kopiere dessen Y-Koordinate und lösche dann ihn wieder.
  GetGroundAtTrf tut das gleiche für eine vollständige Trafo-Matrix.
 */
func int GetGroundAtTrf(var int trfPtr) {
    /* Füge temporären Hilfs-Vob ein (setToGround == 1)
      Muss Visual haben wegen GroundAlignment. Keine Sorge, das showVisual-Bit
      ist aber aus: Das Gold ist nicht sichtbar. */
    var int vobPtr; vobPtr = InsertVobAt(trfPtr, 1, 0, "", "ItMi_Gold.3ds",
        0, 0, 0, 0); // Kein Visual (zCVob_bitfield0_staticVob ist aus)
    if (!vobPtr) {
        MEM_Warn("GetGroundAtPos: Could not insert help-vob."); return 0; };
    var int newHeight; newHeight = MEM_ReadInt(vobPtr + 88);
    RemoveoCVobSafe(vobPtr, 1);
    return newHeight;
};
func int GetGroundAtPos(var int vecPtr) {
    // Erstelle provisorische Positionsmatrix
    var int trafo[16]; MEM_CopyWords(NewTrafo(), _@(trafo), 16);
    trafo[ 3] = MEM_ReadInt(vecPtr);
    trafo[ 7] = MEM_ReadInt(vecPtr + 4);
    trafo[11] = MEM_ReadInt(vecPtr + 8);
    return GetGroundAtTrf(_@(trafo));
};

/****************************
   PosToTrf
 ****************************
  Gibt den Zeiger auf eine Traformationsmatrix (zMATRIX4) zurück und nimmt als
  Argumente Weltkoordinaten und Blickrichtung an. Zusätzlich kann man über
  leveled und setToGround entscheiden, ob die Blickrichtung waagerecht und
  ob die Höhe an den Boden des Levelmeshs angepasst werden soll.
 */
func int PosToTrf(var int posPtr, var int dirPtr, var int leveled,
        var int setToGround) {
    var int pos[3]; MEM_CopyWords(posPtr, _@(pos), 3); // Kopie zum Verändern
    var int dir[3]; MEM_CopyWords(dirPtr, _@(dir), 3); // Kopie zum Verändern
    var int trafo[16]; MEM_CopyWords(NewTrafo(), _@(trafo), 16);
    // Position
    if (setToGround) { // Am Boden anpassen
        var int newHeight; newHeight = GetGroundAtPos(_@(pos));
        if (!newHeight) {
            MEM_Warn("PosToTrf: Could not set trafo to ground.");
            // Return oder weiter?
        } else {
            pos[1] = newHeight;
        };
    };
    trafo[ 3] = pos[0];
    trafo[ 7] = pos[1];
    trafo[11] = pos[2];
    if (leveled) { LevelVec(_@(dir)); }; // Waagerecht
    // Ausrichtung (OutVector)
    const int zMAT4__SetAtVector = 5683552; //0x56B960
    CALL_PtrParam(_@(dir));
    CALL__thiscall(_@(trafo), zMAT4__SetAtVector);
    // Mache Up- und RightVector wieder orthonormal
    const int zMAT4__MakeOrthonormal = 5337904; //0x517330
    CALL__thiscall(_@(trafo), zMAT4__MakeOrthonormal);
    return _@(trafo);
};


/****************************************************************************/


/****************************
   AlignWPToFloor
 ****************************
  Passt die Höhe eines Waypoints am Levelsmesh an. Zusätzlich gibt es auch
  die ideale Höhe zurück anhand der man z.B. Vobs genau abschliessend mit dem
  Boden positionieren kann.
 */
func int AlignWPToFloor(var int wpPtr) {
     // Gothic richtet uns den Waypoint korrekt überm Boden aus
     const int zCWaypoint__CorrectHeight = 8061088; //0x7B00A0
     CALL_PtrParam(_@(MEM_World));
     CALL__thiscall(wpPtr, zCWaypoint__CorrectHeight);
     // Optional: Es wird die Höhe, genau überm Boden, zurückgegeben.
     var zCWaypoint tmpWP; tmpWP = _^(wpPtr);
     return subf(tmpWP.pos[1], mkf(50)); // Fine-tuning (-50cm): Oberfläche
};

/****************************
   GetTrafoFromWP
 ****************************
  Gibt den Zeiger auf eine Traformationsmatrix (zMATRIX4) zurück und nimmt als
  Argument einen Waypoint-namen entgegen.
 */
func int GetTrafoFromWP(var String waypoint, var int setToGround) {
    // Hole Waypoint
    const int zCWayNet__GetWaypoint = 8061744; //0x7B0330
    CALL__fastcall(_@(MEM_Waynet), _@s(waypoint), zCWayNet__GetWaypoint);
    var int wpPtr; wpPtr = CALL_RetValAsInt();
    if (!wpPtr){ MEM_Warn("GetTrafoFromWP: Waypoint not found."); return 0; };
    // Leiste Spacernacharbeit und richte den Waypoint richtig aus (Höhe)
    AlignWPToFloor(wpPtr);
    // Baue Traformationsmatrix von Position und Ausrichtung
    var zCWaypoint wp; wp = _^(wpPtr);
    var int pos[3]; MEM_CopyWords(_@(wp.pos), _@(pos), 3);
    if (setToGround) { pos[1] = subf(pos[1], mkf(50)); }; // Korrigiere Hoehe
    return PosToTrf(_@(pos), _@(wp.dir), 1, 0);
};

/****************************
   AlignVobToWP
 ****************************
  Richtet bestehendes Vob an Waypoint/Boden aus. Hilfreich um Vobs in der Welt
  zur Laufzeit ganz leicht anhand von Waypoints zu verschieben.
 */
func int AlignVobToWP(var int vobPtr, var String waypoint) {
    // Hole Traformationsmatrix vom WP
    var int trfPtr; trfPtr = GetTrafoFromWP(waypoint, TRUE); // WP, am Boden
    if (!trfPtr) {
        MEM_Warn("AlignVobToWP: Could not align vob to WP."); return 0; };
    AlignVobAt(vobPtr, trfPtr);
    // Da es auf den Waypoint soll, setzen wir es ohne zu fragen auf den Boden
    // AlignVobToFloor(vobPtr); // Wird 5 Zeilen höher schon gemacht.
    return 1;
};


/****************************************************************************/


/****************************
   InsertVobWP
 ***************************/
func int InsertVobWP(var String waypoint, var int vtreePtr,
        var String objectName, var String visual, var int staticVob,
        var int collDyn, var int collStat, var int showVisual) {
    var int trfPtr; trfPtr = GetTrafoFromWP(waypoint, TRUE); // WP, am Boden
    if (!trfPtr) {
        MEM_Warn("InsertVobWP: Could not get trafo from WP."); return 0; };
    return (InsertVobAt(trfPtr, 1, vtreePtr, objectName, visual, staticVob,
        collStat, collDyn, showVisual));
};

/****************************
   PileOfVobs
 ***************************
  Erstellt einen "Haufen" von Vobs an einer bestimmten Position in bestimmten
  Radius.
 */
func void PileOfVobs(var String visual, var int trfPtr, var int amount,
        var int radius, var int rotate, var int staticVob, var int collStat,
        var int collDyn, var int showVisual) {
    var int trafo[16]; MEM_CopyWords(trfPtr, _@(trafo), 16);
    trafo[ 7] = addf(trafo[ 7], mkf(200)); // Zum Stapeln etwas nach oben
    var int rtrafo[16]; // Für zufällige Positionen
    var int dir[3]; dir[1] = 0; // Für optionale Rotation
    var int label; var int index; index = 0;
    label = MEM_StackPos.position;
    // Loop {
        // Neue Position innerhalb des Radiuses
        MEM_CopyWords(_@(trafo), _@(rtrafo), 16); // Neu Beginnen
        rtrafo[ 3] = addf(trafo[ 3], mkf(Hlp_Random(radius*2)-radius));
        rtrafo[11] = addf(trafo[11], mkf(Hlp_Random(radius*2)-radius));
        // Rotieren
        if (rotate) { // X/Z des OutVektors zwischen -1 und 1
            dir[0] = fracf(Hlp_Random(200)-100,200);
            dir[2] = fracf(Hlp_Random(200)-100,200);
            // Ausrichtung (OutVector)
            const int zMAT4__SetAtVector = 5683552; //0x56B960
            CALL_PtrParam(_@(dir));
            CALL__thiscall(_@(rtrafo), zMAT4__SetAtVector);
            // Mache Up- und RightVector wieder orthonormal
            const int zMAT4__MakeOrthonormal = 5337904; //0x517330
            CALL__thiscall(_@(rtrafo), zMAT4__MakeOrthonormal);
        };
        // Einfügen
        InsertVobAt(_@(rtrafo), TRUE, 0, "", visual, staticVob, collStat,
            collDyn, showVisual);
        // Index erhöhen und Schleife verlassen
        index += 1;
        if (index >= amount) { return; };
    // };
    MEM_StackPos.position = label;
};

/****************************
   InsertMobSuper
 ****************************
  Fügt ein bereits erstelltes Objekt (mindestens zCVob oder oCMob) in die Welt
  ein. Abwärts- und Aufwärstkompatibel, d.h. es werden alle Subklassen aus der
  oCMob-Familie sowie auch zCVobs (dafür eignet sich aber InsertVobAt besser)
  akzeptiert. Wenn man der Funktion bspw. einen Zeiger auf ein oCMobInter
  übergibt, das die Eigenschaft 'locked' gar nicht hat, übergibt man einfach
  leere (im Falle von Strings "" oder 0 für Ints) Argumente. Das wird aber
  alles schon in den einzelnen Wrapperklassen gemacht. Diese Funktion braucht
  man also ausserhalb dieses Skripts nie aufrufen.
 */
func int InsertMobSuper(var int mobPtr, var int trfPtr, var int setToGround,
        var int vtreePtr, var String objectName, var String visual,
        var String focusName, var String useWithItem,
        var String onStateFuncName, var String triggerTarget,
        var String keyInstance, var String pickLockStr, var int locked,
        var String contains, var String fireSlot, var String fireVobtreeName,
        var int fireVobtree){
    if (!mobPtr) {
        MEM_Warn("InsertMobSuper: Mob-pointer invalid."); return 0; };
    // Setze Obj (in die Welt und) -Eigenschaften zu erst
    if (!InsertoCVobIntoWorld(mobPtr, trfPtr, vtreePtr, objectName, visual)) {
        MEM_Warn("InsertMobSuper: Could not insert vob to world"); return 0;};
    // Am Boden ausrichten
    if (setToGround) { AlignVobToFloor(mobPtr); };
    // Dann alle zutreffenden oCMob Eigenschaften
    if (Hlp_Is_oCMob(mobPtr)) {               /* oCMob */
        var oCMob mob1; mob1 = _^(mobPtr);
        mob1.name = focusName;                  //zSTRING Symbolischer Name
        mob1.focusNameIndex = MEM_GetSymbolIndex(focusName); //Parsersymbol id
        // Des Wordwraps wegen in mehreren Zeilen
        var int setBits; setBits = (zCVob_bitfield0_collDetectionDynamic +
        /* Afaik haben ALLE Mobs */ zCVob_bitfield0_collDetectionStatic +
        /* diese Eigenschaften */   zCVob_bitfield0_staticVob);
        mob1._zCVob_bitfield[0] = mob1._zCVob_bitfield[0] |  (setBits);
    };
    if (Hlp_Is_oCMobInter(mobPtr)) {          /* oCMobInter */
        var oCMobInter mob2; mob2 = _^(mobPtr);
        mob2.triggerTarget = triggerTarget;     //zSTRING
        mob2.useWithItem = useWithItem;         //zSTRING
        mob2.onStateFuncName = onStateFuncName; //zSTRING
    };
    if (Hlp_Is_oCMobLockable(mobPtr)) {       /* oCMobLockable */
        var oCMobLockable mob3; mob3 = _^(mobPtr);
        mob3.keyInstance = keyInstance;         // zSTRING: Schlüsselinstanz
        mob3.pickLockStr = pickLockStr;         // zSTRING: Linksrechtscombo
        if (locked)
            { mob3.bitfield=mob3.bitfield | oCMobLockable_bitfield_locked; };
    };
    if (Hlp_Is_oCMobContainer(mobPtr)) {      /* oCMobContainer */
        // Fülle Container
        const int oCMobContainer__CreateContents = 7496080; //0x726190
        CALL_zStringPtrParam(contains);
        CALL__thiscall(mobPtr, oCMobContainer__CreateContents);
    };
    /* if (Hlp_Is_oCMobDoor(mobPtr)) {        /* oCMobDoor °/
        // oCMobDoor ist ausser
        // onStateFuncName hier nicht
        // anders als oCMobLockable
    };                                                                      */
    if (Hlp_Is_oCMobFire(mobPtr)) {           /* oCMobFire */
        var oCMobFire mob4; mob4 = _^(mobPtr);
        mob4.fireSlot = fireSlot;               //zSTRING: "BIP01 FIRE"
        mob4.fireVobtreeName = fireVobtreeName; //zSTRING: "FIRETREE_LAMP.ZEN"
        mob4.fireVobtree = fireVobtree;         //zCVob*
    };
    return 1;
};


/****************************************************************************/


/****************************
   InsertMob[...]At
 ***************************
  Nimmt Position und Eigenschaften entgegen und erstellt daraus ein entsprech-
  endes Mob an der gegebenen Position durch einen Aufruf von InsertMobSuper.
 */
func int InsertMobAt(var int trfPtr, var int setToGround, var int vtreePtr,
        var String objectName, var String visual, var String focusName) {
    /* Diese Funktion ist nur der Vollständigkeit halber drin. Denn eigentlich
       ist ein oCMob im Grunde ein nur zCVob, daher reicht auch InsertVobAt().
     */
    var int mobPtr; mobPtr = MEM_Alloc(sizeof_oCMob);
    const int oCMob__oCMob = 7452912; //0x71B8F0
    CALL__thiscall(mobPtr, oCMob__oCMob);
    if (!InsertMobSuper(mobPtr, trfPtr, setToGround, vtreePtr, objectName,
            visual, focusName, "", "", "", "", "", 0, "", "", "", 0)) {
        MEM_Warn("InsertMobAt: Could not insert mob.");
        RemoveoCVobSafe(mobPtr, 1);
        return 0; };
    return mobPtr;
};
func int InsertMobInterAt(var int trfPtr, var int setToGround,
        var int vtreePtr, var String objectName, var String visual,
        var String focusName, var String useWithItem,
        var String onStateFuncName, var String triggerTarget) {
    var int mobPtr; mobPtr = MEM_Alloc(sizeof_oCMobInter);
    const int oCMobInter__oCMobInter = 7458832; //0x71D010
    CALL__thiscall(mobPtr, oCMobInter__oCMobInter);
    if (!InsertMobSuper(mobPtr, trfPtr, setToGround, vtreePtr, objectName,
            visual, focusName, useWithItem, onStateFuncName, triggerTarget,
            "", "", 0, "", "", "", 0)) {
        MEM_Warn("InsertMobInterAt: Could not insert mob.");
        RemoveoCVobSafe(mobPtr, 1);
        return 0; };
    return mobPtr;
};
func int InsertMobLockableAt(var int trfPtr, var int setToGround,
        var int vtreePtr, var String objectName, var String visual,
        var String focusName, var String triggerTarget,
        var String keyInstance, var String pickLockStr, var int locked) {
    var int mobPtr; mobPtr = MEM_Alloc(sizeof_oCMobLockable);
    const int oCMobLockable__oCMobLockable = 7485728; //0x723920
    CALL__thiscall(mobPtr, oCMobLockable__oCMobLockable);
    if (!InsertMobSuper(mobPtr, trfPtr, setToGround, vtreePtr, objectName,
            visual, focusName, "", "", triggerTarget, keyInstance,
            pickLockStr, locked, "", "", "", 0)) {
        MEM_Warn("InsertMobLockableAt: Could not insert mob.");
        RemoveoCVobSafe(mobPtr, 1);
        return 0; };
    return mobPtr;
};
func int InsertMobContainerAt(var int trfPtr, var int setToGround,
        var int vtreePtr, var String objectName, var String visual,
        var String focusName, var String triggerTarget,
        var String keyInstance, var String pickLockStr, var int locked,
        var String contains) {
    var int mobPtr; mobPtr = MEM_Alloc(sizeof_oCMobContainer);
    const int oCMobContainer__oCMobContainer = 7493600; //0x7257E0
    CALL__thiscall(mobPtr, oCMobContainer__oCMobContainer);
    if (!InsertMobSuper(mobPtr, trfPtr, setToGround, vtreePtr, objectName,
            visual, focusName, "", "", triggerTarget, keyInstance,
            pickLockStr, locked, contains, "","", 0)) {
        MEM_Warn("InsertMobContainerAt: Could not insert mob.");
        RemoveoCVobSafe(mobPtr, 1);
        return 0; };
    return mobPtr;
};
func int InsertMobDoorAt(var int trfPtr, var int setToGround,
        var int vtreePtr, var String objectName, var String visual,
        var String focusName, var String onStateFuncName,
        var String triggerTarget, var String keyInstance,
        var String pickLockStr, var int locked) {
    var int mobPtr; mobPtr = MEM_Alloc(sizeof_oCMobDoor);
    const int oCMobDoor__oCMobDoor = 7498160; //0x7269B0
    CALL__thiscall(mobPtr, oCMobDoor__oCMobDoor);
    if (!InsertMobSuper(mobPtr, trfPtr, setToGround, vtreePtr, objectName,
            visual, focusName, "", onStateFuncName, triggerTarget,
            keyInstance, pickLockStr, locked, "", "", "", 0)) {
        MEM_Warn("InsertMobDoorAt: Could not insert mob.");
        RemoveoCVobSafe(mobPtr, 1);
        return 0; };
    return mobPtr;
};
func int InsertMobFireAt(var int trfPtr, var int setToGround,
        var int vtreePtr, var String objectName, var String visual,
        var String focusName, var String fireSlot, var String fireVobtreeName,
        var int fireVobtree){
    var int mobPtr; mobPtr = MEM_Alloc(sizeof_oCMobFire);
    const int oCMobFire__oCMobFire = 7480416; //0x722460
    CALL__thiscall(mobPtr, oCMobFire__oCMobFire);
    if (!InsertMobSuper(mobPtr, trfPtr, setToGround, vtreePtr, objectName,
            visual, focusName, "", "", "", "", "", 0, "", fireSlot,
            fireVobtreeName, fireVobtree)) {
        MEM_Warn("InsertMobFireAt: Could not insert mob.");
        RemoveoCVobSafe(mobPtr, 1);
        return 0; };
    return mobPtr;
};

/****************************
   InsertMob[...]WP
 ***************************
  Wrapperfunktionen für InsertMob[...]At, um anstatt einer Position einen Way-
  point anzugeben.
 */
func int InsertMobWP(var String waypoint, var int vtreePtr,
        var String objectName, var String visual, var String focusName) {
    /* Diese Funktion ist nur der Vollständigkeit halber drin. Denn eigentlich
       ist ein oCMob im Grunde ein nur zCVob, daher reicht auch InsertVobWP().
    */
    var int trfPtr; trfPtr = GetTrafoFromWP(waypoint, 1);
    if (!trfPtr) {
        MEM_Warn("InsertMobWP: Could not get trafo from WP."); return 0; };
    return InsertMobAt(trfPtr, 1, vtreePtr, objectName, visual, focusName);
};
func int InsertMobInterWP(var String waypoint, var int vtreePtr,
        var String objectName, var String visual, var String focusName,
        var String useWithItem, var String onStateFuncName,
        var String triggerTarget) {
    var int trfPtr; trfPtr = GetTrafoFromWP(waypoint, 1);
    if (!trfPtr) {
        MEM_Warn("InsertMobInterWP: Could not get trafo from WP.");
        return 0; };
    return (InsertMobInterAt(trfPtr, 1, vtreePtr, objectName, visual,
        focusName, useWithItem, onStateFuncName, triggerTarget));
};
func int InsertMobLockableWP(var String waypoint, var int vtreePtr,
        var String objectName, var String visual, var String focusName,
        var String triggerTarget, var String keyInstance,
        var String pickLockStr, var int locked) {
    var int trfPtr; trfPtr = GetTrafoFromWP(waypoint, 1);
    if (!trfPtr) {
        MEM_Warn("InsertMobLockableWP: Could not get trafo from WP.");
        return 0; };
    return (InsertMobLockableAt(trfPtr, 1, vtreePtr, objectName, visual,
        focusName, triggerTarget, keyInstance, pickLockStr, locked));
};
func int InsertMobContainerWP(var String waypoint, var int vtreePtr,
        var String objectName, var String visual, var String focusName,
        var String triggerTarget, var String keyInstance,
        var String pickLockStr, var int locked, var String contains) {
    var int trfPtr; trfPtr = GetTrafoFromWP(waypoint, 1);
    if (!trfPtr) {
        MEM_Warn("InsertMobContainerWP: Could not get trafo from WP.");
        return 0; };
    return (InsertMobContainerAt(trfPtr, 1, vtreePtr, objectName, visual,
        focusName, triggerTarget, keyInstance, pickLockStr, locked,
        contains));
};
func int InsertMobDoorWP(var String waypoint, var int vtreePtr,
        var String objectName, var String visual, var String focusName,
        var String onStateFuncName, var String triggerTarget,
        var String keyInstance, var String pickLockStr, var int locked) {
    var int trfPtr; trfPtr = GetTrafoFromWP(waypoint, 1);
    if (!trfPtr) {
        MEM_Warn("InsertMobDoorWP: Could not get trafo from WP.");
        return 0; };
    return (InsertMobDoorAt(trfPtr, 1, vtreePtr, objectName, visual,
        focusName, onStateFuncName, triggerTarget, keyInstance, pickLockStr,
        locked));
};
func int InsertMobFireWP(var String waypoint, var int vtreePtr,
        var String objectName, var String visual, var String focusName,
        var String fireSlot, var String fireVobtreeName, var int fireVobtree){
    var int trfPtr; trfPtr = GetTrafoFromWP(waypoint, 1);
    if (!trfPtr) {
        MEM_Warn("InsertMobFireWP: Could not get trafo from WP.");
        return 0; };
    return (InsertMobFireAt(trfPtr, 1, vtreePtr, objectName, visual,
        focusName, fireSlot, fireVobtreeName, fireVobtree));
};


/****************************************************************************/


/****************************
   InsertItem{At,WP}
 ***************************
  Nimmt Position/Waypoint, Skript-Instanz (z.B. ItMi_Gold) und Anzahl entgegen
  und erstellt daraus ein entsprechendes Item in der Welt.
  Achtung: Amount sollte nur höher als 1 sein, wenn das Item stapelbar ist
  (wie z.B. Gold)! Bei anderen Items kommt es zu Problemen.
 */
func int InsertItemAt(var int trfPtr, var int setToGround,
        var String itemInstance, var int amount) {
    var int itmPtr; itmPtr = MEM_Alloc(sizeof_oCItem);
    const int oCItem__oCItem = 7410800;
    CALL_IntParam(amount);
    CALL_zStringPtrParam(itemInstance);
    CALL__thiscall(itmPtr, oCItem__oCItem);
    if (!itmPtr) {
        MEM_Warn("InsertItemAt: Could not create item instance."); return 0;};
    // Visual holen. Der Rest geht automatisch dank der Item-Instanz.
    var oCItem itm; itm = _^(itmPtr);
    if (!InsertoCVobIntoWorld(itmPtr, trfPtr, 0, "", itm.visual)) {
        MEM_Warn("InsertItemAt: Could not insert Item.");
        RemoveoCVobSafe(itmPtr, 1);
        return 0; };
    // Am Boden ausrichten
    if (setToGround) { AlignVobToFloor(itmPtr); };
    return itmPtr;
};
func int InsertItemWP(var String waypoint, var String itemInstance,
        var int amount) {
    var int trfPtr; trfPtr = GetTrafoFromWP(waypoint, 1);
    if (!trfPtr) {
        MEM_Warn("InsertItemWP: Could not get trafo from WP."); return 0; };
    return InsertItemAt(trfPtr, 1, itemInstance, amount);
};

/****************************
   PileOfItems
 ***************************
  Erstellt einen "Haufen" von Items an einer bestimmten Position in bestimmtem
  Radius.
 */
func void PileOfItems(var String itemInstance, var int trfPtr, var int amount,
        var int radius, var int rotate) {
    var int trafo[16]; MEM_CopyWords(trfPtr, _@(trafo), 16);
    trafo[ 7] = addf(trafo[ 7], mkf(200)); // Zum Stapeln etwas nach oben
    var int rtrafo[16]; // Für zufällige Positionen
    var int dir[3]; dir[1] = 0; // Für optionale Rotation
    var int label; var int index; index = 0;
    label = MEM_StackPos.position;
    // Loop {
        // Neue Position innerhalb des Radiuses
        MEM_CopyWords(_@(trafo), _@(rtrafo), 16); // Neu Beginnen
        rtrafo[ 3] = addf(trafo[ 3], mkf(Hlp_Random(radius*2)-radius));
        rtrafo[11] = addf(trafo[11], mkf(Hlp_Random(radius*2)-radius));
        // Rotieren
        if (rotate) { // X/Z des OutVektors zwischen -1 und 1
            dir[0] = fracf(Hlp_Random(200)-100,200);
            dir[2] = fracf(Hlp_Random(200)-100,200);
            // Ausrichtung (OutVector)
            const int zMAT4__SetAtVector = 5683552; //0x56B960
            CALL_PtrParam(_@(dir));
            CALL__thiscall(_@(rtrafo), zMAT4__SetAtVector);
            // Mache Up- und RightVector wieder orthonormal
            const int zMAT4__MakeOrthonormal = 5337904; //0x517330
            CALL__thiscall(_@(rtrafo), zMAT4__MakeOrthonormal);
        };
        InsertItemAt(_@(rtrafo), TRUE, itemInstance, 1); // Einfügen
        index += 1; // Index erhöhen
        if (index >= amount) { return; }; // "Schleife" verlassen
    // };
    MEM_StackPos.position = label;
};


/*****************************************************************************


/****************************
   InsertTrigger (Familie)
 ***************************
  Etwas simpler als die anderen Funktionen fügt diese hier einfach Trigger,
  TriggerScript, TriggerChangeLevel oder Mover ein ohne Position oder weitere
  Eigenschaften. Der Grund dafür ist, dass es eher unwahrscheinlich oder selt-
  ener ist diese Art von Vobs einzufügen und die Einstellungsmöglichkeiten je
  nach Anforderungen sehr verschieden aussehen. Daher stellt man diese einfach
  anschliessend manuell ein. Das Einfügen in die Welt wird aber abgenommen.
 */
func int InsertTrigger(var String trgrClass, var int vtreePtr,
        var String objectName, var String visual) {
    var int trgrPtr; const int TriggerConstructAddr = 0;
    if (Hlp_StrCmp(trgrClass, "zCTrigger")) {
        trgrPtr = MEM_Alloc(sizeof_zCTrigger);
        TriggerConstructAddr = 6356640; //0x60FEA0
    } else if (Hlp_StrCmp(trgrClass, "oCTriggerScript")) {
        trgrPtr = MEM_Alloc(sizeof_oCTriggerScript);
        TriggerConstructAddr = 4441072; //0x43C3F0
    } else if (Hlp_StrCmp(trgrClass, "oCTriggerChangeLevel")) {
        trgrPtr = MEM_Alloc(sizeof_oCTriggerChangeLevel);
        TriggerConstructAddr = 4439280; //0x43BCF0
    } else if (Hlp_StrCmp(trgrClass, "zCMover")) {
        trgrPtr = MEM_Alloc(sizeof_zCMover);
        TriggerConstructAddr = 6360352; //0x610D20
    } else {
        MEM_Warn(ConcatStrings("InsertTrigger: Trigger class invalid: ",
            trgrClass));
        return 0;
    };
    CALL__thiscall(trgrPtr, TriggerConstructAddr);
    if (Hlp_StrCmp(trgrClass, "zCTrigger")
    || Hlp_StrCmp(trgrClass, "zCMover")) { // zC-Class
        if (!InsertzCVobIntoWorld(trgrPtr, NewTrafo(), vtreePtr, objectName,
                visual)) {
            MEM_Warn(ConcatStrings("InsertTrigger: Could not insert ",
                trgrClass));
            RemovezCVobSafe(trgrPtr, 1); // Achtung hier auch zC-Class
            return 0;
        };
    } else { // oC-Class
        if (!InsertoCVobIntoWorld(trgrPtr, NewTrafo(), vtreePtr, objectName,
                visual)) {
            MEM_Warn(ConcatStrings("InsertTrigger: Could not insert ",
                trgrClass));
            RemoveoCVobSafe(trgrPtr, 1); // Hier aber oC-Class
            return 0;
        };
    };
    return trgrPtr;
};