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

# Poster IST services
nmsa-ist-services:
	./md2tex.sh nmsa-ist-services.tex
	$(PDFLATEX) nmsa-ist-services.tex
	# $(BIBTEX) nmsa-ist-services
	# $(PDFLATEX) nmsa-ist-services.tex
	# $(PDFLATEX) nmsa-ist-services.tex

# Poster enm-ontoviewer
nmsa-ist-ontoviewer:
	./md2tex.sh nmsa-ist-ontoviewer.tex
	$(PDFLATEX) nmsa-ist-ontoviewer.tex
	# $(BIBTEX) nmsa-ist-ontoviewer
	# $(PDFLATEX) nmsa-ist-ontoviewer.tex
	# $(PDFLATEX) nmsa-ist-ontoviewer.tex
	

# Poster 2
exampleposter2:
	./md2tex.sh postertemplate_2.tex
	$(PDFLATEX) postertemplate_2.tex

clean:
	for file in $(MDTEX) ; do echo remove $$file; rm $$file ;	done
	for ext in $(CLEAN_EXT); do echo remove ./*$$ext; rm -f ./*$$ext; done
 
