options(){
  # Initialize all opt_ variables
  opt_quiet=; opt_projdb=; opt_keydb=; opt_ns=; opt_yes=; opt_all=; opt_alias=;
  opt_context_chain=; opt_chain_mode=; opt_base_override=;
  opt_printer_test=;
  identify;
  local -a remaining_args=();

  # --- First Pass: Scan for and correctly parse the context chain ---
  for arg in "$@"; do
    if [[ "$arg" == *@* ]] || [[ "$arg" == *%* ]]; then
      # This is a context argument, do not add it to remaining_args
      if [[ "$arg" == *@* ]]; then
        opt_chain_mode="@";
        opt_base_override="${arg%%@*}";
        opt_context_chain="${arg#*@}"; # The part AFTER the @
      else # This handles %
        opt_chain_mode="%";
        opt_base_override="${arg%%\%*}";
        opt_context_chain="${arg#*\%}"; # The part AFTER the %
      fi
    else
      remaining_args+=("$arg");
    fi
  done;

  # --- Second Pass: Parse standard flags from the arguments that were NOT context chains ---
  local -a final_args=();
  local i=0;
  while [[ $i -lt ${#remaining_args[@]} ]]; do
    local arg="${remaining_args[$i]}";
    case "$arg" in
      (-a|--all) opt_all=0; ;;
      (-q|--quiet) opt_quiet=0; ;;
      (-y|--yes) opt_yes=0; ;;
      (--soft) SOFT_MODE=0; ;;
      (-p|--projdb) opt_projdb="${remaining_args[$((i+1))]}"; i=$((i+1)); ;;
      (-k|--keydb) opt_keydb="${remaining_args[$((i+1))]}"; i=$((i+1)); ;;
      (--ns) opt_ns="${remaining_args[$((i+1))]}"; i=$((i+1)); ;;
      (--alias) opt_alias="${remaining_args[$((i+1))]}"; i=$((i+1)); ;;
      (--pr*)
        if [[ "${remaining_args[$((i+1))]}" == "stdoutt" ]]; then
          opt_printer_test=1; i=$((i+1));
        else
          error "Invalid value for --printer: ${remaining_args[$((i+1))]}"; usage;
        fi
        ;;
      (--) i=$((i+1)); final_args+=("${remaining_args[@]:$i}"); break; ;;
      (-*) error "Unknown option: $arg"; usage; ;;
      (*) final_args+=("$arg"); ;;
    esac;
    i=$((i+1));
  done;

  ARGS=("${final_args[@]}");
  return 0;
}