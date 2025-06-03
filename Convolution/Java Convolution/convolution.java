import java.util.Scanner;

public class Main {
    public static void main(String[] args) {

        Scanner scanner = new Scanner(System.in);
        long startTime = System.nanoTime();
        int n, rows, columns, x , y;
        float[][] kernel = new float[5][5];
        float[][] inverse = new float[5][5];
        float[][] pixels = new float[1000][1000];
        float[][] result = new float[1000][1000];
        float temp;
        n = scanner.nextInt();
        for(int i = 0; i < n; i++){
            for(int j = 0; j < n; j++){
                temp = scanner.nextFloat();
                kernel[i][j] = temp;
            }
        }
        rows = scanner.nextInt();
        columns = scanner.nextInt();
        for(int i = 0; i < rows; i++){
            for(int j = 0; j < columns; j++){
                temp = scanner.nextFloat();
                pixels[i][j] = temp;
            }
        }
        int counter = 10000000;
        while (counter > 0){
          for(int i = 0; i < rows; i++){
            for(int j = 0; j < columns; j++){
                for(int k = 0; k < n; k++){
                    for(int l = 0; l < n; l++){
                        x = i - n/2 + k;
                        y = j - n/2 + l;
                        if(x < 0)
                            x = 0;
                        else if(x > rows - 1)
                            x = rows - 1;
                        if(y < 0)
                            y = 0;
                        else if(y > columns -1)
                            y = columns - 1;
                        inverse[k][l] = pixels[x][y];
                    }
                }
                result[i][j] = mul_matrix(kernel, inverse, n);
            }
          }
          counter--;
        }
        for(int i = 0; i < rows; i++){
            for(int j = 0; j < columns; j++){
                System.out.print(result[i][j] + " ");
            }
            System.out.println();
        }
        long finishTime = System.nanoTime();
        double duration  = (finishTime - startTime) / 1000000000;
        System.out.println("duration: " + duration);
    }

    static float mul_matrix(float[][] matrix1, float[][] matrix2, int n){
        float sum = 0;
        for (int i = 0; i < n; i++) {
            for (int j = 0; j < n; j++) {
                sum += matrix1[i][j] * matrix2[i][j];
            }
        }
        return sum;
    }
}