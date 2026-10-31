# Private build only: monitor-targeted workspace messages and native fallback.
# Only native (override_redirect) dwm bars are ever destroyed; Quickshell's own
# windows are never destroyed, and a native bar adopts an unowned Quickshell
# panel on its monitor again (e.g. after a DisplayPort monitor wakes up).
/^isaltbar\(Window win, XWindowAttributes \*wa\)$/ { section = "isalt" }
section == "isalt" && /Atom wtype;/ { print; print "\tif (wa && wa->width <= wa->height) return 0; /* Qt helper windows are no bars. */"; next }
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
    print "\t{"
    print "\t\tWindow d1, d2, *wins = NULL, found = 0; unsigned int n = 0;"
    print "\t\tif (XQueryTree(dpy, root, &d1, &d2, &wins, &n)) {"
    print "\t\t\tfor (unsigned int i = 0; i < n && !found; i++) {"
    print "\t\t\t\tXWindowAttributes qa; Monitor *o;"
    print "\t\t\t\tif (wins[i] == m->barwin || !XGetWindowAttributes(dpy, wins[i], &qa) || qa.override_redirect || qa.map_state != IsViewable || qa.width <= qa.height) continue;"
    print "\t\t\t\tif (!wmclasscontains(wins[i], altbarclass, \"\") || recttomon(qa.x, qa.y, qa.width, qa.height) != m || INTERSECT(qa.x, qa.y, qa.width, qa.height, m) <= 0) continue;"
    print "\t\t\t\tfor (o = mons; o && o->barwin != wins[i]; o = o->next);"
    print "\t\t\t\tif (!o) found = wins[i];"
    print "\t\t\t}"
    print "\t\t\tif (wins) XFree(wins);"
    print "\t\t}"
    print "\t\tXWindowAttributes qa;"
    print "\t\tif (found && XGetWindowAttributes(dpy, found, &qa)) {"
    print "\t\t\tupdatealtbar(m, found, &qa);"
    print "\t\t\tXSelectInput(dpy, found, EnterWindowMask|FocusChangeMask|PropertyChangeMask|StructureNotifyMask|ExposureMask);"
    print "\t\t\tXRaiseWindow(dpy, found); updateclientlist(); arrange(m); return;"
    print "\t\t}"
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
    print "\tif (m->barwin && m->barwin != win) { Window old = m->barwin; XWindowAttributes oa; m->barwin = win; if (XGetWindowAttributes(dpy, old, &oa) && oa.override_redirect) XDestroyWindow(dpy, old); }"
}
section == "replace" && /changed = m->barwin != win/ {
    print "\tif (m->barwin && m->barwin != win) { Window old = m->barwin; XWindowAttributes oa; m->barwin = win; if (XGetWindowAttributes(dpy, old, &oa) && oa.override_redirect) XDestroyWindow(dpy, old); }"
}
section == "unmanage" && /m->barwin = 0;/ { print; print "\tm->bh = bh;"; next }
section == "unmanage" && /m->bh = 0;/ { next }
section == "unmanage" && /updatebarpos\(m\);/ { print; print "\tupdatebars(); drawbars();"; next }
{ print }
/^\}$/ { section = "" }