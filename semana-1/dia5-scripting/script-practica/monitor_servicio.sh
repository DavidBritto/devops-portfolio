#!/bin/bash
SERVICIO="apache2"

if ! systemctl is-active --quiet $SERVICIO; then
    systemctl start $SERVICIO
    echo "El servicio $SERVICIO fue reiniciado." | mail -s "Reinicio de $SERVICIO" admin@ejemplo.com
fi