do_install(){
  identify;
  local profile_file;
  __setup_dirs || return 1;
  profile_file=$(__find_shell_profile);
  __setup_confirm "$profile_file" || return 1;

  # --- Installer Pattern Logic ---
  local script_path;
  script_path=$(readlink -f "${APP_BOOKDB}");
  local _cp_path="${BOOK_LIB}/${BOOK_PREF}";
  if [[ ! -f "${script_path}" ]]; then
      fatal "CRITICAL: Could not resolve path for currently executing script: ${APP_BOOKDB}.";
  fi
  trace "Installing/Updating from source: ${script_path}";
  cp -f "${script_path}" "${_cp_path}" || fatal "Failed to copy script to library: ${_cp_path}.";
  chmod +x "${_cp_path}" || fatal "Failed to set executable permissions on '${_cp_path}'.";
  # --- End Installer Pattern ---

  # Create initial 'main' base and set it as active if this is a fresh install
  if [[ ! -e "${BOOK_BASE_CURSOR}" ]]; then
      _create_base "main" || fatal "Failed to create initial 'main' database.";
      printf "%s" "main" > "${BOOK_BASE_CURSOR}" || fatal "Failed to write initial base cursor.";
  fi

  local _ln_path="${BOOK_BIN}/${BOOK_PREF}";
  if [[ ! -L "${_ln_path}" ]]; then
    trace "Creating symlink: ${_ln_path} -> ${_cp_path}";
    ln -s "${_cp_path}" "${_ln_path}" || fatal "Failed to create symlink: ${_ln_path}.";
  else
    warn "Symlink found '${_ln_path}'.";
  fi

  _get_rc_template > "$BOOK_RC" || fatal "Failed to save RC file: ${BOOK_RC}.";
  __link_to_profile "${profile_file}" "source '${BOOK_RC}' # bookdb configuration for ${BOOK_PREF}" || return 1;
  
  if is_user; then
    printf "\n[OKAY] Installation complete!\n" >&2;
    printf "Please restart your shell or run 'source %s' to use the 'bookdb' command.\n" "${profile_file}" >&2;
  else
    devlog "Dev mode installation complete.";
  fi
  return 0;
}