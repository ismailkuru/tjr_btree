(** A simple example of a kv store. *)

open Tjr_btree
(* open Map_on_fd_util *)
open Examples
open Default_filename

let _ = 
  Printf.printf 
    "%s ----------------------------------------------\n%!" 
    __MODULE__

let _ = Test.disable()
let _ = Isa_test.disable_isa_checks()

let max = 10000

let (from_file,close,rest) = Examples.ii_map_on_fd

(* TODO this would be much faster if we used insert_many *)

(* create and init store, write some values, and close *)
let do_write () = 
  Printf.printf "Executing %d writes...\n%!" max;
  print_endline "Writing...";
  let state = from_file ~fn ~create:true ~init:true in
  let (_find,insert,_delete) = rest ~state in
  (* write values *)
  for x=1 to max do
    insert x x;
  done;
  close state;
  ()

(* open store, delete some values, and close *)
let do_delete () = 
  print_endline "Deleting...";
  let state = from_file ~fn ~create:false ~init:false in
  let (_find,_insert,delete) = rest ~state in
  for x=100 to 200 do
    delete x;
  done;
  close state;
  ()

(* open store and check whether various keys and values are correct *)
let do_check () = 
  print_endline "Checking...";
  let state = from_file ~fn ~create:false ~init:false in
  let (find,_insert,_delete) = rest ~state in
  assert(find 100 = None);
  assert(find 1000 = Some 1000);
  close state;
  ()

(* actually execute the above *)
let _ = 
  do_write();
  do_delete();
  do_check();
  ()


let do_full_check () = 
  print_endline "Full check...";
  let state = from_file ~fn ~create:false ~init:false in
  let (find,_insert,_delete) = rest ~state in
  for x = 1 to max do
    if (100 <= x && x <= 200) then
      assert(find x = None)
    else
      assert(find x = Some(x))
  done;
  close state;
  ()

let _ = do_full_check ()
