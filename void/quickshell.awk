# Private build only: monitor-targeted workspace messages and native fallback.
/^drawbar\(Monitor \*m\)$/ { section = "bar" }
/^clientmessage\(XEvent \*e\)$/ { section = "message" }
/^managealtbar\(Window win, XWindowAttributes \*wa\)$/ { section = "manage" }
/^unmanagealtbar\(Window w\)$/ { section = "unmanage" }
/^updatealtbar\(Monitor \*m, Window win, XWindowAttributes \*wa\)$/ { section = "replace" }
section == "bar" && /int x, w, tw = 0;/ {
    print "\tXWindowAttributes attributes;"
    print "\tif (XGetWindowAttributes(dpy, m->barwin, &attributes) && !attributes.override_redirect) return;"
    print "\tchar *name = NULL;"
    print "\tif (XFetchName(dpy, m->barwin, &name) && name) {"
    print "\t\tint external = !strcmp(name, \"quickshell\"); XFree(name); if (external) return;"
    print "\t}"
    print "\tXClassHint hint = {0};"
    print "\tif (XGetClassHint(dpy, m->barwin, &hint)) {"
    print "\t\tint external = hint.res_class && strstr(hint.res_class, \"quickshell\");"
    print "\t\tif (hint.res_name) XFree(hint.res_name);"
    print "\t\tif (hint.res_class) XFree(hint.res_class);"
    print "\t\tif (external) return;"
    print "\t}"
}
section == "message" && /if \(cme->message_type == netatom\[NetCurrentDesktop\]\)/ {
    print "\tif (cme->message_type == XInternAtom(dpy, \"_DWM_VOID_VIEW\", False) && cme->format == 32) {"
    print "\t\tlong tag = cme->data.l[0], x = cme->data.l[1], y = cme->data.l[2];"
    print "\t\tif (tag < 0 || tag >= 9) return;"
    print "\t\tfor (Monitor *m = mons; m; m = m->next) {"
    print "\t\t\tif (m->mx != x || m->my != y) continue;"
    print "\t\t\tif (selmon != m) { unfocus(selmon->sel, 0); selmon = m; focus(NULL); }"
    print "\t\t\tArg workspace = {.ui = 1U << tag}; view(&workspace); return;"
    print "\t\t}"
    print "\t\treturn;"
    print "\t}"
}
section == "manage" && /changed = updatealtbar/ {
    print "\tif (m->barwin && m->barwin != win) { Window old = m->barwin; m->barwin = win; XDestroyWindow(dpy, old); }"
}
section == "replace" && /changed = m->barwin != win/ {
    print "\tif (m->barwin && m->barwin != win) { Window old = m->barwin; m->barwin = win; XDestroyWindow(dpy, old); }"
}
section == "unmanage" && /m->barwin = 0;/ { print; print "\tm->bh = bh;"; next }
section == "unmanage" && /m->bh = 0;/ { next }
section == "unmanage" && /updatebarpos\(m\);/ { print; print "\tupdatebars(); drawbars();"; next }
{ print }
/^\}$/ { section = "" }
