#!/bin/sh
set -eu

if [[ ! -f instance.tex ]]; then
    echo "no instance.tex found!" 1>&2
    exit 1
fi

pdflatex -interaction=batch instance.tex
convert -density 300 instance.pdf -quality 90 -resize 50% -sharpen 0 -fuzz 80% -trim +repage PNG32:formula.png
