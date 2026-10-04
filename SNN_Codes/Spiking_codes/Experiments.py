#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Feb  7 15:54:21 2022

@author: nelson
"""

import os
import random

seed = int(os.environ['SNN_SEED'])
threads = int(os.environ.get('SNN_TORCH_THREADS', '1'))
if not 0 <= seed < 2**32:
    raise ValueError('SNN_SEED must be between 0 and 2**32 - 1')
if threads < 1:
    raise ValueError('SNN_TORCH_THREADS must be positive')

os.environ['OMP_NUM_THREADS'] = str(threads)
os.environ['MKL_NUM_THREADS'] = str(threads)

import numpy as np
import torch

random.seed(seed)
np.random.seed(seed)
torch.manual_seed(seed)
torch.set_num_threads(threads)
print('Python seed: {}; Torch threads: {}'.format(seed, threads), flush=True)

import SNN_train_controller as ctrl

fail = False
m = ctrl.SNN_complete_train_test()
#fail = m.train_SNN()
#m = ctrl.SNN_complete_train_test()
if not fail:
    m.test_SNN()
