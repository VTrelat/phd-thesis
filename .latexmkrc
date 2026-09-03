# Make this project's own files (notably lstlean.sty, with the Lean literates)
# win over any directory prepended to TEXINPUTS by ~/.latexmkrc.
ensure_path('TEXINPUTS', '.');

# ---------------------------------------------------------------------------
# Compilation target.
#
# book.tex, academic.tex and short-fr.tex are thin roots that set
# \ThesisTarget and \input main.tex; building main.tex directly gives the
# "full" development build.  latexmk reads its rc files before it parses the
# command line, so @ARGV still holds the requested root here.
#
# Each target gets its own job name and auxiliary directory.  The separate
# aux directory matters twice over: the aux files that \include writes
# (chapters/*.aux) are named after the chapter, not after the job, and the
# externalized TikZ figures live in <aux_dir>/tikz -- so a shared directory
# would let the A5 book and the A4 versions overwrite each other's page
# numbers and reuse each other's \textwidth-sized pictures.
# ---------------------------------------------------------------------------
my $thesis_target = 'full';
foreach my $arg (@ARGV) {
    next if $arg =~ /^-/;
    $thesis_target = $1
        if $arg =~ m{(?:\A|/)(book|academic|short-fr)(?:\.tex)?\z};
}
# Explicit override, for callers that do not pass the root file positionally.
$thesis_target = $ENV{'THESIS_TARGET'} if $ENV{'THESIS_TARGET'};

# Keep the auxiliary-file layout self-contained: GitHub Actions does not read
# the user-level latexmkrc that normally selects this directory locally.
$aux_dir = ($thesis_target eq 'full') ? 'build' : "build/$thesis_target";

# TikZ's externalization library expects its cache directory to exist before
# it launches the subprocess that renders a figure.
use File::Path qw(make_path);
make_path("$aux_dir/tikz");

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

# Also remove auxiliary files written by \include (for example,
# build/chapters/*.aux).  Otherwise a truncated chapter aux can survive -C
# and poison the next full build.
$cleanup_includes_generated = 1;

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

if ($thesis_target eq 'full') {
    @default_files = ('main');
    $jobname = 'thesis';
} else {
    @default_files = ($thesis_target);
    $jobname = "thesis-$thesis_target";
}
