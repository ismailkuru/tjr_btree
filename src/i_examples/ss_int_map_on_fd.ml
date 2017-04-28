(* a map from small string to int, backed by file -------------------------- *)

open Prelude
open Btree_api
open Small_string
open Example_keys_and_values

module G = Generic_kv_store

let pp = ss_int_pp

let cs sz = Constants.make_constants sz 4 pp.k_len pp.v_len

let mk_ps1 sz = G.mk_ps1 (cs sz) Small_string.compare ss_ss_pp

let mk_unchecked_map_ops sz = G.mk_unchecked_map_ops (mk_ps1 sz)  (* FIXME unchecked *)

