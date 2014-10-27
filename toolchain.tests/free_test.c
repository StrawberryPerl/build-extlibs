#include <stdio.h>
#include <stdlib.h> /* required for the malloc and free functions */

int main() {
  int number = 1000;
  int *ptr;
  int i;


  ptr = malloc(number*sizeof(int)); /* allocate memory */
 
  if(ptr!=NULL) {
    for(i=0 ; i<number ; i++) {
      *(ptr+i) = i;
    }

    for(i=number ; i>0 ; i--) {
      printf("%d\n", *(ptr+(i-1))); /* print out in reverse order */
    }

    printf("Before free-1\n");
    free(ptr); /* free allocated memory */
    printf("Before free-2\n");
    free(ptr); /* free allocated memory */
    printf("Before free-3\n");
    free(ptr); /* free allocated memory */
    printf("Before free-4\n");
    free(ptr); /* free allocated memory */
    printf("Before free-5\n");
    free(ptr); /* free allocated memory */
    printf("Before free-6\n");
    free(ptr); /* free allocated memory */
    printf("Before free-7\n");
    free(ptr); /* free allocated memory */
    printf("Before free-8\n");
    free(ptr); /* free allocated memory */
    return 0;
  }
  else {
    printf("\nMemory allocation failed - not enough memory.\n");
    return 1;
  }
}
