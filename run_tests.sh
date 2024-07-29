#!/bin/bash

cd compliance_files && python3 convert.py && cd .. && snforge test
