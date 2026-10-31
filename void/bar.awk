# Applied only to the temporary Void build copy.
/^drawbar\(Monitor \*m\)$/ { section = "bar" }
/^buttonpress\(XEvent \*e\)$/ { section = "click" }
/^updatestatus\(void\)$/ { section = "status" }
/^void$/ { heldvoid = 1; next }
heldvoid {
    if ($0 == "drawbar(Monitor *m)") print "#include \"logo-draw.h\""
    print "void"
    heldvoid = 0
}
section == "click" && /if \(ev->window == selmon->barwin\) \{/ {
    print
    print "\t\tif (ev->button == Button1 && ev->x < bh) {"
    print "\t\t\tconst char *cmd[] = {\"sh\", \"-c\", \"exec \\\"$HOME/.local/share/dwm-void/power-menu\\\" --control\", NULL};"
    print "\t\t\tArg center = {.v = cmd}; spawn(&center); return;"
    print "\t\t}"
    print "\t\tif (ev->button == Button1 && ev->x >= selmon->ww - bh) {"
    print "\t\t\tconst char *cmd[] = {\"sh\", \"-c\", \"exec \\\"$HOME/.local/share/dwm-void/power-menu\\\"\", NULL};"
    print "\t\t\tArg power = {.v = cmd}; spawn(&power); return;"
    print "\t\t}"
    next
}
section == "click" && /i = x = 0;/ { print "\t\ti = 0; x = bh;"; next }
section == "bar" && /^\tx = 0;/ { print "\tx = bh;"; next }
section == "bar" && /\/\* draw status first/ { print "\tvoid_bar_prepare(m->ww);" }
section == "bar" { gsub(/scheme\[SchemeNorm\]/, "void_bar_scheme[SchemeNorm]"); gsub(/scheme\[SchemeSel\]/, "void_bar_scheme[SchemeSel]"); gsub(/scheme\[m/, "void_bar_scheme[m") }
section == "click" && /click = ClkTagBar;/ {
    print "\t\t\t/* Native Void workspace clicks do not depend on Quickshell mouse bindings. */"
    print "\t\t\tif (ev->button == Button1 && CLEANMASK(ev->state) == 0) {"
    print "\t\t\t\tArg workspace = {.ui = 1U << i}; view(&workspace); return;"
    print "\t\t\t}"
}
section == "bar" && /if \(m == selmon\) \{ \/\* status is only drawn/ { skipstatus = 1; next }
skipstatus { if ($0 ~ /^\t\}/) skipstatus = 0; next }
(section == "bar" || section == "click") && /\/\* Do not (draw|reserve space for) vacant tags \*\// { skipvacant = 2; next }
skipvacant { skipvacant--; next }
section == "bar" && /drw_map\(drw, m->barwin/ {
    print "\t/* Center the status on every monitor, after the title is drawn. */"
    print "\tdrw_setscheme(drw, void_bar_scheme[SchemeNorm]);"
    print "\ttw = MIN(TEXTW(stext) - lrpad + 2, MAX(0, m->ww - x - bh));"
    print "\tif (tw > 0) {"
    print "\t\tint sx = MAX(x, (m->ww - tw) / 2);"
    print "\t\tdrw_text(drw, sx, 0, tw, bh, 0, stext, 0);"
    print "\t}"
    print "\tvoid_draw_power(m->ww);"
    print "\tvoid_draw_logo();"
}
section == "click" && /else if \(ev->x > selmon->ww - statusw\)/ {
    print "\t\telse if (ev->x >= MAX(x, (selmon->ww - statusw) / 2) && ev->x < MAX(x, (selmon->ww - statusw) / 2) + statusw) {"
    next
}
section == "click" && /x = selmon->ww - statusw;/ { print "\t\t\tx = MAX(x, (selmon->ww - statusw) / 2);"; next }
section == "status" && /drawbar\(selmon\);/ { print "\tdrawbars();"; next }
{ print }
/^\}$/ { section = "" }
