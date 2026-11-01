fun assert message b = if b then () else raise Fail message
fun check (input, nfc, nfd) =
    (assert "NFC regression" (UnicodeNormalise.nfc input = nfc);
     assert "NFD regression" (UnicodeNormalise.nfd input = nfd))

val () = List.app check
    [("", "", ""), ("ASCII\000", "ASCII\000", "ASCII\000"),
     ("a\204\138", "\195\165", "a\204\138"),
     ("\226\132\171", "\195\133", "A\204\138"),
     ("\239\172\129", "\239\172\129", "\239\172\129"),
     ("\234\176\129", "\234\176\129", "\225\132\128\225\133\161\225\134\168"),
     ("\240\159\152\128", "\240\159\152\128", "\240\159\152\128")]

fun rejects f s = ((f s; false) handle Chr => true)
val () = List.app
    (fn s => assert "malformed UTF-8 accepted"
                 (rejects UnicodeNormalise.nfc s andalso rejects UnicodeNormalise.nfd s))
    ["\128", "\192\128", "\193\191", "\194", "\194A",
     "\224\128\128", "\237\160\128", "\239\191",
     "\240\128\128\128", "\244\144\128\128", "\245\128\128\128",
     "\255", "\240\159\152", "\226\130A"]

(* Decode the hexadecimal scalar lists in Unicode's NormalizationTest.txt.
   This encoder is independent of the library implementation. *)
fun utf8 cp =
    if cp < 128 then String.str (Char.chr cp)
    else
      let
        val (prefix, bits) =
            if cp < 2048 then (192, 6)
            else if cp < 65536 then (224, 12) else (240, 18)
        val divisor = if bits = 6 then 64 else if bits = 12 then 4096 else 262144
        fun tail (0, _) = []
          | tail (n, d) = Char.chr (128 + cp div d mod 64) :: tail (n - 6, d div 64)
      in
        String.implode (Char.chr (prefix + cp div divisor) :: tail (bits, divisor div 64))
      end

fun hex s =
    case StringCvt.scanString (Int.scan StringCvt.HEX) s of
      SOME n => n
    | NONE => raise Fail ("invalid scalar: " ^ s)
fun scalars s = List.map hex (String.tokens Char.isSpace s)
fun text s = String.concat (List.map utf8 (scalars s))

(* Quick_Check must account for ordering, blocking, and decomposable Maybe
   characters (UAX #15 section 9.2), including the Unicode 16 scripts. *)
val () = List.app
    (fn (input, composed, decomposed) => check (text input, text composed, text decomposed))
    [("00C5", "00C5", "0041 030A"),
     ("0315 0300", "0300 0315", "0300 0315"),
     ("0061 0301 0300", "00E1 0300", "0061 0301 0300"),
     ("0041 0305 030A", "0041 0305 030A", "0041 0305 030A"),
     ("0344", "0308 0301", "0308 0301"),
     ("16D63 16D68", "16D6A", "16D63 16D67 16D67"),
     ("113C2 113C5", "113C5 113C2", "113C2 113C2 113C2"),
     ("1611E 16123", "16126", "1611E 1611E 1611F")]

(* A failed quick check must not bypass validation of the remaining bytes. *)
val () = List.app
    (fn s => assert "invalid suffix after quick-check failure accepted"
                 (rejects UnicodeNormalise.nfc s andalso rejects UnicodeNormalise.nfd s))
    [text "0344" ^ "\128", text "16D68" ^ "\240\159\152"]

fun conformance path =
    let
      val input = TextIO.openIn path
      val seen = Array.array (1114112, false)
      fun lineTest (line, lineNo) =
          let
            val body = hd (String.fields (fn c => c = #"#") line)
            val fields = String.fields (fn c => c = #";") body
          in
            if List.all Char.isSpace (String.explode body)
               orelse String.isPrefix "@" body then false
            else
              case fields of
                a :: b :: c :: d :: e :: _ =>
                  let
                    val c1 = text a
                    val c2 = text b
                    val c3 = text c
                    val c4 = text d
                    val c5 = text e
                    fun eq name f (x, y) =
                        assert (name ^ " at line " ^ Int.toString lineNo) (f x = y)
                    val () = List.app (eq "NFC" UnicodeNormalise.nfc)
                        [(c1,c2), (c2,c2), (c3,c2), (c4,c4), (c5,c4)]
                    val () = List.app (eq "NFD" UnicodeNormalise.nfd)
                        [(c1,c3), (c2,c3), (c3,c3), (c4,c5), (c5,c5)]
                    val () = case scalars a of
                               [cp] => Array.update (seen, cp, true)
                             | _ => ()
                  in true
                  end
              | _ => raise Fail ("invalid test line " ^ Int.toString lineNo)
          end
      fun read (lineNo, count) =
          case TextIO.inputLine input of
            NONE => count
          | SOME line => read (lineNo + 1,
                               if lineTest (line, lineNo) then count + 1 else count)
      val count = (read (1, 0) handle ex => (TextIO.closeIn input; raise ex))
      val () = TextIO.closeIn input
      (* Part 1 also requires identity for every scalar absent from column 1. *)
      fun identity cp =
          if cp = 1114112 then ()
          else
            (if Array.sub (seen, cp) orelse (cp >= 55296 andalso cp <= 57343)
             then ()
             else
               let val s = utf8 cp
               in
                 assert ("identity NFC " ^ Int.toString cp) (UnicodeNormalise.nfc s = s);
                 assert ("identity NFD " ^ Int.toString cp) (UnicodeNormalise.nfd s = s)
               end;
             identity (cp + 1))
      val () = identity 0
    in
      print (Int.toString count ^ " Unicode conformance rows and remaining scalars passed\n")
    end

val () = case CommandLine.arguments () of
           [] => ()
         | [path] => conformance path
         | _ => raise Fail "usage: normalise-test.exe [NormalizationTest.txt]"
val () = print "Normalisation tests passed\n"
