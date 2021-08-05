module G = Gobz

let ( => ) a b = (not a) || b

let ( <=> ) a b = (a && b) || ((not a) && not b)

let check_of_int =
  QCheck.Test.make ~name:"check_of_int" ~count:2000 QCheck.int (fun x ->
      G.fits_double x <=> G.is_small_int (G.of_int x))

let check_of_int32 =
  QCheck.Test.make ~name:"check_of_int32" ~count:2000 QCheck.int32 (fun x ->
      Int32.to_int x >= G.min_int && Int32.to_int x <= G.max_int && G.is_small_int (G.of_int32 x))

let check_of_int64 =
  QCheck.Test.make ~name:"check_of_int64" ~count:2000 QCheck.int64 (fun x ->
      let open Int64 in
      (x >= of_int G.min_int && x <= of_int G.max_int) <=> G.is_small_int (G.of_int64 x))

let check_of_float =
  QCheck.Test.make ~name:"check_of_float" ~count:5000 QCheck.float (fun x ->
      let z = G.of_float x in
      try
        let i = G.to_int z in
        i == int_of_float x && G.fits_double i && G.is_small_int z
      with G.Overflow -> false)

let check_of_string =
  QCheck.Test.make ~name:"check_of_string" ~count:5000 QCheck.int (fun x ->
      let z = G.of_string (Int.to_string x) in
      x = G.to_int z && G.fits_double x <=> G.is_small_int z)

let check_succ =
  QCheck.Test.make ~name:"check_succ" ~count:2000 QCheck.int (fun x ->
      let z = G.of_int x in
      let z' = G.succ z in
      try
        let x' = G.to_int z' in
        x + 1 == x'
        && G.fits_double x <=> G.is_small_int z
        && G.fits_double x' <=> G.is_small_int z'
      with G.Overflow -> x == max_int)

let check_pred =
  QCheck.Test.make ~name:"check_pred" ~count:2000 QCheck.int (fun x ->
      let z = G.of_int x in
      let z' = G.pred z in
      try
        let x' = G.to_int z' in
        x - 1 == x'
        && G.fits_double x <=> G.is_small_int z
        && G.fits_double x' <=> G.is_small_int z'
      with G.Overflow -> x == min_int)

let check_add =
  QCheck.Test.make ~name:"check_add" ~count:10000
    QCheck.(pair int int)
    (fun (x, y) ->
      let z = G.(of_int x + of_int y) in
      try
        let i = G.to_int z in
        i == x + y && G.fits_double i <=> G.is_small_int z
      with G.Overflow -> not (G.is_small_int z))

let check_sub =
  QCheck.Test.make ~name:"check_sub" ~count:10000
    QCheck.(pair int int)
    (fun (x, y) ->
      let z = G.(of_int x - of_int y) in
      try
        let i = G.to_int z in
        i == x - y && G.fits_double i <=> G.is_small_int z
      with G.Overflow -> not (G.is_small_int z))

let check_mul =
  QCheck.Test.make ~name:"check_mul" ~count:10000
    QCheck.(pair int int)
    (fun (x, y) ->
      let z = G.(of_int x * of_int y) in
      try
        let i = G.to_int z in
        i == x * y && G.fits_double i <=> G.is_small_int z
      with G.Overflow -> not (G.is_small_int z))

let check_div =
  QCheck.Test.make ~name:"check_div" ~count:10000
    QCheck.(pair int int)
    (fun (x, y) ->
      if y <> 0 then
        let z = G.(of_int x / of_int y) in
        try
          let i = G.to_int z in
          i == x / y && G.fits_double i <=> G.is_small_int z
        with G.Overflow -> G.equal z (G.of_string (G.to_string z))
      else true)

let check_rem =
  QCheck.Test.make ~name:"check_rem" ~count:10000
    QCheck.(pair int int)
    (fun (x, y) ->
      if y <> 0 then
        let z = G.(of_int x mod of_int y) in
        try
          let i = G.to_int z in
          i == x mod y && G.fits_double i <=> G.is_small_int z
        with G.Overflow -> G.equal z (G.of_string (G.to_string z))
      else true)

let check_lsl =
  QCheck.Test.make ~name:"check_lsl" ~count:10000
    QCheck.(pair int (0 -- 100))
    (fun (x, y) ->
      let z = G.(of_int x lsl y) in
      try
        let i = G.to_int z in
        i == x lsl y && G.fits_double i <=> G.is_small_int z
      with G.Overflow -> not (G.is_small_int z))

let compare_add =
  QCheck.Test.make ~name:"compare_add" ~count:10000
    QCheck.(pair int int)
    (fun (x, y) ->
      let z = G.(of_int x + of_int y) in
      let z' = Z.(of_int x + of_int y) in
      String.equal (G.to_bits z) (Z.to_bits z'))

let compare_sub =
  QCheck.Test.make ~name:"compare_sub" ~count:10000
    QCheck.(pair int int)
    (fun (x, y) ->
      let z = G.(of_int x - of_int y) in
      let z' = Z.(of_int x - of_int y) in
      String.equal (G.to_bits z) (Z.to_bits z'))

let compare_mul =
  QCheck.Test.make ~name:"compare_mul" ~count:10000
    QCheck.(pair int int)
    (fun (x, y) ->
      let z = G.(of_int x * of_int y) in
      let z' = Z.(of_int x * of_int y) in
      String.equal (G.to_bits z) (Z.to_bits z'))

let compare_div =
  QCheck.Test.make ~name:"compare_div" ~count:10000
    QCheck.(pair int int)
    (fun (x, y) ->
      try
        let z = G.(of_int x / of_int y) in
        let z' = Z.(of_int x / of_int y) in
        String.equal (G.to_bits z) (Z.to_bits z')
      with Division_by_zero -> true)

let compare_rem =
  QCheck.Test.make ~name:"compare_rem" ~count:10000
    QCheck.(pair int int)
    (fun (x, y) ->
      try
        let z = G.(of_int x mod of_int y) in
        let z' = Z.(of_int x mod of_int y) in
        String.equal (G.to_bits z) (Z.to_bits z')
      with Division_by_zero -> true)

let compare_lsl =
  QCheck.Test.make ~name:"compare_lsl" ~count:10000
    QCheck.(pair int (0 -- 100))
    (fun (x, y) ->
      let z = G.(of_int x lsl y) in
      let z' = Z.(of_int x lsl y) in
      String.equal (G.to_bits z) (Z.to_bits z'))

let compare_asr =
  QCheck.Test.make ~name:"compare_asr" ~count:10000
    QCheck.(pair int (0 -- 100))
    (fun (x, y) ->
      let z = G.(of_int x asr y) in
      let z' = Z.(of_int x asr y) in
      String.equal (G.to_bits z) (Z.to_bits z'))

let compare_shift_right_trunc =
  QCheck.Test.make ~name:"compare_shift_right_trunc" ~count:10000
    QCheck.(pair int (0 -- 100))
    (fun (x, y) ->
      let z = G.(shift_right_trunc (of_int x) y) in
      let z' = Z.(shift_right_trunc (of_int x) y) in
      String.equal (G.to_bits z) (Z.to_bits z'))

let () =
  QCheck_runner.run_tests_main ~argv:Sys.argv
    [
      check_of_int;
      check_of_int32;
      check_of_int64;
      check_of_float;
      check_of_string;
      check_succ;
      check_pred;
      check_add;
      check_sub;
      check_mul;
      check_div;
      check_rem;
      check_lsl;
      compare_add;
      compare_sub;
      compare_mul;
      compare_div;
      compare_rem;
      compare_lsl;
      compare_asr;
      compare_shift_right_trunc;
    ]
