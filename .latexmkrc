# Make this project's own files (notably lstlean.sty, with the Lean literates)
# win over any directory prepended to TEXINPUTS by ~/.latexmkrc.
ensure_path('TEXINPUTS', '.');

push @extra_pdflatex_options, '-synctex=1', '-interaction=nonstopmode';
push @extra_lualatex_options, '-synctex=1', '-interaction=nonstopmode';
push @extra_xelatex_options, '-synctex=1', '-interaction=nonstopmode';

# wip-stamp.tex shells out to `git` (via Lua io.popen) for the commit hash
# shown on the blank page after the cover; that requires full (non-restricted)
# shell escape. Pushing '-shell-escape' onto @extra_lualatex_options is NOT
# enough: latexmk still starts LuaTeX in its default *restricted* mode
# (banner: "restricted system commands enabled.", which whitelists only a
# few programs like makeindex/bibtex, not git). The flag has to be baked
# into the engine command string itself, since $pdf_mode=4 below always
# invokes lualatex.
$lualatex = 'lualatex -shell-escape %O %S';
$clean_ext .= '.nav .snm .vrb .synctex.gz';

# $file_line_error //= 1;
# if ($file_line_error) {
#     push @extra_pdflatex_options, '-file-line-error';
#     push @extra_lualatex_options, '-file-line-error';
#     push @extra_xelatex_options, '-file-line-error';
# }

$pdf_mode = 4;
$bibtex_use = 1;

# nomencl: run makeindex on .nlo to produce .nls (Index of Notations).
# must=1 so latexmk always rebuilds .nls when .nlo exists, even on first run.
add_cus_dep('nlo', 'nls', 1, 'makenlo2nls');
sub makenlo2nls {
    system("makeindex '$_[0].nlo' -s nomencl.ist -o '$_[0].nls' -t '$_[0].nlg'");
}
# Track .nlo as generated so latexmk cleans it up with -C.
push @generated_exts, 'nlo', 'nls', 'nlg';

@default_files = ('main');
$jobname = 'thesis';