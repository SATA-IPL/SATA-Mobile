import Foundation
import MapKit

struct Stadium: Codable, Identifiable {
  let clubId: String
  let id: String
  let latitude: Double
  let location: String
  let longitude: Double
  let stadiumName: String
  let stadiumSeats: Int
  let yearBuilt: String
  var isFavorite: Bool = false
  
  enum CodingKeys: String, CodingKey {
    case clubId = "club_id"
    case id
    case latitude
    case location
    case longitude
    case stadiumName
    case stadiumSeats
    case yearBuilt
  }
  
  var coordinate: CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }
}
