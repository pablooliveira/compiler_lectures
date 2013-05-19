SRCS = $(wildcard *.md)
ALL_PDF = $(patsubst %.md,%.pdf,$(SRCS))

all: pdf

pdf: $(ALL_PDF)

%.pdf: %.md
	./do-dot.py $< > $<.md.tmp
	pandoc --chapters -t beamer -f markdown $<.md.tmp -o $@

clean:
	rm -f $(ALL_PDF) *.snm *.toc *.out *.nav *.aux *.log *.ps *.dvi temp_* *.tmp
