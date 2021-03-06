if !exists('g:test#fsharp#xunit#file_pattern')
  let g:test#fsharp#xunit#file_pattern = '\v\.fs$'
endif

function! test#fsharp#xunit#test_file(file) abort
  if fnamemodify(a:file, ':t') =~# g:test#fsharp#xunit#file_pattern
    if exists('g:test#fsharp#runner')
      return g:test#fsharp#runner ==# 'xunit'
    else
      return s:is_using_dotnet_xunit_cli(a:file)
          \ && (search('open Xunit', 'n') > 0)
          \ && (search('[<(Fact|Theory)>.*]', 'n') > 0)
    endif
  endif
endfunction

function! test#fsharp#xunit#build_position(type, position) abort
  let l:found_nearest = 0
  if a:type ==# 'nearest'
    let l:found_nearest = 1
    let l:n = test#base#nearest_test(a:position, g:test#fsharp#patterns)
    let l:fully_qualified_name = join(l:n['namespace'] + l:n['test'], '.')
    if !empty(l:fully_qualified_name)
      return [s:test_command(l:n), l:fully_qualified_name]
    endif
  endif
  if a:type ==# 'file' || l:found_nearest
    let l:position = a:position
    let l:position['line'] = '$'
    let l:n = test#base#nearest_test(l:position, g:test#fsharp#patterns)

    " Discard the test name and use the name space with the test class name
    let l:n['test'] = []
    let l:fully_qualified_name = join(l:n['namespace'][:1], '.')

    if !empty(l:fully_qualified_name)
      return [s:test_command(l:n), l:fully_qualified_name]
    else
      throw 'Could not find any tests.'
    endif
  endif

  return []
endfunction

function! test#fsharp#xunit#build_args(args) abort
  let l:args = a:args
  call insert(l:args, '-nologo')
  return [join(l:args, ' ')]
endfunction

function! test#fsharp#xunit#executable() abort
  return 'dotnet xunit'
endfunction

function! s:test_command(name) abort
  if !empty(a:name['test'])
    return '-method'
  elseif len(a:name['namespace']) > 1
    return '-class'
  else
    return '-namespace'
  endif
endfunction

function! s:is_using_dotnet_xunit_cli(file) abort
  let l:project_path = test#fsharp#get_project_path(a:file)
  return filereadable(l:project_path) 
      \ && match(
          \ readfile(l:project_path), 
          \ 'DotNetCliToolReference.*dotnet-xunit')
endfunction
