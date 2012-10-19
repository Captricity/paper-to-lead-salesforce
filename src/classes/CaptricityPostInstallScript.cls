/* First thing to do once the app is installed, is to put in the third party app credentials */
global class CaptricityPostInstallScript implements InstallHandler {
	global void onInstall(InstallContext context) {
		if (context.previousVersion() == null) {
			CaptricityCalloutUtil.insertDefaultSettings();
		}
	}
}