#!/usr/bin/env bash
#
# test_mdb_refactored.sh - A refactored, function-based smoke test for bookdb's MDB features.
#

# IMPORTANT! | You must export DEV_MODE=0 to see logger messages from BOOKDB where it 
#            | prints to STDERR. BookDB implements QUITE(2) via DEV_MODE (not opt_ flag) in MVP phase

# IMPORTANT! | You cannot use `bookdb` as an alias name, its not an alias. Its the
#            | name of the default install. Do not use BOOK_PREF to override --alias flag

#-------------------------------------------------------------------------------
#  Escape & Logging Helpers (Copied from original test_mdb.sh)
#-------------------------------------------------------------------------------

COUNTER=".count_bookdb";
counter(){ local c=$(countx --name "$COUNTER"); printf "$c"; }

counter_init(){
  [ -f "$COUNTER" ] && rm "$COUNTER" >/dev/null;
  local c=$(countx init 0 --name "$COUNTER");
}

counter_inc(){ local c=$(countx 1 --name "$COUNTER"); printf "$c"; }


_test_num=0;

_increment(){
  local new_sum inc;
  inc=1;
  new_sum=$(( _test_num + inc ));
  _test_num=$new_sum;
}

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
    stderr "${purple}\n ========================= $1 (step $c) ============================= \n";

  }


# --- Setup Global Variables (Copied from original test_mdb.sh) ---

  set -e # Exit immediately on error
  rm -rf "./tmp"; # Ensure clean slate for tests
  BOOKDB_SCRIPT="./bookdb"; # Assumes bookdb is in the same directory
  mkdir -p "./tmp" > /dev/null;
  readonly TEST_HOME="./tmp/.test_bookdb_env"; # Isolated HOME for testing
  readonly BOOK_TEST_BASE="test";

  USE_STDOUTT=1
  STDOUT_PRINTER="--printer stdoutt"

# --- Simple Logger (Copied from original test_mdb.sh) ---

_ok()   { okay "  [OK] $1";  }
_fail() { error "  [FAIL] $1 " ; }

# --- Simple Assertion (Copied from original test_mdb.sh) ---
assert_contains() {
  local output="$1"
  local pattern="$2"
  local message="$3"
  if echo "${output}" | grep -q -- "${pattern}"; then
      _ok "$message"
  else
      _fail "Assertion failed: Output did not contain the required data ('${pattern}'). Output was:\n${output}"
      return 1 # Indicate failure
  fi
}

run_with_dev_mode() {
  local bookdb_script_or_alias="$1"; # This is the actual script/alias to run (e.g., "./bookdb" or "chickendb")
  shift; # Remove it from "$@"
  local bookdb_command_args=("$@"); # Capture the rest of the arguments (e.g., "noop", "--printer stdoutt")

  # Construct the command to be executed
  local full_command=("${bookdb_script_or_alias}" "${bookdb_command_args[@]}");

  info "DEBUG: Running command: env HOME=\"${TEST_HOME}\" TEST_MODE=0 DEV_MODE=0 ${full_command[*]}" >&2; # Print to stderr for debugging
  done_step;
  env HOME="${TEST_HOME}" TEST_MODE=0 DEV_MODE=0 "${full_command[@]}"
}

test_runner(){
  :
}

#-------------------------------------------------------------------------------
#  Test Functions (Refactored from original main function)
#-------------------------------------------------------------------------------

test_setup_and_cleanup() {
    counter_init;
    step "PHASE 0: CLEANUP & SETUP (QUITE:$QUIET_MODE)"
    # Ensure a clean test environment every time
    rm -rf "./tmp";
    mkdir -p "./tmp" > /dev/null;
    export HOME="${TEST_HOME}";
    mkdir -p "${TEST_HOME}"
    touch "${TEST_HOME}/.bashrc"
    info "DEBUG: Current working directory: $(pwd)";
    info "DEBUG: Contents of TEST_HOME (${TEST_HOME}):";
    ls -la "${TEST_HOME}" >&2;
    info "DEBUG: Contents of TEST_HOME/.local: ";
    ls -la "${TEST_HOME}/.local" >&2;
    _ok "Test environment created at ${TEST_HOME}"
    done_step;
}

test_installation() {
    step "PHASE 1: INSTALLATION"
    run_with_dev_mode "${BOOKDB_SCRIPT}" install -y $STDOUT_PRINTER;
    done_step;
    _ok "bookdb installed successfully"
}

test_base_creation_and_selection() {
    step "PHASE 2: BASE CREATION & SELECTION"
    run_with_dev_mode "${BOOKDB_SCRIPT}" new base --ns work $STDOUT_PRINTER;
    done_step;
    _ok "Created new base 'work'"

    run_with_dev_mode "${BOOKDB_SCRIPT}" select work $STDOUT_PRINTER;
    done_step;
    _ok "Selected 'work' as active base"

    local base_output=$(run_with_dev_mode "${BOOKDB_SCRIPT}" base)
    assert_contains "$base_output" "work" "Verified active base is 'work'"
}

test_crud_in_custom_base() {
    step "PHASE 3: CRUD IN CUSTOM BASE"
    run_with_dev_mode "${BOOKDB_SCRIPT}" new project --ns tickets $STDOUT_PRINTER;
    done_step;
    _ok "Created project 'tickets' in 'work' base"

    run_with_dev_mode "${BOOKDB_SCRIPT}" setv TICKET-123="Fix the login button" @tickets.VAR.MAIN $STDOUT_PRINTER >/dev/null
    done_step;
    _ok "Set a value in tickets.VAR.MAIN"

    local ticket_val=$(run_with_dev_mode "${BOOKDB_SCRIPT}" getv TICKET-123)
    assert_contains "$ticket_val" "Fix the login button" "Verified value in 'work' base"
    done_step;
}

test_on_the_fly_base_context_syntax() {
    step "PHASE 4: ON-THE-FLY BASE@CONTEXT SYNTAX"
    run_with_dev_mode "${BOOKDB_SCRIPT}" setv PERSONAL_NOTE="Buy milk" main@GLOBAL.VAR.MAIN $STDOUT_PRINTER >/dev/null;
    done_step;
    _ok "Set a value in 'main' base using base@context syntax"

    # After the above command, the active base is now 'main' and context is 'GLOBAL.VAR.MAIN'
    # Select 'main' base to retrieve the value
    run_with_dev_mode "${BOOKDB_SCRIPT}" select main >/dev/null;
    done_step;
    _ok "Selected 'main' as active base to retrieve value"

    local personal_note=$(run_with_dev_mode "${BOOKDB_SCRIPT}" getv PERSONAL_NOTE)
    done_step;
    assert_contains "$personal_note" "Buy milk" "Verified value retrieved from 'main' base"

    # bookdb's 'cursor' command normally prints to stderr.
    # With $STDOUT_PRINTER set, it redirects to stdout for test capture.
    local cursor_output=$(run_with_dev_mode "${BOOKDB_SCRIPT}" cursor $STDOUT_PRINTER)
    done_step;
    assert_contains "$cursor_output" "main@GLOBAL.VAR.MAIN" "Verified cursor was persisted to 'main'"
}

test_listing_and_backup() {
    step "PHASE 5: LISTING & BACKUP"
    # Select 'work' base again to test the ls output formatting
    run_with_dev_mode "${BOOKDB_SCRIPT}" select work >/dev/null;
    done_step;

    # bookdb's 'ls bases' command normally prints to stderr.
    # With $STDOUT_PRINTER set, it redirects to stdout for test capture.
    local ls_bases_output=$(run_with_dev_mode "${BOOKDB_SCRIPT}" ls bases $STDOUT_PRINTER)
    assert_contains "$ls_bases_output" "* work" "ls bases correctly shows 'work' as active"
    assert_contains "$ls_bases_output" "main" "ls bases correctly shows 'main' as inactive"

    run_with_dev_mode "${BOOKDB_SCRIPT}" backup --all $STDOUT_PRINTER >/dev/null
    done_step;
    _ok "Full backup (--all) command executed";

    # A simple check to see if a backup file was created
    if ! ls -t "${TEST_HOME}"/bookdb_backup_*.tar.gz 1> /dev/null 2>&1; then
        _fail "Backup file was not created in ${TEST_HOME}"
        return 1 # Indicate failure
    fi
    _ok "Backup file was created"
}

test_reset_bookdb() {
    step "PHASE 6: CLEANUP"
    run_with_dev_mode "${BOOKDB_SCRIPT}" reset -y $STDOUT_PRINTER;
    _ok "bookdb reset successfully"

    if [ -d "${TEST_HOME}/.local/data/fx/bookdb" ]; then
        _fail "bookdb DATA directory still exists after reset"
        return 1 # Indicate failure
    fi
    _ok "bookdb DATA directory was removed"

    if [ -d "${TEST_HOME}/.local/state/fx/bookdb" ]; then
        _fail "bookdb STATE directory still exists after reset"
        return 1 # Indicate failure
    fi
    _ok "bookdb STATE directory was removed"

    rm -rf "${TEST_HOME}"
    _ok "Test environment cleaned up"
}

test_aliased_installation() {
    step "PHASE 7: Installing aliased version"
    #we need setup again due to prior rm
    mkdir -p "${TEST_HOME}"
    touch "${TEST_HOME}/.bashrc"

    local ALIAS_NAME="chickendb";
    local ALIAS_SCRIPT="${TEST_HOME}/.local/bin/fx/${ALIAS_NAME}";
    local ALIAS_DATA_DIR="${TEST_HOME}/.local/data/fx/${ALIAS_NAME}";

    run_with_dev_mode "${BOOKDB_SCRIPT}" install -y --alias "${ALIAS_NAME}" $STDOUT_PRINTER;
    done_step;
    _ok "Aliased script '${ALIAS_SCRIPT}' created."
    if [[ ! -f "${ALIAS_SCRIPT}" ]]; then
        _fail "Aliased script '${ALIAS_SCRIPT}' was not created."
        return 1 # Indicate failure
    fi
}

test_aliased_command_independence() {
    step "PHASE 8: Verifying aliased command independence"
    local ALIAS_NAME="chickendb";
    local ALIAS_SCRIPT="${TEST_HOME}/.local/bin/fx/${ALIAS_NAME}";

    local alias_output=$(        env HOME="${TEST_HOME}" TEST_MODE=0 DEV_MODE=0 "${ALIAS_SCRIPT}" setv ALIAS_TEST_KEY="Hello from alias" &&         step "PHASE 8B" && done_step &&          env HOME="${TEST_HOME}" TEST_MODE=0 DEV_MODE=0 "${ALIAS_SCRIPT}" getv ALIAS_TEST_KEY    );    done_step;    assert_contains "${alias_output}" "Hello from alias" "Aliased command set/get value correctly."
}

test_original_bookdb_unaffected() {
    step "PHASE 9: Verifying original bookdb is unaffected"
    local original_output=$(run_with_dev_mode "${BOOKDB_SCRIPT}" getv ALIAS_TEST_KEY $STDOUT_PRINTER);
    done_step;

    if [[ -n "${original_output}" && "${original_output}" != *"not found"* ]]; then
        _fail "Original bookdb was affected by aliased install. Output: ${original_output}"
        return 1 # Indicate failure
    fi
    _ok "Original bookdb unaffected by aliased install."
}

test_reset_aliased_version() {
  step "PHASE 10: Reset aliased version"
  local ALIAS_NAME="chickendb";
  local ALIAS_SCRIPT="${TEST_HOME}/.local/bin/fx/${ALIAS_NAME}";
  local ALIAS_DATA_DIR="${TEST_HOME}/.local/data/fx/${ALIAS_NAME}";

  run_with_dev_mode "${BOOKDB_SCRIPT}" reset -y --alias "${ALIAS_NAME}" $STDOUT_PRINTER;
  done_step;

  _ok "Aliased script '${ALIAS_SCRIPT}' removed."
  if [[ -f "${ALIAS_SCRIPT}" ]]; then
      _fail "Aliased script '${ALIAS_SCRIPT}' was not removed after reset."
      return 1 # Indicate failure
  fi
  if [[ -d "${ALIAS_DATA_DIR}" ]]; then
      _fail "Aliased data directory '${ALIAS_DATA_DIR}' was not removed after reset."
      return 1 # Indicate failure
  fi
  _ok "Aliased data directory '${ALIAS_DATA_DIR}' removed."
}

test_noop(){
  step "PHASE 0: Baseline Noop Test";
  run_with_dev_mode "${BOOKDB_SCRIPT}" noop $STDOUT_PRINTER;
  done_step;
}

test_alias_guards() {
    step "PHASE 10B: Verifying alias command guards"
    local ALIAS_NAME="chickendb";
    local ALIAS_SCRIPT="${TEST_HOME}/.local/bin/fx/${ALIAS_NAME}";

    # Re-install the alias to test the guards
    run_with_dev_mode "${BOOKDB_SCRIPT}" install -y --alias "${ALIAS_NAME}" $STDOUT_PRINTER;

    # Test that `install` is blocked
    local install_output=$(run_with_dev_mode "$ALIAS_NAME" "${ALIAS_SCRIPT}" install 2>&1 || true)
    assert_contains "$install_output" "Cannot run 'install' from an aliased version" "Verified 'install' is blocked in alias mode"

    # Test that `reset` is blocked
    local reset_output=$(run_with_dev_mode "$ALIAS_NAME" "${ALIAS_SCRIPT}" reset 2>&1 || true)
    assert_contains "$reset_output" "Cannot run 'reset' from an aliased version" "Verified 'reset' is blocked in alias mode"

    # Test that `checksum` is blocked
    local checksum_output=$(run_with_dev_mode "$ALIAS_NAME" "${ALIAS_SCRIPT}" checksum 2>&1 || true)
    assert_contains "$checksum_output" "Checksum verification is not applicable" "Verified 'checksum' is blocked in alias mode"

    # Test that creating an alias from an alias is blocked
    local nested_alias_output=$(run_with_dev_mode "$ALIAS_NAME" "${ALIAS_SCRIPT}" install --alias newalias 2>&1 || true)
    assert_contains "$nested_alias_output" "Cannot create a new alias" "Verified nested alias creation is blocked"

    # Clean up the alias for the next test
    run_with_dev_mode "${BOOKDB_SCRIPT}" reset -y --alias "${ALIAS_NAME}" $STDOUT_PRINTER >/dev/null;
}

final_sanity_check_original_bookdb() {
    step "PHASE 11: FINAL SANITY CHECK OF ORIGINAL BOOKDB"
    # Re-run a simple command on original bookdb to ensure it's still functional
    # bookdb's 'status' command normally prints to stderr.
    # With $STDOUT_PRINTER set, it redirects to stdout for test capture.
    local final_original_output=$(run_with_dev_mode "${BOOKDB_SCRIPT}" status main $STDOUT_PRINTER);
    done_step;
    assert_contains "${final_original_output}" "Active Database: main" "Original bookdb still functional after aliased operations."
}

#-------------------------------------------------------------------------------
#  Main Test Runner
#-------------------------------------------------------------------------------

run_all_tests() {
    test_noop
    test_setup_and_cleanup
    test_installation
    test_base_creation_and_selection
    test_crud_in_custom_base
    test_on_the_fly_base_context_syntax
    test_listing_and_backup
    test_reset_bookdb

    step "✅ MDB SMOKE TEST PASSED";
    done_step;

    # Aliasing tests
    test_aliased_installation
    test_aliased_command_independence
    test_original_bookdb_unaffected
    test_reset_aliased_version
    # test_alias_guards # Add this new test function here
    final_sanity_check_original_bookdb

    step "✅ ALIASING SMOKE TEST PASSED";
    done_step;

    _ok "All MDB smoke tests completed successfully!"
}

# Execute all tests
run_all_tests "$@";
