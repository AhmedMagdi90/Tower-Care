import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareService {
  Future<void> shareText(String text, {String? subject}) async {
    await Share.share(text, subject: subject);
  }

  Future<void> shareToWhatsApp(String text) async {
    final encoded = Uri.encodeComponent(text);
    final whatsapp = Uri.parse('whatsapp://send?text=$encoded');
    if (await canLaunchUrl(whatsapp)) {
      await launchUrl(whatsapp, mode: LaunchMode.externalApplication);
      return;
    }

    final webWhatsapp = Uri.parse('https://wa.me/?text=$encoded');
    if (await canLaunchUrl(webWhatsapp)) {
      await launchUrl(webWhatsapp, mode: LaunchMode.externalApplication);
      return;
    }

    await Share.share(text);
  }

  Future<void> shareFile(String path, {String? text}) async {
    await Share.shareXFiles([XFile(path)], text: text);
  }
}
