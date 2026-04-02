import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agora_rtm/agora_rtm.dart';
import 'user_model.dart';

class VoiceTherapyRoom {
  // استبدل هذه القيم بالمفاتيح التي حصلت عليها من Agora Console
  static const String appId = "YOUR_AGORA_APP_ID"; 
  static const String token = "YOUR_AGORA_TOKEN"; // اتركها فارغة إذا اخترت App ID Only في الإعدادات

  late RtcEngine _engine;
  late AgoraRtmClient _rtmClient;
  bool _isInitialized = false;

  // تهيئة المحرك
  Future<void> initAgora(String userUid) async {
    if (_isInitialized) return;
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(appId: appId));
    
    // تمكين نظام الصوت
    await _engine.enableAudio();
    await _engine.setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
    _isInitialized = true;

    // تهيئة RTM للاستقبال
    _rtmClient = await AgoraRtmClient.createInstance(appId);
    await _rtmClient.login(null, userUid);
    
    // الاستماع للرسائل الخاصة
    _rtmClient.onMessageReceived = (AgoraRtmMessage message, String peerId) {
      if (message.text == 'force_mute') {
        // تنفيذ الكتم الإجباري محلياً عند المريض
        toggleLocalAudio(true);
        // يمكن إضافة تنبيه للمريض هنا
        print("تم كتم الميكروفون بواسطة المعالج");
      }
    };
  }

  // تشغيل مقطع صوتي للجميع (Broadcasting Audio)
  // يسمعه جميع المشاركين في القناة
  Future<void> playHealingAudio(String audioUrl) async {
    await _engine.startAudioMixing(
      filePath: audioUrl,
      loopback: false, // false لضمان إرساله للشبكة وليس فقط للجهاز المحلي
      cycle: 1,
    );
  }

  // إيقاف المقطع الصوتي
  Future<void> stopHealingAudio() async {
    await _engine.stopAudioMixing();
  }

  // كتم/إلغاء كتم الميكروفون الخاص بي
  Future<void> toggleLocalAudio(bool mute) async {
    await _engine.muteLocalAudioStream(mute);
  }

  // كتم الصوت عن المشرف فقط (RTC)
  Future<void> muteAllUsers(bool mute) async {
    await _engine.muteAllRemoteAudioStreams(mute);
  }

  // إرسال إشارة إجبار مريض على الصمت (تتطلب منطق RTM في الواجهة)
  Future<void> forceMuteUserSignal(String userUid) async {
    await _rtmClient.sendMessageToPeer(userUid, AgoraRtmMessage.fromText('force_mute'));
  }

  // كتم مستخدم محدد (للمسؤول)
  Future<void> muteSpecificUser(int uid, bool mute) async {
    await _engine.muteRemoteAudioStream(uid: uid, mute: mute);
  }

  // الانضمام للمكالمة (فردية أو جماعية)
  Future<void> joinRoom(String channelId, int uid, UserRole role, {bool isSilent = false}) async {
    // تحديد الدور بناءً على نوع المستخدم
    ClientRoleType agoraRole = ClientRoleType.clientRoleBroadcaster;
    
    // إذا كان المريض في وضع الاستماع فقط يمكن تغيير الدور، 
    // ولكن في العلاج الجماعي عادة الكل يحتاج الكلام

    await _engine.joinChannel(
      token: token,
      channelId: channelId,
      uid: uid,
      options: ChannelMediaOptions(
        clientRoleType: agoraRole,
        publishMicrophoneTrack: !isSilent,
        autoSubscribeAudio: true,
      ),
    );
  }

  // مغادرة المكالمة
  Future<void> leaveRoom() async {
    await _engine.stopAudioMixing();
    await _engine.leaveChannel();
    // لا نغلق المحرك هنا لضمان إمكانية إعادة الاستخدام
  }
}