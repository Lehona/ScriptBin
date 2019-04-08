// See https://forum.worldofplayers.de/forum/threads/790720-Scriptpaket-Zugriff-auf-ZenGine-Objekte?p=13659168&viewfull=1#post13659168
// Made by Gottfried	

//########################################################################################
//##                                                                                    ##
//##    B_MultiPageBooks                                                                ##
//##    ================                                                                ##
//##                                                                                    ##
//##    Dieses Script ermöglicht die Erstellung von mehrseitigen Büchern, die           ##
//##    per Tastendruck (Pfeiltasten links und rechts) durchgeblättert werden können.   ##
//##    In jedem "Multibuch" müss in der On_State Funktion "B_MultiPageBooks"           ##
//##    aufgerufen werden. Als Parameter erwartet die Funktion einen String,            ##
//##    der den Funktionsnamen der Buchseiten enthält (GROß GESCHRIEBEN!). In der       ##
//##    neuen Version wird keine Seitenzahl mehr benötigt, sie wird nun vom Spiel       ##
//##    selbst erkannt. Außerdem können nun alle Seiten in eine einzige Funktion        ##
//##    geschrieben werden und das ganze System ist nun denke ich verständlicher        ##
//##                                                                                    ##
//########################################################################################

//----------------------------------
//    Genutzte Variablen
//----------------------------------
var int    CurrentPage;          //Aktuelle Seite
var string CurrentBook;          //Aktuelles Buch
var int    CurrentBookLoopable;  //Darf nach der letzten Seite wieder die erste erscheinen?
var int    CurrentBookMaxPage;   //Anzahl an Seiten des aktuellen Buches
var int    UpdatePage;           //Soll eine neue Seite angezeigt werden?
    
//----------------------------------
//    Nützliche Konstanten
//----------------------------------

// Wird verwendet um eine Schriftart, Margins oder das Hintergrundbild dauerhaft zu setzen (siehe Beispiel)
const int LEFT_PAGE  = -3;
const int RIGHT_PAGE = -2;
const int FONT_EVER  = -1;

// Flags (können über mDoc_Create(var int flag) gesetzt werden
const int DOC_FLAG_NONE = 0; // Nichts
const int DOC_FLAG_LOOP = 1; // Buch fängt hinten wieder von vorne an

//----------------------------------
//    Buchhelfer
//----------------------------------
instance BookHelper (C_NPC)
{
    name = "";
    id   = 43;
    attribute [ATR_HITPOINTS_MAX] = 24;
    attribute [ATR_HITPOINTS]     = 24;
    Mdl_SetVisual (self,"HUMANS.MDS");
};

//----------------------------------
//    ZS des Buchhelfers
//----------------------------------

// Wird für Tastatureingaben verwendet

func void ZS_MultiPageBooks() {
    //Damit sich der hero nicht beim umblättern dreht^^
    var oCNpc her;
    her = Hlp_GetNpc(hero);
    her._zCVob_bitfield[2] = (her._zCVob_bitfield[2] & ~ zCVob_bitfield2_sleepingMode) | 0;
};

func int ZS_MultiPageBooks_Loop() {
    // Wichtig, damit eine Taste nicht mehrmals aufgerufen wird
    AI_Wait (self, 0.1);
    
    // Die nächste Seite aufrufen?
    if (UpdatePage == TRUE)
    {
        MEM_CallByString(CurrentBook);
        UpdatePage = FALSE;
    };
    
    // Tasten
    var int LeftKey;  LeftKey  = MEM_KeyState(KEY_LEFTARROW);
    var int RightKey; RightKey = MEM_KeyState(KEY_RIGHTARROW);
    var int EscKey;   EscKey   = MEM_KeyState(KEY_ESCAPE);
	var int MouseRightKey;   MouseRightKey   = MEM_KeyState(MOUSE_BUTTONRIGHT);
    
    // Pfeil-Links gedrückt
    if (LeftKey == KEY_PRESSED) {
        // Ende des Buches noch nicht erreicht
        if (CurrentPage > 0)
        {
            CurrentPage -= 2;
            MEM_InsertKeyEvent (KEY_ESCAPE);
			MEM_InsertKeyEvent (MOUSE_BUTTONRIGHT);
            UpdatePage = TRUE;
            return LOOP_CONTINUE;
        }
        // Ende des Buches erreicht, aber Loop ist eingeschaltet
        else if (CurrentBookLoopable) {
            CurrentPage = CurrentBookMaxPage - (CurrentBookMaxPage%2);
            MEM_InsertKeyEvent (KEY_ESCAPE);
			MEM_InsertKeyEvent (MOUSE_BUTTONRIGHT);
            UpdatePage = TRUE;
            return LOOP_CONTINUE;
        };
    };
    
    // Pfeil-Rechts gedrückt
    if (RightKey == KEY_PRESSED) {
        // Ende des Buches noch nicht erreicht
        if (CurrentPage < CurrentBookMaxPage-2)
        {
            CurrentPage += 2;
            MEM_InsertKeyEvent (KEY_ESCAPE);
			MEM_InsertKeyEvent (MOUSE_BUTTONRIGHT);
            UpdatePage = TRUE;
            return LOOP_CONTINUE;
        }
        // Ende des Buches erreicht, aber Loop ist eingeschaltet
        else if (CurrentBookLoopable) {
            CurrentPage = 0;
            MEM_InsertKeyEvent (KEY_ESCAPE);
			MEM_InsertKeyEvent (MOUSE_BUTTONRIGHT);
            UpdatePage = TRUE;
            return LOOP_CONTINUE;
        };
    };
    
    // Wenn Escape gedrückt, Loop verlassen und Buch schließen
    if (EscKey == KEY_PRESSED || MouseRightKey == KEY_PRESSED)
    {
        return LOOP_END;
    };
};

func void ZS_MultiPageBooks_End()
{
    // Nicht vergessen den hero wieder aufzutauen
    var oCNpc her;
    her = Hlp_GetNpc(hero);
    her._zCVob_bitfield[2] = (her._zCVob_bitfield[2] & ~ zCVob_bitfield2_sleepingMode) | 1;

    // Und den Buchhelfer wieder ins jenseits befördern
	
	MEMINT_StackPushInst(self);
	MEM_Call(B_RemoveNpc);
};

//----------------------------------
//    Die eigentliche Funktion
//    um ein Buch zu öffnen
//----------------------------------
func void B_MultiPageBooks(var string fnc) {
    CurrentBookMaxPage = 2;
    CurrentBook = fnc;
    CurrentPage = 0;
    CurrentBookMaxPage = CurrentBookMaxPage;

    UpdatePage = TRUE;
    Wld_SpawnNpcRange (hero, BookHelper, 1, 500);

    var C_NPC Book;
    Book = Hlp_GetNPC (BookHelper);

    AI_StartState (Book, ZS_MultiPageBooks, 1, "");
};

//----------------------------------
//    Die Doc Funktionen zum
//    Gebrauch von mehr als 
//    nur zwei Seiten
//----------------------------------

// Die Namen wurden alle beibehalten, es wurde nur überall ein 'm' vorne angehängt (m wie multi)

// Neu: Flags (siehe Konstanten)
func int mDoc_Create(var int flags) {
    if(flags==DOC_FLAG_LOOP) {
        CurrentBookLoopable = 1;
    }
    else {
        CurrentBookLoopable = 0;
    };
    CurrentBookMaxPage = 0;
    return Doc_Create();
};

// Neu: Seitenzahl wird nicht mehr benötigt
func void mDoc_SetPages(var int id) {
    Doc_SetPages(id, 2);
};

// Neu: Mehr als nur 0, 1 bei 'page' möglich
func void mDoc_SetMargins(var int id, var int page, var int x1, var int x2, var int x3, var int x4, var int pxl) {
    if(page<-1) {
        Doc_SetMargins(id, page+3, x1, x2, x3, x4, pxl);
        return;
    };
    if(page>CurrentBookMaxPage) { CurrentBookMaxPage = page; };
    if(page-CurrentPage < 0||page-CurrentPage > 1) {
        return;
    };
    Doc_SetMargins(id, page - CurrentPage, x1, x2, x3, x4, pxl);
};

// Neu: Mehr als nur 0, 1 bei 'page' möglich
func void mDoc_SetPage(var int id, var int page, var string tex, var int scl) {
    if(page<-1) {
        Doc_SetPage(id, page+3, tex, scl);
        return;
    };
    if(page>CurrentBookMaxPage) { CurrentBookMaxPage = page; };
    if(page-CurrentPage < 0||page-CurrentPage > 1) {
        return;
    };
    Doc_SetPage(id, page - CurrentPage, tex, scl);
};

// Neu: Mehr als nur -1, 0 und 1 bei 'page' möglich
func void mDoc_SetFont(var int id, var int page, var string tex) {
    if(page<-1) {
        Doc_SetFont(id, page+3, tex);
        return;
    };
    if(page==-1) {
        Doc_SetFont(id, page, tex);
        return;
    };
    if(page>CurrentBookMaxPage) { CurrentBookMaxPage = page; };
    if(page-CurrentPage < 0||page-CurrentPage > 1) {
        return;
    };
    Doc_SetFont(id, page - CurrentPage, tex);
};

// Neu: Mehr als nur 0, 1 bei 'page' möglich
func void mDoc_PrintLine(var int id, var int page, var string text) {
    if(page>CurrentBookMaxPage) { CurrentBookMaxPage = page; };
    if(page-CurrentPage < 0||page-CurrentPage > 1) {
        return;
    };
    Doc_PrintLine(id, page - CurrentPage, text);
};

// Neu: Mehr als nur 0, 1 bei 'page' möglich
func void mDoc_PrintLines(var int id, var int page, var string text) {
    if(page>CurrentBookMaxPage) { CurrentBookMaxPage = page; };
    if(page-CurrentPage < 0||page-CurrentPage > 1) {
        return;
    };
    Doc_PrintLines(id, page - CurrentPage, text);
};

// Neue Hilfsfunktion: Erstellt ein normales Buch (es fehlen nur noch Hintergründe)
func void mDoc_CreateStandard(var int DocID) {
    mDoc_SetPages   (DocID);
    mDoc_SetMargins (DocID, LEFT_PAGE,  275, 20, 30,  20, 1);
    mDoc_SetMargins (DocID, RIGHT_PAGE, 30,  20, 275, 20, 1);
};

// Unverändert [existiert nur der Ordnung halber]
func void mDoc_Show(var int id) {
    // Überflüssig ich weiß :p
    Doc_Show(id);
};

//----------------------------------
//    BEISPIELBÜCHER
//----------------------------------

//-------------------------------
//    MULTITESTBUCH_01
//-------------------------------
// Hier wird ein Buch so einfach und so kurz wie Möglich geschrieben
instance _01_MultiTestBuch(C_Item) 
{
    name         =    "Leichtes Buch";
    mainflag     =    ITEM_KAT_DOCS;
    visual       =    "ItWr_Book_02_04.3ds";
    material     =    MAT_LEATHER;
    scemeName    =    "MAP";    
    description  =    "Zum Testen von mehrseitigen Büchern";
    on_state[0]  =    MultiTestBuch_01_OnState;
};

func void MultiTestBuch_01_OnState() {
    B_MultiPageBooks("MULTITESTBUCH_01_CONTENT");
};

// Der Inhalt des Buches:
func void MULTITESTBUCH_01_CONTENT() {
    var int DocID;
    // Ein normales Buch
    DocID = mDoc_Create(DOC_FLAG_NONE);
    mDoc_CreateStandard(DocID);
    
    // Hintergründe
    // Hier werden die Konstanten "LEFT_PAGE" und "RIGHT_PAGE" und "FONT_EVER"
    // verwendet, dadurch werden die hier angegebenen Hintergründe
    // auf jeder Seite angezeigt und sie müssen nur einmalig hier
    // oben angegeben werden
    mDoc_SetPage    (DocID, LEFT_PAGE,  "Book_Brown_L.tga", 0); 
    mDoc_SetPage    (DocID, RIGHT_PAGE, "Book_Brown_R.tga", 0);
    mDoc_SetFont    (DocID, FONT_EVER,  "font_10_book.tga");
    
    // Alle Standards sind gesetzt, damit kann jetzt frei drauflos
    // geschrieben werden!
    // Nach der ID wird die Seite angegeben, bei der 'm' Funktionen
    // können nun aber auch mehr als 0 und 1 erfolgen:
    
    // 1. Seite
    mDoc_PrintLine  (DocID, 0,  "");
    mDoc_PrintLine  (DocID, 0,  "");
    mDoc_PrintLine  (DocID, 0,  "Testseite 1");

    // 2.Seite
    mDoc_PrintLine  (DocID, 1, "");
    mDoc_PrintLine  (DocID, 1, "");
    mDoc_PrintLine  (DocID, 1, "Testseite 2");
    
    // 3.Seite
    mDoc_PrintLine  (DocID, 2, "");
    mDoc_PrintLine  (DocID, 2, "");
    mDoc_PrintLine  (DocID, 2, "Testseite 3");
    
    // 4.Seite
    mDoc_PrintLine  (DocID, 3, "");
    mDoc_PrintLine  (DocID, 3, "");
    mDoc_PrintLine  (DocID, 3, "Testseite 4");

    // Und alles anzeigen:
    mDoc_Show       (DocID);
};

//-------------------------------
//    MULTITESTBUCH_02
//-------------------------------
// Hier wird ein Buch mit (fast ;-) ) allen Möglichkeiten die dieses Pack
// bietet angezeigt:
instance _02_MultiTestBuch(C_Item)
{
    name         =    "Schweres Buch";
    mainflag     =    ITEM_KAT_DOCS;
    visual       =    "ItWr_Book_02_04.3ds";
    material     =    MAT_LEATHER;
    scemeName    =    "MAP";    
    description  =    "Zum Testen von mehrseitigen Büchern";
    on_state[0]  =    MultiTestBuch_02_OnState;
};

func void MultiTestBuch_02_OnState() {
    B_MultiPageBooks("MULTITESTBUCH_02_CONTENT");
};

// Der Inhalt des Buches:
func void MULTITESTBUCH_02_CONTENT() {
    var int DocID;
    // Ein Buch das niemals endet:
    DocID = mDoc_Create(DOC_FLAG_LOOP);
    
    // MUSS kommen:
    mDoc_SetPages   (DocID);
    
    mDoc_SetMargins (DocID, LEFT_PAGE,  275, 20, 30,  20, 1);
    mDoc_SetMargins (DocID, RIGHT_PAGE, 30,  20, 275, 20, 1);
    
    // Diesmal kommen Hintergründe, Fonts und Margins zu jeder
    // Seite extra und nicht dauerhaft:
    
    // 1. Seite
    mDoc_SetPage    (DocID, 0, "Book_Brown_L.tga", 0);    
    mDoc_SetMargins (DocID, 0, 275, 20, 30, 20, 1);
    mDoc_SetFont    (DocID, 0, "font_20_book.tga");
    mDoc_PrintLine  (DocID, 0,  "");
    mDoc_PrintLine  (DocID, 0,  "Verschiedene");
    mDoc_SetFont    (DocID, 0, "font_10_book.tga");
    mDoc_PrintLine  (DocID, 0,  "Schriftarten,");

    // 2.Seite
    mDoc_SetPage    (DocID, 1, "Book_Red_R.tga", 0);
    mDoc_SetMargins (DocID, 1, 30, 20, 275, 20, 1);
    mDoc_SetFont    (DocID, 1, "font_10_book.tga");
    mDoc_PrintLine  (DocID, 1, "");
    mDoc_PrintLine  (DocID, 1, "");
    mDoc_PrintLines (DocID, 1, "Unterschiedliche Hintergründe,");
    
    // 3.Seite
    mDoc_SetPage    (DocID, 2, "Book_Mage_R.tga", 0);
    mDoc_SetMargins (DocID, 2, 30, 20, 275, 20, 1);
    mDoc_SetFont    (DocID, 2, "font_10_book.tga");
    mDoc_PrintLine  (DocID, 2, "");
    mDoc_PrintLine  (DocID, 2, "");
    mDoc_PrintLine  (DocID, 2, "Oder lieber etwas");
    
    // 4.Seite
    mDoc_SetPage    (DocID, 3, "Book_Mage_L.tga", 0);    
    mDoc_SetMargins (DocID, 3, 275, 20, 30, 20, 1);
    mDoc_SetFont    (DocID, 3, "font_10_book.tga");
    mDoc_PrintLine  (DocID, 3, "");
    mDoc_PrintLine  (DocID, 3, "");
    mDoc_PrintLine  (DocID, 3, "ganz anderes?");
    
    // 5.Seite
    mDoc_SetPage    (DocID, 4, "Book_MayaRead_L.tga", 0);
    mDoc_SetMargins (DocID, 4, 275, 20, 30, 20, 1);
    mDoc_SetFont    (DocID, 4, "font_10_book.tga");
    mDoc_PrintLine  (DocID, 4, "");
    mDoc_PrintLine  (DocID, 4, "");
    mDoc_PrintLines (DocID, 4, "Und jetzt der Knüller: Ich weiß in welche Richtung du Blätterst ;)");
    
    // 6.Seite
    var int x;
    mDoc_SetPage    (DocID, 5, "Book_MayaRead_R.tga", 0);    
    mDoc_SetMargins (DocID, 5, 30, 20, 275, 20, 1);
    mDoc_SetFont    (DocID, 5, "font_20_book.tga");
    mDoc_PrintLine  (DocID, 5, "");
    if(x!=2) {
        mDoc_PrintLine  (DocID, 5, "Von Rechts!");
    }
    else {
        mDoc_PrintLine  (DocID, 5, "Von Links!");
    };
    
    x = CurrentPage;
    
    // 7.Seite
    mDoc_SetPage    (DocID, 6, "Gesucht.tga", 0);    
    
    // 9. Seite
    mDoc_SetPage    (DocID, 8, "Book_Brown_L.tga", 0);    
    mDoc_SetMargins (DocID, 8, 275, 20, 30, 20, 1);
    mDoc_SetFont    (DocID, 8, "font_10_book.tga");
    mDoc_PrintLine  (DocID, 8, "");
    mDoc_PrintLine  (DocID, 8, "");
    mDoc_PrintLines (DocID, 8, "Auch Seiten einfach auslassen ist kein Problem.");

    // 10.Seite
    mDoc_SetPage    (DocID, 9, "Book_Red_R.tga", 0);
    mDoc_SetMargins (DocID, 9, 30, 20, 275, 20, 1);
    mDoc_SetFont    (DocID, 9, "font_10_book.tga");
    mDoc_PrintLine  (DocID, 9, "");
    mDoc_PrintLine  (DocID, 9, "");
    mDoc_PrintLine  (DocID, 9, "");
    mDoc_PrintLine  (DocID, 9, "");
    mDoc_PrintLine  (DocID, 9, "");
    mDoc_PrintLine  (DocID, 9, "");
    mDoc_PrintLines (DocID, 9, "Ja und das wars auch schon :) Viel Spaß! [Dank dem Loop kommst du jetzt wieder auf Seite 1]");

    // Und alles anzeigen:
    mDoc_Show       (DocID);
};

func void _mDoc_SetPagenumbersLayout(var int DocID) {
    mDoc_SetMargins (DocID, LEFT_PAGE,  375, 453, 30,  20, 1);
    mDoc_SetMargins (DocID, RIGHT_PAGE, 160, 453, 30,  20, 1);
};
	
func void _mDoc_CreatePageNumbers(var int DocID, var int Pagenumber) {
    if Pagenumber > 0 {
		mDoc_PrintLines (DocID, Pagenumber - 1, IntToString(Pagenumber));
		_mDoc_CreatePageNumbers(DocID, Pagenumber - 1);
	};
};
func void mDoc_SetPagenumbers(var int DocID, var int Pagenumbers){    
	_mDoc_SetPagenumbersLayout(DocID);
    _mDoc_CreatePageNumbers(DocID, Pagenumbers);
};
