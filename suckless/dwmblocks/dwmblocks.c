#include<stdlib.h>
#include<stdio.h>
#include<string.h>
#include<unistd.h>
#include<signal.h>
#include<sys/wait.h>
#include<sys/select.h>
#include<time.h>
#ifndef NO_X
#include<X11/Xlib.h>
#endif
#ifdef __OpenBSD__
#define SIGPLUS			SIGUSR1+1
#define SIGMINUS		SIGUSR1-1
#else
#define SIGPLUS			SIGRTMIN
#define SIGMINUS		SIGRTMIN
#endif
#define LENGTH(X)               (sizeof(X) / sizeof (X[0]))
#define CMDLENGTH		50
#define MIN( a, b ) ( ( a < b) ? a : b )
#define STATUSLENGTH (LENGTH(blocks) * CMDLENGTH + 1)

typedef struct {
	char* icon;
	char* command;
	unsigned int interval;
	unsigned int signal;
} Block;
#ifndef __OpenBSD__
void dummysighandler(int num);
#endif
void getcmds(int time);
void getsigcmds(unsigned int signal);
void runpending();
void setupsignals();
void sighandler(int signum, siginfo_t *si, void *ucontext);
int getstatus(char *str, char *last);
void statusloop();
void termhandler(int signum);
void chldhandler(int signum);
void pstdout();
#ifndef NO_X
void setroot();
static void (*writestatus) () = setroot;
static int setupX();
static Display *dpy;
static int screen;
static Window root;
#else
static void (*writestatus) () = pstdout;
#endif


#include "blocks.h"

static char statusbar[LENGTH(blocks)][CMDLENGTH] = {0};
static char statusstr[2][STATUSLENGTH];
static int statusContinue = 1;
static int returnStatus = 0;
/* Block signals received but not handled yet, one bit per signal number. The
 * block signals stay blocked outside the pselect in statusloop, so the handler
 * only ever runs there and this needs no further locking. */
static volatile sig_atomic_t pendingsigs = 0;
static sigset_t origmask;

//opens process *cmd and stores output in *output
void getcmd(const Block *block, char *output)
{
	if (block->signal)
		*output++ = block->signal;
	strcpy(output, block->icon);
	FILE *cmdf = popen(block->command, "r");
	if (!cmdf)
		return;
	int i = strlen(block->icon);
	fgets(output+i, CMDLENGTH-i-delimLen, cmdf);
	i = strlen(output);
	if (i == 0) {
		//return if block and command output are both empty
		pclose(cmdf);
		return;
	}
	//only chop off newline if one is present at the end
	i = output[i-1] == '\n' ? i-1 : i;
	if (delim[0] != '\0') {
		strncpy(output+i, delim, delimLen); 
	}
	else
		output[i++] = '\0';
	pclose(cmdf);
}

void getcmds(int time)
{
	const Block* current;
	for (unsigned int i = 0; i < LENGTH(blocks); i++) {
		current = blocks + i;
		if ((current->interval != 0 && time % current->interval == 0) || time == -1)
			getcmd(current,statusbar[i]);
	}
}

void getsigcmds(unsigned int signal)
{
	const Block *current;
	for (unsigned int i = 0; i < LENGTH(blocks); i++) {
		current = blocks + i;
		if (current->signal == signal)
			getcmd(current,statusbar[i]);
	}
}

void setupsignals()
{
	/* SA_RESTART: without it, a signal landing while the main loop reads another
	 * block's command makes that fgets fail, and the block goes blank until its
	 * next update. The charger udev rule sends several signals in a row. */
	struct sigaction sa = { .sa_sigaction = sighandler, .sa_flags = SA_SIGINFO | SA_RESTART };
#ifndef __OpenBSD__
	    /* initialize all real time signals with dummy handler */
    for (int i = SIGRTMIN; i <= SIGRTMAX; i++) {
        signal(i, dummysighandler);
		sigaddset(&sa.sa_mask, i);
	}
#endif

	sigset_t blocksigs;
	sigemptyset(&blocksigs);
	for (unsigned int i = 0; i < LENGTH(blocks); i++) {
		if (blocks[i].signal > 0) {
			sigaction(SIGMINUS+blocks[i].signal, &sa, NULL);
			sigaddset(&blocksigs, SIGMINUS+blocks[i].signal);
		}
	}
	sigprocmask(SIG_BLOCK, &blocksigs, &origmask);
}

void runpending()
{
	unsigned int sigs = pendingsigs;
	pendingsigs = 0;
	for (unsigned int signal = 0; sigs; signal++, sigs >>= 1)
		if (sigs & 1)
			getsigcmds(signal);
	writestatus();
}

int getstatus(char *str, char *last)
{
	strcpy(last, str);
	str[0] = '\0';
	for (unsigned int i = 0; i < LENGTH(blocks); i++)
		strcat(str, statusbar[i]);
	str[strlen(str)-strlen(delim)] = '\0';
	return strcmp(str, last);//0 if they are the same
}

#ifndef NO_X
void setroot()
{
	if (!getstatus(statusstr[0], statusstr[1]))//Only set root if text has changed.
		return;
	XStoreName(dpy, root, statusstr[0]);
	XFlush(dpy);
}

int setupX()
{
	dpy = XOpenDisplay(NULL);
	if (!dpy) {
		fprintf(stderr, "dwmblocks: Failed to open display\n");
		return 0;
	}
	screen = DefaultScreen(dpy);
	root = RootWindow(dpy, screen);
	return 1;
}
#endif

void pstdout()
{
	if (!getstatus(statusstr[0], statusstr[1]))//Only write out if text has changed.
		return;
	printf("%s\n",statusstr[0]);
	fflush(stdout);
}


void statusloop()
{
	setupsignals();
	int i = 0;
	getcmds(-1);
	while (1) {
		getcmds(i++);
		writestatus();
		if (!statusContinue)
			break;
		/* Wait out the second, refreshing signalled blocks as they come in.
		 * The handler used to refresh them itself, at any point of the loop:
		 * while another block was half written, which blanked it in the bar
		 * whenever signals came in bursts (a held volume key, the charger).
		 * pselect unblocks the signals only while waiting, and a burst ends
		 * up as one refresh. */
		struct timespec now, end, left;
		clock_gettime(CLOCK_MONOTONIC, &end);
		end.tv_sec++;
		while (statusContinue) {
			clock_gettime(CLOCK_MONOTONIC, &now);
			left.tv_sec = end.tv_sec - now.tv_sec;
			left.tv_nsec = end.tv_nsec - now.tv_nsec;
			if (left.tv_nsec < 0) {
				left.tv_sec--;
				left.tv_nsec += 1000000000L;
			}
			if (left.tv_sec < 0 || pselect(0, NULL, NULL, NULL, &left, &origmask) == 0)
				break;
			runpending();
		}
	}
}

#ifndef __OpenBSD__
/* this signal handler should do nothing */
void dummysighandler(int signum)
{
    return;
}
#endif

void sighandler(int signum, siginfo_t *si, void *ucontext)
{
	if (si->si_value.sival_int) {
		pid_t parent = getpid();
		if (fork() == 0) {
#ifndef NO_X
			if (dpy)
				close(ConnectionNumber(dpy));
#endif
			int i;
			for (i = 0; i < LENGTH(blocks) && blocks[i].signal != signum-SIGRTMIN; i++);

			char shcmd[1024];
			sprintf(shcmd, "%s; kill -%d %d", blocks[i].command, SIGRTMIN+blocks[i].signal, parent);
			char *cmd[] = { "/bin/sh", "-c", shcmd, NULL };
			char button[2] = { '0' + si->si_value.sival_int, '\0' };
			setenv("BUTTON", button, 1);
			setsid();
			/* The block signals are blocked outside pselect; the command
			 * should not inherit that. */
			sigprocmask(SIG_SETMASK, &origmask, NULL);
			execvp(cmd[0], cmd);
			perror(cmd[0]);
			exit(EXIT_SUCCESS);
		}
	} else {
		pendingsigs |= 1 << (signum-SIGPLUS);
	}
}

void termhandler(int signum)
{
	statusContinue = 0;
}

void chldhandler(int signum)
{
	while (0 < waitpid(-1, NULL, WNOHANG));
}

int main(int argc, char** argv)
{
	for (int i = 0; i < argc; i++) {//Handle command line arguments
		if (!strcmp("-d",argv[i]))
			strncpy(delim, argv[++i], delimLen);
		else if (!strcmp("-p",argv[i]))
			writestatus = pstdout;
	}
#ifndef NO_X
	if (!setupX())
		return 1;
#endif
	delimLen = MIN(delimLen, strlen(delim));
	delim[delimLen++] = '\0';
	signal(SIGTERM, termhandler);
	signal(SIGINT, termhandler);
	signal(SIGCHLD, chldhandler);
	statusloop();
#ifndef NO_X
	XCloseDisplay(dpy);
#endif
	return 0;
}
