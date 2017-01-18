# lazar-poster

lazar-poster is a poster template that uses pandoc, pdflatex and beamer-poster to create scientific posters out of a \*.tex template and some markdown files. Markdown-files will be compiled to latex files by the makefile, before they are inserted into the beamerposter template. Markdown is much easier to edit for the textblocks and the *LaTeX* template provides a good possibility for positioning blocks and format posters. ```make```command generates PDF output in A0 Poster size, adjust the Makefile to compile your poster. 

## Usage

### Edit header contents
Edit title, author, institute/company and footer
```latex
\title{lazar: a modular predictive toxicology framework}
\author{C. Helma, M. Rautenberg, D. Gebele}
\institute{\emph{in silico} toxicology gmbh, Basel, Switzerland}
\footer{Contact: \texttt{support@in-silico.ch}. Information: \texttt{www.in-silico.ch}}
```
### Textblocks
Add a textblock with markdown-content (link the file company in directory markdown_blocks) for the company description. 
```latex
\begin{textblock}{40.0}(1,6)   % textblock, width 40, position x,y
  \input{./markdown_blocks/company} % insert textblock company.tex
\end{textblock}
```

Add a textblock with justified text
```latex
\begin{block}{My Textblocktitle}
  \justifying
  \input{./markdown_blocks/mytextblock}
\end{block}
```


the directory *markdown_blocks* contains the markdown documents. 
e.G.: company.md

```markdown
***my company***, Sometown, Everywhere – Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse commodo elit eget tellus posuere, eget blandit metus pretium. Mauris eu volutpat nisl. Praesent iaculis eros sit amet cursus fringilla. Morbi rhoncus bibendum odio, ut tincidunt sapien. Nam pellentesque nunc tellus, eu volutpat risus vehicula nec. Integer id volutpat mi. 
```

### Citations
to cite an article add 
```latex
\cite{ArticleName}
``` 
in the markdown document. Articles are listed in the file references.bib. References will be added automatically during compilation.


### Add images
add images in the markdown files with standard markdown syntax 
```markdown
![Endpoints](./images/my_image.png){width=600px }
```
### Add tables
see ```man pandoc``` for all table formats. This example is made with the *pipe_tables* extension.
```markdown
| Descriptor     | Val1 | Val2    | Val3   |
|----------------|-----:|---------|:------:|
| Physchem A     |  12  |    12   |    12  |
| Physchem B     |  123 |   123   |   123  |
| Physchem C     |    1 |     1   |     1  |

: Here's the caption of the table.
```
