# CADMUS-CR-12 · Secure Coding C/C++ — sandbox definition

Sandbox definition for the CADMUS CyberRangeᶜᶻ platform (cr.cybersecurity-training.cti.gr) used by
the CADMUS bootcamp **BTCMP-02 Secure Coding**, Cyber Range course
**CADMUS-CR-12 Secure Coding C/C++**.

It implements section 2 *Training Scenario Architecture* of the
*CADMUS Cyber Range Training Scenario Framework* for CR-12 — a Windows 11
developer workstation, a Docker host with Valgrind and a Docker host with
SonarQube — on the tested design of the CR-13 and CR-14 sandboxes. The
application under test is
[`aradovanJava/cadmus-vulnshop-cpp-cr`](https://github.com/aradovanJava/cadmus-vulnshop-cpp-cr),
the participant build of the deliberately vulnerable C++17 order service used
in the course's CR1–CR4 labs.

> **Training system.** The application contains memory-corruption defects and
> an OS command injection. It binds to `127.0.0.1` with `config/sandbox.ini`
> and runs only inside this sandbox. See `SAFETY.md` in the application.

## Topology

```
                 internet-connection (WAN)
                           |
                        router  10.10.10.1
                           |
   dev-lan 10.10.10.0/24 --+-----------------------+----------------------+
                           |                       |                      |
                 sc1  10.10.10.10         sq1  10.10.10.20         v1  10.10.10.30
                 VM1  Windows 11          VM3  SonarQube          VM2  Linux build host
                 trainee workstation      + sonar-cxx (SAST)      Docker + Valgrind
```

| Host | Framework ID | Image | Flavor | Role |
|---|---|---|---|---|
| `sc1` | VM1 · SC1 | `windows-11-x86_64` | `c4_r8_d60` | Workstation, RDP: VS Code (C/C++, Remote-SSH), GCC-win64 (MinGW-w64), CMake, make, Git, Snyk, Postman |
| `v1` | VM2 · V1 | `ubuntu-noble-x86_64` | `c4_r8_d40` | Builds and runs the application: g++, make, CMake, Valgrind (native and the Valgrind container), ASan/UBSan, cppcheck, clang-tidy, SonarScanner CLI, Snyk |
| `sq1` | VM3 · SQ1 | `ubuntu-noble-x86_64` | `c4_r8_d40` | SonarQube Community Build 26.1 (pinned) with the sonar-cxx plugin |
| `router` | — | `debian-12-x86_64` | `standard.small` | Gateway |

## Design decisions

1. **The application is built and run on V1 (Linux), not on SC1.** It is POSIX
   C++ (`sys/socket.h`, `unistd.h`, `popen`, ELF-only linker flags) and does not
   build with MinGW on Windows; its dynamic-analysis tier (Valgrind,
   AddressSanitizer, UBSan) only exists on Linux. The framework's VM2 —
   "Docker (Valgrind)" — is therefore also the build host. Trainees work at
   SC1 and edit on V1 through **VS Code Remote-SSH** (host `v1` is
   pre-configured); VS Code forwards the application's port to SC1, so the
   application stays on `127.0.0.1` as `SAFETY.md` requires.
2. **SonarQube Community Build has no C/C++ analyser** — Sonar ships C/C++
   from the commercial Developer Edition up, which is what the application's
   `build-wrapper` / `sonar.cfamily.*` configuration assumes. This sandbox uses
   the community plugin **sonar-cxx 2.3.1**, which imports reports from
   cppcheck, clang-tidy and Valgrind, and pins SonarQube to Community Build
   26.1, which that plugin was released against. A quality profile
   `CADMUS-CR-12` with every C++ rule active is created and made the default,
   so imported findings are not dropped. `~/lab-tools/scan-sonar.sh` on V1 runs
   cppcheck and clang-tidy (with the Clang static analyzer, `bugprone-*` and
   CERT checks) and the scanner. Its findings are not the commercial
   analyser's, so the CR1 static-analysis key on the LMS does not match one to
   one.
3. **Valgrind container.** `~/lab-tools/valgrind-container.sh` runs the
   repository's `tools/scan-valgrind.sh` inside a pre-built image
   (`cadmus-valgrind:local`) as the trainee, so files in `build/` and `lab/`
   stay the trainee's. The repository's own `docker compose run --rm valgrind`
   also works (it reinstalls the compiler each run and writes files as root).
4. **One request, one process for the sanitizers.** The request corpus
   contains an oversized search query that crashes the service (finding M7),
   and the Makefile's `asan` target is built without `-fsanitize-recover`, so
   a whole-corpus run reports only the first defect. `~/lab-tools/replay-each.sh`
   replays every request against a fresh sanitizer process and reports M6, M7,
   M3, M1 and M4 exactly as the instructor key lists them.
5. **Self-test.** At the end of V1's provisioning the sandbox runs Valgrind
   over the corpus and one SonarQube analysis on a scratch copy, and prints
   the result in the allocation log (`SELF-TEST valgrind` / `SELF-TEST
   sonarqube`). This also warms SonarQube and makes the project appear, as the
   CR1 instructor guide recommends. The checks never fail the sandbox.
6. **Password SSH on V1/SQ1.** Ubuntu cloud images disable it; the sandbox
   re-enables it for the trainee account so Remote-SSH works without keys.
7. **SC1 restarts as the last step**, so the first trainee session has the
   final PATH (CR-14 lesson). `C:\Lab\fix-path.ps1` repairs a stale window.
8. **Level E1 (GitHub Actions)** runs on GitHub. Trainees fork
   `cadmus-vulnshop-cpp-cr` and complete `.github/workflows/security-pipeline.yml`.

## Access

| | |
|---|---|
| Account on all three machines | `user` / `Password123` (platform standard; administrator on SC1, sudo + docker on V1/SQ1) |
| SonarQube | `http://localhost:9000` on SC1, `http://sq1:9000` from V1; first login `admin` / `admin`, then a forced password change |
| Application | on V1: `cd ~/cadmus-vulnshop-cpp-cr && make && ./build/vulnshop config/sandbox.ini`; on SC1 `http://localhost:8080/shop` through the VS Code port forward |
| Environment checks | SC1: `C:\Lab\verify-cr-env.ps1` · V1: `~/lab-tools/verify-v1.sh` |

## Mapping to the training levels

| Level | Machine(s) | What the sandbox provides |
|---|---|---|
| 0 · Access | SC1 → V1 | RDP account, desktop README, both environment checks, Remote-SSH to V1 |
| A1/A2 · Dynamic (Valgrind) | V1 | Valgrind natively and in the container, the request corpus, `replay-each.sh` |
| A3/A4 · Static (SonarQube) | SC1 → SQ1, V1 | SonarQube with sonar-cxx, `scan-sonar.sh` (cppcheck + clang-tidy) |
| C1/C2 · Triage and fix | SC1 + V1 | VS Code on V1's source, rebuild and re-run Valgrind |
| D1 · Patch and rebuild | V1 | Git, make, smoke test |
| E1 · CI/CD | GitHub | Trainee's fork with the starter workflow |

## Using it on the platform

1. **Sandboxes → Definition → Create** — Git URL
   `https://github.com/aradovanJava/cadmus-cr-12-sandbox-definition.git`,
   revision = the full SHA of the commit to use (not `main`).
2. **Sandboxes → Pool → Create** from that definition; size = number of trainees.
3. **Allocate.** 30–60 minutes; then read `SELF-TEST` in the user-ansible log.
4. Link the pool to the training instance built from the CR-12 training definition.

## Repository layout

```
topology.yml                              hosts, router, network, addressing
provisioning/
├── playbook.yml                          SQ1+V1 base, SQ1, V1 (+ self-test), SC1
├── requirements.yml                      roles and collections
├── group_vars/all.yml                    credentials, IPs, pinned images, tool URLs
└── templates/
    ├── sq1-docker-compose.yml.j2         SonarQube + sonar-cxx
    ├── sc1-README.txt.j2                 desktop README on SC1
    ├── verify-cr-env.ps1.j2, fix-path.ps1.j2   SC1 checks
    ├── ssh-config.j2                     Remote-SSH hosts v1 / sq1
    └── v1/                               V1: lab tools, Valgrind image, README
tools/                                    rendered copies of the scripts above
```

## Notes for instructors

- **Pin the revision.** The platform reads `topology.yml` when the definition
  is created and does not follow a branch. The application itself is cloned
  from `main` at provisioning, so a change there reaches new allocations
  without a new definition.
- **SonarQube version.** Do not unpin the image to `community`: a newer
  Community Build may refuse sonar-cxx 2.3.1. Move both together.
- **Snyk** needs a free account: `snyk auth` once on V1 (it prints a URL to open
  on SC1). For vendored C/C++ use `snyk test --unmanaged`.
- The `docs/ANSWER_KEY.md` / `docs/FIXES.md` instructor build stays on the LMS.

---

Co-funded by the European Union (Digital Europe Programme, grant agreement
101190006 — CADMUS). Views and opinions expressed are those of the author(s)
only and do not necessarily reflect those of the European Union or HaDEA.
