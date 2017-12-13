open Frame

(** Block ref to frame option *)
type ('k,'v,'r,'t) r2f = ('t -> 'r -> ('k,'v,'r) frame option) 


let mk_r2f ~store_read : ('k,'v,'r,'t) r2f = (
  fun s r ->
    s |> store_read r 
    |> function (s',Ok f) -> Some f | _ -> (ignore(failwith __LOC__); None))
