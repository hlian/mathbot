pdflatex -interaction=batch "\deformula{E=rac{m_1v^2}{2}}\input{formula.tex}"; convert -density 300 formula.pdf -quality 90 -resize 50% -sharpen 0 -fuzz 80% -trim +repage PNG32:formula.png
