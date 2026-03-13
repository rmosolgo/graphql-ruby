#!/bin/bash
set -euo pipefail
./test_fast.sh 2>&1 | tail -50
