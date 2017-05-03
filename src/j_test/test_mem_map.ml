(* exhaustive in-mem testing ---------------------------------------- *)

open Base_types
open Monad
open Prelude
open Btree_api
open Mem_store
open Page_ref_int
open Mem_store.O

(* we concentrate on relatively small parameters *)

type key = int  [@@deriving yojson]
type value = int  [@@deriving yojson]

type tree = (key,value)Tree.tree
type store = (key,value)mem
type frame = (key,value)Page_ref_int.frame

module T = struct 
  type t = { 
    t:tree;
    s:store;
    r:page_ref 
  }
  type global_state = t
  (* compare: we want to ignore the store and page_ref *)
  let compare (x:t) (y:t) = (Pervasives.compare (x.t) (y.t))
end
open T

let constants = Constants.{
    max_leaf_size = 5;
    max_node_keys = 5;
    min_leaf_size = 2;
    min_node_keys = 2;
  }

let pr_ops = Store_to_map.{
    get_page_ref=(fun () -> fun t -> (t,Ok t.r));
    set_page_ref=(fun r -> fun t -> ({t with r},Ok ()))
  }

let mem_ops : ('k,'v,T.t) mem_ops = {
  get_store=(fun () -> fun t -> (t,Ok t.s));
  set_store=(fun s -> fun t -> ({t with s},Ok ()));
}

let store_ops = Mem_store.mk_store_ops mem_ops

let r2t = store_ops_to_r2t store_ops

let ps = 
  object
    method compare_k=Int.compare
    method constants=constants
    method debug=Some{r2t;k2j=key_to_yojson;v2j=value_to_yojson;r2j=page_ref_to_yojson} (* TODO Some(r2t) *)
  end

let map_ops = Mem_map.mk_map_ops ps mem_ops pr_ops

(* for maintaing a set of states *)
module TSET = Set.Make(T)

type action = Insert of int | Delete of int


(* we have a set of states s that we have already generated; 
   we have a set of states todo that we need to process; 
   for each todo, we apply all possible actions; 
   any new states that result are stored in "todo"; *)

(* if we hit an exception, we want to know what the input tree was,
   and what the command was *)

(* save so we know what the last action was *)
let action = ref (Insert 0) 

type range_t = int list[@@deriving yojson]

(* explore all possible states for the given range *)


(* exhaustive testing ---------------------------------------- *)

(* TODO use exhaustive.ml *)

let (init_store,init_r) = Mem_store.(
    { 
      free=1; 
      map=(Map_int.empty |> Map_int.add 0 (Frame.Leaf_frame[])) 
    }
    |> (fun s -> (s,0)))


let step range (t:global_state) = (
  let r1 = (
    range|>List.map (
      fun x -> 
        action:=Insert x; 
        map_ops.insert x x|>(fun f -> f t)))
  in
  let r2 = (
    range|>List.map (
      fun x -> 
        action:=Delete x; 
        map_ops.delete x|>(fun f -> f t)))
  in
  r1@r2 |> List.map (
    fun (t',res) -> 
      match res with
      | Ok () -> {t=r2t t' t'.r |> dest_Some; s=t'.s; r=t'.r }
      | Error e -> (failwith (__LOC__^e)))
  |> TSET.of_list)

let test_exhaustive range = TSET.(
    Printf.printf "%s: exhaustive test, %d elts: "  __MODULE__ (List.length range);
    flush_out();
    let s = ref TSET.(singleton {t=Tree.Leaf[];s=init_store;r=init_r }) in
    let todo = ref (!s) in
    (* next states from a given tree *)
    ignore (
      (* FIXME this may be faster if we store todo as a list and check
         for membership when computing next state of the head of todo;
         use rev_append *)
      (* Printf.printf "test: starting while\n"; *)
      while (not(TSET.is_empty !todo)) do
        let nexts : TSET.t list = 
          !todo|>TSET.elements|>List.map (step range) in
        let next = List.fold_left 
            (fun a b -> TSET.union a b) 
            TSET.empty nexts 
        in
        let new_ = TSET.diff next !s in
        s:=TSET.union !s new_;
        todo:=new_;
        print_string "."; flush_out ();
        ()
      done);
    Printf.printf "tests passed; num states explored: %d\n" (TSET.cardinal !s))


(* testing insert ---------------------------------------- *)

(* TODO do n inserts; check wf *)

let test_insert range = (
  Printf.printf "%s: test_insert, %d inserts, check wf etc:" __MODULE__ (List.length range);
  flush_out();
  let s0 = ref { t=Leaf[]; s=init_store; r=init_r } in
  let xs = ref range in
  let c = ref 0 in
  while (!xs <> []) do
    if (!c) mod 100 = 0 then (Printf.printf "."; flush_out ()) else ();
    let x = List.hd !xs in
    ignore(
      map_ops.insert x (2*x) |> run !s0
      |> (fun (s',Ok ()) -> s0:=s'));
    c:=!c+1;
    xs:=List.tl !xs;
  done;
  print_newline ()
)

(* TODO testing leaf_stream ---------------------------------------- *)

open Extlib.ExtList.List

type t = int list [@@deriving yojson]

(*
let test_leaf_stream range = (
  Printf.printf "%s: test_leaf_stream, %d inserts, check wf etc:" 
    __MODULE__ 
    (List.length range);
  flush_out();
  let r0 = init_r in
  let s0 = init_store in
  let sr = ref (s0,r0) in
  let run = Sem.run_ref sr in
  (* insert into an empty btree *)
  let xs = ref range in
  while (!xs <> []) do
    print_string "."; flush_out();
    let x = List.hd !xs in
    run (Raw_map.insert x (2*x));
    xs:=tl !xs
  done;
  (* check that leaf stream is what it should be *)
  let open Leaf_stream_ in
  let (s0,r0) = !sr in
  let s0 = ref s0 in
  let ls = Sem.run_ref s0 (Leaf_stream_.mk r0) in
  let run = Sem.run_ref (ref (!s0,ls)) in
  let x = List.sort Pervasives.compare range in
  let y = (run (all_kvs ()) |> List.map fst) in
  Test.log (y|>to_yojson|>Yojson.Safe.to_string);
  assert (x=y);
  print_newline ()
)


*)

