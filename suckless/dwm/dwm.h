#ifndef DWM_H
#define DWM_H

#include <X11/Xlib.h>
#include <X11/keysym.h>
#include <X11/Xproto.h>
#include <X11/Xutil.h>
#include <stdlib.h>

// Add any other needed includes or definitions
typedef struct {
  int i;
  unsigned int ui;
  const void *v;
} Arg;

void quit(const Arg *arg);
void quit_properly(const Arg *arg);

// Add other function declarations here if needed

#endif // DWM_H
