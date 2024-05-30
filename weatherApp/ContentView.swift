import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var weather: Weather?

    var body: some View {
        VStack {
            if let location = locationManager.location {
               
                if let weather = weather {
                    Text("Temperature: \(String(format: "%.0f", weather.temp.rounded()))°F")
                    Text("Feels Like: \(String(format: "%.0f", weather.feels_like.rounded()))°F")
                    Text("Humidity: \(String(format: "%.0f", weather.humidity.rounded()))%")
                }
                Button(action: {
                    fetchWeather(for: location)
                }) {
                    Text("Refresh Weather for Current Location")
                }
                .padding()
            } else {
                Text("Fetching location...")
            }
        }
        .padding()
    }

    func fetchWeather(for location: CLLocationCoordinate2D) {
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(location.latitude)&longitude=\(location.longitude)&current=temperature_2m,relative_humidity_2m,apparent_temperature&hourly=temperature_2m,relative_humidity_2m,dew_point_2m,apparent_temperature,uv_index&temperature_unit=fahrenheit&wind_speed_unit=mph&precipitation_unit=inch&past_days=0"

        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                if let decodedResponse = try? JSONDecoder().decode(WeatherResponse.self, from: data) {
                    DispatchQueue.main.async {
                        self.weather = Weather(temp: decodedResponse.current.temperature_2m, humidity:decodedResponse.current.relative_humidity_2m,
                                               feels_like:decodedResponse.current.apparent_temperature,uv: decodedResponse.hourly.uv_index[0],
                                               temp_forecast:decodedResponse.hourly.temperature_2m[0])
                    }
                    return
                }
            }
        }.resume()
    }
}

struct Weather {
    let temp: Double
    let humidity: Double
    let feels_like: Double
    let uv: Double
    let temp_forecast: Double
}

struct WeatherResponse: Codable {
    struct Current: Codable {
        let temperature_2m: Double
        let relative_humidity_2m: Double
        let apparent_temperature: Double
    }
    struct Hourly: Codable {
        let temperature_2m: [Double]
        let uv_index: [Double]
    }
    let current: Current
    let hourly: Hourly
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocationCoordinate2D?

    override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        self.location = location.coordinate
        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
}
