fun msplit_all str chr_tokens =
let
    fun msplit_all' str chr_tokens memo = 
	case String.msplit {Haystack = str, Needle = chr_tokens}  of
	    Some("",c,s) => msplit_all' s chr_tokens ((str1 c) :: memo)
	  | Some(p,c,s) => msplit_all' s chr_tokens ((str1 c) :: p :: memo)
	  | None => List.rev (str :: memo)
in
    msplit_all' str chr_tokens []
end


datatype bbtoken = Open of string | Close of string | Text of string

fun string_of_bbtoken bt = 
    case bt of
	Open x => "[" ^ x ^ "]"
      | Close x => "[/" ^ x ^ "]"
      | Text x => x

fun xml_of_bbtoken bt = (<xml>{[string_of_bbtoken bt]}</xml>)

(* it's like this for later conversion to typeclass/pvar *)
fun mkTag' tag =
   (case tag of
	"b" => Some "b" 
      | "i" => Some "i"
      | "o" => Some "o"
      | "u" => Some "u"
      | _ => None)

fun mkTag tag cons =
    case mkTag' tag of
	Some tt => cons tt
      (* return text node for invalid tags (since it is a markup langauge) *)
      | None => Text tag

fun tagify tokens =
    case tokens of
	[] => []
      | "" :: [] => []
      | "[" :: tag :: "]" :: rest => (mkTag tag @@Open) :: (tagify rest)
      | "[" :: "/" :: tag :: "]" :: rest =>  (mkTag tag @@Close) :: (tagify rest)
      | text :: rest => (Text text) :: (tagify rest)


fun getTransformer (tag : string) : (xbody -> xbody) = 
    case tag of
	"root" => (fn x => <xml>{x}</xml>)
      | "b" => (fn x => <xml><strong>{x}</strong></xml>)
      | "i" => (fn x => <xml><em>{x}</em></xml>)
      | "o" => (fn x => <xml><span style={STYLE "text-decoration:overline"}>{x}</span></xml>)
      | "u" => (fn x => <xml><span style={STYLE "text-decoration:underline"}>{x}</span></xml>)
      | _ => (fn x => <xml/>) (* TODO: this should be unreacable *)

datatype el = El of (bbtoken * list el)

fun xml_of_el (element : el) : xbody  =
    case element of
	El ((Close tag), cs) => ((getTransformer tag) (List.mapX xml_of_el cs))
      | El (v, []) => xml_of_bbtoken v
      | El (v, _) => xml_of_bbtoken v (* should be impossible to reach *)

fun push_val (s : list el) (v : bbtoken)  =
    case s of
	(El ((Open t), cs)) :: rest => (El (Open t, ((El (v, [])) :: cs))) :: rest
      | _ => (El (v, [])) :: s

fun push_el (s : list el) (p : el) =
    case s of
	(El (Open t, cs)) :: rest => (El (Open t, (p :: cs))) :: rest
      | _ => p :: s

fun run tokens =
    let
	fun run' cmds stack = 
	    case cmds of
		[] =>  stack
	      (* add the value to the first "object" on the stack *)
	      | (Text v) :: cmds' => run' cmds' (push_val stack (Text v))
              (* create a new "object" on the stack represented by: (tag, elements) *)
	      | (Open c) :: cmds' => run' cmds' ((El (Open c, [])) :: stack)
	      | (Close c) :: cmds' =>
		case stack of
		    (El (Open hc, cs)) :: rst =>
		    (if hc = c
		     (* the constructin is complete, push it on the head of rst *)
		     (* swapping the Open tag for the Close tag to indicate it is done *)
		     then run' cmds' (push_el rst (El (Close hc, List.rev cs)))
		     (* this end tag doesn't match start tag; push it as a val *)
		     else run' cmds' (push_val stack (Close c)))
		  (* should be unreachable *)
		  | _ => run' cmds' (push_val stack (Close c))
    in
	El ((Close "root"), List.rev (run' tokens []))
    end

fun bbcode str = (xml_of_el (run (tagify (msplit_all str "[]/"))))
