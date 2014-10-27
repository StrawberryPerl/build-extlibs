/*  gcc -xc -E /dev/null -dD */

int main()
{
printf ("\n__MINGW__\t: ");
#ifdef __MINGW__
printf ("defined");
#endif

printf ("\n__MINGW32__\t: ");
#ifdef __MINGW32__
printf ("defined");
#endif

printf ("\n__MINGW64__\t: ");
#ifdef __MINGW64__
printf ("defined");
#endif

printf ("\nWIN64\t\t: ");
#ifdef WIN64
printf ("defined");
#endif

printf ("\n_WIN64\t\t: ");
#ifdef _WIN64
printf ("defined");
#endif

printf ("\nWIN32\t\t: ");
#ifdef WIN32
printf ("defined");
#endif

printf ("\n_WIN32\t\t: ");
#ifdef _WIN32
printf ("defined");
#endif

printf ("\nGNUC\t\t: ");
#ifdef GNUC
printf ("defined");
#endif

}