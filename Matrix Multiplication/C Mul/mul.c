#include <stdio.h>
#include <stdlib.h>

int main()
{
    int n;
    float temp;
    float matrix_A[8][8], matrix_B[8][8], matrix_R[8][8];
    scanf("%d", &n);
    printf("--matrix one--\n");
    for(int i = 0; i < n; i++){
        for(int j = 0; j < n; j++){
            scanf("%f", &temp);
            matrix_A[i][j] = temp;
        }
    }
    printf("--matrix two--\n");
    for(int i = 0; i < n; i++){
        for(int j = 0; j < n; j++){
            scanf("%f", &temp);
            matrix_B[i][j] = temp;
        }
    }
    int counter = 100000000;
    while(counter >= 0){

        for (int i = 0; i < n; i++) {
            for (int j = 0; j < n; j++) {
                matrix_R[i][j] = 0;

                for (int k = 0; k < n; k++) {
                    matrix_R[i][j] += matrix_A[i][k] * matrix_B[k][j];
                }
            }
        }

        counter--;
    }
    printf("--matrix reult--\n");
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {

            printf("%f\t", matrix_R[i][j]);
        }
        printf("\n");
    }
    return 0;
}
