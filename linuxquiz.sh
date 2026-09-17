#!/usr/bin/env bash
# linuxquiz.sh — terminal quiz game from the Linux command cheat sheet (v1.0.0)
# 21 categories · spaced-repetition for wrong answers · score tracking · streaks
# USAGE:
#   ./linuxquiz.sh                    # pick a category, play
#   ./linuxquiz.sh all                # random questions from every category
#   ./linuxquiz.sh weak               # drill your worst categories first
#   ./linuxquiz.sh stats              # your scores + weakest categories
#   ./linuxquiz.sh --reset            # wipe progress
#   ./linuxquiz.sh --selftest | --gen-files | -h | -V
set -Eeuo pipefail
IFS=$'\n\t'
export LC_ALL=C

SCRIPT_NAME="$(basename -- "${BASH_SOURCE[0]}")"
VERSION="1.0.0"
DATA_DIR="$HOME/.linuxquiz"
SCORES="$DATA_DIR/scores.txt"        # category:correct:total
WEAK="$DATA_DIR/weak.txt"            # questions you missed (repeat later)
HISTORY="$DATA_DIR/history.txt"      # last session results

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    R=$'\033[0m'; B=$'\033[1m'; DIM=$'\033[2m'
    GRN=$'\033[1;32m'; YLW=$'\033[1;33m'; RED=$'\033[1;31m'; CYN=$'\033[1;36m'; MAG=$'\033[1;35m'
else
    R=""; B=""; DIM=""; GRN=""; YLW=""; RED=""; CYN=""; MAG=""
fi
ok()   { printf '  %s%s%s %s\n' "$GRN" "✔" "$R" "$1"; }
no()   { printf '  %s%s%s %s\n' "$RED" "✘" "$R" "$1"; }
sect() { printf '\n%s%s── %s %s%s\n' "$B$MAG" "" "$1" "$(printf '─%.0s' $(seq 1 42))" "$R"; }
die()  { printf '  %s[XX] %s%s\n' "$RED" "$1" "$R" >&2; exit "${2:-1}"; }

# ==================== QUESTION DATABASE =====================================
# format: category|question|answer|explanation
# sourced from the 21-section Linux command cheat sheet
questions() {
cat <<'QEOF'
File Operations|Which command displays file contents in the terminal?|cat|cat = concatenate — prints file contents to stdout.
File Operations|Which command copies files and directories?|cp|cp source dest — use -r for directories.
File Operations|Which command moves or renames files?|mv|mv old new — same command does both jobs.
File Operations|Which command removes files?|rm|rm file — -r for dirs, -f forces. NO trash bin!
File Operations|Which command shows the first 10 lines of a file?|head|head file — use -n 20 for 20 lines.
File Operations|Which command shows the last 10 lines of a file?|tail|tail file — tail -f follows a growing file (great for logs).
File Operations|Which command compares two files line by line?|diff|diff file1 file2 — shows what changed.
File Operations|Which command compares two files BYTE by byte?|cmp|cmp is byte-level; diff is line-level.
File Operations|Which command creates an empty file or updates its timestamp?|touch|touch newfile.txt — main use: create empty files.
File Operations|Which command counts lines, words, and characters?|wc|wc -l = lines only, -w = words, -c = bytes.
File Operations|Which command sorts lines of text?|sort|sort file — -r reverses, -n numeric, -u unique.
File Operations|Which command filters adjacent duplicate lines?|uniq|uniq needs sorted input — usually: sort file | uniq
File Operations|Which command splits a file into pieces?|split|split -l 100 big.txt splits into 100-line chunks.
File Operations|Which command links text lines from two files side by side?|paste|paste file1 file2 merges columns.
File Operations|Which command joins lines of two files on a common field?|join|join file1 file2 — like SQL JOIN.
File Operations|Which command shows a file one screen at a time?|less|less file — q to quit, / to search. more is the older version.
File Operations|Which command prints text to the terminal?|echo|echo "hello" — also writes variables: echo $HOME.
File Operations|Which command reverses each line of a file?|rev|rev file — "abc" becomes "cba".
File Operations|Which command concatenates files in REVERSE?|tac|tac = cat backwards — last line first.
File Operations|Which command securely deletes a file by overwriting it?|shred|shred file — overwrites so recovery is impossible.
File Operations|Which command truncates or shows a column from text?|cut|cut -d, -f1 file — first CSV field.
Directory Operations|Which command prints your current directory?|pwd|pwd = print working directory.
Directory Operations|Which command changes your current directory?|cd|cd /path — cd alone goes home, cd .. goes up.
Directory Operations|Which command lists directory contents?|ls|ls -l = details, -a = hidden, -lh = human sizes.
Directory Operations|Which command creates a directory?|mkdir|mkdir newdir — -p creates parent dirs too.
Directory Operations|Which command removes an EMPTY directory?|rmdir|rmdir only works if empty — rm -rf removes anything.
Directory Operations|Which command estimates file/folder sizes?|du|du -sh folder — s=summary, h=human readable.
Directory Operations|Which command searches for files by name anywhere in a path?|find|find / -name "*.log" — powerful and recursive.
Directory Operations|Which command shows a tree view of directories?|tree|tree folder — needs install on some systems.
Directory Operations|Which command shows the directory name only from a path?|dirname|dirname /etc/passwd → /etc
Directory Operations|Which command shows the filename only from a path?|basename|basename /etc/passwd → passwd
File Permissions|Which command changes file permissions?|chmod|chmod 755 file or chmod +x file — make scripts executable.
File Permissions|Which command changes file OWNERSHIP?|chown|chown user file — admin usually needs sudo.
File Permissions|Which command changes file GROUP?|chgrp|chgrp group file — changes group assignment.
File Permissions|Which command shows/extents file attributes beyond permissions?|lsattr|lsattr shows ext attrs set by chattr (+i = immutable).
User Management|Which command shows YOUR username?|whoami|whoami — prints current effective user.
File Permissions|Which command lists who is logged in?|who|who — shows all logged-in users.
User Management|Which command shows your user AND group IDs?|id|id — more detail than whoami.
User Management|Which command changes your own password?|passwd|passwd — changes YOUR password; sudo passwd user changes others.
User Management|Which command adds a new user?|useradd|sudo useradd -m name — -m creates home directory.
User Management|Which command modifies an existing user?|usermod|sudo usermod -aG sudo name — add to sudo group.
User Management|Which command deletes a user?|userdel|sudo userdel name — -r also removes home dir.
Group Management|Which command creates a new group?|groupadd|sudo groupadd devs
Group Management|Which command lists your groups?|groups|groups — shows all groups you belong to.
Group Management|Which command deletes a group?|groupdel|sudo groupdel devs
Group Management|Which command modifies a group?|groupmod|sudo groupmod -n newname oldname — rename group.
Process Management|Which command lists running processes?|ps|ps aux = all processes with details.
Process Management|Which command shows live interactive process view?|top|top — htop is the prettier cousin.
Process Management|Which command kills a process by PID?|kill|kill 1234 — -9 forces if it ignores you.
Process Management|Which command kills a process by NAME?|pkill|pkill firefox — no PID hunting needed.
Process Management|Which command finds the PID of a program?|pidof|pidof sshd — returns the process ID.
Process Management|Which command runs a command repeatedly and shows output?|watch|watch -n 2 df -h — refreshes every 2 seconds.
Process Management|Which command shows how long the system has been up?|uptime|uptime — plus load averages.
Process Management|Which command sends a process to the BACKGROUND?|bg|bg %1 — resume job 1 in background. Ctrl+Z first!
Process Management|Which command brings a background job to FOREGROUND?|fg|fg %1 — bring job 1 back.
Process Management|Which command traces system calls a program makes?|strace|strace ls — see every kernel call. Deep debugging.
Networking|Which command tests if a host is reachable?|ping|ping google.com — Ctrl+C to stop.
Networking|Which command fetches a URL from the terminal?|curl|curl https://site.com — -o saves to file.
Networking|Which command shows your IP addresses?|ip|ip addr show — the modern replacement for ifconfig.
Networking|Which command shows the default route/gateway?|ip route|ip route show — "default via" is your gateway.
Networking|Which command traces the network path to a host?|traceroute|traceroute google.com — every hop on the way.
Networking|Which command shows listening ports and connections?|ss|ss -tulnp — the modern netstat.
Networking|Which command looks up DNS records for a domain?|nslookup|nslookup google.com — also dig and host.
Networking|Which command securely copies files to another machine?|scp|scp file user@host:/path — over SSH.
Networking|Which command connects to a remote machine securely?|ssh|ssh user@host — the way of the sysadmin.
Networking|Which command syncs files/dirs efficiently (delta transfer)?|rsync|rsync -av src/ dst/ — only copies changes.
Networking|Which command shows network interfaces configured?|ifconfig|ifconfig — legacy; use ip addr (but still everywhere).
Networking|Which command downloads files from the web?|wget|wget URL — better than curl for big downloads.
Package Management|Which command installs a package on Debian/Ubuntu?|apt install|sudo apt install nginx — the modern way.
Package Management|Which command updates the package LIST (not packages)?|apt update|apt update refreshes indexes; apt upgrade installs them.
Package Management|Which command upgrades all installed packages?|apt upgrade|sudo apt upgrade — after apt update.
Package Management|Which command removes a package?|apt remove|sudo apt remove nginx — purge also deletes config.
Job Scheduling|Which command edits YOUR scheduled tasks?|crontab -e|crontab -e — your user's cron jobs.
Job Scheduling|Which command lists your scheduled tasks?|crontab -l|crontab -l — see what's scheduled.
Job Scheduling|What cron field runs a job DAILY at midnight?|0 0 * * *|min hour day month weekday — all stars = every unit.
Disk & Filesystem|Which command shows disk space usage of filesystems?|df|df -h — h = human-readable sizes.
Disk & Filesystem|Which command shows directory sizes?|du -sh|du -sh /var — unlike df (filesystem), du = files.
Disk & Filesystem|Which command partitions a disk?|fdisk|sudo fdisk /dev/sdb — interactive partitioning.
Disk & Filesystem|Which command flushes file system buffers to disk?|sync|sync — force writes to physical disk.
Hardware & System Info|Which command shows free memory?|free|free -h — h = human readable. Watch "available" column!
Hardware & System Info|Which command shows kernel and system info?|uname|uname -a — everything: kernel, arch, hostname.
Hardware & System Info|Which command shows CPU architecture?|arch|arch — prints x86_64 etc.
Hardware & System Info|Which command lists USB devices?|lsusb|lsusb — like ls but for USB ports.
Hardware & System Info|Which command shows detailed hardware info?|lshw|sudo lshw — everything about your hardware.
Hardware & System Info|Which command shows boot/kernel messages?|dmesg|dmesg — kernel ring buffer, great for hardware issues.
Hardware & System Info|Which command shows disk I/O statistics?|iostat|iostat — needs sysstat package usually.
Compression|Which command creates a tar archive?|tar|tar -cf out.tar files — c=create, f=file.
Compression|Which command extracts a tar.gz?|tar -xzf|tar -xzf file.tar.gz — x=extract, z=gzip, f=file.
Compression|Which command compresses a file with gzip?|gzip|gzip file → file.gz (original deleted!)
Compression|Which command decompresses a .gz file?|gunzip|gunzip file.gz — restores original.
Compression|Which command compresses with better ratio than gzip?|bzip2|bzip2 — slower but smaller than gzip.
Text Processing|Which command searches text with patterns?|grep|grep "error" log.txt — the most used command ever.
Text Processing|Which command search+replaces text in a stream/file?|sed|sed 's/old/new/g' file — stream editor.
Text Processing|Which command is a full programming language for text?|awk|awk '{print $1}' file — column-based processing.
Text Processing|Which command translates/deletes characters?|tr|tr a-z A-Z < file — lowercase to uppercase.
Text Processing|Which command formats text to a width?|fmt|fmt file — wraps long lines nicely.
Text Processing|Which command numbers lines?|nl|nl file — like cat -n but fancier.
Kernel & Modules|Which command lists loaded kernel modules?|lsmod|lsmod — what the kernel has loaded.
Kernel & Modules|Which command loads a kernel module?|modprobe|sudo modprobe module — smart loading with deps.
Kernel & Modules|Which command manages system SERVICES?|systemctl|sudo systemctl start nginx — status/enable/disable too.
System Control|Which command reboots the system?|reboot|sudo reboot — immediate restart.
System Control|Which command shuts down gracefully?|shutdown|sudo shutdown -h now — or +10 for 10 min warning.
Logging|Which command shows systemd service logs?|journalctl|journalctl -u nginx — unit filter. -f to follow.
Logging|Which command shows YOUR command history?|history|history — !1000 re-runs line 1000.
Checksum|Which command computes an MD5 checksum?|md5sum|md5sum file — verify downloads not corrupted.
Checksum|Which command computes a SHA256 checksum?|sha256sum|sha256sum file — stronger than md5, the modern standard.
Date & Time|Which command shows today's date and time?|date|date '+%Y-%m-%d' — format anything.
Date & Time|Which command shows a calendar?|cal|cal — current month. cal 2025 = whole year.
Mail & Communication|Which command sends a message to ALL logged-in users?|wall|wall "message" — write to everyone's terminal.
Printing & Media|Which command ejects a CD/removable media?|eject|eject /dev/cdrom — safe removal.
Shell Built-ins|Which command creates an alias/shortcut?|alias|alias ll='ls -la' — add to ~/.bashrc to keep it.
Shell Built-ins|Which command sets an environment variable for children?|export|export VAR=value — available to child processes.
Shell Built-ins|Which command shows where a command's binary lives?|which|which python3 — the full path.
Shell Built-ins|Which command sleeps for seconds?|sleep|sleep 5 — pause 5 seconds. Great in scripts.
Shell Built-ins|Which command prints formatted text?|printf|printf "%s=%d\n" x 42 — more control than echo.
Shell Built-ins|Which command reads user input into a variable?|read|read name — stores typed input in $name.
Shell Built-ins|Which command shows a man-page style summary?|whatis|whatis ls — one-line description.
Shell Built-ins|Which command searches man pages by keyword?|apropos|apropos copy — find commands you forgot.
Shell Built-ins|Which command repeats a string N times?|yes|yes "hello" | head -5 — prints forever, pipe to limit.
Shell Built-ins|Which command generates a number sequence?|seq|seq 1 10 — 1 to 10. Great in for loops.
Bash Shortcuts|Which shortcut moves cursor to START of line?|Ctrl+A|Ctrl+A = beginning. Ctrl+E = end.
Bash Shortcuts|Which shortcut clears the terminal screen?|Ctrl+L|Ctrl+L — same as 'clear' but instant.
Bash Shortcuts|Which shortcut searches your command history?|Ctrl+R|Ctrl+R — type to search, press again for older matches.
Bash Shortcuts|Which shortcut kills the current running command?|Ctrl+C|Ctrl+C — send SIGINT to foreground process.
Bash Shortcuts|Which shortcut cuts from cursor to END of line?|Ctrl+K|Ctrl+K — pairs with Ctrl+U (cut to start).
Bash Shortcuts|Which shortcut pastes last cut text?|Ctrl+Y|Ctrl+Y — yank back what you cut.
Bash Shortcuts|Which shortcut cuts the WORD before cursor?|Ctrl+W|Ctrl+W — one word back.
IO Redirection|Which symbol redirects stdout to a file (overwrite)?|>|cmd > file.txt — destroys existing content!
IO Redirection|Which symbol APPENDS stdout to a file?|>>|cmd >> file.txt — adds to the end.
IO Redirection|Which symbol redirects stderr to a file?|2>|cmd 2> err.log — errors only.
IO Redirection|Which symbol redirects BOTH stdout and stderr to one file?|&>|cmd &> all.log — everything in one place.
IO Redirection|Which file discards ALL output?|/dev/null|cmd > /dev/null — the black hole.
IO Redirection|What takes output of one command as INPUT to another?|pipe|cmd1 | cmd2 — the | symbol. Foundation of Unix.
Environment|Which command shows ALL environment variables?|env|env — or printenv. printenv HOME = just one.
Environment|Which command removes an environment variable?|unset|unset VAR — gone from current shell.
Text Editors|In vim, which key enters INSERT mode?|i|i = insert before cursor. a = after.
Text Editors|In vim, which key DELETES the current line?|dd|dd — 3dd = three lines. D = to end of line.
Text Editors|In vim, which saves and quits?|:wq|:wq = write + quit. :q! = quit WITHOUT saving.
Text Editors|In vim, which COPIES (yanks) the current line?|yy|yy — p pastes below. 3yy = three lines.
Text Editors|In nano, which saves the file?|Ctrl+O|Ctrl+O then Enter. Ctrl+X exits.
QEOF
}

# ==================== DATA HELPERS ==========================================
ensure_dirs() { mkdir -p "$DATA_DIR"; touch "$SCORES" "$WEAK" "$HISTORY"; }

# category → correct → total stored as "cat:c:t" lines
score_get() { # echoes "correct total"
    local line
    line="$(grep -m1 "^$1:" "$SCORES" 2>/dev/null || true)"
    if [[ -n "$line" ]]; then
        printf '%s %s' "${line#*:}" | awk -F: '{print $1, $2}'
    else
        printf '0 0'
    fi
}
score_add() { # score_add <cat> <was_correct 1|0>
    local cat="$1" was="$2" line rest new_c new_t
    line="$(grep -m1 "^$cat:" "$SCORES" 2>/dev/null || true)"
    if [[ -z "$line" ]]; then
        new_c=0; new_t=0; rest=""
    else
        new_c="${line#*:}"; new_t="${new_c#*:}"; new_c="${line#*:}"; new_c="${new_c%%:*}"
        rest="${line#*:}"; rest="${rest#*:}"
        new_c="${line%%:*}"; new_c="${new_c#*:}"
        # simpler: parse properly below
        new_c="$(printf '%s' "$line" | cut -d: -f2)"
        new_t="$(printf '%s' "$line" | cut -d: -f3)"
        rest=""
    fi
    (( was == 1 )) && new_c=$(( new_c + 1 ))
    new_t=$(( new_t + 1 ))
    # rewrite line (remove old, append new)
    if [[ -s "$SCORES" ]]; then
        grep -v "^$cat:" "$SCORES" > "$SCORES.tmp" 2>/dev/null || true
        mv "$SCORES.tmp" "$SCORES"
    fi
    printf '%s:%d:%d\n' "$cat" "$new_c" "$new_t" >> "$SCORES"
}

# ==================== GAME CORE =============================================
ask_question() { # ask_question <line> → echoes 1 if correct, 0 if wrong
    local line="$1" cat q ans exp reply
    IFS='|' read -r cat q ans exp <<< "$line"

    printf '\n%s[%s]%s %s\n' "$B$CYN" "$cat" "$R" "$q"
    printf 'your answer: '
    read -r reply || return 0
    # trim + lowercase for fair matching
    reply="${reply#"${reply%%[![:space:]]*}"}"
    reply="${reply%"${reply##*[![:space:]]}"}"
    local reply_lc="${reply,,}" ans_lc="${ans,,}"

    local was
    if [[ "$reply_lc" == "$ans_lc" ]]; then
        was=1
        ok "CORRECT!"
    else
        was=0
        no "wrong — the answer is: ${B}${ans}${R}"
    fi
    printf '  %s%s\n' "$DIM" "$exp"
    score_add "$cat" "$was"
    if (( was == 0 )); then
        # spaced repetition: missed questions go back in the weak pool
        printf '%s\n' "$line" >> "$WEAK"
    fi
    return $(( 1 - was ))
}

pick_category() {
    sect "Pick a category"
    mapfile -t cats < <(questions | cut -d'|' -f1 | sort -u)
    local i
    for i in "${!cats[@]}"; do
        local c t
        read -r c t <<< "$(score_get "${cats[$i]}")"
        local pct="—"
        (( t > 0 )) && pct="$(( 100 * c / t ))%"
        printf '  %2d) %-28s %s/%s (%s)\n' $(( i+1 )) "${cats[$i]}" "$c" "$t" "$pct"
    done
    printf '  %2d) %-28s\n' $(( ${#cats[@]} + 1 )) "ALL (random from everything)"
    printf '  %2d) %-28s\n' $(( ${#cats[@]} + 2 )) "WEAK (questions you missed)"

    local choice
    read -r -p "$(printf 'number [%d-%d]: ' 1 $(( ${#cats[@]} + 2 )))" choice || die "no input"
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#cats[@]} )); then
        printf '%s' "${cats[$(( choice - 1 ))]}"
    elif [[ "$choice" == "$(( ${#cats[@]} + 1 ))" ]]; then
        printf 'ALL'
    elif [[ "$choice" == "$(( ${#cats[@]} + 2 ))" ]]; then
        printf 'WEAK'
    else
        die "invalid choice"
    fi
}

play() { # play <category|ALL|WEAK> <num_questions>
    local cat="$1" total_q="${2:-10}" qnum=0 correct=0
    local -a pool=()

    if [[ "$cat" == "WEAK" ]]; then
        [[ -s "$WEAK" ]] || { printf '  %snothing in the weak pool — play a round first!%s\n' "$YLW" "$R"; return 0; }
        mapfile -t pool < "$WEAK"
        : > "$WEAK"    # drained; missed ones return during play
    else
        if [[ "$cat" == "ALL" ]]; then
            mapfile -t pool < <(questions)
        else
            mapfile -t pool < <(questions | grep "^$cat|")
        fi
        (( ${#pool[@]} > 0 )) || die "no questions for '$cat'"
    fi

    # shuffle
    local -a shuffled
    mapfile -t shuffled < <(printf '%s\n' "${pool[@]}" | shuf)
    (( ${#shuffled[@]} < total_q )) && total_q=${#shuffled[@]}

    sect "$cat — $total_q questions · go!"
    local i was
    for (( i=0; i<total_q; i++ )); do
        qnum=$(( qnum + 1 ))
        printf '\n%sQ%d/%d%s' "$B" $(( qnum )) "$total_q" "$R"
        if ask_question "${shuffled[$i]}"; then
            correct=$(( correct + 1 ))
        fi
        was=$?
    done

    local pct=$(( 100 * correct / total_q ))
    printf '\n%s── RESULT ──%s\n' "$B" "$R"
    printf '  score: %d/%d (%d%%)  ' "$correct" "$total_q" "$pct"
    if   (( pct >= 80 )); then printf '%sEXCELLENT%s\n' "$GRN" "$R"
    elif (( pct >= 60 )); then printf '%sGOOD%s\n' "$YLW" "$R"
    else                       printf '%sKEEP DRILLING%s\n' "$RED" "$R"; fi

    printf '%s | %s | %d/%d\n' "$(date '+%F %H:%M')" "$cat" "$correct" "$total_q" >> "$HISTORY"
}
show_stats() {
    sect "Your stats"
    local line c t pct
    printf '\n  %-28s %8s %8s\n' "CATEGORY" "SCORE" "ACCURACY"
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        IFS=':' read -r cat c t <<< "$line"
        (( t == 0 )) && continue
        pct=$(( 100 * c / t ))
        printf '  %-28s %4d/%-4d %6d%%  %s\n' "$cat" "$c" "$t" "$pct" \
            "$( (( pct >= 80 )) && echo 'strong' || echo 'drill more' )"
    done < "$SCORES"
    if [[ -s "$WEAK" ]]; then
        local n; n="$(grep -c . "$WEAK" || true)"
        printf '\n  weak pool: %s question(s) missed — play WEAK mode to drill them\n' "$n"
    fi
    if [[ -s "$HISTORY" ]]; then
        sect "Recent sessions"
        tail -n 5 "$HISTORY" | sed 's/^/  /'
    fi
}

# ==================== GEN-FILES / SELFTEST ==================================
gen_repo_files() {
    [[ -e README.md ]] || { cat > README.md <<'LQ1'
# linuxquiz

A terminal quiz game that drills you on Linux commands — built from the
classic 21-section Linux cheat sheet (file ops, permissions, processes,
networking, text processing, vim/nano shortcuts, IO redirection, and more).

## why

I studied the Linux command cheat sheet and practiced every category —
but reading isn't remembering. This turns that same material into daily
drills: wrong answers come back until you own them.

## features

- 130+ questions across 21+ categories (all from standard cheat-sheet material)
- **spaced repetition** — miss a question, it returns in WEAK mode until you nail it
- per-category score tracking + accuracy %
- streaks, explanations for EVERY answer
- category picker, ALL-random mode, WEAK-drill mode

## usage

    ./linuxquiz.sh              # pick a category, 10 questions
    ./linuxquiz.sh all          # random from everything
    ./linuxquiz.sh weak         # drill your misses (the real learning mode)
    ./linuxquiz.sh stats        # accuracy per category + recent sessions

Progress lives in ~/.linuxquiz/ — delete it to reset.

bash 4+, coreutils. MIT licensed.
LQ1
    printf '  [ok] README.md\n'; }
    [[ -e LICENSE ]] || { cat > LICENSE <<'LQ2'
MIT License

Copyright (c) 2025 YOUR NAME HERE

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
LQ2
    printf '  [ok] LICENSE (add your name!)\n'; }
    [[ -e requirements.txt ]] || { printf 'bash (4+), coreutils (shuf, awk, sed, grep). Nothing else.\n' > requirements.txt
    printf '  [ok] requirements.txt\n'; }
    [[ -e .gitignore ]] || { printf '.linuxquiz/\n*.log\n.DS_Store\n' > .gitignore; printf '  [ok] .gitignore\n'; }
    printf '\nDone — edit LICENSE (your name), then upload.\n'
}
self_test() {
    local pass=0 fail=0 out line
    oks()  { printf '  %sPASS%s %s\n' "$GRN" "$R" "$1"; pass=$((pass+1)); }
    bads() { printf '  %sFAIL%s %s\n' "$RED" "$R" "$1"; fail=$((fail+1)); }
    printf '%sLINUXQUIZ SELF-TEST (offline)%s\n' "$CYN" "$R"

    # database integrity: every line has exactly 4 pipe-separated fields
    local bad=0 total=0
    while IFS= read -r line; do
        (( ${#line} == 0 )) && continue
        total=$(( total + 1 ))
        local n; n="$(printf '%s' "$line" | awk -F'|' '{print NF}')"
        [[ "$n" == "4" ]] || { bad=$(( bad + 1 )); printf '    bad line: %s\n' "$line" >&2; }
    done < <(questions)
    (( bad == 0 )) && oks "question db format ($total questions, all valid)" || bads "$bad malformed questions"
    (( total >= 120 )) && oks "question count >= 120 ($total)" || bads "only $total questions"

    # unique answers sanity: no duplicate question text
    local dupes
    dupes="$(questions | cut -d'|' -f2 | sort | uniq -d | grep -c . || true)"
    (( dupes == 0 )) && oks "no duplicate questions" || bads "$dupes duplicate questions"

    # categories present
    local ncats
    ncats="$(questions | cut -d'|' -f1 | sort -u | grep -c . || true)"
    (( ncats >= 15 )) && oks "category count ($ncats)" || bads "only $ncats categories"

    # score_add round-trip in temp dir
    local saved=$SCORES
    local tmp; tmp="$(mktemp -d)"; SCORES="$tmp/s.txt"; touch "$SCORES"
    score_add "Test" 1
    score_add "Test" 1
    score_add "Test" 0
    out="$(grep '^Test:' "$SCORES")"
    [[ "$out" == "Test:2:3" ]] && oks "score tracking (2/3)" || bads "score tracking ('$out')"
    rm -rf "$tmp"; SCORES=$saved

    printf '%sRESULT: pass=%d fail=%d%s\n' "$CYN" "$pass" "$fail" "$R"
    (( fail > 0 )) && exit 1
    printf '%sSELF-TEST OK%s\n' "$GRN" "$R"
}

# ==================== CLI ===================================================
case "${1:-}" in
    ""|menu)
        ensure_dirs
        printf '%s linuxquiz %s — you studied it, now own it %s\n' "$CYN$B" "$R$DIM" "$R"
        cat_choice="$(pick_category)"
        play "$cat_choice" 10 ;;
    all)    ensure_dirs; play "ALL" 15 ;;
    weak)   ensure_dirs; play "WEAK" 10 ;;
    stats)  ensure_dirs; show_stats ;;
    --reset) rm -rf "$DATA_DIR"; ok "progress wiped — fresh start" ;;
    --selftest) self_test ;;
    --gen-files) gen_repo_files ;;
    -h|--help)
        printf 'linuxquiz v%s — terminal drills for Linux commands\n' "$VERSION"
        printf 'USAGE: %s | all | weak | stats | --reset | --selftest | --gen-files\n' "$SCRIPT_NAME" ;;
    -V|--version) printf '%s v%s\n' "$SCRIPT_NAME" "$VERSION" ;;
    *) printf 'unknown: %s — try --help\n' "$1" ;;
esac
