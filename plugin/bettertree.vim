"
"----netrw
"

"general netrw settings
set ignorecase
set splitright
set splitbelow
let g:netrw_bufsettings = 'noma nomod nu nobl nowrap ro'
let g:netrw_banner=0
let g:netrw_liststyle=3
let g:netrw_browse_split=4
let g:netrw_winsize=15

"start netrw on vim launch
augroup tree_enter
autocmd vimenter * 15Vexplore | set wfw | wincmd p | wincmd =
autocmd vimenter * call ToggleAutoTree()
autocmd vimenter * call HighlightBuffer()
augroup END

"jump to window of buffer name
function! s:win_by_bufname(bufname)
	let bufmap=map(range(1, winnr('$')), '[bufname(winbufnr(v:val)), v:val]')
	let thewindow=filter(bufmap, 'v:val[0] =~ a:bufname')[0][1]
	execute thewindow 'wincmd w'
endfunction

command! -nargs=* WinGo call s:win_by_bufname(<q-args>)
nnoremap <Leader>i :WinGo netrw<CR>

"refresh netrw
function Refresh(var)
    call ToggleAutoTree()
    bd
    exec "Vexplore ".a:var | wincmd H | vertical resize 30 | set wfw | wincmd =
    call ToggleAutoTree()
endfunction

"highlight file location within netrw
function! HighlightBuffer()
    if &modifiable&&strlen(expand('%'))>0&&!&diff
        let var=expand('%:p')
        let var=split(var, '/')
        let file_name=var[-1]
        let num=0
        let var=join(var,'/')

        exec "call s:win_by_bufname('netrw')" | bd
        exec "call s:win_by_bufname(file_name)"

        Vexplore | wincmd H | vertical resize 30 | set wfw | wincmd =

        let char=split(file_name,'\zs')

        call search(file_name)
        normal zz
        wincmd p
    endif
endfunction

"toggle auto tree
let g:AutoTreeOn=0

function! ToggleAutoTree()
    if g:AutoTreeOn
        autocmd! buffer_highlight BufEnter *
        let g:AutoTreeOn=0
    else
        let g:AutoTreeOn=1
        augroup buffer_highlight
        autocmd BufEnter * silent! call HighlightBuffer()
        augroup end
    endif
endfunction


"toggle netrw
let g:NetrwIsOpen=1

function! ToggleNetrw()
    let bufname=bufname('%')

    if g:NetrwIsOpen
        call ToggleAutoTree()
        exec "WinGo ".'netrw' | bd
        let g:NetrwIsOpen=0
        exec "WinGo ".bufname
    else
        let var=expand('%:p')
        let var=split(var, '/')
        let var=join(var[0:-2], '/')
        let var='/'.var.'/'
        exec "WinGo ".bufname
        Vexplore | wincmd H | vertical resize 30 | set wfw | wincmd =
        call ToggleAutoTree()
        let g:NetrwIsOpen=1
    endif
    exec "WinGo ".bufname
endfunction

noremap <silent> <C-t> :silent! call ToggleNetrw()<CR>

"tree navigation

"differentiate between local and remote path
function LocalRemote()
    let var=b:netrw_curdir
    let var=split(var, '/')
    let var=var[0]

    if (var=='scp:')
        let var='remote'
    else
        let car='local'
    endif

    return var
endfunction

"return dir name
function DirParse()
    let var=b:netrw_curdir
    let var=split(var, '/')
    let var=var[-1]
    return var
endfunction

"navigate up the tree stucture
function ForwardNode()
    let var=LocalRemote()

    if (var=='local')
        call LocalForwardNode()
    else
        call RemoteForwardNode()
    endif
endfunction

"navigate down the tree structure
function BackNode()
    let var=LocalRemote()

    if (var=='local')
        call LocalBackNode()
    else
        call RemoteBackNode()
    endif
endfunction

"navigate up a remote tree
function RemoteForwardNode()
    normal gd
    call Refresh(b:netrw_curdir)
endfunction

"navigate down a remote tree
function RemoteBackNode()
    let var=DirParse()
    let var='| '.var
    normal gg
    normal -
    call Refresh(b:netrw_curdir)
    call search(var)
endfunction

"navigate up a local tree
function LocalForwardNode()
    normal gn
    normal gg
    normal j
endfunction

"navigate down a local tree
function LocalBackNode()
    let var=DirParse()
    let var='| '.var
    normal gg
    normal j
    normal -
    normal gd
    call Refresh(b:netrw_curdir)
    call search(var)
endfunction

"tree navigation shortcut keys
autocmd filetype netrw nmap <buffer> <c-m> :call ForwardNode()<CR>
autocmd filetype netrw nmap <buffer> <c-n> :call BackNode()<CR>

"""file / folder creation

"create a new file on a local host
function! LocalFile()
    let l:filename=input("please enter filename: ")
    let curdir=b:netrw_curdir
    let full_path=curdir.'/'.l:filename
    let var='touch /'.full_path

    call system(var)
    call Refresh(b:netrw_curdir)

    let var='| '.l:filename
    call search(var)
endfunction

"create a new file on a remote host
function! RemoteFile()
    let l:filename=input("please enter filename: ")
    let curdir=b:netrw_curdir
    let list=split(curdir,'/')

    let var='ssh '.list[2]
    let dir=list[4:-1]+['']
    let dir=join(dir,'/')
    let str=var.' "touch /'.dir.l:filename.'"'

    call system(str)
    call Refresh(b:netrw_curdir)

    let var='| '.l:filename
    call search(var)
endfunction

"create a new directory on a local machine
function! LocalDir()
    let l:filename=input("please enter directory name: ")
    let curdir=b:netrw_curdir
    let full_path=curdir.'/'.l:filename
    let var='mkdir /'.full_path

    call system(var)
    call Refresh(b:netrw_curdir)

    let var='| '.l:filename
    call search(var)
endfunction

" create a new directory on a remote machine
function! RemoteDir()
    let l:filename=input("please enter directory name: ")
    let curdir=b:netrw_curdir
    let list=split(curdir,'/')

    let var='ssh '.list[2]
    let dir=list[4:-1]+['']
    let dir=join(dir,'/')
    let str=var.' "mkdir /'.dir.l:filename.'"'

    call system(str)
    call Refresh(b:netrw_curdir)

    let var='| '.l:filename
    call search(var)
endfunction

"differentiate between local and remote new file
function! NewFile()
    let var=b:netrw_curdir
    let var=split(var, '/')
    let var=var[0]
    if (var=='scp:')
        call RemoteFile()
    else
        call LocalFile()
    endif
endfunction

"differentiate between local and remote new directory
function! NewDir()
    let var=b:netrw_curdir
    let var=split(var, '/')
    let var=var[0]
    if (var=='scp:')
        call RemoteDir()
    else
        call LocalDir()
    endif
endfunction

"new file / new directory shorcuyt keys
autocmd filetype netrw nmap <buffer> % :call NewFile()<CR>
autocmd filetype netrw nmap <buffer> d :call NewDir()<CR>

"""path dir targets

"return path, is dir or file, is local or remote 
function ParsePath(list)
    let var=a:list
    let list=[]

    for i in var
        let path=i

        let char=split(path, '\zs')
        let path=split(i, '/')

        if (char[-1]=='/')
            if (path[0]=='scp:')
                let ip_add=path[2]
                let path=join(path[4:-2], '/')
                let path='/'.path.'/'
                let dir='true'
            else
                let path=join(path[0:-2], '/')
                let path='/'.path.'/'
                let dir='true'
                let ip_add='local'
            endif
        else
            if (path[0]=='scp:')
                let ip_add=path[2]
                let path=join(path[4:-1], '/')
                let path='/'.path
                let dir='false'
            else
                let path=join(path, '/')
                let path='/'.path
                let dir='false'
                let ip_add='local'
            endif
        endif

        let list=list+[[path]+[dir]+[ip_add]]
    endfor
    return list
endfunction

"return mark file list
function! ItemList()
    let var=netrw#Expose("netrwmarkfilelist")
    let a=ParsePath(var)
    return a
endfunction

"return item path
function! ItemPath()
    let list=[]
    normal mf
    let var=netrw#Expose("netrwmarkfilelist")
    let var=var[-1]
    normal mf
    let var=list+[var]
    let var=ParsePath(var)
    return var
endfunction

"differentiate between single item and multiple item mark file list
function! MF_List()
    let mf_list=netrw#Expose("netrwmarkfilelist")
    let var=mf_list[0]
    if (var=='n')
        let var=ItemPath()
    else
        let var=ItemList()
    endif
    return var
endfunction

"format target path
function! TargetParse()
    let path=ItemPath()
    let path=path[0]
    let path=path[0]

    let path=split(path, '/')
    let path=join(path[0:-2], '/')
    let path='/'.path.'/'
    return path
endfunction

"return target path
function! Target()
    normal gg
    normal j

    let line=getline('.')
    let line=split(line, '://')

    let var=ItemPath()

    for i in var
        let list=[]
        let path=i[0]
        let dir=i[1]
        let ip_add=i[2]

        if (line[0]=='scp')
            let path=split(path, 'scp:')
            let path=path[0]
        endif

        let list=list+[[path]+[dir]+[ip_add]]
    endfor
    return list
endfunction

"""open, copy, move delete functions

"open file 
function! OpenFile()
    normal gf
endfunction

autocmd filetype netrw nmap <buffer> o :call OpenFile()<CR>

"open file vertical split
function! OpenVerticalWin()
    normal o
    wincmd =
endfunction

autocmd filetype netrw nmap <buffer> v :call OpenVerticalWin()<CR>

"open file in previous window
function! OpenPreviousWin()
    let var=ItemPath()
    let var=var[0]
    let var=var[0]
    wincmd p
    cd
    execute 'edit '.var
endfunction

autocmd filetype netrw nmap <buffer> p :call OpenPreviousWin()<CR>

"remove item prompt
function! RemoveItemPrompt()
    let refresh_path=b:netrw_curdir
    let char=split(refresh_path, '\zs')
    let split=split(refresh_path, '/')

    if (char[-1]=='/')
        let refresh_path=join(split[0:-2], '/')
    endif

    if (split[0]=='scp:')
        let refresh_path=b:netrw_curdir
    endif

    let mf_list=MF_List()

    for i in mf_list
        echo i[0]
    endfor

    let prompt=input('delete selected items {y/n} :')

    if (prompt=='y'||prompt=='Y'||prompt=='Yes')
        call RemoveItems()
        call Refresh(refresh_path)
        normal mF
    else
        echo ''
    endif

endfunction

autocmd filetype netrw nmap <buffer> D :call RemoveItemPrompt()<CR>

"delete items
function! RemoveItems()
    let mf_list=MF_List()

    for i in mf_list
        let path=i[0]
        let dir=i[1]
        let ip_add=i[2]

        if (dir=='true')
            let cmd='rm -rf '
        else
            let cmd='rm '
        endif

        let cmd=cmd.path

        if (ip_add=='local')
            echo ''
        else
            let cmd='ssh '.ip_add.' "'.cmd.'"'
        endif

        call system(cmd)

    endfor
endfunction

"copy move item prompt
function! MoveCopyItemPrompt(var)
    let mf_list=MF_List()
    let var=a:var

    if (var=='cp')
        let str='copy'
    elseif (var=='mv')
        let str='move'
    endif

    for i in mf_list
        echo i[0]
    endfor

    let target=Target()
    let path=target[0]
    let path=path[0]
    let input=str.' items to: '.path.' {y/n}: '
    let prompt=input(input)

    if (prompt=='y'||prompt=='Y'||prompt=='Yes')
        call MoveCopy(a:var, target)
        call Refresh(b:netrw_curdir)
        normal mF
    else
        echo ''
    endif
endfunction

"move copy shortcut keys
autocmd filetype netrw nmap <buffer> C :call MoveCopyItemPrompt('cp')<CR>
autocmd filetype netrw nmap <buffer> M :call MoveCopyItemPrompt('mv')<CR>

"differentiate between local and remote move / copy
function MoveCopy(cmd, target)
    let mf_list=MF_List()
    let cmd=a:cmd
    let target=a:target
    let target=target[0]

    for i in mf_list

        if (i[2]=='local'&&target[2]=='local')
            call LocalCopyMove(i, target, cmd)
        endif

        if (i[2]!='local'&&target[2]!='local')
            call RemoteCopyMove(i, target, cmd)
        endif

        if (i[2]=='local'&&target[2]!='local')
            call LocalRemoteCopy(i, target)
        endif

        if (i[2]!='local'&&target[2]=='local')
            call RemoteLocalCopy(i, target)
        endif

    endfor
endfunction

"copy / move a local item to a local target
function! LocalCopyMove(path, target, cmd)
    let path=a:path[0]
    let target=a:target[0]

    if (a:path[1]=='true')
        let cmd=a:cmd.' -rf '
    else
        let cmd=a:cmd.' '
    endif

    let str=cmd.path.' '.target
    call system(str)
endfunction

"copy / move a remote item to a remote target
function! RemoteCopyMove(path, target, cmd)
    let path=a:path[0]
    let target=a:target[0]

    if (a:path[1]=='true')
        let cmd=a:cmd.' -rf '
    else
        let cmd=a:cmd.' '
    endif

    let str='ssh '.a:path[2].' "'.cmd.path.' '.target.'"'
    call system(str)
endfunction

"copy / move a local item to a remote target
function! LocalRemoteCopy(path, target)
    if (a:path[1]=='true')
        let cmd=' -r '
    else
        let cmd=' '
    endif

    let str='scp'.cmd.a:path[0].' '.a:target[2].':'.a:target[0]
    call system(str)
endfunction

"copy / move a remote item to a local target
function! RemoteLocalCopy(path, target)
    if (a:path[1]=='true')
        let cmd=' -r '
    else
        let cmd=' '
    endif

    let str='scp'.cmd.a:path[2].':'.a:path[0].' '.a:target[0]
    call system(str)
endfunction
