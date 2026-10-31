#include "logo.h"
/* Dedicated Nord bar colors; existing window themes remain untouched. */
static Clr *void_bar_scheme[2];
static void void_bar_prepare(int width) {
    if (!void_bar_scheme[0]) {
        const char *normal[] = {"#D8DEE9", "#2E3440", "#3B4252"};
        const char *selected[] = {"#ECEFF4", "#434C5E", "#88C0D0"};
        void_bar_scheme[0] = drw_scm_create(drw, normal, 3);
        void_bar_scheme[1] = drw_scm_create(drw, selected, 3);
    }
    drw_setscheme(drw, void_bar_scheme[SchemeNorm]);
    drw_rect(drw, 0, 0, width, bh, 1, 1);
}
static void void_draw_power(int width) {
    int size = MAX(8, bh - 10), x = width - bh + (bh - size) / 2;
    int y = (bh - size) / 2;
    drw_setscheme(drw, void_bar_scheme[SchemeNorm]);
    drw_rect(drw, width - bh, 0, bh, bh, 1, 1);
    XSetForeground(dpy, drw->gc, void_bar_scheme[SchemeNorm][ColFg].pixel);
    XSetLineAttributes(dpy, drw->gc, 2, LineSolid, CapRound, JoinRound);
    XDrawArc(dpy, drw->drawable, drw->gc, x, y, size - 1, size - 1, 135 * 64, 270 * 64);
    XDrawLine(dpy, drw->drawable, drw->gc, x + size / 2, y - 1, x + size / 2, y + size / 2);
    XSetLineAttributes(dpy, drw->gc, 0, LineSolid, CapButt, JoinMiter);
}
static void void_draw_logo(void) {
    drw_setscheme(drw, void_bar_scheme[SchemeNorm]);
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
