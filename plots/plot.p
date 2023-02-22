set terminal pdf
set termoption enhanced

set output "decimaler.pdf"

set logscale x 2
set logscale y 2

set title ""

set key left center

set xlabel "kast"

set ylabel "Error"

plot "bench.dat" u 1:2 w linespoints title "Error", \
     "bench.dat" u 1:3 w linespoints title "1-decimal", \
     "bench.dat" u 1:4 w linespoints title "2-decimaler", \
     "bench.dat" u 1:5 w linespoints title "3-decimaler", \
     "bench.dat" u 1:6 w linespoints title "4-decimaler", \
     "bench.dat" u 1:7 w linespoints title "5-decimaler", \
     "bench.dat" u 1:8 w linespoints title "6-decimaler", \
