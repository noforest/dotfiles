/* See LICENSE file for copyright and license details. */

/* appearance */
static const unsigned int borderpx  = 2;        /* border pixel of windows */
static const unsigned int gappx     = 4;        /* gaps between windows */
static const unsigned int snap      = 10;       /* snap pixel */
static const int showbar            = 1;        /* 0 means no bar */
static const int topbar             = 1;        /* 0 means bottom bar */
// static const char *fonts[]          = { "monospace:size=10" };
// static const char dmenufont[]       = "monospace:size=10";
// static const char *fonts[]          = { "LiterationMonoNerdFont-Regular:size=9" };
// static const char dmenufont[]       = {"LiterationMonoNerdFont-Regular:size=9"};

// static const char *fonts[]          = { "LiterationMono Nerd Font:size=9" };
// static const char dmenufont[]       = {"LiterationMono Nerd Font:size=9"};

static const char *fonts[] = {
    "LiterationMono Nerd Font:size=9:antialias=true:autohint=true",
    "Noto Color Emoji:size=9:antialias=true:autohint=true"
};

static const char dmenufont[] = "LiterationMono Nerd Font:size=9:antialias=true:autohint=true";


// static const char *fonts[] = {
//     "Hack Nerd Font:size=10:antialias=true:autohint=true",
//     "Noto Color Emoji:size=10:antialias=true:autohint=true"
// };
//
// static const char dmenufont[] = "Hack Nerd Font:size=10:antialias=true:autohint=true";


// static const char *fonts[] = {
//     "JetBrainsMono Nerd Font:size=10:antialias=true:autohint=true",
//     "Noto Color Emoji:size=10:antialias=true:autohint=true"
// };
//
// static const char dmenufont[] = "JetBrainsMono Nerd Font:size=10:antialias=true:autohint=true";


// static const char *fonts[] = {
//     "RobotoMono Nerd Font:size=10:antialias=true:autohint=true",
//     "Noto Color Emoji:size=10:antialias=true:autohint=true"
// };
//
// static const char dmenufont[] = "RobotoMono Nerd Font:size=10:antialias=true:autohint=true";



static const char col_gray1[]       = "#222222";
static const char col_gray2[]       = "#444444";
static const char col_gray3[]       = "#bbbbbb";
static const char col_gray4[]       = "#eeeeee";
static const char col_cyan[]        = "#005577";
// static const char col_cyan[]        = "#7222ab";
// static const unsigned int baralpha = 0xd0;
// static const unsigned int borderalpha = 0xff;
static const char *colors[][3]      = {
	/*               fg         bg         border   */
	[SchemeNorm] = { col_gray3, col_gray1, col_gray2 },
	[SchemeSel]  = { col_gray4, col_cyan,  col_cyan  },
	[SchemeStatus]  = { col_gray3, col_gray1,  "#000000"  }, // Statusbar right {text,background,not used but cannot be empty}
	[SchemeTagsSel]  = { col_gray4, col_cyan,  "#000000"  }, // Tagbar left selected {text,background,not used but cannot be empty}
	[SchemeTagsNorm]  = { col_gray3, col_gray1,  "#000000"  }, // Tagbar left unselected {text,background,not used but cannot be empty}
	[SchemeInfoSel]  = { col_gray4, col_gray1,  "#000000"  }, // infobar middle  selected {text,background,not used but cannot be empty}
	[SchemeInfoNorm]  = { col_gray3, col_gray1,  "#000000"  }, // infobar middle  unselected {text,background,not used but cannot be empty}
};
// static const unsigned int alphas[][3]      = {
//     /*               fg      bg        border*/
//     [SchemeNorm] = { OPAQUE, baralpha, borderalpha },
// 	[SchemeSel]  = { OPAQUE, baralpha, borderalpha },
// };

/* tagging */
static const char *tags[] = { "1", "2", "3", "4", "5", "6", "7", "8", "9" };

static const Rule rules[] = {
	/* xprop(1):
	 *	WM_CLASS(STRING) = instance, class
	 *	WM_NAME(STRING) = title
	 */
	/* class      		    instance    title       tags mask     	isfloating   	monitor    float x,y,w,h         floatborderpx*/
	// { "Gimp",     		    NULL,       NULL,       0,            	1,             	-1,        50,50,500,500,        5 },
	// { "Firefox",  		    NULL,       NULL,       1 << 8,       	0,             	-1,        50,50,500,500,        5 },
	// { "pavucontrol",  	    NULL,       NULL,       0,       	    1,             	-1,        1262,26,650,308,      0 },
	// { "st",  		        NULL,       "nmtui",    0,       	    1,             	-1,        1400,26,600,700,      0 },
	// { "Blueman-manager",  	NULL,       NULL,       0,       	    1,             	-1,        1400,26,600,700,      0 },
	// { "Xfce4-notifyd",  	NULL,       NULL,       0,       	    1,             	-1,        -1,26,-1,-1,      	 0 },
 //    { "Clipster",  	        NULL,       NULL,       0,       	    1,             	-1,        1450,26,-1,-1,      	 0 },
 //  // { "alacritty",         NULL,       NULL,       1 << 1,         0,              -1,        50,50,500,500,       0},

    { "Gimp",     		    NULL,       NULL,       0,            	0,             	-1,        50,50,500,500,        5 },
    { "Firefox",  		    NULL,       NULL,       1 << 8,       	0,             	-1,        50,50,500,500,        5 },
    { "pavucontrol",  	    NULL,       NULL,       0,       	    1,             	-1,        6000,22,500,-1,      0 },
    { "st",  		        NULL,       "nmtui",    0,       	    1,             	-1,        6000,22,700,800,      0 },
    { "Blueman-manager",  	NULL,       NULL,       0,       	    1,             	-1,        5900,22,500,-1,      0 },
    { "Xfce4-notifyd",  	NULL,       NULL,       0,       	    1,             	-1,        -1,22,-1,-1,      	 0 },
    { "Clipster",  	        NULL,       NULL,       0,       	    1,             	-1,        6000,22,500,-1,      	 0 },
    { "Matplotlib",  	    NULL,       NULL,       0,       	    1,             	-1,        -1,-1,-1,-1,      	 0 },
    { "Thunar",  	        NULL,       "File Operation Progress",0,1,             	-1,        -1,-1,-1,-1,      	 0 },
    { "Thunar",             NULL,       "Rename",   0,              1,              -1,        -1,-1,-1,-1,         0 },
    { "Swappy",             NULL,       NULL,       0,              1,              -1,        -1,-1,-1,-1,         0 },
    { "okular",             NULL,       NULL,       1 << 2,         0,              -1,         -1,-1,-1,-1,         0 },

    // { "alacritty",         NULL,       NULL,       1 << 1,         0,              -1,        50,50,500,500,       0},
};

/* layout(s) */
static const float mfact     = 0.5; /* factor of master area size [0.05..0.95] */
static const int nmaster     = 1;    /* number of clients in master area */
static const int resizehints = 0;    /* 1 means respect size hints in tiled resizals */
static const int attachbelow = 1;    /* 1 means attach after the currently active window */
static const int lockfullscreen = 1; /* 1 will force focus on the fullscreen window */

// static const int ratiofullscreenborders = 0;

static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[]=",      tile },    /* first entry is default */
	{ "><>",      NULL },    /* no layout function means floating behavior */
	{ "[M]",      monocle },
};

/* key definitions */
#define MODKEY Mod4Mask
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

#define STATUSBAR "dwmblocks"

/* commands */
static char dmenumon[2] = "0"; /* component of dmenucmd, manipulated in spawn() */
static const char *dmenucmd[] = { "dmenu_run", "-m", dmenumon, "-fn", dmenufont, "-nb", col_gray1, "-nf", col_gray3, "-sb", col_cyan, "-sf", col_gray4, NULL };
static const char *termcmd[]  = { "alacritty", NULL };
static const char *prtscrcmd[] = { "flameshot", "gui", NULL};
// static const char *prtscrcmd[] = { "maim_swappy_screenshot.sh", NULL};
#include <X11/XF86keysym.h>
#include "movestack.c"
#include "patches/shiftview.c"


// void spawn_chrome_monocle(const Arg *arg) {
//   const char *chrome[] = { "google-chrome-stable", NULL };
//
//   // Si aucune autre fenêtre n'est présente, passer en mode monocle
//   if (!selmon->clients || !selmon->clients->next) {
//     setlayout(&((Arg) { .v = &layouts[2] }));  // Mode monocle
//   }
//
//   // Lancer Google Chrome
//   spawn(&(const Arg) { .v = chrome });
// }

// static const char *termcmd2[] = { "alacritty", NULL };

static const char *tmuxterm[] = { "alacritty", "-e", "tmux", "new-session", "-A", "-s", "main", NULL };

// static const char *chrome_with_options[] = {
//   "google-chrome-stable",
//   // "--ozone-platform-hint=auto",
//   "--enable-features=TouchpadOverscrollHistoryNavigation",
//   NULL
// };
// static const char *nvimcmd[] = {"nvim", NULL};
static const char *firefox_launch[] = {"firefox", NULL};
static const char *monitor_hotplug[] = {"/usr/local/bin/monitor-hotplug", NULL};

Autostarttag autostarttaglist[] = {
  // {.cmd = nvimcmd, .tags = 1 << 7 },
  // {.cmd = chrome_with_options, .tags = 1 << 0 },
  {.cmd = monitor_hotplug, .tags = 0 },  // tags = 0 : s'exécute en arrière-plan sans tag spécifique
  {.cmd = firefox_launch, .tags = 1 << 0 },
  {.cmd = tmuxterm, .tags = 1 << 1 },
  {.cmd = NULL, .tags = 0 },
};

static const Key keys[] = {
    /* modifier                     key        function        argument */
    // { MODKEY|ControlMask,           XK_f,      toggleratiofullscr,  {0} },
    {MODKEY, XK_p, spawn, {.v = dmenucmd}},
    {MODKEY | ShiftMask, XK_Return, spawn, {.v = termcmd}},
    {MODKEY, XK_b, togglebar, {0}},
    {MODKEY, XK_j, focusstack, {.i = +1}},
    {MODKEY, XK_k, focusstack, {.i = -1}},

    // NOTE: shortcut qui foutent la merde (window qui va au bottom qui peut
    // plus facilement revenir à droite)
    // { MODKEY,                       XK_i,      incnmaster,     {.i = +1 } },
    // { MODKEY,                       XK_d,      incnmaster,     {.i = -1 } },

    {MODKEY, XK_h, setmfact, {.f = -0.05}},
    {MODKEY, XK_l, setmfact, {.f = +0.05}},
    {MODKEY | ShiftMask, XK_j, movestack, {.i = +1}},
    {MODKEY | ShiftMask, XK_k, movestack, {.i = -1}},
    {MODKEY, XK_Return, zoom, {0}},
    {MODKEY, XK_Tab, view, {0}},
    // { MODKEY|ShiftMask,            	XK_c,      killclient,     {0} },
    {MODKEY | ShiftMask, XK_c, smart_kill_with_ctrlq_firefox, {0}},
    {MODKEY, XK_t, setlayout, {.v = &layouts[0]}},
    {MODKEY, XK_f, setlayout, {.v = &layouts[1]}},
    {MODKEY, XK_m, setlayout, {.v = &layouts[2]}},
    {MODKEY, XK_space, setlayout, {0}},
    {MODKEY | ShiftMask, XK_space, togglefloating, {0}},
    {MODKEY, XK_agrave, view, {.ui = ~0}},
    {MODKEY | ShiftMask, XK_agrave, tag, {.ui = ~0}},
    {MODKEY, XK_comma, focusmon, {.i = -1}},
    {MODKEY, XK_semicolon, focusmon, {.i = +1}},
    {MODKEY | ShiftMask, XK_comma, tagmon, {.i = -1}},
    {MODKEY | ShiftMask, XK_semicolon, tagmon, {.i = +1}},
    TAGKEYS(XK_ampersand, 0) TAGKEYS(XK_eacute, 1) TAGKEYS(XK_quotedbl, 2)
        TAGKEYS(XK_apostrophe, 3) TAGKEYS(XK_parenleft, 4) TAGKEYS(XK_minus, 5)
            TAGKEYS(XK_egrave, 6) TAGKEYS(XK_underscore, 7)
                TAGKEYS(XK_ccedilla, 8)
    // { MODKEY|ShiftMask,             XK_q,      quit_properly,           {0}
    // },
    {MODKEY, XK_z, shiftview, {.i = +1}},
    {MODKEY, XK_a, shiftview, {.i = -1}},
    {MODKEY | ShiftMask, XK_s, spawn, {.v = prtscrcmd}},
    // { 0, XF86XK_AudioMute,                         spawn, SHCMD("wpctl
    // set-mute @DEFAULT_AUDIO_SINK@ toggle; kill -44 $(pidof dwmblocks)") }, {
    // 0, XF86XK_AudioRaiseVolume,                  spawn, SHCMD("wpctl
    // set-volume @DEFAULT_AUDIO_SINK@ 0%- && wpctl set-volume
    // @DEFAULT_AUDIO_SINK@ 5%+; kill -44 $(pidof dwmblocks)") }, { 0,
    // XF86XK_AudioLowerVolume,                  spawn, SHCMD("wpctl set-volume
    // @DEFAULT_AUDIO_SINK@ 0%+ && wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-;
    // kill -44 $(pidof dwmblocks)") },
    // { 0, XF86XK_MonBrightnessUp,                   spawn, {.v = (const
    // char*[]){ "xbacklight", "-inc", "15", NULL } } }, { 0,
    // XF86XK_MonBrightnessDown,                 spawn,                  {.v =
    // (const char*[]){ "xbacklight", "-dec", "15", NULL } } },

    // volume
    {0, XF86XK_AudioMute, spawn,
     SHCMD("/usr/local/bin/dunst_vol.sh muted; kill -44 $(pidof dwmblocks)")},
    {0, XF86XK_AudioRaiseVolume, spawn,
     SHCMD("/usr/local/bin/dunst_vol.sh up; kill -44 $(pidof dwmblocks)")},
    {0, XF86XK_AudioLowerVolume, spawn,
     SHCMD("/usr/local/bin/dunst_vol.sh down; kill -44 $(pidof dwmblocks)")},

    {0, XF86XK_AudioPlay, spawn, SHCMD("playerctl play-pause")},
    {0, XF86XK_AudioNext, spawn, SHCMD("playerctl next")},
    {0, XF86XK_AudioPrev, spawn, SHCMD("playerctl previous")},

    // monitor brighness
    {0, XF86XK_MonBrightnessUp, spawn,
     SHCMD("/usr/local/bin/dunst_brightness.sh up")},
    {0, XF86XK_MonBrightnessDown, spawn,
     SHCMD("/usr/local/bin/dunst_brightness.sh down")},
    {0, XF86XK_ScreenSaver, spawn, SHCMD("xset s activate")},

    {MODKEY, XK_g, spawn, SHCMD("firefox")},
    {MODKEY | ShiftMask, XK_asterisk, spawn,
     SHCMD("custom_dir_open_alacritty.sh")},

    {MODKEY, XK_s, spawn, SHCMD("spotify")},
    {MODKEY | ShiftMask, XK_q, spawn, SHCMD("powermenu")},
    {MODKEY, XK_e, spawn, SHCMD("thunar")},
    {MODKEY | ShiftMask, XK_l, spawn, SHCMD("xset s activate")},
    {MODKEY, XK_r, spawn, SHCMD("screen_menu")}, // r comme reload screen

};

/* button definitions */
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */
static const Button buttons[] = {
	/* click                event mask      button          function        argument */
	{ ClkLtSymbol,          0,              Button1,        setlayout,      {0} },
	{ ClkLtSymbol,          0,              Button3,        setlayout,      {.v = &layouts[2]} },
	{ ClkWinTitle,          0,              Button2,        zoom,           {0} },
	{ ClkStatusText,        0,              Button1,        sigstatusbar,   {.i = 1} },
	{ ClkStatusText,        0,              Button2,        sigstatusbar,   {.i = 2} },
	{ ClkStatusText,        0,              Button3,        sigstatusbar,   {.i = 3} },
	{ ClkStatusText,        0,              Button4,        sigstatusbar,   {.i = 4} },
	{ ClkStatusText,        0,              Button5,        sigstatusbar,   {.i = 5} },
	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
	{ ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
	{ ClkTagBar,            0,              Button1,        view,           {0} },
	{ ClkTagBar,            0,              Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
};

void
setlayoutex(const Arg *arg)
{
	setlayout(&((Arg) { .v = &layouts[arg->i] }));
}

void
viewex(const Arg *arg)
{
	view(&((Arg) { .ui = 1 << arg->ui }));
}

void
viewall(const Arg *arg)
{
	view(&((Arg){.ui = ~0}));
}

void
toggleviewex(const Arg *arg)
{
	toggleview(&((Arg) { .ui = 1 << arg->ui }));
}

void
tagex(const Arg *arg)
{
	tag(&((Arg) { .ui = 1 << arg->ui }));
}

void
toggletagex(const Arg *arg)
{
	toggletag(&((Arg) { .ui = 1 << arg->ui }));
}

void
tagall(const Arg *arg)
{
	tag(&((Arg){.ui = ~0}));
}

/* signal definitions */
/* signum must be greater than 0 */
/* trigger signals using `xsetroot -name "fsignal:<signame> [<type> <value>]"` */
static Signal signals[] = {
	/* signum           function */
	{ "focusstack",     focusstack },
	{ "setmfact",       setmfact },
	{ "togglebar",      togglebar },
	{ "incnmaster",     incnmaster },
	{ "togglefloating", togglefloating },
	{ "focusmon",       focusmon },
	{ "tagmon",         tagmon },
	{ "zoom",           zoom },
	{ "view",           view },
	{ "viewall",        viewall },
	{ "viewex",         viewex },
	{ "toggleview",     view },
	{ "toggleviewex",   toggleviewex },
	{ "tag",            tag },
	{ "tagall",         tagall },
	{ "tagex",          tagex },
	{ "toggletag",      tag },
	{ "toggletagex",    toggletagex },
	{ "killclient",     killclient },
	{ "quit",           quit },
	{ "setlayout",      setlayout },
	{ "setlayoutex",    setlayoutex },
};
