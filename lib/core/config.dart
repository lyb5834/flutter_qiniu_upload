class Config {
  String? fixedZone;
  String? recorderPath;

  static Config fromMap(Map<String, dynamic> map) {
    Config configBean = Config();
    configBean.fixedZone = map['fixedZone'] as String?;
    configBean.recorderPath = map['recorderPath'] as String?;
    return configBean;
  }

  Map<String, dynamic> toJson() => {
        "fixedZone": fixedZone,
        "recorderPath": recorderPath,
      };
}
