/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This controller manages the watchOS app's complications.
*/

import ClockKit
import os.log

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    static func updateAllActiveComplications() {
        let complicationServer = CLKComplicationServer.sharedInstance()
        
        guard let activeComplications = complicationServer.activeComplications else {
            return
        }
        
        for complication in activeComplications {
            complicationServer.reloadTimeline(for: complication)
        }
    }
    
    private let logger = Logger(
        subsystem: BARBluetoothApp.name,
        category: String(describing: ComplicationController.self)
    )
    
    // MARK: - Complication Configuration

    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(identifier: "com.example.bar-bluetooth",
                                      displayName: "BARBluetooth",
                                      supportedFamilies: CLKComplicationFamily.allCases)
        ]
        
        // Call the handler with the currently supported complication descriptors.
        handler(descriptors)
    }
    
    func handleSharedComplicationDescriptors(_ complicationDescriptors: [CLKComplicationDescriptor]) {
        // Do any necessary work to support these newly shared complication descriptors.
    }

    // MARK: - Timeline Configuration
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        // Call the handler with nil to indicate that the app can't support future timelines.
        handler(nil)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        // Shows the complication when the device is locked.
        handler(.showOnLockScreen)
    }

    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        
        let value = UserDefaults.standard.integer(forKey: BluetoothConstants.receivedDataKey)
        
        if let template = makeTemplate(for: complication, value: value) {
            logger.info("updating all active \(BARBluetoothApp.name) complications")
            handler(CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template))
        } else {
            handler(nil)
        }
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int,
                            withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // This app doesn't support batch-loading future timeline entries.
        handler(nil)
    }

    // MARK: - Sample Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        let template = makeTemplate(for: complication, value: 23)
        handler(template)
    }
    
    // MARK: -
    
    private func makeTemplate(for complication: CLKComplication, value: Int) -> CLKComplicationTemplate? {
        
        let unitString = "℃"
        
        switch complication.family {
        case .graphicCircular:
            return CLKComplicationTemplateGraphicCircularStackText(
                line1TextProvider: CLKSimpleTextProvider(text: "\(value)"),
                line2TextProvider: CLKSimpleTextProvider(text: unitString)
            )
        case .graphicRectangular:
            return CLKComplicationTemplateGraphicRectangularStandardBody(
                headerTextProvider: CLKSimpleTextProvider(text: "Temperature"),
                body1TextProvider: CLKSimpleTextProvider(text: "\(value)\(unitString)")
            )
        case .circularSmall:
            return CLKComplicationTemplateCircularSmallStackText(
                line1TextProvider: CLKSimpleTextProvider(text: "\(value)"),
                line2TextProvider: CLKSimpleTextProvider(text: unitString)
            )
        case .modularSmall:
            return CLKComplicationTemplateModularSmallStackText(
                line1TextProvider: CLKSimpleTextProvider(text: "\(value)"),
                line2TextProvider: CLKSimpleTextProvider(text: unitString)
            )
        case .modularLarge:
            return CLKComplicationTemplateModularLargeStandardBody(
                headerTextProvider: CLKSimpleTextProvider(text: "Temperature"),
                body1TextProvider: CLKSimpleTextProvider(text: "\(value)\(unitString)")
            )
        case .graphicCorner:
            return CLKComplicationTemplateGraphicCornerStackText(
                innerTextProvider: CLKSimpleTextProvider(text: "Temperature"),
                outerTextProvider: CLKSimpleTextProvider(text: "\(value)\(unitString)")
            )
        default:
            return nil
        }
    }
}
