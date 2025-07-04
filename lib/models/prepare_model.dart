class PrepareReplenishResponse {
  final bool success;
  final String message;
  final ATMPrepareReplenishData? data;
  final int recordCount;

  PrepareReplenishResponse({
    required this.success,
    required this.message,
    this.data,
    required this.recordCount,
  });

  factory PrepareReplenishResponse.fromJson(Map<String, dynamic> json) {
    return PrepareReplenishResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? ATMPrepareReplenishData.fromJson(json['data']) : null,
      recordCount: json['recordCount'] ?? 0,
    );
  }
}

class CatridgeDetail {
  final int id;
  final String code;
  final String seal;
  final int denom;
  final int value;

  CatridgeDetail({
    required this.id,
    required this.code,
    required this.seal,
    required this.denom,
    required this.value,
  });

  factory CatridgeDetail.fromJson(Map<String, dynamic> json) {
    return CatridgeDetail(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      seal: json['seal'] ?? '',
      denom: json['denom'] ?? 0,
      value: json['value'] ?? 0,
    );
  }
}

class ATMPrepareReplenishData {
  final int id;
  final String planNo;
  final int idLokasi;
  final DateTime datePlanning;
  final String atmCode;
  final String jnsMesin;
  final String codeBank;
  final String idTypeATM;
  final String idCust1;
  final String idCust2;
  final String cashierCode;
  final DateTime? dateStart;
  final DateTime? dateFinish;
  final String tripType;
  final String bagCode;
  final String catridgeCode;
  final String sealCode;
  final String catridgeSeal;
  final String denomCode;
  final int qty;
  final String runCode;
  final String nmRun;
  final int value;
  final int total;
  final String lokasi;
  final String namaBank;
  final String name;
  final String typeCatridge;
  final DateTime? dateReplenish;
  final String siklusCode;
  final String tableCode;
  final String typeATM;
  final int jmlKaset;
  final int standValue;
  final String branchCode;
  final String kasir;
  final String tipeDenom;
  final int jumlah;
  final int denomCass1;
  final int denomCass2;
  final int denomCass3;
  final int denomCass4;
  final int denomCass5;
  final int denomCass6;
  final int denomCass7;
  final int jmlCass1;
  final int jmlCass2;
  final int jmlCass3;
  final int jmlCass4;
  final int jmlCass5;
  final int jmlCass6;
  final int jmlCass7;
  final bool isEmpty;
  final bool isNoBag;
  final bool isMDM;
  final List<CatridgeDetail> listCatridge;

  ATMPrepareReplenishData({
    required this.id,
    required this.planNo,
    required this.idLokasi,
    required this.datePlanning,
    required this.atmCode,
    required this.jnsMesin,
    required this.codeBank,
    required this.idTypeATM,
    required this.idCust1,
    required this.idCust2,
    required this.cashierCode,
    this.dateStart,
    this.dateFinish,
    required this.tripType,
    required this.bagCode,
    required this.catridgeCode,
    required this.sealCode,
    required this.catridgeSeal,
    required this.denomCode,
    required this.qty,
    required this.runCode,
    required this.nmRun,
    required this.value,
    required this.total,
    required this.lokasi,
    required this.namaBank,
    required this.name,
    required this.typeCatridge,
    this.dateReplenish,
    required this.siklusCode,
    required this.tableCode,
    required this.typeATM,
    required this.jmlKaset,
    required this.standValue,
    required this.branchCode,
    required this.kasir,
    required this.tipeDenom,
    required this.jumlah,
    required this.denomCass1,
    required this.denomCass2,
    required this.denomCass3,
    required this.denomCass4,
    required this.denomCass5,
    required this.denomCass6,
    required this.denomCass7,
    required this.jmlCass1,
    required this.jmlCass2,
    required this.jmlCass3,
    required this.jmlCass4,
    required this.jmlCass5,
    required this.jmlCass6,
    required this.jmlCass7,
    required this.isEmpty,
    required this.isNoBag,
    required this.isMDM,
    required this.listCatridge,
  });

  factory ATMPrepareReplenishData.fromJson(Map<String, dynamic> json) {
    List<CatridgeDetail> catridgeList = [];
    
    // Check for catridge data in different formats
    if (json['listCatridge'] != null) {
      // If listCatridge field is present as an array
      catridgeList = (json['listCatridge'] as List)
          .map((item) => CatridgeDetail.fromJson(item))
          .toList();
    } else {
      // Create a synthetic list from individual catridge data
      // Add each catridge that has valid data
      if (json['catridgeCode'] != null && json['catridgeCode'].toString().isNotEmpty) {
        catridgeList.add(CatridgeDetail(
          id: 1,
          code: json['catridgeCode'] ?? '',
          seal: json['catridgeSeal'] ?? '',
          denom: json['denomCass1'] ?? 0,
          value: json['value'] ?? 0,
        ));
      }
      
      // Add additional catridges based on jmlKaset if needed
      int jmlKaset = json['jmlKaset'] ?? 0;
      for (int i = 1; i < jmlKaset; i++) {
        if (i >= catridgeList.length) {
          catridgeList.add(CatridgeDetail(
            id: i + 1,
            code: '',
            seal: '',
            denom: i == 1 ? (json['denomCass2'] ?? 0) :
                  i == 2 ? (json['denomCass3'] ?? 0) :
                  i == 3 ? (json['denomCass4'] ?? 0) :
                  i == 4 ? (json['denomCass5'] ?? 0) :
                  i == 5 ? (json['denomCass6'] ?? 0) :
                  i == 6 ? (json['denomCass7'] ?? 0) : 0,
            value: 0,
          ));
        }
      }
    }
    
    return ATMPrepareReplenishData(
      id: json['id'] ?? 0,
      planNo: json['planNo'] ?? '',
      idLokasi: json['idLokasi'] ?? 0,
      datePlanning: json['datePlanning'] != null ? DateTime.parse(json['datePlanning']) : DateTime.now(),
      atmCode: json['atmCode'] ?? '',
      jnsMesin: json['jnsMesin'] ?? '',
      codeBank: json['codeBank'] ?? '',
      idTypeATM: json['idTypeATM'] ?? '',
      idCust1: json['idCust1'] ?? '',
      idCust2: json['idCust2'] ?? '',
      cashierCode: json['cashierCode'] ?? '',
      dateStart: json['dateStart'] != null ? DateTime.parse(json['dateStart']) : null,
      dateFinish: json['dateFinish'] != null ? DateTime.parse(json['dateFinish']) : null,
      tripType: json['tripType'] ?? '',
      bagCode: json['bagCode'] ?? '',
      catridgeCode: json['catridgeCode'] ?? '',
      sealCode: json['sealCode'] ?? '',
      catridgeSeal: json['catridgeSeal'] ?? '',
      denomCode: json['denomCode'] ?? '',
      qty: json['qty'] ?? 0,
      runCode: json['runCode'] ?? '',
      nmRun: json['nmRun'] ?? '',
      value: json['value'] ?? 0,
      total: json['total'] ?? 0,
      lokasi: json['lokasi'] ?? '',
      namaBank: json['namaBank'] ?? '',
      name: json['name'] ?? '',
      typeCatridge: json['typeCatridge'] ?? '',
      dateReplenish: json['dateReplenish'] != null ? DateTime.parse(json['dateReplenish']) : null,
      siklusCode: json['siklusCode'] ?? '',
      tableCode: json['tableCode'] ?? '',
      typeATM: json['typeATM'] ?? '',
      jmlKaset: json['jmlKaset'] ?? 0,
      standValue: json['standValue'] ?? 0,
      branchCode: json['branchCode'] ?? '',
      kasir: json['kasir'] ?? '',
      tipeDenom: json['tipeDenom'] ?? '',
      jumlah: json['jumlah'] ?? 0,
      denomCass1: json['denomCass1'] ?? 0,
      denomCass2: json['denomCass2'] ?? 0,
      denomCass3: json['denomCass3'] ?? 0,
      denomCass4: json['denomCass4'] ?? 0,
      denomCass5: json['denomCass5'] ?? 0,
      denomCass6: json['denomCass6'] ?? 0,
      denomCass7: json['denomCass7'] ?? 0,
      jmlCass1: json['jmlCass1'] ?? 0,
      jmlCass2: json['jmlCass2'] ?? 0,
      jmlCass3: json['jmlCass3'] ?? 0,
      jmlCass4: json['jmlCass4'] ?? 0,
      jmlCass5: json['jmlCass5'] ?? 0,
      jmlCass6: json['jmlCass6'] ?? 0,
      jmlCass7: json['jmlCass7'] ?? 0,
      isEmpty: json['isEmpty'] ?? false,
      isNoBag: json['isNoBag'] ?? false,
      isMDM: json['isMDM'] ?? false,
      listCatridge: catridgeList,
    );
  }
}

// Model for catridge lookup response
class CatridgeData {
  final String code;
  final String barCode;
  final String typeCatridge;
  final String codeBank;
  final int standValue;

  CatridgeData({
    required this.code,
    required this.barCode,
    required this.typeCatridge,
    required this.codeBank,
    required this.standValue,
  });

  factory CatridgeData.fromJson(Map<String, dynamic> json) {
    return CatridgeData(
      code: json['Code'] ?? '',
      barCode: json['BarCode'] ?? '',
      typeCatridge: json['TypeCatridge'] ?? '',
      codeBank: json['CodeBank'] ?? '',
      standValue: json['StandValue'] ?? 0,
    );
  }
}

class CatridgeResponse {
  final bool success;
  final String message;
  final List<CatridgeData> data;

  CatridgeResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory CatridgeResponse.fromJson(Map<String, dynamic> json) {
    var dataList = json['data'] as List<dynamic>? ?? [];
    List<CatridgeData> catridgeList = dataList
        .map((item) => CatridgeData.fromJson(item))
        .toList();

    return CatridgeResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: catridgeList,
    );
  }
}

// Model for comprehensive seal validation response from SP
class SealValidationData {
  final String validationStatus;
  final String errorCode;
  final String errorMessage;
  final String validatedSealCode;
  final DateTime validationDate;
  final String requestedSealCode;

  SealValidationData({
    required this.validationStatus,
    required this.errorCode,
    required this.errorMessage,
    required this.validatedSealCode,
    required this.validationDate,
    required this.requestedSealCode,
  });

  factory SealValidationData.fromJson(Map<String, dynamic> json) {
    return SealValidationData(
      validationStatus: json['validationStatus'] ?? '',
      errorCode: json['errorCode'] ?? '',
      errorMessage: json['errorMessage'] ?? '',
      validatedSealCode: json['validatedSealCode'] ?? '',
      validationDate: json['validationDate'] != null 
        ? DateTime.parse(json['validationDate']) 
        : DateTime.now(),
      requestedSealCode: json['requestedSealCode'] ?? '',
    );
  }
}

class SealValidationResponse {
  final bool success;
  final String message;
  final SealValidationData? data;

  SealValidationResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory SealValidationResponse.fromJson(Map<String, dynamic> json) {
    return SealValidationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? SealValidationData.fromJson(json['data']) : null,
    );
  }
}

// Model for detail catridge items in the right panel
class DetailCatridgeItem {
  final int index;
  String noCatridge;
  String sealCatridge;
  int value;
  String total;
  String denom;

  DetailCatridgeItem({
    required this.index,
    this.noCatridge = '',
    this.sealCatridge = '',
    this.value = 0,
    this.total = '',
    this.denom = '',
  });
}

// Generic API Response model for planning/update and atm/catridge APIs
class ApiResponse {
  final bool success;
  final String message;
  final dynamic data;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }
} 