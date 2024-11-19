;extends

((text) 
 @injection.content
 (#lua-match? @injection.content "^@code%s*{.*}") 
 (#offset! @injection.content 0 5 0 0)
 (#set! injection.language "c_sharp")
    )


((text) 
 @injection.content
 (#lua-match? @injection.content "^@%s*{.*}") 
 (#offset! @injection.content 0 1 0 0)
 (#set! injection.language "c_sharp")
    )


