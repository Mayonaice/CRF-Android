class ReturnCatridgeResponse {
  final bool success;
  final String message;
  final List<ReturnCatridgeData> data;
  final int recordCount;

  ReturnCatridgeResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.recordCount,
  });

  factory ReturnCatridgeResponse.fromJson(Map<String, dynamic> json) {
    var dataList = json['data'] as List<dynamic>? ?? [];
    List<ReturnCatridgeData> returnCatridgeList = dataList
        .map((item) => ReturnCatridgeData.fromJson(item))
        .toList();

    return ReturnCatridgeResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: returnCatridgeList,
      recordCount: json['recordCount'] ?? 0,
    );
  }
}

class ReturnCatridgeData {
  final String idTool;
  final String catridgeCode;
  final String catridgeSeal;
  final String denomCode;
  final String typeCatridge;

  ReturnCatridgeData({
    required this.idTool,
    required this.catridgeCode,
    required this.catridgeSeal,
    required this.denomCode,
    required this.typeCatridge,
  });

  factory ReturnCatridgeData.fromJson(Map<String, dynamic> json) {
    return ReturnCatridgeData(
      idTool: json['idTool'] ?? '',
      catridgeCode: json['catridgeCode'] ?? '',
      catridgeSeal: json['catridgeSeal'] ?? '',
      denomCode: json['denomCode'] ?? '',
      typeCatridge: json['typeCatridge'] ?? '',
    );
  }
}

// Model for detail return items in the right panel
class DetailReturnItem {
  final int index;
  String noCatridge;
  String sealCatridge;
  int value;
  String total;
  String denom;

  DetailReturnItem({
    required this.index,
    this.noCatridge = '',
    this.sealCatridge = '',
    this.value = 0,
    this.total = '',
    this.denom = '',
  });
}

// Model for return data input
class ReturnInputData {
  final String idTool;
  final String bagCode;
  final String catridgeCode;
  final String sealCode;
  final String catridgeSeal;
  final String denomCode;
  final int qty;
  final String userInput;
  final bool isBalikKaset;
  final String catridgeCodeOld;

  ReturnInputData({
    required this.idTool,
    required this.bagCode,
    required this.catridgeCode,
    required this.sealCode,
    required this.catridgeSeal,
    required this.denomCode,
    required this.qty,
    required this.userInput,
    this.isBalikKaset = false,
    this.catridgeCodeOld = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'idTool': idTool,
      'bagCode': bagCode,
      'catridgeCode': catridgeCode,
      'sealCode': sealCode,
      'catridgeSeal': catridgeSeal,
      'denomCode': denomCode,
      'qty': qty.toString(),
      'userInput': userInput,
      'isBalikKaset': isBalikKaset ? 'Y' : 'N',
      'catridgeCodeOld': catridgeCodeOld,
      'scanCatStatus': 'TEST',
      'scanCatStatusRemark': 'TEST',
      'scanSealStatus': 'TEST',
      'scanSealStatusRemark': 'TEST',
    };
  }
}

class ReturnHeaderData {
  String atmCode;
  String namaBank;
  String lokasi;
  String typeATM;

  ReturnHeaderData({
    this.atmCode = '',
    this.namaBank = '',
    this.lokasi = '',
    this.typeATM = '',
  });

  factory ReturnHeaderData.fromJson(Map<String, dynamic> json) {
    return ReturnHeaderData(
      atmCode: json['atmCode'] ?? '',
      namaBank: json['namaBank'] ?? '',
      lokasi: json['lokasi'] ?? '',
      typeATM: json['typeATM'] ?? '',
    );
  }
}

class ReturnHeaderResponse {
  final bool success;
  final String message;
  final ReturnHeaderData? header;
  final List<ReturnCatridgeData> data;

  ReturnHeaderResponse({
    required this.success,
    required this.message,
    this.header,
    required this.data,
  });

  factory ReturnHeaderResponse.fromJson(Map<String, dynamic> json) {
    return ReturnHeaderResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      header: json['header'] != null ? ReturnHeaderData.fromJson(json['header']) : null,
      data: (json['data'] as List<dynamic>? ?? [])
          .map((item) => ReturnCatridgeData.fromJson(item))
          .toList(),
    );
  }
}

class ReturnDataFromView {
  final String id;
  final String atmCode;
  final String namaBank;
  final String lokasi;
  final String typeATM;
  final String denomCode;
  final double total;

  ReturnDataFromView({
    required this.id,
    required this.atmCode,
    required this.namaBank,
    required this.lokasi,
    required this.typeATM,
    required this.denomCode,
    required this.total,
  });

  factory ReturnDataFromView.fromJson(Map<String, dynamic> json) {
    return ReturnDataFromView(
      id: json['id'] ?? '',
      atmCode: json['atmCode'] ?? '',
      namaBank: json['namaBank'] ?? '',
      lokasi: json['lokasi'] ?? '',
      typeATM: json['typeATM'] ?? '',
      denomCode: json['denomCode'] ?? '',
      total: (json['total'] ?? 0).toDouble(),
    );
  }
}

class ReturnDataFromViewResponse {
  final bool success;
  final String message;
  final List<ReturnDataFromView> data;

  ReturnDataFromViewResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ReturnDataFromViewResponse.fromJson(Map<String, dynamic> json) {
    return ReturnDataFromViewResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>? ?? [])
          .map((item) => ReturnDataFromView.fromJson(item))
          .toList(),
    );
  }
} 