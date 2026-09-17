linuxquiz
A terminal quiz game that drills you on Linux commands — built from theclassic 21-section Linux command cheat sheet (file ops, permissions,processes, networking, text processing, vim/nano shortcuts, IOredirection, environment variables, and more).

why I built it
I studied the Linux command reference and practiced every categoryhands-on — but reading isn't remembering. So I turned the exact samematerial into a drill machine: wrong answers come back until you ownthem, and every explanation teaches the gotcha behind the command.

features
130+ questions across 21+ categories — all standard cheat-sheet material
spaced repetition — missed questions return in WEAK mode until mastered
per-category tracking — accuracy % for every category at a glance
explanations for every answer — including the traps (rm has no trash bin, uniq needs sorted input, gzip deletes your original)
three modes: category drill, ALL-random, and WEAK-repair
usage
./linuxquiz.sh              # pick a category, 10 questions./linuxquiz.sh all          # 15 random from everything./linuxquiz.sh weak         # drill your misses — the real learning mode./linuxquiz.sh stats        # per-category accuracy + recent sessions./linuxquiz.sh --reset      # wipe progress, fresh start
Progress lives in ~/.linuxquiz/ (scores, weak pool, session history).

the study method that works
Run ALL mode → find categories under 60%
Daily: one category + WEAK mode (5 minutes)
When a category shows 80%+ on stats → it's yours
Before any interview: drill every "drill more" category cold
self-test (offline)
./linuxquiz.sh --selftest
Validates the whole question database (format, count, no duplicates)and score-tracking logic.

bash 4+, coreutils. Zero other dependencies. MIT licensed.
