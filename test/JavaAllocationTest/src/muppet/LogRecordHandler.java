package muppet;

public class LogRecordHandler extends FileHandler {

  private LogRecord last;

  @Override
  protected void handle(String time, String key, String message) {
    finishRecord();

    last = new LogRecord();
    last.setTime(time);
    last.setKey(key);
    last.getMessage().append(message);
  }

  private void finishRecord() {
    if (last != null) {
      // store
      last.getMessage().toString();
      countRecord();
      last = null;
    }
  }

  @Override
  protected void handle(String continuation) {
    last.getMessage().append(NEW_LINE).append(continuation);
  }

  @Override
  public void finish() {
    finishRecord();
  }

}
