#!/usr/bin/env bash

#
# test_streams
# this is a private test file experimenting with Bash 5 features







is_array(){
	# 0 is an array
	# 1 is something else (2 doesnt make sense here)
	identify;
	local arr="$1" arr_info;
	if ! arr_info=$(declare -p "$var_name" 2>/dev/null); then
		return 2 # Not found
	fi
	if [[ ! "$arr_info" =~ ^declare\ -[aA] ]]; then
		return 2 # Not an array
	fi
	return 0;
}

is_empty_array(){
	identify;
	local this="$1" len ret=1;
	len=$(array_len "$this");ret=$?; #has implied is_array call
	[[ "$len" -eq 0 ]] && return 0;
	return $ret;
}

array_len(){
	identify;
	local this="$1";
	if is_array "${this}"; then
		len="${#${!var_name}[@]}";
		echo "$len";
		return 0;
	else
		return 2; # its not even an array champ.
	fi
}








# sub_list_bases(){
#   local buffer=();
#   for db_file in "${BOOK_DATA}"/*.sqlite; do
#     if [[ -f "$db_file" ]]; then # Check if glob found a file
#       item=$(basename "${db_file%.sqlite}");
#       buffer+=("$item")
#     fi
#   done

#   dump_buffer "$buffer[@]}";
#   return 0;
# }


# sub_list_bases(){
#   local arr col opt_dump_col="$orange";
#   arr=("${@}"); len=${#arr[@]}
#   if [ $len -gt 0 ]; then
#     for i in ${!arr[@]}; do
#       this="${arr[$i]}"
#       [ -n "$this" ] && printf -v "out" "$opt_dump_col(%d) %s\n$x" "$i" "$this"
#       printf "$out"
#     done
#   fi
#}

sub_dump_bases(){
	local bases len;
	bases=$(__get_bases_array);
	len=$(array_len "${bases[@]}");
	dump_buffer "${bases[@]}";
	#__get_bases_array;
	fruits=( apple cherry banana );
	printf "%s\n" "${fruits[@]}" | noop_filter;
	echo "$len";
}

__get_bases_array(){
	local arr;
	#BOOK_DATA must be defined. otherwise error.
	#arr=("${BOOK_DATA}"/*.sqlite );
	array_from_glob "${BOOK_DATA}/*.sqlite" arr;	
	echo "${arr[@]}"; 
}

# mapfile -t my_array < <(__get_bases_pipe_ready)
# my_scalar_var=$(__get_bases_pipe_ready) <-- wrong


# a filter that only passes values through it (testing)
noop_filter() {
	while IFS= read -r line; do
		echo "cat: $line";
	done
}

noop_cat_filter(){
	info "catting";
	cat
}

array_from_glob() {
  local glob_pattern="$1"        # The glob pattern as a string
  local -n target_array="$2"     # Nameref to the array to be populated

  # Use the glob pattern directly to populate the array
  target_array=( $glob_pattern ) # Shell will expand $glob_pattern here
}
# usage:
# declare -a my_array
# array_from_glob "${BOOK_DATA}/*.sqlite" my_array


pipe_array() {
  local -n arr_ref="$1" # Use nameref to alias the passed array name

  # Check if the nameref successfully points to an array
  # This provides robustness against non-existent or non-array inputs.
  # declare -p returns non-zero if variable doesn't exist or isn't array/scalar.
  # We check for -a (indexed) or -A (associative) in the declare -p output.
  if ! declare -p "${arr_ref@Q}" &>/dev/null || \
     [[ ! "$(declare -p "${arr_ref@Q}" 2>/dev/null)" =~ ^declare\ -[aA] ]]; then
    error "Error: pipe_array expects an array name as its argument." >&2
    return 1; # Indicate error
  fi

  # Print each element to stdout, followed by a newline.
  # This is the core of piping out the array.
  printf "%s\n" "${arr_ref[@]}"
}

# get_sqlite_files() {
#   local dir_path="$1";
#   local -n output_array_ref="$2"; # Nameref for the output array

#   output_array_ref=( "${dir_path}"/*.sqlite )
# }

# declare -a my_db_files # Declare an array to receive results
# get_sqlite_files "$BOOK_DATA" my_db_files



# 1. Basic: Each line of input becomes an argument to a command.
echo "--- Basic xargs (default behavior) ---"
printf "%s\n" "file1.txt" "file2.txt" | xargs ls -l
# xargs will run: ls -l file1.txt file2.txt

# 2. -n: Pass at most N arguments per command line.
echo -e "\n--- xargs -n (pass N args per command) ---"
printf "%s\n" "argA" "argB" "argC" "argD" "argE" | xargs -n 2 echo "Processing:"
# xargs will run:
# echo "Processing:" argA argB
# echo "Processing:" argC argD
# echo "Processing:" argE

# 3. -I {}: Replace occurrence of {} with the input line.
#    Useful for commands that don't take arguments at the end (like `basename`)
echo -e "\n--- xargs -I {} (replace specific string) ---"
printf "%s\n" "/path/to/file1.txt" "/another/path/file2.log" | xargs -n 1 -I {} basename {}
# xargs will run:
# basename /path/to/file1.txt
# basename /another/path/file2.log

# 4. -d: Custom delimiter (e.g., null-byte for `find -print0`).
echo -e "\n--- xargs -d (custom delimiter) ---"
printf "%s\0%s\0" "item with spaces" "another item" | xargs -0 -n 1 echo "Found:"
# xargs -0 is shorthand for xargs -d '\0'
# xargs will run:
# echo "Found:" "item with spaces"
# echo "Found:" "another item"

# 5. -P: Run N processes in parallel.
echo -e "\n--- xargs -P (parallel execution) ---"
# Simulate a long-running task
long_task() {
  echo "Starting $1..."
  sleep 1 # Simulate work
  echo "Finished $1."
}
export -f long_task # Export function for xargs
printf "%s\n" "Job1" "Job2" "Job3" "Job4" | xargs -n 1 -P 2 bash -c 'long_task "$0"'
# xargs will run 2 jobs concurrently, then 2 more, etc.

# 6. -r: Don't run command if input is empty (GNU xargs extension).
echo -e "\n--- xargs -r (no execution on empty input) ---"
# An empty pipe
printf "" | xargs -r echo "This message won't appear"
# If -r was not used, "This message won't appear" would print.


# Producer of file paths (one per line)
generate_paths() {
  printf "%s\n" "/tmp/test_xargs/file1.txt" "/tmp/test_xargs/subdir/file2.txt"
}

echo "--- Correct xargs -I for basename ---"
# -I {} implies -n 1. No need to specify -n 1 explicitly.
generate_paths | xargs -I {} basename {}

echo -e "\n--- Alternative: No xargs, just pipe to while read ---"
# For simple cases like basename, a while read loop is often clearer and doesn't
# involve an external 'xargs' process.
generate_paths | while IFS= read -r filepath; do
  basename "$filepath"
done
