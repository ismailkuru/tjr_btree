open Frame
open Iu_pervasives

(* just an abstraction, so no sync; use sync on underlying disk *)
type ('k,'v,'r,'t) store_ops = {
  store_free: 'r list -> (unit,'t) m;
  store_read : 'r -> (('k, 'v,'r) frame,'t) m;  (* FIXME option? *)
  store_alloc : ('k, 'v,'r) frame -> ('r,'t) m;
}
