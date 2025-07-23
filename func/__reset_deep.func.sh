__reset_deep(){
  trace "Performing deep clean of all XDG directories...";
  # The BOOK_PREF is already incorporated into BOOK_DATA, BOOK_ETC, BOOK_STATE
  # so we only need to explicitly use it for BOOK_LIB and BOOK_BIN.
  rm -rf "${BOOK_DATA}" "${BOOK_ETC}" "${BOOK_STATE}" "${BOOK_LIB}/${BOOK_PREF}" "${BOOK_BIN}/${BOOK_PREF}"; 
}