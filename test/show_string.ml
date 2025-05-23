open Tsdl
open Tsdl_ttf

let ( >>= ) o f =
  match o with
  | Error (`Msg e) -> failwith (Printf.sprintf "Error %s" e)
  | Ok a -> f a

let unwind ~(protect : 'a -> unit) f x =
  try
    let y = f x in
    protect x;
    y
  with e ->
    protect x;
    raise e

let () =
  ignore (Sdl.init Sdl.Init.everything);
  Ttf.init () >>= fun () ->
  assert (Ttf.was_init ());
  Ttf.open_font "f500.ttf" 72 >>= fun font ->
  let fg_color = Sdl.Color.create ~r:255 ~g:255 ~b:255 ~a:255 in
  Ttf.render_text_solid font "foobar" fg_color >>= fun sface ->
  let display_width = 640 in
  let display_height = 480 in
  match
    Sdl.create_window "tsdl-ttf test" ~w:display_width ~h:display_height
      Sdl.Window.windowed
  with
  | Error (`Msg e) ->
      Printf.printf "Surface was generated but cannot be shown: %s\n" e
  | Ok window -> (
      Sdl.set_window_size window ~w:display_width ~h:display_height;
      match Sdl.get_window_surface window with
      | Error (`Msg e) ->
          Printf.printf
            "Text surface was generated but cannot get window surface: %s\n" e
      | Ok display ->
          let e = Sdl.Event.create () in
          let r = Sdl.Rect.create ~x:0 ~y:0 ~w:0 ~h:0 in
          let rec loop () =
            print_endline "loop";
            Sdl.fill_rect display None 0l >>= fun () ->
            Sdl.blit_surface ~src:sface None ~dst:display (Some r) >>= fun () ->
            Sdl.update_window_surface window >>= fun () ->
            match Sdl.wait_event (Some e) with
            | Error (`Msg err) ->
                Sdl.log "Could not wait event: %s" err;
                ()
            | Ok () -> (
                match Sdl.Event.(enum (get e typ)) with
                | `Quit | `Key_down -> ()
                | _ -> loop ())
          in
          if Sdl.get_current_video_driver () = Some "dummy" then
            print_endline "Dummy video driver"
          else
            unwind
              ~protect:(fun () ->
                Sdl.destroy_window window;
                Ttf.quit ();
                Sdl.quit ())
              loop ())
