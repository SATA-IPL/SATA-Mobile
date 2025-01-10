import Foundation

/// Converts result string to standardized format
/// - Parameter result: The result string to convert
/// - Returns: Standardized result format (W/D/L)
func convertResult(_ result: String) -> String {
  print("🔄 Converting result: \(result)")
  let converted = switch result.lowercased() {
    case "win": "W"
    case "draw": "D"
    case "loss": "L"
    default: "-"
  }
  print("✅ Converted to: \(converted)")
  return converted
}