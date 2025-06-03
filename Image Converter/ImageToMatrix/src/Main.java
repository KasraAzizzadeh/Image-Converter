import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.*;
import java.util.Scanner;

public class Main {

    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);
        try {
            // Replace "input.png" with the actual path to your input grayscale image
            String inputFileName = scanner.nextLine();
            // Replace "output.txt" with the desired name for the output text file
            String outputFileName = "output.txt";

            // Read grayscale pixel values from the image
            int[] pixelValues = readGrayscalePixelsFromFile(inputFileName);

            // Save the pixel values to a text file
            savePixelValuesToFile(inputFileName, outputFileName, pixelValues);

            System.out.println("Pixel values saved to " + outputFileName + " successfully.");

        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private static int[] readGrayscalePixelsFromFile(String fileName) throws IOException {
        BufferedImage image = ImageIO.read(new File(fileName));
        int width = image.getWidth();
        int height = image.getHeight();



        int[] pixelValues = new int[width * height];

        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                int rgb = image.getRGB(x, y);
                int red = (rgb >> 16) & 0xFF;
                int green = (rgb >> 8) & 0xFF;
                int blue = rgb & 0xFF;

                // Assuming grayscale, use the red component (or any other channel, they are the same)
                pixelValues[y * width + x] = red;
            }
        }

        return pixelValues;
    }

    private static void savePixelValuesToFile(String  inputFileName, String outputFileName, int[] values) throws IOException {
        try (PrintWriter writer = new PrintWriter(new FileWriter(outputFileName))) {
            BufferedImage image = ImageIO.read(new File(inputFileName));
            int width = image.getWidth();
            int height = image.getHeight();
            writer.println(width);
            writer.println(height);

            for (int value : values) {
                writer.println(value);
            }
        }
    }
}