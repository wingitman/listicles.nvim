if exists('g:loaded_listicles') | finish | endif
let g:loaded_listicles = 1

" :Listicles [dir]  – open listicles, optionally starting in [dir]
command! -nargs=? -complete=dir Listicles lua require('listicles').open(<q-args> ~= '' and <q-args> or nil)

" :ListiclesToggle [dir]  – toggle listicles
command! -nargs=? -complete=dir ListiclesToggle lua require('listicles').toggle(<q-args> ~= '' and <q-args> or nil)
