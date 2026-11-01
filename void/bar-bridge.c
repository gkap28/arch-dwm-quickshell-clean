/* Narrow X11 bridge for the isolated Quickshell bar; no shell evaluation. */
#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static int integer(const char *s, long *out) {
    char *end; *out = strtol(s, &end, 10);
    return *s && !*end && *out >= -32768 && *out <= 32767;
}
static void state(Display *d, Window root) {
    Atom type; int format; unsigned long n, remaining; unsigned char *data = NULL;
    printf("{\"monitors\":[");
    if (XGetWindowProperty(d, root, XInternAtom(d, "_DWM_MONITOR_DESKTOPS", False),
            0, 1024, False, XA_INTEGER, &type, &format, &n, &remaining, &data) == Success && format == 32) {
        long *v = (long *)data;
        for (unsigned long i = 0; i + 4 < n; i += 5)
            printf("%s{\"x\":%ld,\"y\":%ld,\"desktop\":%ld}", i ? "," : "", v[i], v[i+1], v[i+4]);
    }
    if (data) XFree(data);
    printf("],\"status\":\"");
    char *name = NULL;
    if (XFetchName(d, root, &name) && name) {
        for (unsigned char *p = (unsigned char *)name; *p; ++p) {
            if (*p == '"' || *p == '\\') putchar('\\');
            if (*p >= 32) putchar(*p);
        }
        XFree(name);
    }
    puts("\"}"); fflush(stdout);
}
int main(int argc, char **argv) {
    Display *d = XOpenDisplay(NULL); if (!d) return 1;
    Window root = DefaultRootWindow(d);
    if (argc == 5 && !strcmp(argv[1], "view")) {
        long tag, x, y;
        if (!integer(argv[2], &tag) || tag < 0 || tag > 8 || !integer(argv[3], &x) || !integer(argv[4], &y)) return 2;
        XEvent event = {0}; event.xclient.type = ClientMessage; event.xclient.window = root;
        event.xclient.message_type = XInternAtom(d, "_DWM_VOID_VIEW", False); event.xclient.format = 32;
        event.xclient.data.l[0] = tag; event.xclient.data.l[1] = x; event.xclient.data.l[2] = y;
        XSendEvent(d, root, False, SubstructureRedirectMask | SubstructureNotifyMask, &event); XFlush(d);
    } else if (argc == 4 && !strcmp(argv[1], "focus")) {
        long x, y;
        if (!integer(argv[2], &x) || !integer(argv[3], &y)) return 2;
        XEvent event = {0}; event.xclient.type = ClientMessage; event.xclient.window = root;
        event.xclient.message_type = XInternAtom(d, "_DWM_VOID_FOCUS", False); event.xclient.format = 32;
        event.xclient.data.l[0] = x; event.xclient.data.l[1] = y;
        XSendEvent(d, root, False, SubstructureRedirectMask | SubstructureNotifyMask, &event); XSync(d, False);
    } else if (argc == 2 && !strcmp(argv[1], "reload")) {
        XEvent event = {0}; event.xclient.type = ClientMessage; event.xclient.window = root;
        event.xclient.message_type = XInternAtom(d, "_DWM_VOID_RELOAD", False); event.xclient.format = 32;
        XSendEvent(d, root, False, SubstructureRedirectMask | SubstructureNotifyMask, &event); XSync(d, False);
    } else if (argc == 6 && !strcmp(argv[1], "outside")) {
        long x, y, width, height;
        if (!integer(argv[2], &x) || !integer(argv[3], &y) ||
            !integer(argv[4], &width) || !integer(argv[5], &height) || width <= 0 || height <= 0) return 2;
        Atom click = XInternAtom(d, "_DWM_VOID_DESKTOP_CLICK", False);
        XSelectInput(d, root, PropertyChangeMask);
        XSync(d, False);
        /* Two independent signals: dwm's root-click property, and a pointer poll
         * that still sees desktop presses while another client grabs the mouse. */
        int was_pressed = 1;
        for (;;) {
            int outside = 0;
            while (XPending(d)) {
                XEvent event; XNextEvent(d, &event);
                if (event.type != PropertyNotify || event.xproperty.atom != click) continue;
                Atom type; int format; unsigned long n, remaining; unsigned char *data = NULL;
                if (XGetWindowProperty(d, root, click, 0, 2, False, XA_INTEGER,
                        &type, &format, &n, &remaining, &data) == Success && format == 32 && n == 2 && data) {
                    long *position = (long *)data;
                    if (position[0] < x || position[1] < y || position[0] >= x + width || position[1] >= y + height) outside = 1;
                }
                if (data) XFree(data);
            }
            Window r, child; int rx, ry, wx, wy; unsigned int mask;
            if (XQueryPointer(d, root, &r, &child, &rx, &ry, &wx, &wy, &mask)) {
                int pressed = (mask & (Button1Mask | Button2Mask | Button3Mask)) != 0;
                if (pressed && !was_pressed && child == None &&
                    (rx < x || ry < y || rx >= x + width || ry >= y + height)) outside = 1;
                was_pressed = pressed;
            }
            if (outside) { puts("outside"); fflush(stdout); break; }
            usleep(10000);
        }
    } else if (argc == 2 && !strcmp(argv[1], "watch")) {
        XSelectInput(d, root, PropertyChangeMask); state(d, root);
        for (;;) {
            XEvent event; XNextEvent(d, &event);
            Atom a = event.xproperty.atom;
            if (a == XA_WM_NAME || a == XInternAtom(d, "_DWM_MONITOR_DESKTOPS", False)) state(d, root);
        }
    } else { XCloseDisplay(d); return 2; }
    XCloseDisplay(d); return 0;
}