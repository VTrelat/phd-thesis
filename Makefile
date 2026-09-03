# Compilation targets for the thesis.
#
#   make book       thesis-book.pdf       A5, cover artwork front and back, no
#                                         official title page, full manuscript.
#                                         Ready for A5 book printing.
#   make academic   thesis-academic.pdf   A4, official Université de Lorraine
#                                         title page only, no cover artwork,
#                                         full manuscript.
#   make short-fr   thesis-short-fr.pdf   A4, cover artwork front and back,
#                                         French abstract + "Résumé étendu" and
#                                         a bibliography recompiled from
#                                         scratch, so it holds only the
#                                         references those two cite.
#   make full       thesis.pdf            A4, both covers, full manuscript.
#                                         The development build (make's default).
#
# Each target reads main.tex through a thin root that sets \ThesisTarget; see
# the table at the top of preamble.tex.  Auxiliary files, including each
# target's own cache of externalized TikZ figures, go to build/<target>/
# (build/ for the development build).

LATEXMK  ?= latexmk
TARGETS   = book academic short-fr

.PHONY: all full release $(TARGETS) clean cleanall

all: full

full:
	$(LATEXMK) main.tex

$(TARGETS):
	$(LATEXMK) $@.tex

# The three PDFs published by the release workflow.
release: $(TARGETS)

# Remove the auxiliary files of every target but keep the figure caches.
clean:
	$(LATEXMK) -c main.tex
	@for t in $(TARGETS); do $(LATEXMK) -c $$t.tex; done

# Also remove the PDFs, and every cached figure with them.
cleanall:
	$(LATEXMK) -C main.tex
	@for t in $(TARGETS); do $(LATEXMK) -C $$t.tex; done
	rm -rf build
