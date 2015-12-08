(* pagination that tries to stay the same size *)
(* it also has beggining/end and prev/next jumps *)
(* <- 1 ... 4 5 6 7 [8] 9 10 11 ... 25 -> *)


fun iota_rev s e =
    let fun aux e a =
            if e > s
            then aux (e - 1) (e :: a)
            else e :: a
    in
        aux e []
    end

style pagination
style page_link
style active
style disabled

val size = 8

fun pagination_links pages page prefix =
    let
        val bbump = max 0
        val tbump = min pages
        (* shrink list for smaller collections *)
        val size = tbump size
        (* estimate range *)
        val low = bbump (page - size / 2)
        val high = low + size
        (* overflow leftovers into low *)
        val low' = if high > pages
                   then low - (high - pages)
                   else low
        (* cut off bad parts *)
        val start = bbump low'
        val finish = tbump high
        (* define previous and next pages *)
        val back = bbump (page - 1)
        val forward = tbump (page + 1)

        fun link_page page_no =
            (<xml><li><a href={url (prefix page_no)} class={if page_no = page then active else page_link}>{[show page_no]}</a></li></xml>)
        fun link page_no text =
            (<xml><li><a href={url (prefix page_no)} class={if page_no = page then disabled else page_link}>{[text]}</a></li></xml>)
            
        val pad = <xml><li><a class={disabled}>...</a></li></xml>
    in
        <xml>
          <ul class={pagination}>
            {link back "Previous"}
            {if start <= 0 then <xml></xml> else <xml>{link_page 0}{pad}</xml>}
            {List.mapX link_page (iota_rev start finish)}
            {if finish >= pages then <xml></xml> else <xml>{pad}{link_page pages}</xml>}
            {link forward "Next"}
          </ul>
        </xml>
    end
