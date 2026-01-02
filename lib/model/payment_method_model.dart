class PaymentModel {
  Wallet? wallet;
  Cashfree? cashfree;

  PaymentModel({
    this.wallet,
    this.cashfree,
  });

  PaymentModel.fromJson(Map<String, dynamic> json) {
    wallet = json['wallet'] != null ? Wallet.fromJson(json['wallet']) : null;
    cashfree =
        json['cashfree'] != null ? Cashfree.fromJson(json['cashfree']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (wallet != null) {
      data['wallet'] = wallet!.toJson();
    }
    if (cashfree != null) {
      data['cashfree'] = cashfree!.toJson();
    }
    return data;
  }
}

class Wallet {
  bool? enable;
  String? name;

  Wallet({this.enable, this.name});

  Wallet.fromJson(Map<String, dynamic> json) {
    enable = json['enable'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['enable'] = enable;
    data['name'] = name;
    return data;
  }
}

class Cashfree {
  bool? enable;
  String? name;
  String? appId;
  String? clientId;
  String? clientSecret;
  String? secretKey;
  bool? isSandbox;
  bool? isWithdrawEnabled;

  Cashfree({
    this.name,
    this.enable,
    this.appId,
    this.clientId,
    this.clientSecret,
    this.secretKey,
    this.isSandbox,
    this.isWithdrawEnabled,
  });

  Cashfree.fromJson(Map<String, dynamic> json) {
    enable = json['enable'];
    name = json['name'] ?? "Cashfree";
    appId = json['appId'];
    clientId = json['clientId'];
    clientSecret = json['clientSecret'];
    secretKey = json['secretKey'];
    isSandbox = json['isSandbox'];
    isWithdrawEnabled = json['isWithdrawEnabled'] ?? false;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['enable'] = enable;
    data['name'] = name;
    data['appId'] = appId;
    data['clientId'] = clientId;
    data['clientSecret'] = clientSecret;
    data['secretKey'] = secretKey;
    data['isSandbox'] = isSandbox;
    data['isWithdrawEnabled'] = isWithdrawEnabled;
    return data;
  }
}
