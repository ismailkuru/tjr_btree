(* simple state-passing monad ---------------------------------------- *)

module O = struct
  type ('a,'s) m = 's -> 's * ('a,string) result
end

include O

let bind : ('a -> ('b,'s) m) -> ('a,'s)m -> ('b,'s)m = fun f x s ->
  match x s with
  | (s',Ok y) -> f y s'
  | (s',Error e) -> (s',Error e)

let return x = fun s -> (s,Ok x)

let err e = fun s -> (s,Error e)


let run s = fun m -> m s
