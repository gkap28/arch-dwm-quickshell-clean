#!/bin/sh
# Stable German weekday and requested month spelling without locale dependency.
clock_text() {
    case "$1" in 0) day=So;; 1) day=Mo;; 2) day=Di;; 3) day=Mi;; 4) day=Do;; 5) day=Fr;; 6) day=Sa;; esac
    case "$3" in 01) month=Jan;; 02) month=Feb;; 03) month=Mär;; 04) month=Apr;; 05) month=Mai;; 06) month=Jun;; 07) month=Jul;; 08) month=Aug;; 09) month=Sep;; 10) month=Okt;; 11) month=Nov;; 12) month=Dez;; esac
    printf '%s %s %s - %s\n' "$day" "$2" "$month" "$4"
}