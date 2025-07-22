// services/weather_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  final String description;
  final double temperature;
  final String cityName;
  final String iconCode;

  WeatherData({
    required this.description,
    required this.temperature,
    required this.cityName,
    required this.iconCode,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      description: json['weather'][0]['description'],
      temperature: json['main']['temp'].toDouble(),
      cityName: json['name'],
      iconCode: json['weather'][0]['icon'],
    );
  }
}

class WeatherService {
  static const String _apiKey = '6ec6f140f1ecb199dca483203cae9530';
  static const String _baseUrl =
      'https://api.openweathermap.org/data/2.5/weather';

  Future<WeatherData> fetchWeatherByLocation(double lat, double lon) async {
    final url = Uri.parse(
      '$_baseUrl?lat=$lat&lon=$lon&units=metric&lang=es&appid=$_apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return WeatherData.fromJson(json);
    } else {
      throw Exception('Error al obtener el clima');
    }
  }
}
