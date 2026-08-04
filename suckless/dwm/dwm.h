#ifndef DWM_H
#define DWM_H

#include <X11/Xlib.h>
#include <X11/keysym.h>
#include <X11/Xproto.h>
#include <X11/Xutil.h>
#include <stdlib.h>

// Ajoutez d'autres includes ou définitions nécessaires
typedef struct {
  int i;
  unsigned int ui;
  const void *v;
} Arg;

void quit(const Arg *arg);
void quit_properly(const Arg *arg);

// Ajoutez d'autres déclarations de fonction ici si nécessaire

#endif // DWM_H
