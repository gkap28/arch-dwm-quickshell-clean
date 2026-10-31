/* Small native X11 popup, isolated from the Quickshell/Fedora installation. */
#include <X11/Xlib.h>
#include <X11/keysym.h>
#include <X11/Xft/Xft.h>
#include <X11/extensions/Xinerama.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include "popup-grab.h"
#include "logo.h"

static const char *labels[] = {"Neustart", "Abmelden", "Sperren", "Ruhezustand", "Ausschalten"};
static const char *actions[] = {"reboot", "logout", "lock", "suspend", "shutdown"};
enum { WIDTH = 300, ROW = 42, HEADER = 46, HEIGHT = HEADER + 5 * ROW + 12 };

int main(int argc, char **argv) {
    int control = argc > 1 && strcmp(argv[1], "--control") == 0;
    const char *control_labels[] = {"Terminal", "Dateien", "Tastenbelegung", "Bildschirme", "Lautstaerke", "Netzwerk", "Hintergrund", "Power"};
    const char *control_actions[] = {"terminal", "files", "hotkeys", "displays", "volume", "network", "wallpaper", "power"};
    int height = control ? HEADER + 8 * ROW + 12 : HEIGHT;
    Display *d = XOpenDisplay(NULL);
    if (!d) return 1;
    int screen = DefaultScreen(d), px = 0, py = 0, wx, wy;
    unsigned int mask;
    Window root = RootWindow(d, screen), child, ignored;
    XQueryPointer(d, root, &ignored, &child, &px, &py, &wx, &wy, &mask);
    int edge = DisplayWidth(d, screen), left = 0;
    if (XineramaIsActive(d)) {
        int count = 0;
        XineramaScreenInfo *screens = XineramaQueryScreens(d, &count);
        if (screens) {
            for (int i = 0; i < count; ++i)
                if (px >= screens[i].x_org && px < screens[i].x_org + screens[i].width) {
                    edge = screens[i].x_org + screens[i].width;
                    left = screens[i].x_org;
                }
            XFree(screens);
        }
    }
    Visual *visual = DefaultVisual(d, screen);
    Colormap cmap = DefaultColormap(d, screen);
    XftColor bg, text, muted, accent;
    if (!XftColorAllocName(d, visual, cmap, "#2E3440", &bg)
        || !XftColorAllocName(d, visual, cmap, "#ECEFF4", &text)
        || !XftColorAllocName(d, visual, cmap, "#D8DEE9", &muted)
        || !XftColorAllocName(d, visual, cmap, "#88C0D0", &accent)) return 1;
    XSetWindowAttributes attrs = {0};
    attrs.override_redirect = True;
    attrs.background_pixel = bg.pixel;
    attrs.border_pixel = accent.pixel;
    attrs.event_mask = ExposureMask | ButtonPressMask | ButtonReleaseMask | KeyPressMask | PointerMotionMask;
    Window win = XCreateWindow(d, root, control ? left + 10 : (edge > WIDTH + 10 ? edge - WIDTH - 10 : 0),
        py + 16, WIDTH, height, 1, CopyFromParent, InputOutput, visual,
        CWOverrideRedirect | CWBackPixel | CWBorderPixel | CWEventMask, &attrs);
    XStoreName(d, win, control ? "Void Control" : "Void Power");
    XftFont *font = XftFontOpenName(d, screen, "monospace:size=12");
    if (!font) { XDestroyWindow(d, win); XCloseDisplay(d); return 1; }
    XftDraw *draw = XftDrawCreate(d, win, visual, cmap);
    GC gc = XCreateGC(d, win, 0, NULL);
    if (!popup_grab(d, win, root)) { XDestroyWindow(d, win); XCloseDisplay(d); return 1; }
    int selected = -1, confirmation = -1, done = 0, execute = -1;
    while (!done) {
        XClearWindow(d, win);
        const char *title = control ? "Kontrollzentrum" : (confirmation < 0 ? "Power" : "Bestaetigen?");
        XftDrawStringUtf8(draw, &accent, font, 16, 29, (const FcChar8 *)title, strlen(title));
        int rows = control ? 8 : (confirmation < 0 ? 5 : 3);
        for (int i = 0; i < rows; ++i) {
            const char *label = control ? control_labels[i] : (confirmation < 0 ? labels[i] :
                (i == 0 ? labels[confirmation] : (i == 1 ? "Abbrechen" : "Bestaetigen")));
            if (i == selected) {
                XSetForeground(d, gc, accent.pixel);
                XDrawRectangle(d, win, gc, 8, HEADER + i * ROW, WIDTH - 17, ROW - 2);
            }
            XftDrawStringUtf8(draw, i == selected ? &accent : &text, font,
                16, HEADER + i * ROW + 27, (const FcChar8 *)label, strlen(label));
        }
        XFlush(d);
        XEvent ev; XNextEvent(d, &ev);
        if (ev.type == MotionNotify) {
            selected = (ev.xmotion.y - HEADER) / ROW;
            if (ev.xmotion.y < HEADER || selected >= rows) selected = -1;
        } else if (ev.type == KeyPress) {
            KeySym key = XLookupKeysym(&ev.xkey, 0);
            if (key == XK_Escape) done = 1;
            else if (key == XK_Down) selected = (selected + 1) % rows;
            else if (key == XK_Up) selected = (selected + rows - 1) % rows;
            else if (key == XK_Return && selected >= 0) {
                if (control) { execute = selected; done = 1; }
                else if (confirmation < 0) {
                    if (selected == 2) { execute = 2; done = 1; }
                    else { confirmation = selected; selected = -1; }
                } else if (selected == 1) { confirmation = -1; selected = -1; }
                else if (selected == 2) { execute = confirmation; done = 1; }
            }
        } else if (ev.type == ButtonRelease) {
            int x = ev.xbutton.x, y = ev.xbutton.y;
            if (x < 0 || x >= WIDTH || y < 0 || y >= height) { done = 1; continue; }
            int row = (y - HEADER) / ROW;
            if (ev.xbutton.button != Button1 || y < HEADER || row >= rows) continue;
            if (control) { execute = row; done = 1; }
            else if (confirmation < 0) {
                if (row == 2) { execute = 2; done = 1; }
                else { confirmation = row; selected = -1; }
            } else if (row == 1) { confirmation = -1; selected = -1; }
            else if (row == 2) { execute = confirmation; done = 1; }
        }
    }
    XUngrabPointer(d, CurrentTime); XUngrabKeyboard(d, CurrentTime);
    XftDrawDestroy(draw); XftFontClose(d, font); XFreeGC(d, gc);
    XDestroyWindow(d, win); XCloseDisplay(d);
    if (execute >= 0) {
        const char *home = getenv("HOME");
        char path[4096];
        if (!home || snprintf(path, sizeof(path), "%s/.local/share/dwm-void/%s", home, control ? "control-action.sh" : "power-action.sh") >= (int)sizeof(path)) return 1;
        execlp("sh", "sh", path, control ? control_actions[execute] : actions[execute], (char *)NULL);
        perror("Power action"); return 1;
    }
    return 0;
}