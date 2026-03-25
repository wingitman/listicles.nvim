if exists('g:loaded_listicle') | finish | endif
let g:loaded_listicle = 1

" :Listicle [dir]  – open listicle, optionally starting in [dir]
command! -nargs=? -complete=dir Listicle lua require('listicle').open(<q-args> ~= '' and <q-args> or nil)

" :ListicleToggle [dir]  – toggle listicle
command! -nargs=? -complete=dir ListicleToggle lua require('listicle').toggle(<q-args> ~= '' and <q-args> or nil)
