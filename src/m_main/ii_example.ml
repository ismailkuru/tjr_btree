(** A simple example of a kv store. *)

open Int_int_map_on_fd

open Default_filename
open Block.Blk4096

let _ = Test.disable()

(* construct keys and values from an int *)
let k x = x
let v x = x

let close = Map_on_fd.Default_implementation.close

let max = 10000

(* create and init store, write some values, and close *)
let do_write () = (
  print_endline "Writing...";
  (* create and initialize *)
  let s = ref (from_file ~fn ~create:true ~init:true) in
  (* get map operations *)
  let map_ops = imperative_map_ops s in
  (* write values *)
  for x=1 to max do
    print_endline (string_of_int x);
    (* TODO this would be much faster if we used insert_many *)
    map_ops.insert (k x) (v x);
  done;
  (* close *)
  close ~blk_sz !s;
  ()
)

(* open store, delete some values, and close *)
let do_delete () = (
  print_endline "Deleting...";
  let s = ref (from_file ~fn ~create:false ~init:false) in
  let map_ops = imperative_map_ops s in
  for x=100 to 200 do
    map_ops.delete (k x);
  done;
  close ~blk_sz !s;
  ()
)

(* open store and check whether various keys and values are correct *)
let do_check () = (
  print_endline "Checking...";
  let s = ref (from_file ~fn ~create:false ~init:false) in
  let map_ops = imperative_map_ops s in
  assert(map_ops.find (k 100) = None);
  assert(map_ops.find (k 1000) = Some(v 1000));
  close ~blk_sz !s;
  ()
)

(* actually execute the above *)
let _ = (
  do_write();
  do_delete();
  do_check()
)


let do_full_check () = (
  print_endline "Full check...";
  let s = ref (from_file ~fn ~create:false ~init:false) in
  let map_ops = imperative_map_ops s in
  for x = 1 to max do
    if (100 <= x && x <= 200) then
      assert(map_ops.find (k x) = None)
    else
      assert(map_ops.find (k x) = Some(v x))
  done;
  close !s
)

let _ = do_full_check ()