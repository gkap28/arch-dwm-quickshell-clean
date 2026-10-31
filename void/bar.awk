# Applied only to the temporary Void build copy.
/^drawbar\(Monitor \*m\)$/ { section = "bar" }
/^buttonpress\(XEvent \*e\)$/ { section = "click" }
/^updatestatus\(void\)$/ { section = "status" }
section == "bar" && /if \(m == selmon\) \{ \/\* status is only drawn/ { skipstatus = 1; next }
skipstatus { if ($0 ~ /^\t\}/) skipstatus = 0; next }
(section == "bar" || section == "click") && /\/\* Do not (draw|reserve space for) vacant tags \*\// { skipvacant = 2; next }
skipvacant { skipvacant--; next }
section == "bar" && /drw_map\(drw, m->barwin/ {
    print "\t/* Center the status on every monitor, after the title is drawn. */"
    print "\tdrw_setscheme(drw, scheme[SchemeNorm]);"
    print "\ttw = MIN(TEXTW(stext) - lrpad + 2, MAX(0, m->ww - x));"
    print "\tif (tw > 0) {"
    print "\t\tint sx = MAX(x, (m->ww - tw) / 2);"
    print "\t\tdrw_text(drw, sx, 0, tw, bh, 0, stext, 0);"
    print "\t}"
}
section == "click" && /else if \(ev->x > selmon->ww - statusw\)/ {
    print "\t\telse if (ev->x >= MAX(x, (selmon->ww - statusw) / 2) && ev->x < MAX(x, (selmon->ww - statusw) / 2) + statusw) {"
    next
}
section == "click" && /x = selmon->ww - statusw;/ { print "\t\t\tx = MAX(x, (selmon->ww - statusw) / 2);"; next }
section == "status" && /drawbar\(selmon\);/ { print "\tdrawbars();"; next }
{ print }
/^\}$/ { section = "" }
