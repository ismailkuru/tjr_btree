(** Collect base types together with sensible names *)

module Constants = Bt_constants
module Tree = Bt_tree
module Frame = Frame
module R2t = R2t
module Store_ops = Store_ops
(* module Base_types_params = Bt_params *)
module Monad = Bt_monad

include Base_types_pervasives
include Tree
include Frame
include Store_ops
include R2t
include Pickle_params
