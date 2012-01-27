(**************************************************************************)
(* Sample use of ParMap,  a simple library to perform Map computations on *)
(* a multi-core                                                           *)
(*                                                                        *)
(*  Author(s):  Marco Danelutto and Roberto Di Cosmo                      *)
(*                                                                        *)
(*  This program is free software: you can redistribute it and/or modify  *)
(*  it under the terms of the GNU General Public License as               *)
(*  published by the Free Software Foundation, either version 2 of the    *)
(*  License, or (at your option) any later version.                       *)
(**************************************************************************)

open Graphics;;

let n   = 1000;; (* the size of the square screen windows in pixels      *)
let res = 1000;; (* the resolution: maximum number of iterations allowed *)

(* convert an integer in the range 0..res into a screen color *)

let color_of c res = Pervasives.truncate 
      (((float c)/.(float res))*.(float Graphics.white));;

(* compute the color of a pixel by iterating z_n+1=z_n^2+c *)
(* j,k are the pixel coordinates                           *)

let pixel (j,k,res,n) = 
  let zr = ref 0.0 in
  let zi = ref 0.0 in
  let cr = ref 0.0 in
  let ci = ref 0.0 in
  let zrs = ref 0.0 in
  let zis = ref 0.0 in
  let d   = ref (2.0 /. ((float  n) -. 1.0)) in
  let colour = Array.create n (Graphics.black) in

  for s = 0 to (n-1) do
    let j1 = ref (float  j.(s)) in
    let k1 = ref (float  k) in
    begin
      zr := !j1 *. !d -. 1.0;
      zi := !k1 *. !d -. 1.0;
      cr := !zr;
      ci := !zi;
      zrs := 0.0;
      zis := 0.0;
      for i=0 to (res-1) do
	begin
	  if(not((!zrs +. !zis) > 4.0))
	  then 
	    begin
	      zrs := !zr *. !zr;
	      zis := !zi *. !zi;
	      zi  := 2.0 *. !zr *. !zi +. !ci;
	      zr  := !zrs -. !zis +. !cr;
	      Array.set colour s (color_of i res);
	    end;
    	end
      done
    end
  done;
  (colour,k);;

(* draw a line on the screen using fast image functions *)

let show_a_result r =
  match r with
    (col,j) ->
      draw_image (make_image [| col |]) 0 j;;

(* generate the initial configuration *)

let initsegm n = 
  let rec aux acc = function 0 -> acc | n -> aux (n::acc) (n-1) in
  aux [] n
;;

let tasks = 
  let ini = Array.create n 0 in
  let iniv = 
    for i=0 to (n-1) do
      Array.set ini i i
    done; ini in
  List.map (fun seed -> (iniv,seed,res,n)) (initsegm n)
;;

let draw res =
  open_graph (" "^(string_of_int n)^"x"^(string_of_int n));
  List.iter show_a_result res;;

(* compute the image *)

Printf.printf "*** Computing\n%!";;
let m=Parmap.parmap ~ncores:4 ~chunksize: 1 pixel (Parmap.L tasks);;

(* draw the image *)

Printf.printf "*** Drawing... hit newline to finish\n%!";;
draw m;;
ignore(input_line stdin);;
close_graph();;
