package muppet;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

public abstract class FileHandler {

  protected final static String NEW_LINE = System.getProperty("line.separator", "\n");

  /**
   * Parse lines like
   * 
   * <pre>
   * 2009-06-21 15:09:10.605 lledqnqqmmxwudl END
   * </pre>
   */
  private static final Pattern LOG_LINE = Pattern
      .compile("(\\d{4}-\\d{2}-\\d{2}\\s\\d{2}:\\d{2}:\\d{2}\\.\\d{0,3})\\s(\\S+)\\s(.*)");

  private final Matcher matcher = LOG_LINE.matcher("");

  private long records;

  protected abstract void handle(String time, String key, String message);

  protected abstract void handle(String continuation);

  public void reset() {
    records = 0;
  }

  protected void countRecord() {
    ++records;
  }

  public long getRecords() {
    return records;
  }

  public void process(String line) {
    if (matcher.reset(line).matches()) {
      // regular line
      handle(matcher.group(1), matcher.group(2), line);
    } else {
      // continuation line
      handle(line);
    }
  }

  public void finish() {
    // nothing to do
  }
}
