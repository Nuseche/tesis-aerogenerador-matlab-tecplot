#!/bin/sh

#Bajo entornos UNIX, este comando puede simplificar la compilación. 
#En entornos MS Windows(R) se pueden buscar herramientas interactivas como TeXnicCenter, TexMaker, etc.

pdflatex -synctex=1 -interaction=nonstopmode FCEFyN-paper.tex
evince FCEFyN-paper.pdf &
bibtex FCEFyN-paper.aux
makeindex FCEFyN-paper.idx
