#!/usr/bin/env bash
# CADMUS-CR-12 - environment check for V1 (Linux build host, Valgrind).
#
#   ~/lab-tools/verify-v1.sh
#
# OK/MISSING is decided only by whether the command exists; the version next
# to it is informational.
ok=1
check() {  # name command [version-args...]
  local name="$1" cmd="$2"; shift 2
  printf '%-18s' "$name"
  if command -v "$cmd" >/dev/null 2>&1; then
    printf 'OK    %s\n' "$("$cmd" "$@" 2>&1 | grep -m1 -v '^\s*$' | cut -c1-70)"
  else
    printf 'MISSING\n'; ok=0
  fi
}
url() {  # name url
  printf '%-18s' "$1"
  if out=$(curl -s -m 10 "$2"); then printf 'OK    %s\n' "$(echo "$out" | cut -c1-60)"; else printf 'DOWN  %s\n' "$2"; ok=0; fi
}

echo
echo "CADMUS-CR-12 - environment check (V1)"
echo
check "g++"            g++            --version
check "make"           make           --version
check "cmake"          cmake          --version
check "valgrind"       valgrind       --version
check "cppcheck"       cppcheck       --version
check "clang"          clang          --version
check "sonar-scanner"  sonar-scanner  --version
check "snyk"           snyk           --version
check "docker"         docker         --version
check "curl"           curl           --version

printf '%-18s' "valgrind image"
if docker image inspect cadmus-valgrind:local >/dev/null 2>&1; then echo "OK    cadmus-valgrind:local"; else echo "MISSING"; ok=0; fi

printf '%-18s' "application"
if [ -f /home/user/cadmus-vulnshop-cpp-cr/Makefile ]; then echo "OK    /home/user/cadmus-vulnshop-cpp-cr"; else echo "MISSING  git clone https://github.com/aradovanJava/cadmus-vulnshop-cpp-cr.git /home/user/cadmus-vulnshop-cpp-cr"; ok=0; fi

printf '%-18s' "attachments dir"
if [ -w /var/lib/vulnshop/attachments ]; then echo "OK    /var/lib/vulnshop/attachments"; else echo "MISSING or not writable"; ok=0; fi

echo
url "sonarqube (SQ1)" "http://sq1:9000/api/system/status"
echo
if [ "$ok" = 1 ]; then echo "V1 ready."; else echo "Something is missing or down - raise it now."; fi
echo
