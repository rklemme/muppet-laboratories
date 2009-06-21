package muppet;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStreamReader;

/**
 * Test driver for the <a
 * href="http://blog.rubybestpractices.com/posts/rklemme/008-First_Design_Considerations.html">muppet
 * project</a>.
 * 
 * @author robert
 */
public class TestDriver {

  private static final int TESTS = 5;

  /**
   * Read files and test allocation properties.
   * 
   * @param args
   *                file names.
   * @throws IOException
   */
  public static void main(String[] args) throws IOException {
    for (String arg : args) {
      final File file = new File(arg);

      if (file.canRead()) {
        processFile(file);
      } else {
        System.err.println("Ignoring " + arg);
      }
    }
  }

  /**
   * Process a single file.
   * 
   * @param file
   *                the file to process.
   * @throws IOException
   */
  private static void processFile(File file) throws IOException {
    final FileHandler[] handlers = { new StraightHandler(), new LogRecordHandler(), };
    final long times[] = new long[handlers.length];

    for (int i = 0; i < times.length; ++i) {
      assert times[i] == 0;
    }

    for (int i = 1; i <= TESTS; ++i) {
      System.out.println(file + " run " + i);

      for (int j = 0; j < handlers.length; ++j) {
        final FileHandler handler = handlers[j];
        final long t = processFile(file, handler);
        times[j] += t;
      }

      System.out.println();
    }

    for (int i = 0; i < handlers.length; ++i) {
      System.out.printf("%1d. %10.3f%n", i, ((double) times[i] / TESTS));
    }
  }

  private static long processFile(File file, FileHandler handler) throws IOException {
    final FileInputStream fin = new FileInputStream(file);
    final InputStreamReader reader = new InputStreamReader(fin);
    final BufferedReader lineReader = new BufferedReader(reader, 4096);
    try {
      handler.reset();
      final long t0 = System.currentTimeMillis();
      String line;

      while ((line = lineReader.readLine()) != null) {
        handler.process(line);
      }

      handler.finish();

      final long t1 = System.currentTimeMillis() - t0;
      final long lines = handler.getRecords();
      final double linesPerSec = ((double) lines * 1000) / t1;
      System.out.printf("%-25s %7d lines %7dms %11.3fl/sec%n", handler.getClass().getName(), lines, t1, linesPerSec);
      return t1;
    } finally {
      lineReader.close();
    }
  }
}
