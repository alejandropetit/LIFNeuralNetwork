#!/bin/bash
export SNN_ROUTE_FILE="${SNN_ROUTE_FILE:-/home/nelson/Documentos/Ubuntu_master/routes/route.json}"
if [ ! -f "$SNN_ROUTE_FILE" ]; then
    echo "No existe la ruta: $SNN_ROUTE_FILE" >&2
    exit 1
fi
cd /home/nelson
source /home/nelson/Puerto_serie.sh &
source /home/nelson/sail_init.sh &
source Anaconda.sh
python Documentos/Ubuntu_master/SNN_Codes/Spiking_codes/Experiments.py
exit

