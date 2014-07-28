sequence board_counter
sequence discussion_counter
sequence post_counter

table board : { Id : int, Title : string } (* , Slug : string } *)
		  PRIMARY KEY (Id)

table disc : { Id : int, Board : int, Topic : string, Op : int, Bumped : time }
		 PRIMARY KEY (Id), CONSTRAINT Board FOREIGN KEY Board REFERENCES board(Id)

table post : { Id : int, Text : string, Parent : int, Date : time }
		 PRIMARY KEY (Id), CONSTRAINT Parent FOREIGN KEY Parent REFERENCES disc(Id)


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

val cssString  = "
body {
  background-color:#f1ede7; /*#FFFDEF;*/
  margin:0;
  padding:1em;
  padding-bottom:10em;
  color:#393733;
  font-size:11pt;
  font-family: Arial,Helvetica,sans-serif;
}

input[type=\"text\"], textarea { border:1px solid #ccc; }
label { line-height:150%; }

h1 { text-align:center; padding:0; margin:0; color:#56554e;}
pre, code { margin:0; padding:0; }

a {
  color:#105CB6;
}
a:hover { color:#000; }
.clear { clear:both; margin:0; padding:0; visibility:hidden; }

.mhead { margin:1em 0 2em 0; }
.mhead h2 { text-align:center; padding:0; margin:0; color:#56554e; font-style:italic;}

.nav { 
  margin:1em;
  list-style:none;
  padding:.75em;
  background-color:#DAD9C7;
}
.nav li {
  display:inline;
}
.nav li a {
  text-decoration:none;
  font-weight:bold;
  padding:.25em .75em;
  color:#56554e;
}
.nav li a.current_board_link { 
  background-color:#F1EDE7;
}
.nav li a:hover {
  background-color:#F1EDE7;
  color:#20201E;
}

.nav .first a { margin-left:-2px; border-left:2px solid #a00;}
.nav .first a:hover { border-left:2px solid #600;}

.mmain {
  margin:1em;
  background-color:#fff;
  padding:1em;
}


.board_sidebar {
  position:fixed;
  width:18em;
  float:left;
}

.board_title {
  text-align:center;
  padding:.25em;
  color:#799F4F;
  margin:0 0 1em 0;
}

.board_nav {
  margin:0;
  padding:0;
  list-style-type:none;
}
.board_nav a#discussion_form_a {
  cursor:pointer;
  font-weight:bold;
  text-decoration:none;
  padding:4px 6px;
}

.board_nav li {
  margin:0;
}


.board_nav li a {
  background-color:#F1EDE7;
  display:block;
  padding:2px 6px;
  margin-bottom:2px;
}

.board_nav .pagenav {
  float:left;
  width:50%;
  font-weight:bold;
}

.board_nav .pagenav a { padding:4px 9px; text-decoration:none; }
.board_nav .nav_prev a { margin-right:1px; text-align:right; }
.board_nav .nav_next a { margin-left:1px; }


.discussions {
  margin-left:20em;
}

.discussion {
  margin-bottom:2em;
}

.discussion h1.discussion_topic {
  text-align:left;
  padding:0; margin:.5em .25em;
  font-size:14pt;
}
/*
.discussion .discussion_topic a:visited {
  color:inherit;
  text-decoration:none;
}
*/
.message {
  /* float:left; clear:both; */
  margin:.5em 0;
  padding:1em;
  border-bottom:1px solid #DAD9C7;
}
.message .post_head {
  border-bottom-width:0;
}
.message .post_head .post_title {
  font-weight:bold;
}
.message .post_head .message_anchor {
  text-decoration:none;
}
.message .post_head .posT_author {
  font-weight:bold;
  color:#62523a;
}

.message .post_body {
  padding:1em 0;
  border-top-width:0;
  color:#4F4A45;
}

.message .post_body .greentext {
  color:#789922;
}

.op_class {
  background-color:#F3EECC;
  border-color:#F3EECC;
}

.replies {
  margin-left:2em;
}

ul.pagination {
  margin:0;
  padding:0;
  list-style-type:none;
  border:1px solid #ccc;
  border-right:0;
  float:left;
}

ul.pagination li {
  margin:0;
  padding:0;
  display:inline;
}

ul.pagination li a {
  float:left;
  border-right:1px solid #ccc;
  text-decoration:none;
  padding:8px 16px;
  background-color:#fff;
}

ul.pagination li a:hover, ul.pagination li a.active {
  background-color:#DAD9C7;
}

ul.pagination li a.disabled, ul.pagination li a.disabled:hover {
  background-color:#fff;
  color:#aaa;
}

blockquote, pre {
  margin-left:0em;
  padding:.5em 0 .5em 1em;
  border-left:3px solid #DAD9C7;
  background-color:#F1EDE7;
}

.op_class blockquote, .op_class pre {
  border-color:#D3CEAC;
  background-color:#FFFEDC;
}

.spoiler {
  color:#000;
  background-color:#000;
}
.spoiler:hover { background-color:transparent; }

p#top {padding:0;margin:0;}
p#top a, #bottom a { text-decoration:none; }
"

fun css () =
    returnBlob (textBlob cssString) (blessMime "text/css")

(* TODO: per-thread user id
<textbox name="key" value="key" id="key"/>
<label>Generate ID: </label><checkbox{#Gen_id} value="true" id="gen_id" />
 *)
fun post_form action = <xml>
  <form>
    <p class={reply_form}>
      <label>Bump: </label><checkbox{#Bump} checked={True} /><br />
      <textarea{#Text} rows=8 cols=80/><br/>
      <submit action={action}/>
    </p>
  </form>
</xml>

fun render_discussion_form action id = <xml>
    <form>
      <p class={discussion_form}>
	<label for={id}>Topic: </label><textbox{#Topic} size=32 id={id}/><br/>
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
		     WHERE post.Parent={[d.Id]})
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
    dml (INSERT INTO post (Id, Text, Parent, Date)
	 VALUES ({[pid]}, {[r.Text]}, {[parent]}, {[ptime]}));
    return (pid, ptime)

and add_post parent r =
    (pid, ptime) <- create_post parent (r -- #Bump);
    dml (UPDATE disc
	 SET Bumped = {[ptime]}
	 WHERE Id = {[parent]}
	   AND {[ptime]} > Bumped
	   AND {[r.Bump]});
    redirect (url (view_discussion parent))

and add_discussion board_id r =
    id <- nextval discussion_counter;
    (pid, ptime) <- create_post id (r -- #Topic);
    dml (INSERT INTO disc (Id, Board, Topic, Op, Bumped)
	 VALUES ({[id]}, {[board_id]}, {[r.Topic]}, {[pid]}, {[ptime]}));
    redirect (url (view_discussion id))

and render_post opid p =
    let
	val opclass = (if opid = p.Post.Id then op_class else null)
    in
	<xml>
	  <div class={classes message opclass}>
	    <div class={post_header}> 
              <span class={post_author}>author</span> -
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
	<link rel="stylesheet" type="text/css" href={url (css ())}/>
	{case template.Code of
	     Some(code) => code
	   | None => <xml></xml>}
	(*<link type="text/css" rel="stylesheet" media="screen" href="/style.css" />*)
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
and view_discussion discussion_id =
    d <- oneRow (SELECT * FROM disc WHERE disc.Id={[discussion_id]});
    b <- oneRow (SELECT * FROM board WHERE board.Id={[d.Disc.Board]});
    posts <- queryX (SELECT *
		     FROM post
		     WHERE post.Parent={[discussion_id]}
		     ORDER BY post.Date DESC
		     LIMIT {posts_per_page}
		     OFFSET {posts_per_page * 0})
		    (render_post d.Disc.Op);
    s <- source posts;
    template <- render_layout {
		Board = Some(b.Board.Id),
		Code = Some <xml><script code={spawn (timeLoop s {Id = d.Disc.Id, Op = d.Disc.Op})} /></xml>,
		Body = <xml>
		  <p>
		    <a href={url (view_board b.Board.Id)}>{[b.Board.Title]}</a> /
		    <a href={url (view_discussion d.Disc.Id)}>{[d.Disc.Topic]}</a>
		  </p>
		  <div class={discussion}><dyn signal={signal s}/></div>
		  {post_form (add_post d.Disc.Id)}
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
	      <a href={url (view_discussion l.Disc.Disc.Id)}>{topic}</a>
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
    let
	(* TODO: nested query instead? *)
	val discussions_list = List.rev discussions_list'
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
			      <a href={url (view_discussion d.Disc.Disc.Id)}>
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
		      </div>

		      <hr class={clear} />
		    </xml> };
	return template
    end




fun main () =
    layout <- render_layout { Board = None, Code = None, Body = <xml><p>Welcome to Ur/Chan!</p></xml> };
    return layout
