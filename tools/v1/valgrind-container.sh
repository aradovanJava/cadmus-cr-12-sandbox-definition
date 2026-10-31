#!/usr/bin/env bash
# CADMUS-CR-12 - the Valgrind container (framework VM2) on V1.
#
#   ~/lab-tools/valgrind-container.sh
#
# Runs the repository's own tools/scan-valgrind.sh inside the container image
# cadmus-valgrind:local (Ubuntu + g++ + make + Valgrind, built during
# provisioning), as YOUR user, with the repository mounted at /work. It builds
# the application, starts it under Memcheck, replays the request corpus,
# stops it so the leak summary is written, and leaves lab/valgrind-report.txt.
#
# The repository's "docker compose run --rm valgrind" does the same, but runs
# as root and installs the compiler on every run; files it writes into build/
# and lab/ then belong to root. This wrapper avoids both.
set -euo pipefail
APP="${APP:-/home/user/cadmus-vulnshop-cpp-cr}"
exec docker run --rm -u "$(id -u):$(id -g)" -v "$APP:/work" -w /work \
     cadmus-valgrind:local ./tools/scan-valgrind.sh
