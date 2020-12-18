let g:test#fsharp#patterns = {
  \ 'test':      ['\v\s*let ``([^`\(\)]+)``'],
  \ 'namespace': ['\v^\s*module (\w+)', '\v^\s*namespace ((\w|\.)+)'],
\}

let s:slash = (has('win32') || has('win64')) && fnamemodify(&shell, ':t') ==? 'cmd.exe' ? '\' : '/'

function! test#fsharp#get_project_path(file) abort
  let l:filepath = fnamemodify(a:file, ':p:h')
  let l:project_files = s:get_project_files(l:filepath)
  let l:search_for_fsproj = 1

  while len(l:project_files) == 0 && l:search_for_fsproj
    let l:filepath_parts = split(l:filepath, s:slash)
    let l:search_for_fsproj = len(l:filepath_parts) > 1
    " only want the forward slash at the root dir for non-windows machines
    let l:filepath = substitute(s:slash, '\', '', '').join(l:filepath_parts[0:-2], s:slash)
    let l:project_files = s:get_project_files(l:filepath)
  endwhile

  if len(l:project_files) == 0
    throw 'Unable to find .fsproj file, a .fsproj file is required to make use of the `dotnet test` command.'
  endif

  return l:project_files[0]
endfunction

function! s:get_project_files(filepath) abort
  return split(glob(a:filepath . s:slash . '*.fsproj'), '\n')
endfunction
