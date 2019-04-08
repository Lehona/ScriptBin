func void ScreenFade(var int durationInMS, var int waitInMS) {
	var int view; view = View_Create(0, 0, 8192, 8192);
	View_SetTexture(view, "default.tga");
	View_SetColor(view, 0);
	View_Open(view);
	
    var int a8; a8 = Anim8_NewExt(0, ScreenFadeHandler, view, false);
	Anim8_RemoveIfEmpty(a8, true);
	Anim8_RemoveDataIfEmpty(a8, true); 
    
    Anim8(a8, 255, durationInMS, A8_Constant);
    Anim8q(a8, 255, waitInMS, A8_Wait);
    Anim8q(a8, 0, durationInMS, A8_Constant);
	
	FF_ApplyExt(TurnScreenBackOn, 2*durationInMS+waitInMS+50, 1); // Delay an extra 50ms just to make sure the ordering is correct. TODO: Extend Anim8 to do this
	
};

func void ScreenFadeHandler(var int view, var int alpha) {
	HideBars();
	View_SetColor(view, RGBA(0, 0, 0, alpha));
};

func void TurnScreenBackOn() {
	ShowBars();
};