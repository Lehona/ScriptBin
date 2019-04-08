// See https://forum.worldofplayers.de/forum/threads/775333-Script-Broadcasts?p=17232705&viewfull=1#post17232705
// Made by Sektenspinner


//#################################################
//
//    Nutzungshinweise:
//
//#################################################

/*************************************************
//   Idee
//************************************************

Die hier vorgestellten Funktionen ermöglichen es,
für alle Npcs in der Welt oder alle Npcs in der KI-Glocke
eine beliebige Funktion aufzurufen. 

//************************************************
//   Setup
//************************************************

Eine aktuelle Version von Ikarus wird benötigt.
Ikarus gibt es hier:
http://forum.worldofplayers.de/forum/threads/969446-Skriptpaket-Ikarus-3

Die Datei, die du grade liest, ist nach Ikarus zu parsen.
 
//************************************************
//   Funktionen
//************************************************

func void DoForAll    (var func function)
func void DoForSphere (var func function)
 
"function" muss eine Funktion sein, die einen Parameter
vom Typ C_NPC nimmt und nichts zurückgibt.
DoForAll ruft function für jeden Npc auf, der in der Welt existiert.
DoForSphere ruft function für jeden Npc in der KI-Glocke auf
(also im Radius von ~40 Meter um die Kamera)

Beispiel:

**************************
func void foo() {
    DoForSphere(SayHi);
};

func void SayHi(var C_NPC slf) {
    PrintDebug(ConcatStrings (slf.name, " sagt Hallo!"));
};
**************************

Eine mögliche Anwendung für DoForAll wäre ein Schwierigkeitsgradsystem, dass,
wenn der Schwierigkeitsgrad verändert wird, alle Npcs anpassen muss.

######### Broadcasts #########

Eine einfache Abwandlung dieser Funktionen ist der Broadcast.
Die Idee ist hierbei, dass ein Npc, der "Caster", eine Nachricht
an alle anderen Npcs sendet, die dann bei jedem Npc verarbeitet wird.

Beispielsweise könnte ein Npc, der einen Massenheilzauber spricht,
dies "broadcasten" und die Npcs reagieren darauf, indem sie ihre Lebensenergie
auffüllen (wenn sie in der selben Partei kämpfen wie der Caster).
Grundsätzlich ergeben sich durch Broadcasts mannigfache Möglichkeiten für Flächenzauber.

Broadcasts können auch Wahrnehmungen sinnvoll ergänzen und helfen eine Situation zu überblicken.
Etwa könnte ein Monster, bevor es den Spieler angreift erstmal einen "durchzählen!"-Broadcast
herausschicken, indem sich alle Freunde des Monsters "melden". So könnte ein Wolf,
der alleine ist, fliehen (vielleicht sogar zu einem Rudel in der Nähe);
ein Wolf, der im Rudel steht dagegen mutiger sein.

Ein Troll, der den Spieler kommen sieht, könnte das allen Npcs mitteilen,
woraufhin vielleicht Goblins in der Umgebung bei ihm Schutz suchen.

Doch nun zur Funktion:

func void Broadcast (var C_NPC caster, var func function)

function muss eine Funktion sein, die zwei C_NPC Parameter entgegennimmt und nichts zurückgibt.
Dann wird function(npc, caster) für jeden Npc aufgerufen, der folgende Bedingungen erfüllt:

1.) Er ist in der KI-Glocke
2.) Er ist nicht tot (HP != 0).

Es gibt eine erweiterte ("EXtended") Version von Broadcast mit folgender Signatur:

func void BroadcastEx(var C_NPC caster, var func function,
                      var int excludeCaster, var int includeDead, var int includeShrinked)
                      
Sind die drei zusätzlichen Parameter 0, so verhält sich BroadcastEx genau wie Broadcast.
Ansonsten beeinflussen die drei Parameter folgendes, wenn sie nicht Null sind:

    excludeCaster:   function wird nicht für den Caster aufgerufen
                     (das heißt der Caster benachrichtigt sich nicht selbst)
    includeDead:     Auch tote Npcs werden benachrichtigt (Bedingung 2. wird also ignoriert)
    includeShrinked: Auch Npcs außerhalb der KI-Glocke (die daher nur in einer abgespeckten
                     Version in der Welt existieren (kein aktives Visual)) werden benachrichtigt.
                     (das heißt Bedingung 1. wird ignoriert).

Beispiel:

**************************

var int friendCount;
//Gibt Anzahl Freunde von slf zurück, die in der KI-Glocke sind.
func int CountFriends(var C_NPC slf) {
    friendCount = 0;
    Broadcast(slf, CountFrieds_Sub);
    return friendCount;
};

//Hilfsfunktion:
func void CountFrieds_Sub(var C_NPC slf, var C_NPC caster) {
    if (Npc_GetPermAttitude(slf, caster) == ATT_FRIENDLY) {
        friendCount += 1;
    };
};

**************************

Anmerkung: Schachteln der Funktionen ist nicht erlaubt.
Das heißt während eine Ausführung von DoForAll / DoForSphere läuft,
darf keine weitere gestartet werden.
*/

//#################################################
//
//    Implementierung
//
//#################################################

//************************************************
//   The Core: Iterating through Lists.
//************************************************

func void _BC_ForAll(var int funcID, var int sphereOnly) {
    MEM_InitAll(); //safety, don't know if user did it.

    var int busy;
    if (busy) {
        MEM_Error("Broadcast-System: Nesting is not allowed!");
        return;
    };
    
    busy = true;
    
    var C_NPC slfBak; slfBak = Hlp_GetNpc(self);
    var C_NPC othBak; othBak = Hlp_GetNpc(other);
    
    if (sphereOnly) {
        /* to speed things up (and do the filtering)
         * we only search the (small) active Vob List */
        var int i;    i    = 0;
        var int loop; loop = MEM_StackPos.position;
        
        if (i < MEM_World.activeVobList_numInArray) {
            var int vob;
            vob = MEM_ReadIntArray(MEM_World.activeVobList_array, i);
            
            if (Hlp_Is_oCNpc(vob)) {
                var C_NPC npc;
                npc = MEM_PtrToInst(vob);
                MEM_PushInstParam(npc);
                MEM_CallByID(funcID);
            };
            
            i += 1;
            MEM_StackPos.position = loop;
        };
    } else {
        /* walk through the entire Npc List (possibly large). */
        var int listPtr; listPtr = MEM_World.voblist_npcs;
        loop = MEM_StackPos.position;
        
        if (listPtr) {
            vob = MEM_ReadInt(listPtr + 4);
            
            if (Hlp_Is_oCNpc(vob)) {
                npc = MEM_PtrToInst(vob);
                MEM_PushInstParam(npc);
                MEM_CallByID(funcID);
            };
            
            listPtr = MEM_ReadInt(listPtr + 8);
            MEM_StackPos.position = loop;
        };
    };
    
    self  = Hlp_GetNpc(slfbak);
    other = Hlp_GetNpc(othbak);
    
    busy = false;
};

func void DoForAll    (var func _) {
    var MEMINT_HelperClass symb;
    var int theHandlerInt;
    theHandlerInt = MEM_ReadInt(MEM_ReadIntArray(contentSymbolTableAddress, symb - 1) + zCParSymbol_content_offset);

    _BC_ForAll(theHandlerInt, 0);
};

func void DoForSphere(var func _) {
    var MEMINT_HelperClass symb;
    var int theHandlerInt;
    theHandlerInt = MEM_ReadInt(MEM_ReadIntArray(contentSymbolTableAddress, symb - 1) + zCParSymbol_content_offset);
    
    _BC_ForAll(theHandlerInt, 1);
};

//************************************************
//   Building on that: The Broadcast
//************************************************

var int   _BC_funcID;
var int   _BC_CasterPtr;
var C_NPC _BC_Caster;
var int   _BC_ExcludeCaster;
var int   _BC_SendToDead;

func void _BC_CallAssessFunc(var C_NPC slf) {
    //ignore dead, unless they are explicitly included
    if (!slf.attribute[ATR_HITPOINTS] && !_BC_SendToDead) {
        return;
    };
    
    //ignore caster if this is wanted
    if (_BC_ExcludeCaster) {
        if (_BC_CasterPtr == MEM_InstToPtr(slf)) {
            return;
        };
    };
    
    MEM_PushInstParam(slf);
    MEM_PushInstParam(_BC_Caster);
    MEM_CallByID(_BC_funcID);
};

func void _BC_Broadcast(var C_NPC caster, var int funcID, var int excludeCaster, var int includeDead, var int includeShrinked) {
    _BC_ExcludeCaster = excludeCaster;
    _BC_Caster        = Hlp_GetNpc(caster);
    _BC_CasterPtr     = MEM_InstToPtr(caster);
    _BC_SendToDead    = includeDead;
    _BC_funcID        = funcID;
    
    if (includeShrinked) {
        DoForAll(_BC_CallAssessFunc);
    } else {
        DoForSphere(_BC_CallAssessFunc);
    };
};

func void Broadcast  (var C_NPC caster, var func _) {
    var MEMINT_HelperClass symb;
    var int reactionFuncID;
    reactionFuncID = MEM_ReadInt(MEM_ReadIntArray(contentSymbolTableAddress, symb - 1) + zCParSymbol_content_offset);
    
    _BC_Broadcast(caster, reactionFuncID, 0, 0, 0);
};

func void BroadcastEx(var C_NPC caster, var func _, var int excludeCaster, var int includeDead, var int includeShrinked) {
    var MEMINT_HelperClass symb;
    var int reactionFuncID;
    reactionFuncID = MEM_ReadInt(MEM_ReadIntArray(contentSymbolTableAddress, symb - 4) + zCParSymbol_content_offset);
    
    _BC_Broadcast(caster, reactionFuncID, excludeCaster, includeDead, includeShrinked);
};