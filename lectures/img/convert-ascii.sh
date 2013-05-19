ditaa -E -S $1.ascii -s 4 -o $1.png
convert $1.png $1.bmp
#mkbitmap -f 2 -s 4 -t 0.48 $1.bmp -o - | potrace -b pdf - -o $1.pdf -n -t 1 -u 1
potrace -b pdf $1.bmp -o $1.pdf -n -t 1 -u 1
