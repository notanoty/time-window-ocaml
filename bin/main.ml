open Printf
open Bogue
open Cohttp
open Cohttp_lwt_unix
open Lwt.Syntax
open Yojson
open Time
open Unix

let window_scaler = 80
let width: int = 16 * window_scaler
let height: int = 9 * window_scaler
let bg = Layout.opaque_bg (0, 3, 3) 
let temperature  = ref 0.0
let my_custom_font = Label.font_from_file "asset/Dotfont-Regular.otf"

 (* Time *)

 let today = Unix.localtime (Unix.time ())
 let day = today.Unix.tm_mday

 let hour = today.tm_hour
 let minute = today.tm_min
 let second = today.tm_sec


let main () =
  let label = Widget.label 
      ~fg:(RGBA.find_color "#eddedd") 
      ~font:my_custom_font
      ~size: (window_scaler / 2 )
      (Printf.sprintf "%.1fC" !temperature) in

  let time_label = Widget.label
    ~fg:(RGBA.find_color "#eddedd") 
    ~font:my_custom_font
    ~size: (window_scaler / 2 )
    (Printf.sprintf "%02d:%02d:%02d" hour minute second) in

  let time_button = Widget.button ~border_radius:10 "Update Time" in
    
let update_clock () =
    let now = Unix.localtime (Unix.time ()) in
    let new_text = Printf.sprintf "%02d:%02d:%02d" now.tm_hour now.tm_min now.tm_sec in
      Widget.set_text time_label new_text;
      Widget.update time_label
  in


  let update_time _src _dst _ev =
    let now = Unix.localtime (Unix.time ()) in
    let new_text = Printf.sprintf "%02d:%02d:%02d" now.tm_hour now.tm_min now.tm_sec in
    Widget.set_text time_label new_text 
  in
  let c =
    Widget.connect ~priority:Widget.Join time_button time_label update_time Trigger.buttons_down
  in

  let inner_layout = Layout.flat_of_w [label; time_label] in

  
  Layout.set_background inner_layout (Some bg);

  let layout = inner_layout in
  
  Layout.set_width layout width;
  Layout.set_height layout height;

  let board = Bogue.of_layout ~connections:[c] layout in

  (* Run the board, telling Bogue to call update_clock before every frame *)
  Bogue.run ~before_display:update_clock board

let () =
  Lwt_main.run (
    let uri = Uri.of_string "https://api.open-meteo.com/v1/forecast?latitude=52.52&longitude=13.41&current=temperature_2m" in
    let* (_response, body) = Cohttp_lwt_unix.Client.get uri in
    
    let* body_str = Cohttp_lwt.Body.to_string body in
    
    let json = Yojson.Safe.from_string body_str in
    
    let open Yojson.Safe.Util in
    let temp = json |> member "current" |> member "temperature_2m" |> to_float in
    temperature := temp;
    
    Printf.printf "The temperature is: %.1f\n" temp;
    Lwt.return ()
  );

  main ();
  Bogue.quit ()
