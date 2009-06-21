package muppet;

public final class LogRecord {

  private String time;
  private String key;
  private final StringBuilder message = new StringBuilder();

  public String getTime() {
    return time;
  }

  public void setTime(String time) {
    this.time = time;
  }

  public String getKey() {
    return key;
  }

  public void setKey(String key) {
    this.key = key;
  }

  public StringBuilder getMessage() {
    return message;
  }

}
