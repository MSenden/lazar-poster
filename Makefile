PDFLATEX = pdflatex -shell-escape 
BIBTEX = bibtex
MD = $(wildcard ./markdown_blocks/*.md)
MDTEX = $(wildcard ./markdown_blocks/*.tex)
CLEAN_EXT = .aux .bbl .blg .log .nav .out .snm .toc





# Poster 1
exampleposter:
	./md2tex.sh postertemplate.tex
	$(PDFLATEX) postertemplate.tex
	$(BIBTEX) postertemplate
	$(PDFLATEX) postertemplate.tex
	$(PDFLATEX) postertemplate.tex

# Poster 2
exampleposter2:
	./md2tex.sh postertemplate_2.tex
	$(PDFLATEX) postertemplate_2.tex

clean:
	for file in $(MDTEX) ; do echo remove $$file; rm $$file ;	done
	for ext in $(CLEAN_EXT); do echo remove ./*$$ext; rm -f ./*$$ext; done

# pandoc nano-lazar.md --bibliography=references.bibtex --latex-engine=pdflatex --filter ./inline.rb --filter pandoc-crossref --filter pandoc-citeproc -o nano-lazar.pdf 
