structure UnicodeNormalise :> UNICODE_NORMALISE = struct

  fun lookup compare table key =
      let
        fun search (lo, hi) =
            if lo >= hi then NONE
            else
              let
                val mid = lo + (hi - lo) div 2
                val (k, value) = Vector.sub (table, mid)
              in
                case compare (key, k) of
                  LESS => search (lo, mid)
                | GREATER => search (mid + 1, hi)
                | EQUAL => SOME value
              end
      in
        search (0, Vector.length table)
      end

  fun combiningClass cp =
      case lookup Int.compare UnicodeNormaliseData.classes cp of
        NONE => 0
      | SOME n => n

  (* Decode scalar values strictly. Utf8.foldl's historical decoder does not
     support supplementary characters or enforce all UTF-8 validity rules. *)
  fun foldDecoded f initial s =
      let
        val n = String.size s
        fun byte i = if i < n then Char.ord (String.sub (s, i)) else raise Chr
        fun continuation i =
            let val b = byte i
            in if b >= 128 andalso b < 192 then b - 128 else raise Chr
            end
        fun loop (i, acc) =
            if i = n then acc
            else
              let
                val b = byte i
                val (cp, len, minimum) =
                    if b < 128 then (b, 1, 0)
                    else if b >= 194 andalso b < 224 then
                      ((b - 192) * 64 + continuation (i + 1), 2, 128)
                    else if b >= 224 andalso b < 240 then
                      ((b - 224) * 4096 + continuation (i + 1) * 64
                       + continuation (i + 2), 3, 2048)
                    else if b >= 240 andalso b < 245 then
                      ((b - 240) * 262144 + continuation (i + 1) * 4096
                       + continuation (i + 2) * 64 + continuation (i + 3),
                       4, 65536)
                    else raise Chr
              in
                if cp < minimum orelse cp > 1114111
                   orelse (cp >= 55296 andalso cp <= 57343) then raise Chr
                else loop (i + len, f (cp, acc))
              end
      in
        loop (0, initial)
      end

  fun decode s = List.rev (foldDecoded (op ::) [] s)

  fun encodeOne cp =
      let val c = Char.chr
      in
        if cp < 128 then String.str (c cp)
        else if cp < 2048 then
          String.implode [c (192 + cp div 64), c (128 + cp mod 64)]
        else if cp < 65536 then
          String.implode [c (224 + cp div 4096),
                          c (128 + cp div 64 mod 64), c (128 + cp mod 64)]
        else
          String.implode [c (240 + cp div 262144),
                          c (128 + cp div 4096 mod 64),
                          c (128 + cp div 64 mod 64), c (128 + cp mod 64)]
      end

  fun encode cps = String.concat (List.map encodeOne cps)

  (* Accumulate the recursively expanded sequence in reverse order.
     Hangul syllables have algorithmic decompositions, absent from the table. *)
  fun decompose (cp, acc) =
      if cp >= 44032 andalso cp < 55204 then
        let
          val s = cp - 44032
          val l = 4352 + s div 588
          val v = 4449 + s mod 588 div 28
          val t = s mod 28
        in
          if t = 0 then v :: l :: acc else (4519 + t) :: v :: l :: acc
        end
      else
        case lookup Int.compare UnicodeNormaliseData.decompositions cp of
          NONE => cp :: acc
        | SOME parts => List.foldl decompose acc parts

  (* Stable merge sort bounds the cost of arbitrarily long combining runs.
     Equal combining classes retain their original order. *)
  fun sortMarks xs =
      let
        fun merge ([], ys, acc) = List.revAppend (acc, ys)
          | merge (xs, [], acc) = List.revAppend (acc, xs)
          | merge (xs as (x, xc) :: xt, ys as (y, yc) :: yt, acc) =
              if xc <= yc then merge (xt, ys, (x, xc) :: acc)
              else merge (xs, yt, (y, yc) :: acc)
        fun sort ([], _) = []
          | sort ([x], _) = [x]
          | sort (xs, n) =
              let val half = n div 2
              in merge (sort (List.take (xs, half), half),
                        sort (List.drop (xs, half), n - half), [])
              end
      in
        sort (xs, List.length xs)
      end

  fun order cps =
      let
        fun flush (marks, acc) =
            List.foldl (fn ((cp, _), out) => cp :: out) acc
              (sortMarks (List.rev marks))
        fun loop ([], marks, acc) = List.rev (flush (marks, acc))
          | loop (cp :: rest, marks, acc) =
              let val cc = combiningClass cp
              in
                if cc = 0 then loop (rest, [], cp :: flush (marks, acc))
                else loop (rest, (cp, cc) :: marks, acc)
              end
      in
        loop (cps, [], [])
      end

  fun pairCompare ((a, b), (c, d)) =
      case Int.compare (a, c) of
        EQUAL => Int.compare (b, d)
      | ord => ord

  fun composite (a, b) =
      if a >= 4352 andalso a < 4371 andalso b >= 4449 andalso b < 4470
      then SOME (44032 + (a - 4352) * 588 + (b - 4449) * 28)
      else if a >= 44032 andalso a < 55204 andalso (a - 44032) mod 28 = 0
              andalso b > 4519 andalso b < 4547
      then SOME (a + b - 4519)
      else lookup pairCompare UnicodeNormaliseData.compositions (a, b)

  fun compose cps =
      let
        val out = Array.array (List.length cps, 0)
        (* lastClass is the class of the last unconsumed character; a
           successful composition must not change this blocking class. *)
        fun loop ([], used, _, _) =
              List.tabulate (used, fn i => Array.sub (out, i))
          | loop (cp :: rest, used, starter, lastClass) =
              let
                val cc = combiningClass cp
                val combined =
                    if starter >= 0 andalso (lastClass = 0 orelse lastClass < cc)
                    then composite (Array.sub (out, starter), cp)
                    else NONE
              in
                case combined of
                  SOME c => (Array.update (out, starter, c);
                             loop (rest, used, starter, lastClass))
                | NONE => (Array.update (out, used, cp);
                           loop (rest, used + 1,
                                 if cc = 0 then used else starter, cc))
              end
      in
        loop (cps, 0, ~1, 0)
      end

  (* UAX #15 section 9: absent Quick_Check properties mean Yes. For NFC,
     both No and Maybe take the normalization path; a Yes result also
     requires canonical combining-class order. *)
  fun quickCheck table s =
      let
        fun rangeCompare ((cp, _), (lo, hi)) =
            if cp < lo then LESS else if cp > hi then GREATER else EQUAL
        fun step (_, (false, _)) = (false, 0)
          | step (cp, (true, lastClass)) =
              let val cc = combiningClass cp
              in
                ((cc = 0 orelse lastClass <= cc)
                 andalso (case lookup rangeCompare table (cp, cp) of
                            NONE => true | SOME () => false), cc)
              end
      in
        #1 (foldDecoded step (true, 0) s)
      end

  fun ascii s =
      let
        fun loop i = i = String.size s orelse
                     (Char.ord (String.sub (s, i)) < 128 andalso loop (i + 1))
      in loop 0
      end

  fun normalise table finish s =
      if ascii s then s
      else
        if quickCheck table s then s
        else encode (finish (order (List.rev (List.foldl decompose [] (decode s)))))

  val nfd = normalise UnicodeNormaliseData.nfdQuickCheck (fn cps => cps)
  val nfc = normalise UnicodeNormaliseData.nfcQuickCheck compose
end
