#!/bin/bash
# Shared seed for manual Python and FPGA trials; allow an explicit override.
export SNN_SEED="${SNN_SEED:-1000}"
# lockstep: freeze physics during inference; continuous: hold the last action.
export SNN_SIM_MODE="${SNN_SIM_MODE:-lockstep}"
