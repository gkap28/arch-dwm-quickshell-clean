#include "logo.h"
static void void_draw_logo(void) {
    drw_setscheme(drw, scheme[SchemeNorm]);
    drw_rect(drw, 0, 0, bh, bh, 1, 1);
    GC gc = XCreateGC(dpy, drw->drawable, 0, NULL);
    int size = bh > 4 ? bh - 4 : bh;
    for (int y = 0; y < size; ++y) for (int x = 0; x < size; ++x) {
        unsigned long pixel = void_palette[void_logo[(y * 20 / size) * 20 + x * 20 / size] - 'A'];
        if ((pixel >> 24) < 128) continue;
        XSetForeground(dpy, gc, pixel & 0xffffff);
        XDrawPoint(dpy, drw->drawable, gc, x + 2, y + 2);
    }
    XFreeGC(dpy, gc);
}