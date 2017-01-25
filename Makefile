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
	$(BIBTEX) nmsa-ist-services
	$(PDFLATEX) nmsa-ist-services.tex
	$(PDFLATEX) nmsa-ist-services.tex
	#./dockercmd.sh /bin/sh -c "./md2tex.sh nmsa-ist-services.tex && pdflatex nmsa-ist-services.tex"

# Poster enm-ontoviewer
nmsa-ist-ontoviewer:
	#./md2tex.sh nmsa-ist-ontoviewer.tex
	#$(PDFLATEX) nmsa-ist-ontoviewer.tex
	# $(BIBTEX) nmsa-ist-ontoviewer
	# $(PDFLATEX) nmsa-ist-ontoviewer.tex
	# $(PDFLATEX) nmsa-ist-ontoviewer.tex
	./dockercmd.sh /bin/sh -c "./md2tex.sh nmsa-ist-ontoviewer.tex && pdflatex nmsa-ist-ontoviewer.tex"

# Poster enm-integration
nmsa-ist-integration:
	./md2tex.sh nmsa-ist-integration.tex
	$(PDFLATEX) nmsa-ist-integration.tex
	# $(BIBTEX) nmsa-ist-integration
	# $(PDFLATEX) nmsa-ist-integration.tex
	# $(PDFLATEX) nmsa-ist-integration.tex
	#./dockercmd.sh /bin/sh -c "./md2tex.sh nmsa-ist-integration.tex && pdflatex nmsa-ist-integration.tex"
	
# Poster enm-rest
nmsa-ist-rest:
	./md2tex.sh nmsa-ist-rest.tex
	$(PDFLATEX) nmsa-ist-rest.tex
	$(BIBTEX) nmsa-ist-rest
	$(PDFLATEX) nmsa-ist-rest.tex
	$(PDFLATEX) nmsa-ist-rest.tex
	#./dockercmd.sh /bin/sh -c "./md2tex.sh nmsa-ist-rest.tex && pdflatex nmsa-ist-rest.tex"
	
# Poster 2
exampleposter2:
	./md2tex.sh postertemplate_2.tex
	$(PDFLATEX) postertemplate_2.tex

clean:
	for file in $(MDTEX) ; do echo remove $$file; rm $$file ;	done
	for ext in $(CLEAN_EXT); do echo remove ./*$$ext; rm -f ./*$$ext; done
 
