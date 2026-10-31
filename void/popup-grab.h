/* Wait for the bar's initiating click to finish before mapping/grabbing. */
static int popup_grab(Display *d, Window win, Window root) {
    Window a, b; int x, y, rx, ry; unsigned int mask;
    for (int attempt = 0; attempt < 500; ++attempt) {
        if (!XQueryPointer(d, root, &a, &b, &rx, &ry, &x, &y, &mask)) return 0;
        if (!(mask & (Button1Mask | Button2Mask | Button3Mask))) break;
        if (attempt == 499) return 0;
        usleep(10000);
    }
    XMapRaised(d, win); XSync(d, False);
    for (int attempt = 0; attempt < 100; ++attempt) {
        int result = XGrabPointer(d, win, False, ButtonPressMask | ButtonReleaseMask | PointerMotionMask,
            GrabModeAsync, GrabModeAsync, None, None, CurrentTime);
        if (result == GrabSuccess) {
            if (XGrabKeyboard(d, win, False, GrabModeAsync, GrabModeAsync, CurrentTime) == GrabSuccess) return 1;
            XUngrabPointer(d, CurrentTime);
        }
        usleep(10000);
    }
    fprintf(stderr, "Popup: mouse/keyboard is busy; try again.\n");
    return 0;
}