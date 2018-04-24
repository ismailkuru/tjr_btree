(** A simple example of a kv store. *)

open Tjr_btree
open Default_filename
open Block.Blk4096
open Map_ops
open Map_int_int

let _ = Test.disable()
let _ = Isa_test.disable_isa_checks()

open Examples_common

let x = mk_example_on_fd ~ps

let from_file = from_file x
let imperative_map_ops = imperative_map_ops x
let close = close x


(* construct keys and values from an int *)
let k x = x
let v x = x

let max = 10000


(* TODO this would be much faster if we used insert_many *)

(* create and init store, write some values, and close *)
let do_write () = 
  Printf.printf "Executing %d writes...\n" max;
  print_endline "Writing...";
  (* create and initialize *)
  let s = ref (from_file ~fn ~create:true ~init:true) in
  (* get map operations *)
  let map_ops = imperative_map_ops s in
  dest_imperative_map_ops map_ops @@ fun ~find ~insert ~delete ->
  (* write values *)
  for x=1 to max do
    insert (k x) (v x);
  done;
  close !s;
  ()

(* open store, delete some values, and close *)
let do_delete () = 
  print_endline "Deleting...";
  let s = ref (from_file ~fn ~create:false ~init:false) in
  let map_ops = imperative_map_ops s in
  dest_imperative_map_ops map_ops @@ fun ~find ~insert ~delete ->
  for x=100 to 200 do
    delete (k x);
  done;
  close !s;
  ()

(* open store and check whether various keys and values are correct *)
let do_check () = 
  print_endline "Checking...";
  let s = ref (from_file ~fn ~create:false ~init:false) in
  let map_ops = imperative_map_ops s in
  dest_imperative_map_ops map_ops @@ fun ~find ~insert ~delete ->
  assert(find (k 100) = None);
  assert(find (k 1000) = Some(v 1000));
  close !s;
  ()

(* actually execute the above *)
let _ = 
  do_write();
  do_delete();
  do_check();
  ()


let do_full_check () = 
  print_endline "Full check...";
  let s = ref (from_file ~fn ~create:false ~init:false) in
  let map_ops = imperative_map_ops s in
  dest_imperative_map_ops map_ops @@ fun ~find ~insert ~delete ->
  for x = 1 to max do
    if (100 <= x && x <= 200) then
      assert(find (k x) = None)
    else
      assert(find (k x) = Some(v x))
  done;
  close !s;
  ()

let _ = do_full_check ()

(*
let _ = Test.run_exit_hooks()
*)