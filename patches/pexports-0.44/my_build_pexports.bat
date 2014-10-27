gcc -Wall -c -o hlex.o hlex.c
gcc -Wall -c -o hparse.o hparse.c
gcc -Wall -c -o pexports.o pexports.c
gcc -Wall -c -o str_tree.o str_tree.c
gcc -Wall -o pexports.exe hlex.o hparse.o pexports.o str_tree.o