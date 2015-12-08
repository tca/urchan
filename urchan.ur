sequence board_counter
sequence discussion_counter
sequence post_counter
sequence poster_counter

table board : { Id : int, Title : string } (* , Slug : string } *)
		  PRIMARY KEY (Id)

table disc : { Id : int, Board : int, Topic : string, Op : int, Bumped : time }
		 PRIMARY KEY (Id), CONSTRAINT Board FOREIGN KEY Board REFERENCES board(Id)

table poster : { Id: int, Key : string, Disc : int }
		   PRIMARY KEY (Id), CONSTRAINT Disc FOREIGN KEY Disc REFERENCES disc(Id)
				     
table post : { Id : int, Text : string, Parent : int, Date : time, Poster : option int }
		 PRIMARY KEY (Id),
      (* CONSTRAINT Parent FOREIGN KEY Parent REFERENCES disc(Id), *)
      CONSTRAINT Poster FOREIGN KEY Poster REFERENCES poster(Id)

val discussions_per_page = 5
val posts_per_page = 5

style mhead
style mmain
style nav
style board_nav
style current_board_link
style discussions
style board_title
style board_sidebar
style discussion_form
style discussion_form_a
style pagenav
style nav_next
style nav_prev
style clear
style reply_form
style discussion
style discussion_topic
style message
style op_class
style post_header
style post_author
style post_date
style post_body

datatype authresult = AuthSuccess of int * string | AuthFail | Nothing

fun verify_poster discussion key = 
    user' <- oneOrNoRows (SELECT *
			  FROM poster
			  WHERE poster.Disc={[discussion]}
			    AND poster.Key={[key]});
    case user' of
	None => return AuthFail
      | Some user => return (AuthSuccess (user.Poster.Id, key))

fun gen_key discussion  =
    key <- rand;
    taken <- oneOrNoRows (SELECT *
			  FROM poster
			  WHERE poster.Disc={[discussion]}
			    AND poster.Key={[show key]});
    case taken of
	None => return (show key)
      | Some(_) => k <- (gen_key discussion); return (show k)

fun create_poster discussion =
    id <- nextval poster_counter;
    key <- gen_key discussion;
    dml (INSERT INTO poster (Id, Key, Disc)
	 VALUES ({[id]}, {[key]}, {[discussion]}));
    return (id, key)

fun auth_user disc auth (key : option string) =
    case auth of
      | Some "Gen" => x <- (create_poster disc); return (AuthSuccess x)
      | Some "Key" =>
	(case key of
	     (* | Some "" => empty key error *)
	     Some(key') =>  x <- (verify_poster disc key'); return x
	   | None => return Nothing)
      | _ => return Nothing


fun post_form action pkey = <xml>
  <form>
    <p class={reply_form}>
      <label>Bump:</label> <checkbox{#Bump} checked={True} />
      <label>Auth:</label>
      <radio{#Auth}>
	<radioOption value="No"/>Anonymous
	<radioOption value="Gen"/>Generate Id
	<radioOption value="Key" checked={case pkey of Some _ => True | None => False}/>Use Key:
      </radio>
      <textbox{#Key} value={case pkey of Some k => k | None => ""}/>
      <br />
      <textarea{#Text} rows=8 cols=80/><br/>
      <submit action={action}/>
    </p>
  </form>
</xml>

fun render_discussion_form action id = <xml>
    <form>
      <p class={discussion_form}>
	<label for={id}>Topic: </label><textbox{#Topic} size=32 id={id}/><br/>
	<label>Auth:</label>
	<radio{#Auth}>
	  <radioOption value="No" checked={True} />Anonymous
	  <radioOption value="Gen"/>Generate Id
	</radio>
	<br/>
	<textarea{#Text} rows=8 cols=80/><br/>
	<submit action={action}/>
      </p>
  </form>
</xml>

(* TODO: Only let admins create boards *)
fun add_board r =
    id <- nextval board_counter;
    dml (INSERT INTO board (Id, Title)
	 VALUES ({[id]}, {[r.Title]}));
    redirect (url (view_board id))

and fetch_posts d =
    posts <- queryX (SELECT *
		     FROM post
		     WHERE post.Parent={[d.Id]}
		     ORDER BY post.Date ASC)
		    (render_post d.Op);
    return posts

and timeLoop s d =
    let
	fun loop () = sleep 10000; timeLoop s d
    in
	st <- tryRpc (fetch_posts d);
	case st of
	    Some(t) => set s t; loop ()
	  | None => loop ()
    end

and new_board () =
    return
    <xml>
      <body>
	<h1>Create a New Board</h1>
	<form>
	  <label>Title:</label><textbox{#Title}/>
	  <submit action={add_board} value="Create Board"/>
	</form>
      </body>
    </xml>


and create_post parent r = 
    pid <- nextval post_counter;
    ptime <- now;
    dml (INSERT INTO post (Id, Text, Parent, Date, Poster)
	 VALUES ({[pid]}, {[r.Text]}, {[parent]}, {[ptime]}, {[r.Poster]}));
    return (pid, ptime)

and add_post parent r =
    authr <- (auth_user parent r.Auth (Some(r.Key) : option string));
    case authr of
	AuthSuccess (id,key) => add_post' parent (r ++ { Poster = (Some id), PKey = Some(key)})
      (* TODO: instead send to error page giving chance to edit and re-submit *)
      | AuthFail => redirect (url (view_discussion parent { PKey = None }))
      | Nothing => add_post' parent (r ++ { Poster = None, PKey = None })


and add_post' parent r =
    (pid, ptime) <- create_post parent {Text = r.Text, Poster = r.Poster};
    dml (UPDATE disc
	 SET Bumped = {[ptime]}
	 WHERE Id = {[parent]}
	   AND {[ptime]} > Bumped
	   AND {[r.Bump]});
    redirect (url (view_discussion parent { PKey = r.PKey }))

and add_discussion board_id r =
    id <- nextval discussion_counter;
    authr <- (auth_user id r.Auth None);
    case authr of
	(* TODO: give chance to re-edit and submit post *)
	AuthFail => redirect (url (view_board board_id))
      | AuthSuccess (uid,key) =>
	add_discussion'
	    board_id id
	    { Topic = r.Topic, Text = r.Text, Poster = (Some uid), PKey = Some(key)}
      | Nothing =>
	add_discussion'
	    board_id id
	    { Topic = r.Topic, Text = r.Text, Poster = None, PKey = None}

and add_discussion' board_id id r =
    (pid, ptime) <- create_post id {Text = r.Text, Poster = r.Poster};
    dml (INSERT INTO disc (Id, Board, Topic, Op, Bumped)
	 VALUES ({[id]}, {[board_id]}, {[r.Topic]}, {[pid]}, {[ptime]}));
    redirect (url (view_discussion id { PKey = r.PKey}))


and render_post opid p =
    let
	val opclass = (if opid = p.Post.Id then op_class else null)
    in
	<xml>
	  <div class={classes message opclass}>
	    <div class={post_header}> 
              <span class={post_author}>
	     	{[(case p.Post.Poster of
		       Some poster => show poster
		     | None => "Anonymous")]}
	      </span> -
              <span class={post_date}>{[p.Post.Date]}</span> -
	      (* TODO: fragment links *)
              [ <a>{[p.Post.Id]}</a> ]
	    </div>
	    <div class={post_body}>{Bbcode.bbcode p.Post.Text}</div>
	  </div>
	</xml>
    end

and render_nav cur_board =
    board_links <- queryX (SELECT * FROM board)
			  (fn row => 
			      let
				  val cur_class =
				      case cur_board of
					  Some(cbid) => (if cbid = row.Board.Id
							 then current_board_link
							 else null)
					| None => null
			      in
				  <xml><li>
				    <a href={url (view_board row.Board.Id)} class={cur_class}>
				      {[row.Board.Title]}
				    </a>
				  </li></xml>
			      end);

    return <xml>
      <ul class={nav}>{board_links}</ul>
    </xml>

and render_layout template =
    nav <- render_nav template.Board;
    return <xml>
      <head>
	<title>Ur/Chan</title>
	<link type="text/css" rel="stylesheet" media="screen" href="/style.css" />
	{case template.Code of
	     Some(code) => code
	   | None => <xml></xml>}
	</head>
	<body>
	  <div class={mhead}>
	  <h1>Ur/Chan</h1>
	  <h2>some subtitle</h2>
	  </div>
	  {nav}
	  <div class={mmain}>
	   (* TODO: notifications  *)
	   {template.Body}
	  </div>
	</body>
    </xml>


(* TODO: pagination of replies *)
and view_discussion discussion_id r =
    d <- oneRow (SELECT * FROM disc WHERE disc.Id={[discussion_id]});
    b <- oneRow (SELECT * FROM board WHERE board.Id={[d.Disc.Board]});
    posts <- queryX (SELECT *
		     FROM post
		     WHERE post.Parent={[discussion_id]}
		     ORDER BY post.Date ASC
		     LIMIT {posts_per_page}
		     OFFSET {posts_per_page * 0})
		    (render_post d.Disc.Op);
    s <- source posts;
    template <- render_layout {
		Board = Some(b.Board.Id),
		Code = Some <xml><script code={spawn (timeLoop s {Id = d.Disc.Id, Op = d.Disc.Op})} /></xml>,
		Body = <xml>
		  <p>
		    <a href={url (view_board b.Board.Id)}>{[b.Board.Title]}</a>
                    /
		    <a href={url (view_discussion d.Disc.Id {PKey = None })}>
                      {case d.Disc.Topic of
                          "" => <xml>&lt;thread {[d.Disc.Id]}&gt;</xml>
                        | t => <xml>{[t]}</xml>}
                    </a>
		  </p>
		  <div class={discussion}><dyn signal={signal s}/></div>
		  {post_form (add_post d.Disc.Id) r.PKey}
		</xml>};
    return template

and get_discussion_listing d =
    pcount <- oneRow (SELECT COUNT( * ) AS Count
		      FROM post
		      WHERE post.Parent={[d.Disc.Id]});
    op <- oneRow (SELECT *
		  FROM post
		  WHERE post.Id={[d.Disc.Op]});
    posts <- queryL (SELECT *
		     FROM post
		     WHERE post.Parent={[d.Disc.Id]}
		     ORDER BY post.Date DESC
		     LIMIT 4);
    return { Replies = pcount.Count,
	     Omitted = (pcount.Count - (1 + (List.length posts))),
	     Disc = d,
	     Op = op,
		      Posts = (case (List.nth posts 0) of
				   Some(x) => (if (x.Post.Id = op.Post.Id)
					       then posts
					       else op :: posts)
				 | None => []) }

and render_discussion_listing l =
    let
	val topic = (case l.Disc.Disc.Topic of
			 "" => <xml>&lt;thread {[l.Disc.Disc.Id]}&gt;</xml>
		       | topic' =>  <xml>{[l.Disc.Disc.Topic]}</xml> )
    in
	
	<xml>
	  <div class={discussion}>
	    <h1 class={discussion_topic}>
	      <a href={url (view_discussion l.Disc.Disc.Id { PKey = None})}>{topic}</a>
	    </h1>
	    {case l.Posts of
		 first :: rest => <xml>
		   {render_post l.Disc.Disc.Op first}
		   {if l.Omitted > 0 then <xml><em>{[l.Omitted]} posts omitted</em></xml> else <xml/>}
		   {List.mapX (render_post l.Disc.Disc.Op) rest}
		 </xml>
	       | [] => <xml/> }
	  </div>
	</xml>
    end


(*
 TODO:
 - 404 on bad Id
 - pagination
 - for some reason can't link to this page from itself
*)
and view_board board_id = view_board_page board_id 0

and view_board_page board_id page =
    current_board <- oneRow (SELECT * FROM board WHERE board.Id={[board_id]});
    discussions_list' <- queryL (SELECT *
				 FROM disc
				 WHERE disc.Board={[board_id]}
				 ORDER BY disc.Bumped DESC
				 LIMIT {discussions_per_page}
				 OFFSET {page * discussions_per_page});
    discussion_count <- oneRowE1 (SELECT COUNT( * )
                            FROM disc
                            WHERE disc.Board={[board_id]});
    let
	(* TODO: nested query instead? *)
	val discussions_list = List.rev discussions_list'
                               val page_count = discussion_count / discussions_per_page
    in
	discussions_listings <- List.mapM get_discussion_listing discussions_list;
	discussion_form_id <- fresh;
	template <- render_layout {
		    Board = Some(board_id),
		    Code = None,
		    Body = <xml>
		      <div class={board_sidebar}>
			<h2 class={board_title}>{[current_board.Board.Title]}</h2>
			<ul class={board_nav}>
			  <li><a class={discussion_form_a} onclick={fn _ => giveFocus discussion_form_id}>New Thread</a></li>
			  {List.mapX (fn d => <xml>
			    <li>
			      (* TODO: these are suposed to be fragment links *)
			      <a href={url (view_discussion d.Disc.Disc.Id { PKey = None })}>
				{(case d.Disc.Disc.Topic of
				      "" => <xml>&lt;thread {[d.Disc.Disc.Id]}&gt;</xml>
				    | topic' =>  <xml>{[d.Disc.Disc.Topic]}</xml> )}
				({[d.Replies]})
			      </a>
			    </li>
			  </xml>)
				     discussions_listings}
			  <li class="pagenav nav_prev">
			    <a href={url (view_board_page board_id (page-1))}>&larr; prev page</a></li>
			    <li class="pagenav nav_next">
			      <a href={url (view_board_page board_id (page+1))}>next page &rarr;</a></li>
			</ul>
		      </div>

		      <div class={discussions}>
			{render_discussion_form (add_discussion board_id) discussion_form_id}
			{List.mapX render_discussion_listing discussions_listings}
                        {Pagination.pagination_links page_count page (view_board_page board_id)}
		      </div>
		      <hr class={clear} />
		    </xml> };
	return template
    end

fun main () =
    layout <- render_layout { Board = None, Code = None, Body = <xml><p>Welcome to Ur/Chan!</p></xml> };
    return layout
