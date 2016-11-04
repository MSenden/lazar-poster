PDFLATEX = pdflatex -shell-escape 
MD=$(wildcard ./markdown_blocks/*.md)


# Poster
lazar-poster.pdf:
	./md2tex.sh
	$(PDFLATEX) postertemplate.tex




# pandoc nano-lazar.md --bibliography=references.bibtex --latex-engine=pdflatex --filter ./inline.rb --filter pandoc-crossref --filter pandoc-citeproc -o nano-lazar.pdf 
