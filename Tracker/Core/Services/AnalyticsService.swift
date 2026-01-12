import Foundation
import AppMetricaCore

struct AnalyticsService {
    private static let logger = LoggingService.makeLogger(label: "tracker.analytics")
    
    static func activate() {
        guard
            let rawKey = Bundle.main.object(forInfoDictionaryKey: "AppMetricaAPIKey") as? String
        else {
            logger.error("Missing AppMetricaAPIKey in Info.plist")
            return
        }
        
        let apiKey = rawKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard
            !apiKey.isEmpty,
            apiKey != "REPLACE_ME",
            apiKey != "YOUR_APP_METRICA_API_KEY",
            let configuration = AppMetricaConfiguration(apiKey: apiKey)
        else {
            logger.error("Invalid AppMetricaAPIKey value")
            return
        }
        
        AppMetrica.activate(with: configuration)
    }
    
    static func report(event: String, params : [AnyHashable : Any]) {
        AppMetrica.reportEvent(name: event, parameters: params, onFailure: { error in
            Self.logger.error("Failed to report event: \(error.localizedDescription)")
        })
    }
}
