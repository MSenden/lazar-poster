PDFLATEX = pdflatex -shell-escape 
BIBTEX = bibtex
MD=$(wildcard ./markdown_blocks/*.md)


# Poster 1
lazar-poster.pdf:
	./md2tex.sh
	$(PDFLATEX) postertemplate.tex
	$(BIBTEX) postertemplate
	$(PDFLATEX) postertemplate.tex
	$(PDFLATEX) postertemplate.tex

# Poster 2
lazar-poster2.pdf:
	./md2tex.sh
	$(PDFLATEX) postertemplate_2.tex



# pandoc nano-lazar.md --bibliography=references.bibtex --latex-engine=pdflatex --filter ./inline.rb --filter pandoc-crossref --filter pandoc-citeproc -o nano-lazar.pdf 
