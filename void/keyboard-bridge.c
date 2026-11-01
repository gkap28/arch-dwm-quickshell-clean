#include <stdio.h>
#include <string.h>
#include <X11/Xlib.h>
#include <X11/XKBlib.h>

/* Only the current user's X11 session; no files or system settings. */
int main(int argc, char **argv) {
    Display *display = XOpenDisplay(NULL);
    XkbStateRec state;
    const char *labels[] = {"US", "DE", "GR"};
    if (!display) return 1;
    if (argc != 2 || (strcmp(argv[1], "status") && strcmp(argv[1], "next"))) {
        XCloseDisplay(display); return 2;
    }
    if (XkbGetState(display, XkbUseCoreKbd, &state) != Success) {
        XCloseDisplay(display); return 1;
    }
    if (!strcmp(argv[1], "next")) {
        if (!XkbLockGroup(display, XkbUseCoreKbd, (state.group + 1) % 3)) {
            XCloseDisplay(display); return 1;
        }
        XSync(display, False);
        if (XkbGetState(display, XkbUseCoreKbd, &state) != Success) {
            XCloseDisplay(display); return 1;
        }
    }
    if (state.group < 3) puts(labels[state.group]);
    else puts("—");
    XCloseDisplay(display);
    return 0;
}