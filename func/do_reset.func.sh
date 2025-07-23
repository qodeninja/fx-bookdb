do_reset(){
  local msg;
  identify;

  # Determine the message and confirmation based on the reset type
  if [[ "${SOFT_RESET}" -eq 0 ]]; then
    msg="[Soft Reset]. This will reset all cursors and configuration, and rebase the 'main' database.";
  else
    msg="[Hard Reset]. This will permanently delete ALL bookdb data, configuration, and the installed command associated with '${BOOK_PREF}'.";
  fi;

  if __confirm_action "${msg} Continue?"; then
    __backup_db || return 1;
    
    # --- Mutually Exclusive Logic Paths ---
    if [[ "${SOFT_RESET}" -eq 0 ]]; then
      info "Performing Soft Reset...";
      __reset_cursors;
      __reset_config_and_state;
      # A soft reset should also reset the main database to a pristine state
      do_rebase "main";
    else
      warn "Performing FULL HARD RESET for '${BOOK_PREF}'...";
      local profile_file;
      profile_file=$(__find_shell_profile);
      if [[ -n "${profile_file}" ]]; then
        __unlink_from_profile "${profile_file}";
      fi;
      __reset_deep; # This one command handles all directory removal
    fi;

    printf "\n[OKAY] Reset complete.\n" >&2;
    printf "You may need to run 'hash -r' and start a new shell session.\n" >&2;
    return 0;
  fi;
  warn "Reset cancelled.";
  return 1;
}