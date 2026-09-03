# Trustworthy Reasoning for the B Method – PhD Thesis

## Building

Four compilation targets share `main.tex`; each is a thin root that sets
`\ThesisTarget` (see the table at the top of `preamble.tex`). The class font
size is settled before `\documentclass` in `thesis-target.tex`, which both
`main.tex` and the TikZ externalization driver read, so a figure is typeset at
the size of the page it lands on.

| command | output | paper | contents |
| --- | --- | --- | --- |
| `make book` | `thesis-book.pdf` | A5, 9pt | Cover artwork front and back, no official title page, full manuscript. Ready for book printing. |
| `make academic` | `thesis-academic.pdf` | A4, 10pt | Official Université de Lorraine title page only, no cover artwork, full manuscript. |
| `make short-fr` | `thesis-short-fr.pdf` | A4, 10pt | Cover artwork front and back, French abstract and *Résumé étendu*, with a bibliography recompiled so that it holds only the references those two cite. |
| `make` | `thesis.pdf` | A4, 10pt | Both covers, full manuscript. The development build. |

`make release` builds the first three, which is what the GitHub Actions
workflow publishes to the `pdf` release tag.

Each target keeps its auxiliary files, including its own cache of externalized
TikZ figures, in `build/<target>/` (`build/` for the development build). They
are not shared: a picture drawn in `\textwidth` units does not survive a change
of trim, and the aux files that `\include` writes are named after the chapter
rather than after the job. Build the release targets from the terminal — the
LaTeX Workshop settings in `.vscode/` pin the job name and auxiliary directory
of the development build.
