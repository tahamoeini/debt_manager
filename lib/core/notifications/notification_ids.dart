class NotificationIds {
  static const int installmentBase = 1000000000; // large base within int32
  static int forInstallment(int installmentId) => installmentBase + installmentId;
  static bool isInstallment(int id) => id >= installmentBase;
}
