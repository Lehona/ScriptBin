func string i2s(var int i) {
	return IntToString(i);
};

func string cs2 (var string s1, var string s2) {
    return ConcatStrings (s1, s2);
};

func string cs3 (var string s1, var string s2, var string s3) {
    return cs2 (cs2 (s1, s2), s3);
};

func string cs4 (var string s1, var string s2, var string s3, var string s4) {
    return cs2 (cs3 (s1, s2, s3), s4);
};

func string cs5 (var string s1, var string s2, var string s3, var string s4, var string s5) {
    return cs2 (cs4 (s1, s2, s3, s4), s5);
};

func string cs6 (var string s1, var string s2, var string s3, var string s4, var string s5, var string s6) {
    return cs2 (cs5 (s1, s2, s3, s4, s5), s6);
};

func string cs7 (var string s1, var string s2, var string s3, var string s4, var string s5, var string s6, var string s7) {
    return cs2 (cs6 (s1, s2, s3, s4, s5, s6), s7);
};

func string cs8 (var string s1, var string s2, var string s3, var string s4, var string s5, var string s6, var string s7, var string s8) {
    return cs2 (cs7 (s1, s2, s3, s4, s5, s6, s7), s8);
};

func string cs9 (var string s1, var string s2, var string s3, var string s4, var string s5, var string s6, var string s7, var string s8, var string s9) {
    return cs2 (cs8 (s1, s2, s3, s4, s5, s6, s7, s8), s9);
};

func int max(var int i, var int j) {
	if (i > j) {
		return i;
	};
	return j;
};

func int max3(var int i1, var int i2, var int i3) {
	return max(max(i1, i2), i3);
};

func int max4(var int i1, var int i2, var int i3, var int i4) {
	return max(max3(i1, i2, i3), i4);
};

func int max5(var int i1, var int i2, var int i3, var int i4, var int i5) {
	return max(max4(i1, i2, i3, i4), i5);
};

func int max6(var int i1, var int i2, var int i3, var int i4, var int i5, var int i6) {
	return max(max5(i1, i2, i3, i4, i5), i6);
};

