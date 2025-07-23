main(){
  local ret;
  local run_count=$(counter);
  line "$run_count";
  identify;
  options "$@";
  __apply_alias; # Call the new alias function here

  if [[ -n "$opt_quiet" ]]; then QUIET_MODE=true; fi
  if is_dev; then  imp "Dev Mode Enabled. Safety Guards Disabled!"; fi
  trace "Args: ${ARGS[*]}";

  local cmd_pre_state="${ARGS[0]}";
  LAST_CMD="$cmd_pre_state";
  case "$cmd_pre_state" in
    (rc) dev_rc; exit 0; ;;
    (help|usage) usage; exit 1; ;;
    (inspect) do_inspect; exit $?; ;;
    (install) do_install; exit $?; ;;
    (reset) do_reset; exit $?; ;;
    (checksum) dev_checksum; exit $?; ;;
    (dev_setup) do_dev_setup "${ARGS[1]}"; exit $?; ;;
  esac

  bootstrap;
  select_db;

  if [[ ! -f "${THIS_DB}" ]]; then
    if is_dev; then
      log "DEV_MODE: Auto-installing on first run.";
      do_install;
      if [[ $? -ne 0 ]]; then fatal "Initial auto-installation failed in DEV_MODE."; fi
    else
      printf "BookDB appears to be uninstalled. Run 'bookdb install' to set it up.\n" >&2;
      exit 1;
    fi
  fi

  __resolve_context || exit 1;
  __require_invincible_defaults;

  dispatch;
  return $?;
}