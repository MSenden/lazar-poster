#!/bin/bash

cd markdown_blocks
for i in *.md ; do
    echo converting $i to $(basename "${i/.md}").tex  
    pandoc --listings $i -t beamer  |sed '/\(begin\|end\){frame}/d' > $(basename "${i/.md}").tex 
    sleep 1
done