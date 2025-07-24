#!/usr/bin/env bash
#
# testmdb - A simple "happy path" smoke test for bookdb's MDB features.
#

#-------------------------------------------------------------------------------
#  Escape
#-------------------------------------------------------------------------------

COUNTER=".count_bookdb";
counter(){ local c=$(countx --name "$COUNTER"); printf "$c"; }

counter_init(){ 
  [ -f "$COUNTER" ] && rm "$COUNTER" >/dev/null;  
  local c=$(countx init 0 --name "$COUNTER");  
}

counter_inc(){ local c=$(countx 1 --name "$COUNTER"); printf "$c"; }

# Define some colors for clear output headers
  readonly  red2=$'\x1B[38;5;197m';
  readonly  red=$'\x1B[38;5;9m';
  readonly  deep=$'\x1B[38;5;61m';
  readonly  deep_green=$'\x1B[38;5;60m';
  readonly  orange=$'\x1B[38;5;214m';
  readonly  yellow=$'\x1B[33m';  

  readonly  green2=$'\x1B[32m';
  readonly  green=$'\x1B[38;5;10m';
  readonly  blue=$'\x1B[36m';
  readonly  blue2=$'\x1B[38;5;39m';
  readonly  cyan=$'\x1B[38;5;14m';
  readonly  magenta=$'\x1B[35m';  

  readonly  purple=$'\x1B[38;5;213m';
  readonly  purple2=$'\x1B[38;5;141m';
  readonly  white=$'\x1B[38;5;247m';
  readonly  white2=$'\x1B[38;5;15m';
  readonly  grey=$'\x1B[38;5;242m';
  readonly  grey2=$'\x1B[38;5;240m';
  readonly  grey3=$'\x1B[38;5;237m';
  readonly  xx=$'\x1B[0m'; 

  readonly LINE="$(printf '%.0s-' {1..54})";



  fatal(){  stderr "${red}${*}";exit 1; }
  error(){ stderr "${red}${*}"; }

  warn(){  stderr  "${orange}${*}"; }
  okay(){  stderr  "${green}${*}"; }
  info(){  stderr  "${blue}${*}"; }

  log(){ stderr "${white2}${*}"; }
  trace(){ stderr "${grey2}${*}"; }
  magic(){  stderr "${purple}${*}"; }


  stderr(){ [ -z "$QUIET_MODE" ] &&  printf "%b" "${1}${xx}\n" 1>&2; }

  done_step(){
    echo;echo;echo;echo;
  }

  step(){ 
    local c;
    c=$(counter_inc);
    done_step;
    stderr "${purple}\n =========== $1 (step $c) ========== \n"; 
    
  }


# --- Setup ---
set -e # Exit immediately on error
 BOOKDB_SCRIPT="./bookdb"; # Assumes bookdb is in the same directory
readonly TEST_HOME="${HOME}/.test_bookdb_env"; # Isolated HOME for testing

USE_STDOUTT=1
STDOUT_PRINTER=


# --- Simple Logger ---

_ok()   { okay "  [OK] $1";  }
_fail() { error "  [FAIL] $1 " ; exit 1; }

# --- Simple Assertion ---
assert_contains() {
  local output="$1"
  local pattern="$2"
  local message="$3"
  if echo "${output}" | grep -q -- "${pattern}"; then
      _ok "$message"
  else
      _fail "Assertion failed: Output did not contain the required data ('${pattern}'). Output was:\n${output}"
  fi
}

run_with_dev_mode() {
  # The "$@" passes along all arguments perfectly
  env HOME="${TEST_HOME}" DEV_MODE=0 "$@"
}

# --- Main Test Execution ---
main(){

    if [ -n "USE_STDOUTT" ]; then
      STDOUT_PRINTER="--printer stdoutt";
    fi

    counter_init;
    step "PHASE 0: CLEANUP & SETUP"
    export HOME="${TEST_HOME}";
    rm -rf "${TEST_HOME}"
    mkdir -p "${TEST_HOME}"
    touch "${TEST_HOME}/.bashrc"
    _ok "Test environment created at ${TEST_HOME}"
    done_step;



    step "PHASE 1: INSTALLATION"
    run_with_dev_mode "${BOOKDB_SCRIPT}" install -y $STDOUT_PRINTER >/dev/null;
    done_step;
    _ok "bookdb installed successfully"
    

    step "PHASE 2: BASE CREATION & SELECTION"
    run_with_dev_mode "${BOOKDB_SCRIPT}" new base --ns work $STDOUT_PRINTER >/dev/null;
    done_step;
    _ok "Created new base 'work'"


    run_with_dev_mode "${BOOKDB_SCRIPT}" select work $STDOUT_PRINTER >/dev/null;
    done_step;
    _ok "Selected 'work' as active base"

    
    local base_output=$(run_with_dev_mode "${BOOKDB_SCRIPT}" base)
    assert_contains "$base_output" "work" "Verified active base is 'work'"

    step "PHASE 3: CRUD IN CUSTOM BASE"
    run_with_dev_mode "${BOOKDB_SCRIPT}" new project --ns tickets $STDOUT_PRINTER >/dev/null;
    done_step;
    _ok "Created project 'tickets' in 'work' base"


    run_with_dev_mode "${BOOKDB_SCRIPT}" setv TICKET-123="Fix the login button" @tickets.VAR.MAIN $STDOUT_PRINTER >/dev/null
    done_step;
    _ok "Set a value in tickets.VAR.MAIN"


    local ticket_val=$(run_with_dev_mode "${BOOKDB_SCRIPT}" getv TICKET-123)
    assert_contains "$ticket_val" "Fix the login button" "Verified value in 'work' base"
    done_step;

    step "PHASE 4: ON-THE-FLY BASE@CONTEXT SYNTAX"
    run_with_dev_mode "${BOOKDB_SCRIPT}" setv PERSONAL_NOTE="Buy milk" main@GLOBAL.VAR.MAIN $STDOUT_PRINTER >/dev/null;
    done_step;
    _ok "Set a value in 'main' base using base@context syntax"


    # After the above command, the active base is now 'main' and context is 'GLOBAL.VAR.MAIN'
    local personal_note=$(run_with_dev_mode "${BOOKDB_SCRIPT}" getv PERSONAL_NOTE)
    done_step;
    assert_contains "$personal_note" "Buy milk" "Verified value retrieved from 'main' base"


    local cursor_output=$(run_with_dev_mode "${BOOKDB_SCRIPT}" cursor $STDOUT_PRINTER)
    done_step;
    assert_contains "$cursor_output" "main@GLOBAL.VAR.MAIN" "Verified cursor was persisted to 'main'"


    step "PHASE 5: LISTING & BACKUP"
    # Select 'work' base again to test the ls output formatting
    run_with_dev_mode "${BOOKDB_SCRIPT}" select work >/dev/null;
    done_step;

    local ls_bases_output=$(run_with_dev_mode "${BOOKDB_SCRIPT}" ls bases $STDOUT_PRINTER)
    assert_contains "$ls_bases_output" "\* work" "ls bases correctly shows 'work' as active"
    assert_contains "$ls_bases_output" "main" "ls bases correctly shows 'main' as inactive"

    run_with_dev_mode "${BOOKDB_SCRIPT}" backup --all $STDOUT_PRINTER >/dev/null
    done_step;
    _ok "Full backup (--all) command executed";
  
    # A simple check to see if a backup file was created
    if ! ls -t "${TEST_HOME}"/bookdb_backup_*.tar.gz 1> /dev/null 2>&1; then
        _fail "Backup file was not created in ${TEST_HOME}"
    fi
    _ok "Backup file was created"


    step "PHASE 6: CLEANUP"
    run_with_dev_mode "${BOOKDB_SCRIPT}" reset -y $STDOUT_PRINTER >/dev/null
    _ok "bookdb reset successfully"

    if [ -d "${TEST_HOME}/.local/data/fx/bookdb" ]; then
        _fail "bookdb DATA directory still exists after reset"
    fi
    _ok "bookdb DATA directory was removed"
    
    if [ -d "${TEST_HOME}/.local/state/fx/bookdb" ]; then
        _fail "bookdb STATE directory still exists after reset"
    fi
    _ok "bookdb STATE directory was removed"

    rm -rf "${TEST_HOME}"
    _ok "Test environment cleaned up"

    step "✅ MDB SMOKE TEST PASSED";
    done_step;

    step "PHASE 7: ALIASING INSTALLATION & RESET"
    local ALIAS_NAME="bookdb-v2";
    local ALIAS_SCRIPT="${TEST_HOME}/.local/bin/fx/${ALIAS_NAME}";
    local ALIAS_DATA_DIR="${TEST_HOME}/.local/data/fx/${ALIAS_NAME}";

    # Install with alias
    step "Installing aliased version: ${ALIAS_NAME}"
    run_with_dev_mode "${BOOKDB_SCRIPT}" install -y --alias "${ALIAS_NAME}" $STDOUT_PRINTER >/dev/null;
    _ok "Aliased script '${ALIAS_SCRIPT}' created."
    if [[ ! -f "${ALIAS_SCRIPT}" ]]; then
        _fail "Aliased script '${ALIAS_SCRIPT}' was not created."
    fi
    done_step;

    # Verify aliased command works independently
    step "Verifying aliased command independence"
    local alias_output=$(run_with_dev_mode "${ALIAS_SCRIPT}" setv ALIAS_TEST_KEY="Hello from alias" && run_with_dev_mode "${ALIAS_SCRIPT}" getv ALIAS_TEST_KEY);
    assert_contains "${alias_output}" "Hello from alias" "Aliased command set/get value correctly."
    done_step;

    # Verify original bookdb is unaffected
    step "Verifying original bookdb is unaffected"
    local original_output=$(run_with_dev_mode "${BOOKDB_SCRIPT}" getv ALIAS_TEST_KEY 2>&1 || echo ""); # Expecting empty or error
    if [[ -n "${original_output}" && "${original_output}" != *"not found"* ]]; then
        _fail "Original bookdb was affected by aliased install. Output: ${original_output}"
    fi
    _ok "Original bookdb unaffected by aliased install."
    done_step;

    # Reset aliased version
    step "Resetting aliased version: ${ALIAS_NAME}"
    run_with_dev_mode "${BOOKDB_SCRIPT}" reset -y --alias "${ALIAS_NAME}" $STDOUT_PRINTER >/dev/null;
    _ok "Aliased script '${ALIAS_SCRIPT}' removed."
    if [[ -f "${ALIAS_SCRIPT}" ]]; then
        _fail "Aliased script '${ALIAS_SCRIPT}' was not removed after reset."
    fi
    if [[ -d "${ALIAS_DATA_DIR}" ]]; then
        _fail "Aliased data directory '${ALIAS_DATA_DIR}' was not removed after reset."
    fi
    _ok "Aliased data directory '${ALIAS_DATA_DIR}' removed."
    done_step;

    step "PHASE 8: FINAL SANITY CHECK OF ORIGINAL BOOKDB"
    # Re-run a simple command on original bookdb to ensure it's still functional
    local final_original_output=$(run_with_dev_mode "${BOOKDB_SCRIPT}" status);
    assert_contains "${final_original_output}" "Active Database: main" "Original bookdb still functional after aliased operations."
    done_step;

    step "✅ ALIASING SMOKE TEST PASSED";
    done_step;
}

main "$@";