(* a map from small string to int, backed by file -------------------------- *)

open Prelude
open Btree_api
open Example_keys_and_values
open Btree_with_pickle.O
open Small_string.O
open Default


let ps store_ops = 
  let pp = ss_int_pp in
  object
    method block_size=default_blk_sz
    method pp=pp
    method constants=Constants.make_constants default_blk_sz tag_len pp.k_len pp.v_len
    method compare_k=SS.compare
    method r2t=None (* TODO *)
    method store_ops=store_ops
  end

let store_ops = Map_on_fd.mk_store_ops (ps ())

let map_ops = Map_on_fd.mk_map_ops (ps store_ops)

let ls_ops = Map_on_fd.mk_ls_ops (ps store_ops)
