(** B-tree api types *)

(** This module describes the main interfaces. The interfaces are heavily parameterized. 

To understand the interfaces, we need to introduce the following:

- Keys, represented by type variable ['k]
- Values, by type var ['v]
- Page/block references, ['r]; vars [blk_id]
- Global state, ['t]

The operations typically execute in the {!Base_types.Monad}.


*)

(* various interfaces ---------------------------------------- *)

(* this module safe to open *)

open Base_types
open Prelude
open Block

(* block device ---------------------------------------- *)

(** Disk operations: read, write, and sync. FIXME move to int64 blkid *)
type 't disk_ops = {
  blk_sz: blk_sz;
  read: blk_id -> (blk,'t) m;
  write: blk_id -> blk -> (unit,'t) m;
(*   disk_sync: unit -> (unit,'t) m; *)
}

module Imperative_disk_ops = struct
  type idisk_ops = {
    blk_sz: blk_sz;
    read: blk_id -> blk;
    write: blk_id -> blk -> unit;
  }

  let of_disk_ops (ops:'t disk_ops) (_ref:'t ref) = (
    let read r = 
      ops.read r |> Monad.run !_ref |> fun (t',Ok blk) -> 
      _ref:=t';
      blk
    in
    let write r blk =
      ops.write r blk |> Monad.run !_ref |> fun (t',Ok ()) ->
      _ref:=t';
      ()
    in
    { blk_sz=ops.blk_sz; read; write}
  )
end


(* store ------------------------------------------------------------ *)

(** Store operations: alloc, free and read. The store is a level above
   the raw disk, on which we build the B-tree. *)
type ('k,'v,'r,'t) store_ops = ('k,'v,'r,'t) Store_ops.store_ops = {
  store_free: 'r list -> (unit,'t) m;
  store_read : 'r -> (('k, 'v,'r) frame,'t) m;  (* FIXME option? *)
  store_alloc : ('k, 'v,'r) frame -> ('r,'t) m;
}

(* map ------------------------------------------------------------ *)

(* TODO insert_many *)

(** Map operations: find, insert, [insert_many] and
   delete. [insert_many] attempts to insert as many as possible in a
   single operation, and returns the remainder, and so is typically
   called in a loop. *)
type ('k,'v,'t) map_ops = {
  find: 'k -> ('v option,'t) m;
  insert: 'k -> 'v -> (unit,'t) m;
  insert_many: 'k -> 'v -> ('k*'v) list -> (('k*'v)list,'t) m;
  delete: 'k -> (unit,'t) m;
}

(** Call [insert_many] in a loop. *)
let rec insert_all im k v kvs = Monad.(
  im k v kvs |> bind (fun kvs' -> 
      match kvs' with
      | [] -> return ()
      | (k,v)::kvs -> insert_all im k v kvs))


(** Dummy module containing imperative version of the map interface. *)
module Imperative_map_ops = struct

  (** Imperative version of the map interface; throws exceptions. WARNING likely to change. *)
  type ('k,'v) imap_ops = {
    find: 'k -> 'v option;
    insert: 'k -> 'v -> unit;
    delete: 'k -> unit;
  }

  open Monad
  let of_map_ops (map_ops:('k,'v,'t)map_ops) (s_ref:'t ref) = (
    let find k = 
      map_ops.find k |> run (!s_ref) 
      |> function (s',Ok res) -> (s_ref:=s'; res) | (_,Error e) -> failwith e 
    in
    let insert k v = 
      map_ops.insert k v |> run (!s_ref) 
      |> function (s',Ok res) -> (s_ref:=s'; res) | (_,Error e) -> failwith e 
    in
    let delete k = 
      map_ops.delete k |> run (!s_ref) 
      |> function (s',Ok res) -> (s_ref:=s'; res) | (_,Error e) -> failwith e 
    in
    {find;insert;delete})

  (* FIXME make sure other places where we expect OK actually do
     something with the error *)

end

(* we only reveal lss when it points to a leaf *)

(** Leaf stream representation. This type is for debugging - you
   shouldn't need to access components. *)
type ('k,'v,'r) lss = { kvs: ('k*'v) list; ls: ('k,'v,'r)Small_step.ls_state }

(** A leaf stream is a linear sequence of the leaves in a B-tree, used
   for iterating over all the bindings in the tree. Leaf stream
   operations: make a leaf stream; get the list of (key,value) pairs
   associated to the state of the leaf stream; step to the next
   leaf. *)
type ('k,'v,'r,'t) ls_ops = {
  mk_leaf_stream: unit -> (('k,'v,'r) lss,'t) m;
  ls_step: ('k,'v,'r) lss -> (('k,'v,'r) lss option,'t) m;
  ls_kvs: ('k,'v,'r) lss -> ('k*'v) list
}


(* for debugging *)

(** Get all (key,value) pairs from a leaf stream. Debugging only. *)
let all_kvs: ('k,'v,'r,'t)ls_ops -> (('k * 'v) list,'t) m = Monad.(
    fun ops ->
      let rec loop kvs s = (
        let kvs' = ops.ls_kvs s in
        let kvs = kvs@kvs' in
        ops.ls_step s |> bind (fun s' ->
            match s' with
            | None -> return kvs
            | Some s' -> loop kvs s'))
      in
      ops.mk_leaf_stream () |> bind (fun s -> loop [] s))


