# Make this project's own files (notably lstlean.sty, with the Lean literates)
# win over any directory prepended to TEXINPUTS by ~/.latexmkrc.
ensure_path('TEXINPUTS', '.');

push @extra_pdflatex_options, '-synctex=1', '-interaction=nonstopmode';
push @extra_lualatex_options, '-synctex=1', '-interaction=nonstopmode';
push @extra_xelatex_options, '-synctex=1', '-interaction=nonstopmode';
$clean_ext .= '.nav .snm .vrb .synctex.gz';

$file_line_error //= 1;
if ($file_line_error) {
    push @extra_pdflatex_options, '-file-line-error';
    push @extra_lualatex_options, '-file-line-error';
    push @extra_xelatex_options, '-file-line-error';
}

$pdf_mode = 4;
$bibtex_use = 1;

@default_files = ('main');

# ---------------------------------------------------------------------------
# No-proofs build: latexmk -noproofs
# Replaces every proof body with "Proof. Skipped." and writes thesis-noproofs.pdf.
# Usage: latexmk           → thesis.pdf
#        latexmk -noproofs → thesis-noproofs.pdf
# ---------------------------------------------------------------------------
my $noproofs = 0;
@ARGV = grep { $_ eq '-noproofs' ? do { $noproofs = 1; 0 } : 1 } @ARGV;
if ($noproofs) {
    $jobname = 'thesis-noproofs';
    $pre_tex_code = '\def\skipproofs{}';
    &alt_tex_cmds;  # switches engine template from %S to %P (pretex + \input)
} else {
    $jobname = 'thesis';
}