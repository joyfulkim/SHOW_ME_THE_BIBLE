const configuredAdminEmails = {
  'kms@jfm.kr',
};

bool isConfiguredAdminEmail(String? email) {
  if (email == null) return false;
  return configuredAdminEmails.contains(email.trim().toLowerCase());
}
