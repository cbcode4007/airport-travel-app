class Flight {
  final String flightIata;
  final String flightIcao;
  final String departNumber;
  final String arriveNumber;
  final String departName;
  final String arriveName;
  final DateTime departDate;
  final DateTime arriveDate;

  Flight({required this.flightIata, required this.flightIcao, required this.departNumber, required this.arriveNumber, required this.departName, required this.arriveName, required this.departDate, required this.arriveDate,});

  factory Flight.fromJson(Map<String, dynamic> json) {
    return Flight(
      flightIata: json['flight']['iata'] ?? '',
      flightIcao: json['flight']['icao'] ?? '',
      departNumber: json['departure']['iata'] ?? '',
      arriveNumber: json['arrival']['iata'] ?? '',
      departName: json['departure']['airport'] ?? '',
      arriveName: json['arrival']['airport'] ?? '',
      departDate: DateTime.tryParse(json['departure']['estimated'] ?? '') ?? DateTime(0),
      arriveDate: DateTime.tryParse(json['arrival']['scheduled'] ?? '') ?? DateTime(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'flightIata': flightIata,
      'flightIcao' : flightIcao,
      'departNumber': departNumber,
      'arriveNumber': arriveNumber,
      'departName': departName,
      'arriveName': arriveName,
      'departDate': departDate.toIso8601String(),
      'arriveDate': arriveDate.toIso8601String(),
    };
  }
}
