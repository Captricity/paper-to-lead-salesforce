global class CaptricityPostInstallScript implements InstallHandler {
	global void onInstall(InstallContext context) {
		if (context.previousVersion() == null) {
			CaptricityCalloutUtil.insertDefaultSettings();
		}
	}
}