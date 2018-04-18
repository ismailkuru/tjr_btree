(** Store operations: alloc, free and read. The store is a level above
   the raw disk block device, on which we build the B-tree. *)

open Frame
open Tjr_step_monad


type ('k,'v,'r,'t) store_ops = {
  store_free: 'r list -> (unit,'t) m;
  store_read: 'r -> (('k, 'v,'r) frame,'t) m;
  store_alloc: ('k, 'v,'r) frame -> ('r,'t) m;
}

(* store ------------------------------------------------------------ *)

let mk_store_ops ~store_free ~store_read ~store_alloc =
  {store_free; store_read; store_alloc }


let dest_store_ops r =
  let store_free,store_read,store_alloc = r.store_free,r.store_read,r.store_alloc in
  fun k -> k ~store_free ~store_read ~store_alloc

let _ = dest_store_ops

open Isa_export.Params

let x_store_read ~run store_read = 
  fun rs s -> 
    run s (store_read rs) |> fun (s,x) -> 
    (s,Ok x)

let x_store_alloc ~run store_alloc = 
  fun f s -> 
    run s (store_alloc f) |> fun (s,x) -> 
    (s,Ok x)

FIXME we can make a single lift to the isa monad


let x_store_ops store_ops : ('k,'v,'r,'t,unit) store_ops_ext = (
  dest_store_ops store_ops @@ fun ~store_free ~store_read ~store_alloc ->
  Store_ops_ext(
    (x_store_read ~run:(failwith "FIXME") store_read),
    (x_store_alloc ~run:(failwith "FIXME") store_alloc),
    store_free,()))

let x_ps1 ~constants ~cmp ~store_ops : ('k,'v,'r,'t) ps1 = Isa_export.Params.(
    Ps1(Constants.x_constants constants, (Constants.Isabelle_conversions'.x_cmp cmp, x_store_ops store_ops)))
