// See https://forum.worldofplayers.de/forum/threads/752130-TIPP-Diverse-Zeit-Skripte
// Made by Milky-Way


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//		Wld_GetTime V. 1.5.1
//		----------------------------------------------------
//
//		Wiedergabe der Zeit in Minuten und Ähnliches
//		Basiert auf einem Skript von Nodrog
//
//		B_CalcDayHrMin (VAR int dy, VAR int hr, VAR int min) gibt die Zeit im Format dhhmm wieder, Minuten > 60 werden dabei in Stunden umgerechnet, Stunden > 24 in Tage
//		Wld_GetHour () gibt die aktuelle Stunde zurück
//		Wld_GetMinute () gibt die aktuelle Minute zurück
//		Wld_GetTime() gibt die aktuelle Zeit im Format dhhmm zurück
//		Wld_AddTime (VAR int days_add, VAR int hours_add, VAR int minutes_add) stellt die Zeit um days_add Tage, hours_add Stunden und minutes_add Minuten vor
//		Wld_SubTime (VAR int days_sub, VAR int hours_sub, VAR int minutes_sub) stellt die Zeit um days_sub Tage, hours_sub Stunden und minutes_sub Minuten zurück
//		Wld_GetTimePlus (VAR int days_add, VAR int hours_add, VAR int minutes_add) gibt die Uhrzeit in days_add Tagen, hours_add Stunden und minutes_add Minuten im Format dhhmm zurück
//		Wld_GetTimeSub (VAR int days_sub, VAR int hours_sub, VAR int minutes_sub) gibt die Uhrzeit vor days_sub Tagen, hours_add Stunden und minutes_add Minuten im Format dhhmm zurück
//		B_PrintTime (VAR int hhmm, VAR int x, VAR int y, VAR int t) Printet die Uhrzeit im Format hh:mm an Position (x|y) für t Sekunden
//		Wld_IsExactTime (VAR int hhmm) liefert TRUE zurück, wenn es genau hh:mm Uhr ist
//		SCRIPT_TIME () mindestens einmal die Sekunde vom Trigger TRIGGER_TIME aufrufen lassen, damit die Uhrzeit angezeigt wird
//		Wld_IsBeforeTime (VAR int dhhmm) liefert TRUE zurück, wenn es vor d Tage, hh:mm Uhr ist
//		Wld_IsAfterTime (VAR int dhhmm) liefert TRUE zurück, wenn es nach d Tage, hh:mm Uhr ist
//
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////


FUNC int B_CalcDayHrMin (VAR int dy, VAR int hr, VAR int min)	// Bricht Stunden und Minuten zu einer Zahl
{
	VAR int ret;
	IF (min >= 60)
	{
		RETURN B_CalcDayHrMin (dy, hr+1, min-60);
	}
	ELSE IF (hr >= 24)
	{
		RETURN B_CalcDayHrMin (dy+1, hr-24, min);
	}	
	ELSE
	{
		dy = dy * 10000;
		hr = hr * 100;
		ret = dy + hr + min;
		RETURN ret;
	};	
};

FUNC int Wld_FindMinute(var int Hour,var int from,var int till)		// Returned die aktuelle Minute
{
	IF (from >= 60)
	{
		RETURN -1;
	};
	IF (Wld_IsTime (hour, 59, hour+1, 10))
	{
		RETURN 59;
	}	
	ELSE IF (Wld_IsTime (hour, 58, hour+1, 10))
	{
		RETURN 58;
	}
	ELSE IF (Wld_IsTime (hour, 57, hour+1, 10))
	{
		RETURN 57;
	}
	ELSE IF (Wld_IsTime(Hour,from+1,Hour,till))
	{
		RETURN Wld_FindMinute(Hour,from+1,till);
	}
	ELSE
	{
		RETURN from;
	};
};

FUNC int Wld_FindHour(var int from,var int till)		// Returned die aktuelle Stunde
{
	IF (Wld_IsTime (23,00,0,0))
	{
		RETURN 23;
	}
	ELSE IF (Wld_IsTime (22,55,23,10))
	{
		RETURN 22;
	}
	ELSE IF (from >= 24)
	{
		RETURN -1;    
	}
	ELSE IF (Wld_IsTime(from+1,0,till,0))
	{
		RETURN Wld_FindHour(from+1,till);
	}
	ELSE
	{
		RETURN from;
	};
	
};

FUNC int Wld_GetHour ()		// Returned die aktuelle Stunde
{
	var int hour;
	hour = Wld_FindHour(0,23);
	RETURN hour;
};

FUNC int Wld_GetMinute ()	// Returned die aktuelle Minute
{
	VAR int minute;
	minute = Wld_FindMinute (Wld_GetHour(),0,59);
	RETURN minute;
};

FUNC int Wld_GetTime()		// Returned die Uhrzeit im Format hhmm
{
	var int d;
	VAR int h;
	VAR int m;
	h = Wld_GetHour();
	m = Wld_GetMinute();
	d = Wld_GetDay ();
	
	VAR int ret;
	ret = d * 10000 + h * 100 + m;
	RETURN ret;
};

FUNC void Wld_AddTime (VAR int days_add, VAR int hours_add, VAR int minutes_add)	// Stellt die Zeit vor
{
	VAR int calc;
	calc = B_CalcDayHrMin (days_add, hours_add, minutes_add);
	days_add = calc / 10000;
	hours_add = calc % 10000;
	hours_add = hours_add / 100;
	minutes_add = calc % 100;
	
	VAR int hour;
	hour = Wld_GetHour () + hours_add + 24 * days_add;
	
	VAR int minutes;
	minutes = Wld_GetMinute ();
	hour = hour + ((minutes	+ minutes_add) / 60);
	minutes = (minutes + minutes_add)%60;
	
	Wld_SetTime (hour,minutes);
};

FUNC void Wld_SubTime (VAR int days_sub, VAR int hours_sub, VAR int minutes_sub)		// Stellt die Zeit zurück
{
	VAR int calc;
	calc = B_CalcDayHrMin (days_sub, hours_sub, minutes_sub);
	days_sub = calc / 10000;
	hours_sub = calc % 10000;
	hours_sub = hours_sub / 100;
	minutes_sub = calc % 100;
	
	VAR int hour;
	hour = Wld_GetHour () - hours_sub - 24 * days_sub;
	
	VAR int minutes;
	minutes = Wld_GetMinute ();
	
	IF (minutes >= minutes_sub)
	{
		minutes = minutes - minutes_sub;
	}
	ELSE
	{
		hour = hour - 1;
		minutes = 60 - (minutes_sub - minutes);
	};	
	
	Wld_SetTime (hour,minutes);
};

FUNC int Wld_GetTimePlus (VAR int days_add, VAR int hours_add, VAR int minutes_add)		//Wie viel Uhr ist es in x Stunden und y Minuten?
{
	VAR int calc;
	calc = B_CalcDayHrMin (days_add, hours_add, minutes_add);
	days_add = calc / 10000;
	hours_add = calc % 10000;
	hours_add = hours_add / 100;
	minutes_add = calc % 100;
	
	VAR int newDay;
	newDay = Wld_GetDay ()+ days_add;
	
	VAR int hour;
	hour = Wld_GetHour () + hours_add;
	
	VAR int minutes;
	minutes = Wld_GetMinute ();
	hour = hour + ((minutes	+ minutes_add) / 60);
	newDay = newDay + hour / 24;
	hour = hour % 24;
	minutes = (minutes + minutes_add)%60;
	
	VAR int ret;
	newDay =  newDay * 10000;
	hour = hour * 100;
	ret = newDay + hour + minutes;
	RETURN ret;
};


FUNC int Wld_GetTimeSub (VAR int days_sub, VAR int hours_sub, VAR int minutes_sub)		// Wie viel Uhr war es vor x Stunden und y Minuten?
{
	VAR int calc;
	calc = B_CalcDayHrMin (days_sub, hours_sub, minutes_sub);
	days_sub = calc / 10000;
	hours_sub = calc % 10000;
	hours_sub = hours_sub / 100;
	minutes_sub = calc % 100;
	
	VAR int newDay;
	newDay = Wld_GetDay () - days_sub;
	
	VAR int hour;
	hour = Wld_GetHour () - hours_sub;
	
	VAR int minutes;
	minutes = Wld_GetMinute ();
	
	IF (minutes >= minutes_sub)
	{
		minutes = minutes - minutes_sub;
	}
	ELSE
	{
		hour = hour - 1;
		minutes = 60 - (minutes_sub - minutes);
	};	
	
	IF (hour < 0)
	{
		newDay = newDay - 1;
		hour = 24 + hour;
	};
	
	VAR int ret;
	newDay = newDay * 10000;
	hour = hour * 100;
	ret = newDay + hour + minutes;
	RETURN ret;	
};

Func void B_PrintTime (VAR int dhhmm, VAR int x, VAR int y, VAR int t)	// Umrechnung und Print einer Uhrzeit vom Format hhmm
{
	VAR int curDay;
	VAR int hour;
	VAR int minute;
	curDay = dhhmm / 10000;
	hour = dhhmm % 10000;
	hour = hour / 100;
	minute = dhhmm % 100;
	VAR string prnt;
	VAR string dy;
	VAR string hr;
	VAR string min;
	dy = IntToString (curDay);
	hr = IntToString (hour);
	min = IntToString (minute);
	IF (hour < 10)
	{
		hr = ConcatStrings ("0", hr);
	};
	IF (minute < 10)
	{
		min = ConcatStrings ("0", min);
	};
	prnt = ConcatStrings (dy, ". Tag - ");
	prnt = ConcatStrings (prnt, hr);
	prnt = ConcatStrings (prnt, ":");
	prnt = ConcatStrings (prnt, min);
	PrintScreen (prnt, x,y, FONT_Screen, t);
};

FUNC int Wld_IsExactTime (VAR int dhhmm)		//Ist es genau hhmm Uhr?
{
	IF (dhhmm == Wld_GetTime ())
	{
		RETURN TRUE;
	}
	ELSE
	{
		RETURN FALSE;
	};	
};

FUNC void SCRIPT_TIME ()			//Für Uhrzeit von einem sekündlichem Trigger "TRIGGER_TIME" aufrufen lassen
{
	B_PrintTime (Wld_GetTime (), 5,5,1);
	Wld_SendTrigger ("TRIGGER_TIME");
};

FUNC int Wld_IsBeforeTime (VAR int dhhmm)		//Ist es vor hhmm Uhr?
{
	IF (Wld_GetTime() >= dhhmm)
	{
		RETURN FALSE;
	}
	ELSE
	{
		RETURN TRUE;
	};	
};

FUNC int Wld_IsAfterTime (VAR int dhhmm)		//Ist es nach hhmm Uhr?
{
	IF (Wld_GetTime() <= dhhmm)
	{
		RETURN FALSE;
	}
	ELSE
	{
		RETURN TRUE;
	};	
};