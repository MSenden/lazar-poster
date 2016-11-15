#!/bin/bash

POSTERFILE=$1
mdblocks=$(grep "\\input{./markdown_blocks/" $POSTERFILE|sed 's/\\input{.\/markdown_blocks\///g'|sed 's/}/.md/g' )

cd markdown_blocks
for i in $mdblocks ; do
    echo converting $i to $(basename "${i/.md}").tex
    pandoc --highlight-style=kate --listings $i -t beamer -f markdown+implicit_figures+header_attributes+table_captions+simple_tables+multiline_tables+pipe_tables+grid_tables+simple_tables --bibliography=../references.bib |sed '/\(begin\|end\){frame}/d' > $(basename "${i/.md}").tex
    #sleep 1
done
