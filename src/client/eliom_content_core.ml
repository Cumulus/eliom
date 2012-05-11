
(* This the core of [Eliom_content] without its dependencies to [Eliom_services],
   [Eliom_client] et al.  Its name is not [Eliom_content_base] because this would
   suggest the sharing between server and client. *)

open Eliom_lib

module XML = struct

  include RawXML

  type econtent =
    | Empty
    | Comment of string
    | EncodedPCDATA of string
    | PCDATA of string
    | Entity of string
    | Leaf of ename * attrib list
    | Node of ename * attrib list * elt list
  and node =
    | DomNode of Dom.node Js.t
    | TyXMLNode of econtent
  and elt = {
    (* See Eliom_client.HTML5 for the 'unwrap' function that convert
       the server's tree representation into the client one. *)
    mutable elt : node;
    node_id : node_id;
  }

  let content e =
    match e.elt with
    | DomNode _ -> assert false (* TODO *)
    | TyXMLNode elt -> elt
  let get_node e = e.elt
  let set_dom_node elt node = elt.elt <- DomNode node
  let get_node_id elt = elt.node_id

  let make ?(id = NoId) elt = { elt = TyXMLNode elt; node_id = id; }
  let make_dom ?(id = NoId) node = { elt = DomNode node; node_id = id; }

  let empty () = make Empty

  let comment c = make (Comment c)
  let pcdata d = make (PCDATA d)
  let encodedpcdata d = make (EncodedPCDATA d)
  let entity e = make (Entity e)

  let leaf ?(a = []) name =  make (Leaf (name, a))
  let node ?(a = []) name children = make (Node (name, a, children))
  let lazy_node ?a name children = node ?a name (Eliom_lazy.force children)

  let event_handler_of_function (ev: #Dom_html.event Js.t -> unit) =
    Caml (CE_client_closure (Obj.magic ev))

  (* Deprecated: HTML5.F.a_on* functions are redefinied on the client
     to call event_handler_of_function. *)
  let event_of_function ev = ev

  let end_re = Regexp.regexp_string "]]>"

  let make_node_name =
    let node_id_counter = ref 0 in
    (fun ?(global = true) () ->
      incr node_id_counter;
      (if global then "global_" else "")
      ^ "client_" ^ (string_of_int !node_id_counter))

  let make_process_node ?(id = make_node_name ~global:true ()) elt =
    { elt with node_id = ProcessId id }

  let make_request_node elt =
    { elt with
      node_id = RequestId (make_node_name ()) }

  let cdata s =
    let s' =
      "\n<![CDATA[\n" ^ Regexp.global_replace end_re s "" ^ "\n]]>\n" in
    encodedpcdata s'

  let cdata_script s =
    let s' =
      "\n//<![CDATA[\n" ^ Regexp.global_replace end_re s "" ^ "\n//]]>\n" in
    encodedpcdata s'

  let cdata_style s =
    let s' =
      "\n/* <![CDATA[ */\n" ^ Regexp.global_replace end_re s "" ^ "\n/* ]]> */\n" in
    encodedpcdata s'


end

module SVG = struct

  module D = SVG_f.Make(struct
    include XML

    let make elt = make_request_node (make elt)
    let make_lazy elt = make_request_node (make (Lazy.force elt))

    let empty () = make Empty

    let comment c = make (Comment c)
    let pcdata d = make (PCDATA d)
    let encodedpcdata d = make (EncodedPCDATA d)
    let entity e = make (Entity e)

    let leaf ?(a = []) name =  make (Leaf (name, a))
    let node ?(a = []) name children = make (Node (name, a, children))
    let lazy_node ?(a = []) name children =
      make (Node (name, a, Eliom_lazy.force children))

  end)

  module F = SVG_f.Make(XML)

  type 'a elt = 'a F.elt
  type 'a attrib = 'a F.attrib
  type uri = F.uri

  module Id = struct
    type 'a id = string (* FIXME invariant type parameter ? *)
    let new_elt_id: ?global:bool -> unit -> 'a id = XML.make_node_name
    let create_named_elt ~(id : 'a id) elt =
      D.tot (XML.make_process_node ~id (D.toelt elt))
    let create_global_elt elt =
      D.tot (XML.make_process_node (D.toelt elt))
  end

end

module HTML5 = struct

  module D = struct

    include HTML5_f.Make(struct
      include XML

      let make elt = make_request_node (make elt)
      let make_lazy elt = make_request_node (make (Lazy.force elt))

      let empty () = make Empty

      let comment c = make (Comment c)
      let pcdata d = make (PCDATA d)
      let encodedpcdata d = make (EncodedPCDATA d)
      let entity e = make (Entity e)

      let leaf ?(a = []) name =  make (Leaf (name, a))
      let node ?(a = []) name children = make (Node (name, a, children))
      let lazy_node ?(a = []) name children =
        make (Node (name, a, Eliom_lazy.force children))

    end)(SVG.D)

    let raw_a_onabort = a_onabort
    let raw_a_onafterprint = a_onafterprint
    let raw_a_onbeforeprint = a_onbeforeprint
    let raw_a_onbeforeunload = a_onbeforeunload
    let raw_a_onblur = a_onblur
    let raw_a_oncanplay = a_oncanplay
    let raw_a_oncanplaythrough = a_oncanplaythrough
    let raw_a_onchange = a_onchange
    let raw_a_onclick = a_onclick
    let raw_a_oncontextmenu = a_oncontextmenu
    let raw_a_ondblclick = a_ondblclick
    let raw_a_ondrag = a_ondrag
    let raw_a_ondragend = a_ondragend
    let raw_a_ondragenter = a_ondragenter
    let raw_a_ondragleave = a_ondragleave
    let raw_a_ondragover = a_ondragover
    let raw_a_ondragstart = a_ondragstart
    let raw_a_ondrop = a_ondrop
    let raw_a_ondurationchange = a_ondurationchange
    let raw_a_onemptied = a_onemptied
    let raw_a_onended = a_onended
    let raw_a_onerror = a_onerror
    let raw_a_onfocus = a_onfocus
    let raw_a_onformchange = a_onformchange
    let raw_a_onforminput = a_onforminput
    let raw_a_onhashchange = a_onhashchange
    let raw_a_oninput = a_oninput
    let raw_a_oninvalid = a_oninvalid
    let raw_a_onmousedown = a_onmousedown
    let raw_a_onmouseup = a_onmouseup
    let raw_a_onmouseover = a_onmouseover
    let raw_a_onmousemove = a_onmousemove
    let raw_a_onmouseout = a_onmouseout
    let raw_a_onmousewheel = a_onmousewheel
    let raw_a_onoffline = a_onoffline
    let raw_a_ononline = a_ononline
    let raw_a_onpause = a_onpause
    let raw_a_onplay = a_onplay
    let raw_a_onplaying = a_onplaying
    let raw_a_onpagehide = a_onpagehide
    let raw_a_onpageshow = a_onpageshow
    let raw_a_onpopstate = a_onpopstate
    let raw_a_onprogress = a_onprogress
    let raw_a_onratechange = a_onratechange
    let raw_a_onreadystatechange = a_onreadystatechange
    let raw_a_onredo = a_onredo
    let raw_a_onresize = a_onresize
    let raw_a_onscroll = a_onscroll
    let raw_a_onseeked = a_onseeked
    let raw_a_onseeking = a_onseeking
    let raw_a_onselect = a_onselect
    let raw_a_onshow = a_onshow
    let raw_a_onstalled = a_onstalled
    let raw_a_onstorage = a_onstorage
    let raw_a_onsubmit = a_onsubmit
    let raw_a_onsuspend = a_onsuspend
    let raw_a_ontimeupdate = a_ontimeupdate
    let raw_a_onundo = a_onundo
    let raw_a_onunload = a_onunload
    let raw_a_onvolumechange = a_onvolumechange
    let raw_a_onwaiting = a_onwaiting
    let raw_a_onkeypress = a_onkeypress
    let raw_a_onkeydown = a_onkeydown
    let raw_a_onkeyup = a_onkeyup
    let raw_a_onload = a_onload
    let raw_a_onloadeddata = a_onloadeddata
    let raw_a_onloadedmetadata = a_onloadedmetadata
    let raw_a_onloadstart = a_onloadstart
    let raw_a_onmessage = a_onmessage

    let a_onabort ev = a_onabort (XML.event_handler_of_function ev)
    let a_onafterprint ev = a_onafterprint (XML.event_handler_of_function ev)
    let a_onbeforeprint ev = a_onbeforeprint (XML.event_handler_of_function ev)
    let a_onbeforeunload ev = a_onbeforeunload (XML.event_handler_of_function ev)
    let a_onblur ev = a_onblur (XML.event_handler_of_function ev)
    let a_oncanplay ev = a_oncanplay (XML.event_handler_of_function ev)
    let a_oncanplaythrough ev = a_oncanplaythrough (XML.event_handler_of_function ev)
    let a_onchange ev = a_onchange (XML.event_handler_of_function ev)
    let a_onclick ev = a_onclick (XML.event_handler_of_function ev)
    let a_oncontextmenu ev = a_oncontextmenu (XML.event_handler_of_function ev)
    let a_ondblclick ev = a_ondblclick (XML.event_handler_of_function ev)
    let a_ondrag ev = a_ondrag (XML.event_handler_of_function ev)
    let a_ondragend ev = a_ondragend (XML.event_handler_of_function ev)
    let a_ondragenter ev = a_ondragenter (XML.event_handler_of_function ev)
    let a_ondragleave ev = a_ondragleave (XML.event_handler_of_function ev)
    let a_ondragover ev = a_ondragover (XML.event_handler_of_function ev)
    let a_ondragstart ev = a_ondragstart (XML.event_handler_of_function ev)
    let a_ondrop ev = a_ondrop (XML.event_handler_of_function ev)
    let a_ondurationchange ev = a_ondurationchange (XML.event_handler_of_function ev)
    let a_onemptied ev = a_onemptied (XML.event_handler_of_function ev)
    let a_onended ev = a_onended (XML.event_handler_of_function ev)
    let a_onerror ev = a_onerror (XML.event_handler_of_function ev)
    let a_onfocus ev = a_onfocus (XML.event_handler_of_function ev)
    let a_onformchange ev = a_onformchange (XML.event_handler_of_function ev)
    let a_onforminput ev = a_onforminput (XML.event_handler_of_function ev)
    let a_onhashchange ev = a_onhashchange (XML.event_handler_of_function ev)
    let a_oninput ev = a_oninput (XML.event_handler_of_function ev)
    let a_oninvalid ev = a_oninvalid (XML.event_handler_of_function ev)
    let a_onmousedown ev = a_onmousedown (XML.event_handler_of_function ev)
    let a_onmouseup ev = a_onmouseup (XML.event_handler_of_function ev)
    let a_onmouseover ev = a_onmouseover (XML.event_handler_of_function ev)
    let a_onmousemove ev = a_onmousemove (XML.event_handler_of_function ev)
    let a_onmouseout ev = a_onmouseout (XML.event_handler_of_function ev)
    let a_onmousewheel ev = a_onmousewheel (XML.event_handler_of_function ev)
    let a_onoffline ev = a_onoffline (XML.event_handler_of_function ev)
    let a_ononline ev = a_ononline (XML.event_handler_of_function ev)
    let a_onpause ev = a_onpause (XML.event_handler_of_function ev)
    let a_onplay ev = a_onplay (XML.event_handler_of_function ev)
    let a_onplaying ev = a_onplaying (XML.event_handler_of_function ev)
    let a_onpagehide ev = a_onpagehide (XML.event_handler_of_function ev)
    let a_onpageshow ev = a_onpageshow (XML.event_handler_of_function ev)
    let a_onpopstate ev = a_onpopstate (XML.event_handler_of_function ev)
    let a_onprogress ev = a_onprogress (XML.event_handler_of_function ev)
    let a_onratechange ev = a_onratechange (XML.event_handler_of_function ev)
    let a_onreadystatechange ev = a_onreadystatechange (XML.event_handler_of_function ev)
    let a_onredo ev = a_onredo (XML.event_handler_of_function ev)
    let a_onresize ev = a_onresize (XML.event_handler_of_function ev)
    let a_onscroll ev = a_onscroll (XML.event_handler_of_function ev)
    let a_onseeked ev = a_onseeked (XML.event_handler_of_function ev)
    let a_onseeking ev = a_onseeking (XML.event_handler_of_function ev)
    let a_onselect ev = a_onselect (XML.event_handler_of_function ev)
    let a_onshow ev = a_onshow (XML.event_handler_of_function ev)
    let a_onstalled ev = a_onstalled (XML.event_handler_of_function ev)
    let a_onstorage ev = a_onstorage (XML.event_handler_of_function ev)
    let a_onsubmit ev = a_onsubmit (XML.event_handler_of_function ev)
    let a_onsuspend ev = a_onsuspend (XML.event_handler_of_function ev)
    let a_ontimeupdate ev = a_ontimeupdate (XML.event_handler_of_function ev)
    let a_onundo ev = a_onundo (XML.event_handler_of_function ev)
    let a_onunload ev = a_onunload (XML.event_handler_of_function ev)
    let a_onvolumechange ev = a_onvolumechange (XML.event_handler_of_function ev)
    let a_onwaiting ev = a_onwaiting (XML.event_handler_of_function ev)
    let a_onkeypress ev = a_onkeypress (XML.event_handler_of_function ev)
    let a_onkeydown ev = a_onkeydown (XML.event_handler_of_function ev)
    let a_onkeyup ev = a_onkeyup (XML.event_handler_of_function ev)
    let a_onload ev = a_onload (XML.event_handler_of_function ev)
    let a_onloadeddata ev = a_onloadeddata (XML.event_handler_of_function ev)
    let a_onloadedmetadata ev = a_onloadedmetadata (XML.event_handler_of_function ev)
    let a_onloadstart ev = a_onloadstart (XML.event_handler_of_function ev)
    let a_onmessage ev = a_onmessage (XML.event_handler_of_function ev)

    type ('a, 'b, 'c) lazy_plus =
        ?a: (('a attrib) list) -> 'b elt Eliom_lazy.request -> ('b elt) list Eliom_lazy.request -> 'c elt

    let lazy_form ?(a = []) elt1 elts =
      tot (XML.lazy_node ~a:(to_xmlattribs a) "form"
	     (Eliom_lazy.from_fun
	        (fun () ->
		  toelt (Eliom_lazy.force elt1)
		  :: toeltl (Eliom_lazy.force elts))))

    module Of_dom = struct
      let rebuild_xml (node: 'a Js.t) : 'a elt =
        Obj.magic { XML.elt = XML.DomNode (node :> Dom.node Js.t); node_id = XML.NoId }
      let element : Dom_html.element Js.t -> 'a elt = rebuild_xml
      let html : Dom_html.htmlElement Js.t -> HTML5_types.html elt = rebuild_xml
      let head : Dom_html.headElement Js.t -> HTML5_types.head elt = rebuild_xml
      let link : Dom_html.linkElement Js.t -> HTML5_types.link elt = rebuild_xml
      let title : Dom_html.titleElement Js.t -> HTML5_types.title elt = rebuild_xml
      let meta : Dom_html.metaElement Js.t -> HTML5_types.meta elt = rebuild_xml
      let base : Dom_html.baseElement Js.t -> HTML5_types.base elt = rebuild_xml
      let style : Dom_html.styleElement Js.t -> HTML5_types.style elt = rebuild_xml
      let body : Dom_html.bodyElement Js.t -> HTML5_types.body elt = rebuild_xml
      let form : Dom_html.formElement Js.t -> HTML5_types.form elt = rebuild_xml
      let optGroup : Dom_html.optGroupElement Js.t -> HTML5_types.optgroup elt = rebuild_xml
      let option : Dom_html.optionElement Js.t -> HTML5_types.selectoption elt = rebuild_xml
      let select : Dom_html.selectElement Js.t -> HTML5_types.select elt = rebuild_xml
      let input : Dom_html.inputElement Js.t -> HTML5_types.input elt = rebuild_xml
      let textArea : Dom_html.textAreaElement Js.t -> HTML5_types.textarea elt = rebuild_xml
      let button : Dom_html.buttonElement Js.t -> HTML5_types.button elt = rebuild_xml
      let label : Dom_html.labelElement Js.t -> HTML5_types.label elt = rebuild_xml
      let fieldSet : Dom_html.fieldSetElement Js.t -> HTML5_types.fieldset elt = rebuild_xml
      let legend : Dom_html.legendElement Js.t -> HTML5_types.legend elt = rebuild_xml
      let uList : Dom_html.uListElement Js.t -> HTML5_types.ul elt = rebuild_xml
      let oList : Dom_html.oListElement Js.t -> HTML5_types.ol elt = rebuild_xml
      let dList : Dom_html.dListElement Js.t -> [`Dl] elt = rebuild_xml
      let li : Dom_html.liElement Js.t -> HTML5_types.li elt = rebuild_xml
      let div : Dom_html.divElement Js.t -> HTML5_types.div elt = rebuild_xml
      let paragraph : Dom_html.paragraphElement Js.t -> HTML5_types.p elt = rebuild_xml
      let heading : Dom_html.headingElement Js.t -> HTML5_types.heading elt = rebuild_xml
      let quote : Dom_html.quoteElement Js.t -> HTML5_types.blockquote elt = rebuild_xml
      let pre : Dom_html.preElement Js.t -> HTML5_types.pre elt = rebuild_xml
      let br : Dom_html.brElement Js.t -> HTML5_types.br elt = rebuild_xml
      let hr : Dom_html.hrElement Js.t -> HTML5_types.hr elt = rebuild_xml
      let anchor : Dom_html.anchorElement Js.t -> 'a HTML5_types.a elt = rebuild_xml
      let image : Dom_html.imageElement Js.t -> [`Img] elt = rebuild_xml
      let object_ : Dom_html.objectElement Js.t -> 'a HTML5_types.object_ elt = rebuild_xml
      let param : Dom_html.paramElement Js.t -> HTML5_types.param elt = rebuild_xml
      let area : Dom_html.areaElement Js.t -> HTML5_types.area elt = rebuild_xml
      let map : Dom_html.mapElement Js.t -> 'a HTML5_types.map elt = rebuild_xml
      let script : Dom_html.scriptElement Js.t -> HTML5_types.script elt = rebuild_xml
      let tableCell : Dom_html.tableCellElement Js.t -> [ HTML5_types.td | HTML5_types.td ] elt = rebuild_xml
      let tableRow : Dom_html.tableRowElement Js.t -> HTML5_types.tr elt = rebuild_xml
      let tableCol : Dom_html.tableColElement Js.t -> HTML5_types.col elt = rebuild_xml
      let tableSection : Dom_html.tableSectionElement Js.t -> [ HTML5_types.tfoot | HTML5_types.thead | HTML5_types.tbody ] elt = rebuild_xml
      let tableCaption : Dom_html.tableCaptionElement Js.t -> HTML5_types.caption elt = rebuild_xml
      let table : Dom_html.tableElement Js.t -> HTML5_types.table elt = rebuild_xml
      let canvas : Dom_html.canvasElement Js.t -> 'a HTML5_types.canvas elt = rebuild_xml
      let iFrame : Dom_html.iFrameElement Js.t -> HTML5_types.iframe elt = rebuild_xml
    end

  end

  module F = struct

    include HTML5_f.Make(XML)(SVG.F)

    let raw_a_onabort = a_onabort
    let raw_a_onafterprint = a_onafterprint
    let raw_a_onbeforeprint = a_onbeforeprint
    let raw_a_onbeforeunload = a_onbeforeunload
    let raw_a_onblur = a_onblur
    let raw_a_oncanplay = a_oncanplay
    let raw_a_oncanplaythrough = a_oncanplaythrough
    let raw_a_onchange = a_onchange
    let raw_a_onclick = a_onclick
    let raw_a_oncontextmenu = a_oncontextmenu
    let raw_a_ondblclick = a_ondblclick
    let raw_a_ondrag = a_ondrag
    let raw_a_ondragend = a_ondragend
    let raw_a_ondragenter = a_ondragenter
    let raw_a_ondragleave = a_ondragleave
    let raw_a_ondragover = a_ondragover
    let raw_a_ondragstart = a_ondragstart
    let raw_a_ondrop = a_ondrop
    let raw_a_ondurationchange = a_ondurationchange
    let raw_a_onemptied = a_onemptied
    let raw_a_onended = a_onended
    let raw_a_onerror = a_onerror
    let raw_a_onfocus = a_onfocus
    let raw_a_onformchange = a_onformchange
    let raw_a_onforminput = a_onforminput
    let raw_a_onhashchange = a_onhashchange
    let raw_a_oninput = a_oninput
    let raw_a_oninvalid = a_oninvalid
    let raw_a_onmousedown = a_onmousedown
    let raw_a_onmouseup = a_onmouseup
    let raw_a_onmouseover = a_onmouseover
    let raw_a_onmousemove = a_onmousemove
    let raw_a_onmouseout = a_onmouseout
    let raw_a_onmousewheel = a_onmousewheel
    let raw_a_onoffline = a_onoffline
    let raw_a_ononline = a_ononline
    let raw_a_onpause = a_onpause
    let raw_a_onplay = a_onplay
    let raw_a_onplaying = a_onplaying
    let raw_a_onpagehide = a_onpagehide
    let raw_a_onpageshow = a_onpageshow
    let raw_a_onpopstate = a_onpopstate
    let raw_a_onprogress = a_onprogress
    let raw_a_onratechange = a_onratechange
    let raw_a_onreadystatechange = a_onreadystatechange
    let raw_a_onredo = a_onredo
    let raw_a_onresize = a_onresize
    let raw_a_onscroll = a_onscroll
    let raw_a_onseeked = a_onseeked
    let raw_a_onseeking = a_onseeking
    let raw_a_onselect = a_onselect
    let raw_a_onshow = a_onshow
    let raw_a_onstalled = a_onstalled
    let raw_a_onstorage = a_onstorage
    let raw_a_onsubmit = a_onsubmit
    let raw_a_onsuspend = a_onsuspend
    let raw_a_ontimeupdate = a_ontimeupdate
    let raw_a_onundo = a_onundo
    let raw_a_onunload = a_onunload
    let raw_a_onvolumechange = a_onvolumechange
    let raw_a_onwaiting = a_onwaiting
    let raw_a_onkeypress = a_onkeypress
    let raw_a_onkeydown = a_onkeydown
    let raw_a_onkeyup = a_onkeyup
    let raw_a_onload = a_onload
    let raw_a_onloadeddata = a_onloadeddata
    let raw_a_onloadedmetadata = a_onloadedmetadata
    let raw_a_onloadstart = a_onloadstart
    let raw_a_onmessage = a_onmessage

    let a_onabort ev = a_onabort (XML.event_handler_of_function ev)
    let a_onafterprint ev = a_onafterprint (XML.event_handler_of_function ev)
    let a_onbeforeprint ev = a_onbeforeprint (XML.event_handler_of_function ev)
    let a_onbeforeunload ev = a_onbeforeunload (XML.event_handler_of_function ev)
    let a_onblur ev = a_onblur (XML.event_handler_of_function ev)
    let a_oncanplay ev = a_oncanplay (XML.event_handler_of_function ev)
    let a_oncanplaythrough ev = a_oncanplaythrough (XML.event_handler_of_function ev)
    let a_onchange ev = a_onchange (XML.event_handler_of_function ev)
    let a_onclick ev = a_onclick (XML.event_handler_of_function ev)
    let a_oncontextmenu ev = a_oncontextmenu (XML.event_handler_of_function ev)
    let a_ondblclick ev = a_ondblclick (XML.event_handler_of_function ev)
    let a_ondrag ev = a_ondrag (XML.event_handler_of_function ev)
    let a_ondragend ev = a_ondragend (XML.event_handler_of_function ev)
    let a_ondragenter ev = a_ondragenter (XML.event_handler_of_function ev)
    let a_ondragleave ev = a_ondragleave (XML.event_handler_of_function ev)
    let a_ondragover ev = a_ondragover (XML.event_handler_of_function ev)
    let a_ondragstart ev = a_ondragstart (XML.event_handler_of_function ev)
    let a_ondrop ev = a_ondrop (XML.event_handler_of_function ev)
    let a_ondurationchange ev = a_ondurationchange (XML.event_handler_of_function ev)
    let a_onemptied ev = a_onemptied (XML.event_handler_of_function ev)
    let a_onended ev = a_onended (XML.event_handler_of_function ev)
    let a_onerror ev = a_onerror (XML.event_handler_of_function ev)
    let a_onfocus ev = a_onfocus (XML.event_handler_of_function ev)
    let a_onformchange ev = a_onformchange (XML.event_handler_of_function ev)
    let a_onforminput ev = a_onforminput (XML.event_handler_of_function ev)
    let a_onhashchange ev = a_onhashchange (XML.event_handler_of_function ev)
    let a_oninput ev = a_oninput (XML.event_handler_of_function ev)
    let a_oninvalid ev = a_oninvalid (XML.event_handler_of_function ev)
    let a_onmousedown ev = a_onmousedown (XML.event_handler_of_function ev)
    let a_onmouseup ev = a_onmouseup (XML.event_handler_of_function ev)
    let a_onmouseover ev = a_onmouseover (XML.event_handler_of_function ev)
    let a_onmousemove ev = a_onmousemove (XML.event_handler_of_function ev)
    let a_onmouseout ev = a_onmouseout (XML.event_handler_of_function ev)
    let a_onmousewheel ev = a_onmousewheel (XML.event_handler_of_function ev)
    let a_onoffline ev = a_onoffline (XML.event_handler_of_function ev)
    let a_ononline ev = a_ononline (XML.event_handler_of_function ev)
    let a_onpause ev = a_onpause (XML.event_handler_of_function ev)
    let a_onplay ev = a_onplay (XML.event_handler_of_function ev)
    let a_onplaying ev = a_onplaying (XML.event_handler_of_function ev)
    let a_onpagehide ev = a_onpagehide (XML.event_handler_of_function ev)
    let a_onpageshow ev = a_onpageshow (XML.event_handler_of_function ev)
    let a_onpopstate ev = a_onpopstate (XML.event_handler_of_function ev)
    let a_onprogress ev = a_onprogress (XML.event_handler_of_function ev)
    let a_onratechange ev = a_onratechange (XML.event_handler_of_function ev)
    let a_onreadystatechange ev = a_onreadystatechange (XML.event_handler_of_function ev)
    let a_onredo ev = a_onredo (XML.event_handler_of_function ev)
    let a_onresize ev = a_onresize (XML.event_handler_of_function ev)
    let a_onscroll ev = a_onscroll (XML.event_handler_of_function ev)
    let a_onseeked ev = a_onseeked (XML.event_handler_of_function ev)
    let a_onseeking ev = a_onseeking (XML.event_handler_of_function ev)
    let a_onselect ev = a_onselect (XML.event_handler_of_function ev)
    let a_onshow ev = a_onshow (XML.event_handler_of_function ev)
    let a_onstalled ev = a_onstalled (XML.event_handler_of_function ev)
    let a_onstorage ev = a_onstorage (XML.event_handler_of_function ev)
    let a_onsubmit ev = a_onsubmit (XML.event_handler_of_function ev)
    let a_onsuspend ev = a_onsuspend (XML.event_handler_of_function ev)
    let a_ontimeupdate ev = a_ontimeupdate (XML.event_handler_of_function ev)
    let a_onundo ev = a_onundo (XML.event_handler_of_function ev)
    let a_onunload ev = a_onunload (XML.event_handler_of_function ev)
    let a_onvolumechange ev = a_onvolumechange (XML.event_handler_of_function ev)
    let a_onwaiting ev = a_onwaiting (XML.event_handler_of_function ev)
    let a_onkeypress ev = a_onkeypress (XML.event_handler_of_function ev)
    let a_onkeydown ev = a_onkeydown (XML.event_handler_of_function ev)
    let a_onkeyup ev = a_onkeyup (XML.event_handler_of_function ev)
    let a_onload ev = a_onload (XML.event_handler_of_function ev)
    let a_onloadeddata ev = a_onloadeddata (XML.event_handler_of_function ev)
    let a_onloadedmetadata ev = a_onloadedmetadata (XML.event_handler_of_function ev)
    let a_onloadstart ev = a_onloadstart (XML.event_handler_of_function ev)
    let a_onmessage ev = a_onmessage (XML.event_handler_of_function ev)

    type ('a, 'b, 'c) lazy_plus =
        ?a: (('a attrib) list) -> 'b elt Eliom_lazy.request -> ('b elt) list Eliom_lazy.request -> 'c elt

    let lazy_form ?(a = []) elt1 elts =
      tot (XML.lazy_node ~a:(to_xmlattribs a) "form"
	     (Eliom_lazy.from_fun
	        (fun () ->
		  toelt (Eliom_lazy.force elt1)
		  :: toeltl (Eliom_lazy.force elts))))

  end

  type +'a elt = 'a F.elt
  type +'a attrib = 'a F.attrib
  type uri = F.uri

  module Id = struct
    type 'a id = string (* FIXME invariant type parameter ? *)
    let new_elt_id: ?global:bool -> unit -> 'a id = XML.make_node_name
    let new_global_elt_id () = new_elt_id ()
    let create_named_elt ~(id : 'a id) elt =
      D.tot (XML.make_process_node ~id (D.toelt elt))
    let create_global_elt elt =
      D.tot (XML.make_process_node (D.toelt elt))

    let string_of_id x = x
  end

end



