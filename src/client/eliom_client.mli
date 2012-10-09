(* Ocsigen
 * http://www.ocsigen.org
 * Module eliom_client.ml
 * Copyright (C) 2010 Vincent Balat
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, with linking exception;
 * either version 2.1 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *)

(** Call server side services and change the current page. *)

open Eliom_lib

(** Call a server side service and change the current page.
    If the service belongs to the same application,
    the client side program is not stopped, and only
    the content (not the container) is reloaded. *)
val change_page :
  ?absolute:bool ->
  ?absolute_path:bool ->
  ?https:bool ->
  service:('a, 'b,
           [< Eliom_service.service_kind ],
           [< `WithSuffix | `WithoutSuffix ], 'd, 'e,
           [< Eliom_service.registrable ], Eliom_registration.appl_service)
          Eliom_service.service ->
  ?hostname:string ->
  ?port:int ->
  ?fragment:string ->
  ?keep_nl_params:[ `All | `None | `Persistent ] ->
  ?nl_params:Eliom_parameter.nl_params_set ->
  ?keep_get_na_params:bool -> 'a -> 'b -> unit Lwt.t

(** Call a server side service that return an OCaml value. *)
val call_caml_service :
  ?absolute:bool ->
  ?absolute_path:bool ->
  ?https:bool ->
  service:('a, 'b,
           [< Eliom_service.service_kind ],
           [< `WithSuffix | `WithoutSuffix ], 'd, 'e,
           [< Eliom_service.registrable ], 'return Eliom_parameter.caml)
          Eliom_service.service ->
  ?hostname:string ->
  ?port:int ->
  ?fragment:string ->
  ?keep_nl_params:[ `All | `None | `Persistent ] ->
  ?nl_params:Eliom_parameter.nl_params_set ->
  ?keep_get_na_params:bool -> 'a -> 'b -> 'return Lwt.t


(** Stop current program and load a new page.  Note that for string arguments,
    sole line feed or sole carriage return characters are substituted by the
    string ["\r\n"]. *)
val exit_to :
  ?absolute:bool ->
  ?absolute_path:bool ->
  ?https:bool ->
  service:('a, 'b,
           [< Eliom_service.service_kind ],
           [< `WithSuffix | `WithoutSuffix ], 'd, 'e,
           [< Eliom_service.registrable ], [< Eliom_registration.non_caml_service ])
          Eliom_service.service ->
  ?hostname:string ->
  ?port:int ->
  ?fragment:string ->
  ?keep_nl_params:[ `All | `None | `Persistent ] ->
  ?nl_params:Eliom_parameter.nl_params_set ->
  ?keep_get_na_params:bool -> 'a -> 'b -> unit

(** Loads an Eliom service in a window (cf. Javascript's [window.open]). *)
val window_open :
  window_name:Js.js_string Js.t ->
  ?window_features:Js.js_string Js.t ->
  ?absolute:bool ->
  ?absolute_path:bool ->
  ?https:bool ->
  service:('a, unit,
           [< Eliom_service.get_service_kind ],
           [< `WithSuffix | `WithoutSuffix ], _, unit,
           [< Eliom_service.registrable ], _)
          Eliom_service.service ->
  ?hostname:string ->
  ?port:int ->
  ?fragment:string ->
  ?keep_nl_params:[ `All | `None | `Persistent ] ->
  ?nl_params:Eliom_parameter.nl_params_set ->
  ?keep_get_na_params:bool -> 'a -> Dom_html.window Js.t

(** (low level) Call a server side service and return the content
    of the resulting HTTP frame as a string. *)
val call_service :
  ?absolute:bool ->
  ?absolute_path:bool ->
  ?https:bool ->
  service:('a, 'b,
           [< Eliom_service.service_kind ],
           [< `WithSuffix | `WithoutSuffix ], 'd, 'e,
           [< Eliom_service.registrable ], 'return)
          Eliom_service.service ->
  ?hostname:string ->
  ?port:int ->
  ?fragment:string ->
  ?keep_nl_params:[ `All | `None | `Persistent ] ->
  ?nl_params:Eliom_parameter.nl_params_set ->
  ?keep_get_na_params:bool -> 'a -> 'b -> string Lwt.t

(** Registers a function to call after loading the page, or after
    changing the page the next time. *)
val onload : (unit -> unit) -> unit

(** Register a function to be called before changing the page the next
    time. *)
val onunload : (unit -> unit) -> unit

(** Wait for the initialization phase to terminate *)
val wait_load_end : unit -> unit Lwt.t

(**/**)
(** true if the function is executed inside the loading phase *)
val in_onload : unit -> bool

val run_callbacks : (unit -> unit) list -> unit

val broadcast_load_end : unit -> unit
val flush_onload : unit -> (unit -> unit) list
val relink_request_nodes : Dom_html.htmlElement Js.t -> unit
val reset_request_nodes : unit -> unit
val force_unwrapped_elts : unit -> unit
val do_request_data : request_data -> unit
val relink_page_but_closure_nodes : Dom_html.element Js.t -> Dom_html.element Dom.nodeList Js.t
val leave_page : unit -> unit

val relink_closure_nodes :
  Dom_html.element Js.t ->
  (Dom_html.event Js.t -> unit) Client_value_server_repr.t Eliom_content_core.Xml.ClosureMap.t ->
  Dom_html.element Dom.nodeList Js.t ->
  (unit -> unit)

val getElementById : string -> Dom.node Js.t
val rebuild_node : 'a Eliom_content_core.Html5.elt -> < .. > Js.t

module Syntax_helpers : sig

  (** Look-up of the value of an injection in the global injection table. *)
  val get_injection : string -> 'a

  (** Register a function from the tuple of injected values (['args])
      to the actual code of the client value (['res]) under some
      closure ID *)
  val register_client_closure : int64 -> ('args -> 'res) -> unit

  (** Takes the next list of {!Eliom_lib_base.client_value_datum}s
      from the queue of server section data of the compilation unit
      provided by the first argument
      (cf. {!Eliom_lib_base.compilation_unit_global_data}). It
      initializes and registers the global client values created in
      that section.
      
      Called in parallel with <<a_api subproject="server"|val
      Eliom_service.Syntax_helpers.close_server_section>>. *)
  val close_server_section : string -> unit

  (** Takes the next list of {!Eliom_lib_base.injection_datum}s from
      the queue of client section data of the compilation unit
      specfied with the argument
      (cf. {!Eliom_lib_base.compilation_unit_global_data}). It
      registers those injections for subsequent usage of
      {!Eliom_client.Syntax_helpers.get_injection}.
      
      Called in parallel with <<a_api subproject="server"|val
      Eliom_service.Syntax_helpers.close_client_section>>. *)
  val open_client_section : string -> unit

  (** {!Eliom_lib_base.escaped_value}s are opaque and can be converted
      to ['a] by this function. The syntax extension adds the type
      constraints accordingly. *)
  val get_escaped_value : escaped_value -> 'a
end
