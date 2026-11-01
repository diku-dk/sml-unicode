(** Unicode canonical normalisation of UTF-8 strings. *)

signature UNICODE_NORMALISE = sig
    val nfc : string -> string
    val nfd : string -> string
end

(**
[nfc s] returns the canonical composition (NFC) of the UTF-8 string s.

[nfd s] returns the canonical decomposition (NFD) of the UTF-8 string s.

Both operations use Unicode 17.0.0, preserve canonical equivalence, and
raise Chr if s is not well-formed UTF-8 (including overlong encodings,
surrogates, truncated sequences, and code points above U+10FFFF).
Unassigned code points and noncharacters are preserved. Neither operation
performs compatibility normalisation or case folding. The result is UTF-8.

See https://www.unicode.org/reports/tr15/ for the normalisation forms.
*)
