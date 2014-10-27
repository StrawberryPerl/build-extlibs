#include <iconv.h>
#include <stdio.h>
#include <gmp.h>

int main()
{
  printf("Hi!\n");
  mpf_t x, y, z, w;
printf("s1\n");
  mpf_init (x);			/* use default precision */
  mpf_init2 (y, 100);		/* precision at least 256 bits */
  mpf_init (y);			/* use default precision */
  mpf_init (z);			/* use default precision */
  mpf_init (w);			/* use default precision */
printf("s3\n");
  mpf_set_ui(x, 13);
printf("s4\n");
  mpf_set_ui(y, 26);
printf("s5\n");
  mpf_div_ui(z, x, 3);
printf("s6\n");
  mpf_div_ui(w, y, 61);
  printf("result=%d\n", mpf_eq(z, w, 300));
  mpf_clear (x);
  mpf_clear (y);
  return 1;
} 
