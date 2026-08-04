//Modify this file to change what commands output to your statusbar, and recompile using the make command.

static const Block blocks[] = {
    /*Icon*/	/*Command*/		/*Update Interval*/	/*Update Signal*/
    {"",		"clipboard_history",		0,			17},
    {"",		"vap-battery",		5,			0},
    /*{"",		"vap-bluetooth",	40,			6},*/
    {"",		"vap-internet",		25,			3},
    {"",		"vap-volume",		0,			10},
    {"",		"vap-clock",		5,			1},
    {"",		"powermenu",		0,			13},
    {"",		"dualscreen_focus_on_big_one",		5,			0},
    // {"",		"multiscreen.sh",		5,			0},
    {"",		"multiscreen",		5,			0},
};

//sets delimiter between status commands. NULL character ('\0') means no delimiter.
static char delim[] = " ";
static unsigned int delimLen = 5;

