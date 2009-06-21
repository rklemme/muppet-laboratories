package muppet;

public class StraightHandler extends FileHandler {

  private final StringBuilder lastLine = new StringBuilder();

  @Override
  protected void handle(String time, String key, String message) {
    finishLine();
    assert lastLine.length() == 0;
    lastLine.append(message);
  }

  private void finishLine() {
    if (lastLine.length() > 0) {
      // store
      lastLine.toString();
      countRecord();

      lastLine.setLength(0);
    }
  }

  @Override
  protected void handle(String continuation) {
    lastLine.append(NEW_LINE).append(continuation);
  }

  @Override
  public void finish() {
    finishLine();
  }

}
