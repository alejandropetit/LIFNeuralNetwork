#!/bin/bash
set -e
source "$(dirname "${BASH_SOURCE[0]}")/experiment_config.sh"
exec bash /home/nelson/Velero.sh
