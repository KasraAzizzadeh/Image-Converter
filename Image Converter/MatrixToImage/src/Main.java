import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.io.File;
import java.util.Scanner;

public class Main {
    static int width = 0;
    static int height = 0;

    public static void main(String[] args) {
        try {
            // Replace "input.txt" with the actual path to your text file containing pixel values
            Scanner scanner = new Scanner(System.in);
            String inputFileName = scanner.nextLine();
            // Replace "output.png" with the desired name for the output PNG image
            String outputFileName = "output.png";

            // Read pixel values from the text file
            int[] pixelValues = readPixelValuesFromFile(inputFileName);


            // Create a BufferedImage and set pixel values
            BufferedImage image = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
            for (int y = 0; y < height; y++) {
                for (int x = 0; x < width; x++) {
                    int index = y * width + x;
                    int pixelValue = pixelValues[index];
                    int rgb = (pixelValue << 16) | (pixelValue << 8) | pixelValue; // Grayscale image
                    image.setRGB(x, y, rgb);
                }
            }

            // Save the BufferedImage as a PNG file
            ImageIO.write(image, "png", new File(outputFileName));

            System.out.println("PNG image created successfully.");

        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private static int[] readPixelValuesFromFile(String fileName) throws IOException {
        BufferedReader reader = new BufferedReader(new FileReader(fileName));
        width = Integer.parseInt(reader.readLine());
        height = Integer.parseInt(reader.readLine());

        int[] pixelValues = new int[width * height]; // Adjust the size based on your image dimensions

        int index = 0;
        String line;
        while ((line = reader.readLine()) != null && index < pixelValues.length) {
            // Assuming the pixel values are stored as integers
            pixelValues[index] = Integer.parseInt(line.trim());
            index++;
        }

        reader.close();
        return pixelValues;
    }
}
