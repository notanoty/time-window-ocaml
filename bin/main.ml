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

let bg_color_dark = Layout.opaque_bg (RGB.find_color "#000303") 
let bg_color_light = Layout.opaque_bg  (RGB.find_color "#ffffff")
let fg_color_dark  = RGBA.find_color "#eddedd"
let fg_color_light = RGBA.find_color "#000303"

let fg = ref fg_color_dark
let bg =  ref bg_color_dark
let is_dark_theme = ref true
let temperature  = ref 100.0
let my_custom_font = Label.font_from_file "asset/Dotfont-Regular.otf"

 (* Time *)
let today = Unix.localtime (Unix.time ())
let day = today.Unix.tm_mday
let hour = 99
let minute = 99 
let second = 99 

(* Widgets *)
let temperature_lable = Widget.label 
  ~fg:(RGBA.find_color "#eddedd") 
  ~font:my_custom_font
  ~size: (window_scaler / 2 )
  (Printf.sprintf "%.1fC" !temperature) 

let time_label = Widget.label
  ~fg:(RGBA.find_color "#eddedd") 
  ~font:my_custom_font
  ~size: window_scaler  
  (Printf.sprintf "%02d:%02d:%02d" hour minute second) 

let button = 
  Widget.button 
    ~bg_off: (Style.Solid (RGBA.find_color "#ccdffc")) 
    ~bg_over: (Some (Style.Solid (RGBA.find_color "#555555"))) 
    ~bg_on: (Style.Solid (RGBA.find_color "#ccdffc")) 
    "Theme L/D"

(*Layout*)
let temp_x = width - (2 * window_scaler)
let temp_y = 10
let temp_layout = Layout.resident ~x:temp_x ~y:temp_y temperature_lable

let time_bounding_widget = Widget.empty ~w:(width - 23) ~h:height ()
let box_layout = Layout.resident time_bounding_widget
let label_layout = Layout.resident time_label
let time_layout = Layout.superpose ~center:true [box_layout; label_layout]

let button_x = 1 * window_scaler / 2
let button_y = 1 * window_scaler / 2
let button_layout = Layout.resident ~x:button_x ~y:button_y button 

let main () =
  let bg_layout = Layout.resident ~w:width ~h:height (Widget.label "") in
  (* Functions *)
  let update_clock () =
  let now = Unix.localtime (Unix.time ()) in
  let new_text = Printf.sprintf "%02d:%02d:%02d" now.tm_hour now.tm_min now.tm_sec in
    Widget.set_text time_label new_text;
    Widget.update time_label in

  let update_theme _src _dst _ev =
    if !is_dark_theme then (
      is_dark_theme := false;
      bg := bg_color_light;
      fg := fg_color_light
    ) else (
      is_dark_theme := true;
      bg := bg_color_dark;
      fg := fg_color_dark
    );
    Layout.set_background bg_layout (Some !bg);
    Label.set_fg_color (Widget.get_label time_label) !fg;
    Label.set_fg_color (Widget.get_label temperature_lable) !fg;
    Widget.update time_label;
    Widget.update temperature_lable in

  let c_theme_button =
    Widget.connect ~priority:Widget.Join button time_label update_theme Trigger.buttons_down
  in
  
  Layout.set_background bg_layout (Some !bg);
  let main_layout = Layout.superpose ~scale_content:true
    [ bg_layout; time_layout; temp_layout; button_layout] in
  let layout = main_layout in

  let board = Bogue.of_layout ~connections:[c_theme_button] layout in
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
    Widget.set_text temperature_lable (Printf.sprintf "%.1fC" temp);
    
    Printf.printf "The temperature is: %.1f\n" temp;
    Lwt.return ()
  );
  main ();
  Bogue.quit ()
