#!/bin/bash

cd test_elfs && python3 convert.py && cd .. && snforge test
