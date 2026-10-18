enum TaskStatus {
  belum,
  progress,
  done;

  static TaskStatus fromString(String value) {
    return TaskStatus.values.byName(value);
  }
}
