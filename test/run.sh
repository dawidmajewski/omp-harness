#!/usr/bin/env bash
# omph regression suite: isolated HOME, stub omp first on PATH. Runs on host and in Docker.
set -u

REPO=$(cd "$(dirname "$0")/.." && pwd)
HOME=$(mktemp -d)
export HOME
export PATH="$REPO/docker/stubs:$REPO/bin:$PATH"
export OMPH_TEST_LOG="$HOME/.omph-stub.log"
unset OMP_PROFILE OMPH_PROFILES OMPH_ENV_KEYS OMPH_TEST_SECRET
trap 'rm -rf "$HOME"' EXIT

pass=0 fail=0
OUT=$HOME/.out ERR=$HOME/.err FILES=$HOME/.omph-stub.files
ok() { pass=$((pass + 1)); echo "ok   $1"; }
bad() { fail=$((fail + 1)); echo "FAIL $1"; sed 's/^/     out: /' "$OUT"; sed 's/^/     err: /' "$ERR"; }
check() { if "$@"; then ok "$NAME"; else bad "$NAME"; fi; }
# run <dir> <args...>: run omph in <dir>, capturing stdout/stderr; sets RC.
run() { local dir=$1; shift; (cd "$dir" && omph "$@") >"$OUT" 2>"$ERR"; RC=$?; }
last_log() { tail -n 1 "$OMPH_TEST_LOG" 2>/dev/null; }
file_mode() { stat -c %a "$1" 2>/dev/null || stat -f %Lp "$1"; }
P=$HOME/.config/omph/profiles

# Global MCP pool, as written by omp's /mcp add.
mkdir -p "$HOME/.omp/agent" "$HOME/work/proj/sub" "$HOME/plain" "$HOME/evil"
cat >"$HOME/.omp/agent/mcp.json" <<'EOF'
{"mcpServers": {"playwright": {"command": "x"}, "wiki": {"url": "https://w"}, "tracker": {"url": "https://t"}, "unused": {"url": "https://u"}}}
EOF

NAME="1 :init scaffolds profiles"
for p in base acme sales; do run "$HOME" :init "$p"; done
t1() { [ $RC -eq 0 ] && [ "$(file_mode "$P/sales/env")" = 600 ] && [ -f "$P/sales/mcp" ] && [ -f "$P/base/mcp" ]; }
check t1
echo playwright >>"$P/base/mcp"
echo wiki >>"$P/acme/mcp"
echo tracker >>"$P/sales/mcp"
echo 'OMPH_TEST_SECRET=s3cret' >>"$P/acme/env"
echo 'ACME RULES' >"$P/acme/instructions.md"
mkdir -p "$P/acme/skills"

NAME="2 :use writes a trusted marker; :which resolves it from a subdir"
run "$HOME/work/proj" :use acme sales
run "$HOME/work/proj/sub" :which
t2() { [ $RC -eq 0 ] && grep -qx 'profiles = acme, sales' "$HOME/work/proj/.omph" \
  && grep -q 'profiles: acme sales' "$OUT" && grep -q 'trusted: yes' "$OUT"; }
check t2

NAME="3 launch composes MCP, skills, instructions and secrets of the selected profiles"
run "$HOME/work/proj/sub" -p hi
t3() { [ $RC -eq 0 ] && last_log | grep -q '^OMPH_PROFILES=acme,sales OMPH_TEST_SECRET=s3cret OMP_PROFILE= ARGS=--config .* -p hi$' \
  && grep -qx '  - "mcp:playwright"' "$FILES" && grep -qx '  - "mcp:unused"' "$FILES" \
  && ! grep -q 'mcp:wiki\|mcp:tracker' "$FILES" \
  && grep -qx "    - \"$P/acme/skills\"" "$FILES" \
  && grep -qx '## Profile: acme' "$FILES" && grep -qx 'ACME RULES' "$FILES"; }
check t3

NAME="4 untrusted or edited markers are refused"
echo 'profiles = acme' >"$HOME/evil/.omph"
before=$(last_log)
run "$HOME/evil" -p hi
rc_evil=$RC; err_evil=$(cat "$ERR")
echo '# edited' >>"$HOME/work/proj/.omph"
run "$HOME/work/proj" -p hi
t4() { [ $rc_evil -ne 0 ] && [[ $err_evil == *"not trusted"* ]] && [ $RC -ne 0 ] && grep -q 'not trusted' "$ERR" && [ "$(last_log)" = "$before" ]; }
check t4
run "$HOME/work/proj" :trust

NAME="5 nested run in an unbound dir drops outer secrets and gets only base"
OMPH_TEST_NESTED_DIR="$HOME/plain" run "$HOME/work/proj/sub" -p hi
t5() { [ $RC -eq 0 ] && last_log | grep -q '^OMPH_PROFILES=base OMPH_TEST_SECRET= OMP_PROFILE= ' \
  && grep -qx '  - "mcp:wiki"' "$FILES" && ! grep -q 'mcp:playwright' "$FILES"; }
check t5

NAME="6 unbound dir without a base profile runs plain omp"
mv "$P/base" "$P/base.off"
OMP_PROFILE=stale run "$HOME/plain" -p hi
t6() { [ $RC -eq 0 ] && [ "$(last_log)" = "OMPH_PROFILES= OMPH_TEST_SECRET= OMP_PROFILE= ARGS=-p hi" ]; }
check t6
mv "$P/base.off" "$P/base"

NAME="7 profile naming an MCP server missing from the pool is a hard error"
echo nope >>"$P/sales/mcp"
run "$HOME/work/proj" -p hi
t7() { [ $RC -ne 0 ] && grep -q "'nope', which is not in" "$ERR"; }
check t7
sed -i.bak '/^nope$/d' "$P/sales/mcp"

NAME="8 profile config.yml may not set omph-owned arrays"
printf 'disabledExtensions:\n  - skill:x\n' >"$P/sales/config.yml"
run "$HOME/work/proj" -p hi
t8() { [ $RC -ne 0 ] && grep -q 'which omph owns' "$ERR"; }
check t8
rm -f "$P/sales/config.yml"

NAME="9 malformed markers are rejected (bad line, unknown key, traversal name)"
r=0
for m in 'profiles' 'profile = acme' 'profiles = ../../tmp/x'; do
  printf '%s\n' "$m" >"$HOME/evil/.omph"
  run "$HOME/evil" :which
  [ $RC -ne 0 ] && grep -q 'invalid line\|unknown key\|invalid profile name' "$ERR" || r=1
done
t9() { [ $r -eq 0 ]; }
check t9

NAME="10 :use refuses to bind \$HOME"
run "$HOME" :use base
t10() { [ $RC -ne 0 ] && grep -q 'refusing to bind' "$ERR" && [ ! -e "$HOME/.omph" ]; }
check t10

NAME="11 a symlinked marker cannot borrow a trusted marker's trust, and :use won't write through it"
rm -f "$HOME/evil/.omph"
ln -s "$HOME/work/proj/.omph" "$HOME/evil/.omph"
before=$(cat "$HOME/work/proj/.omph")
run "$HOME/evil" -p hi
rc_launch=$RC
run "$HOME/evil" :use base
t11() { [ $rc_launch -ne 0 ] && [ $RC -ne 0 ] && grep -q 'symlink' "$ERR" && [ "$(cat "$HOME/work/proj/.omph")" = "$before" ]; }
check t11
rm -f "$HOME/evil/.omph"

NAME="12 a path containing a newline cannot match a trusted line"
trusted_line=$(grep " $(realpath "$HOME/work/proj")/.omph\$" "$HOME/.config/omph/trusted")
forged="$HOME/evil/x"$'\n'"${trusted_line%/.omph}"
mkdir -p "$forged"
echo 'profiles = acme' >"$forged/.omph"
run "$forged" -p hi
t12() { [ $RC -ne 0 ] && grep -q 'not trusted' "$ERR"; }
check t12

NAME="13 secrets named like omph state cannot corrupt the launch or nested cleanup"
cp "$P/acme/env" "$P/acme/env.bak"
printf 'OMPH_ENV_KEYS=\n_omph_launch=x\nOMPH_PROFILES=x\n' >>"$P/acme/env"
run "$HOME/work/proj/sub" -p hi
line=$(last_log)
OMPH_TEST_NESTED_DIR="$HOME/plain" run "$HOME/work/proj/sub" -p hi
t13() { [[ $line == "OMPH_PROFILES=acme,sales OMPH_TEST_SECRET=s3cret OMP_PROFILE= ARGS=--config "* ]] \
  && last_log | grep -q '^OMPH_PROFILES=base OMPH_TEST_SECRET= '; }
check t13
mv -f "$P/acme/env.bak" "$P/acme/env"

echo "passed: $pass  failed: $fail"
[ $fail -eq 0 ]
