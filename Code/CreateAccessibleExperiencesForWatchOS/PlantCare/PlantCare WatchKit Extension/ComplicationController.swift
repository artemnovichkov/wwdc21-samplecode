/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The complication data source.
*/

import ClockKit
class ComplicationController: NSObject, CLKComplicationDataSource {
    // The Plant Tracker app's data model
    lazy var plant = PlantData.shared.plants[0]
        
    // MARK: - Complication Configuration

    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(identifier: "Plant_Care", displayName: "Plant Care", supportedFamilies: CLKComplicationFamily.allCases)
        ]
        handler(descriptors)
    }

    func handleSharedComplicationDescriptors(_ complicationDescriptors: [CLKComplicationDescriptor]) {
        // Do any necessary work to support these newly shared complication descriptors.
    }

    // MARK: - Timeline Configuration
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(Date().addingTimeInterval(24.0 * 60.0 * 60.0))
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }

    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        handler(createTimelineEntry(forComplication: complication, date: Date()))
    }
    
    func getTimelineEntries(
        for complication: CLKComplication,
        after date: Date,
        limit: Int,
        withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries after the given date.
        let fiveMinutes = 5.0 * 60.0
        let twentyFourHours = 24.0 * 60.0 * 60.0
        
        // Create an array to hold the timeline entries.
        var entries = [CLKComplicationTimelineEntry]()
        
        // Calculate the start and end dates.
        var current = date.addingTimeInterval(fiveMinutes)
        let endDate = date.addingTimeInterval(twentyFourHours)
        
        // Create a timeline entry for every five minutes from the starting time.
        // Stop once you reach the limit or the end date.
        while current.compare(endDate) == .orderedAscending && entries.count < limit {
            entries.append(createTimelineEntry(forComplication: complication, date: current))
            current = current.addingTimeInterval(fiveMinutes)
        }
        
        handler(entries)
    }

    // MARK: - Sample Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        let future = Date().addingTimeInterval(25.0 * 60.0 * 60.0)
        let template = createTemplate(forComplication: complication, date: future)
        handler(template)
    }
    
    // MARK: - Private Methods
    
    private func createTimelineEntry(forComplication complication: CLKComplication, date: Date) -> CLKComplicationTimelineEntry {
        let template = createTemplate(forComplication: complication, date: date)
        return CLKComplicationTimelineEntry(date: date, complicationTemplate: template)
    }
    
    private func createTemplate(forComplication complication: CLKComplication,
                                date: Date) -> CLKComplicationTemplate {
        switch complication.family {
        case .modularSmall:
            return createModularSmallTemplate(forDate: date)
        case .modularLarge:
            return createModularLargeTemplate(forDate: date)
        case .utilitarianSmall, .utilitarianSmallFlat:
            return createUtilitarianSmallFlatTemplate(forDate: date)
        case .utilitarianLarge:
            return createUtilitarianLargeTemplate(forDate: date)
        case .circularSmall:
            return createCircularSmallTemplate(forDate: date)
        case .extraLarge:
            return createExtraLargeTemplate(forDate: date)
        case .graphicCorner:
            return createGraphicCornerTemplate(forDate: date)
        case .graphicCircular:
            return createGraphicCircleTemplate(forDate: date)
        case .graphicRectangular:
            return createGraphicRectangularTemplate(forDate: date)
        case .graphicBezel:
            return createGraphicBezelTemplate(forDate: date)
        case .graphicExtraLarge:
            if #available(watchOSApplicationExtension 7.0, *) {
                return createGraphicExtraLargeTemplate(forDate: date)
            } else {
                fatalError("Graphic Extra Large template is only available on watchOS 7.")
            }
        @unknown default:
            fatalError("*** Unknown Complication Family ***")
        }
    }
    
    // Return a modular small template.
    private func createModularSmallTemplate(forDate date: Date) -> CLKComplicationTemplate {
        let leafImage = UIImage(systemName: "leaf")!
        let imageProvider = CLKImageProvider(onePieceImage: leafImage)
        imageProvider.accessibilityLabel = "Plant health"

        let complication = CLKComplicationTemplateModularSmallRingImage(
            imageProvider: imageProvider,
            fillFraction: plant.percentageOfTimeUntilWateringDue,
            ringStyle: .closed)
        complication.tintColor = .green
        
        return complication
    }
    
    // Return a modular large template.
    private func createModularLargeTemplate(forDate date: Date) -> CLKComplicationTemplate {
        let waterRemainingDays = plant.daysUntilNextWateringDue
        let fertilizerRemainingDays = plant.daysUntilNextFertilizingDue

        let titleTextProvider = CLKSimpleTextProvider(text: plant.name)
        titleTextProvider.tintColor = .orange

        let waterTextProvider = CLKSimpleTextProvider(text: "Water: \(waterRemainingDays)", shortText: "W: \(waterRemainingDays)")
        let unitTextProvider = CLKSimpleTextProvider(text: "days", shortText: "")
        let combinedWaterProvider = CLKTextProvider(format: "%@ %@", waterTextProvider, unitTextProvider)
        combinedWaterProvider.accessibilityLabel = plant.accessibilityStringForTask(task: .water)

        let fertilizerTextProvider = CLKSimpleTextProvider(text: "Fertilize: \(fertilizerRemainingDays)", shortText: "F: \(fertilizerRemainingDays)")
        let combinedFertilizerProvider = CLKTextProvider(format: "%@ %@", fertilizerTextProvider, unitTextProvider)
        combinedFertilizerProvider.accessibilityLabel = plant.accessibilityStringForTask(task: .fertilize)
                        
        return CLKComplicationTemplateModularLargeStandardBody(
            headerTextProvider: titleTextProvider,
            body1TextProvider: combinedWaterProvider,
            body2TextProvider: combinedFertilizerProvider)
    }
    
    // Return a utilitarian small flat template.
    private func createUtilitarianSmallFlatTemplate(forDate date: Date) -> CLKComplicationTemplate {
        let leafImage = UIImage(systemName: "leaf")!
        let imageProvider = CLKImageProvider(onePieceImage: leafImage)
        imageProvider.accessibilityLabel = "Plant health"
        
        return CLKComplicationTemplateUtilitarianSmallRingImage(
            imageProvider: imageProvider,
            fillFraction: plant.percentageOfTimeUntilWateringDue,
            ringStyle: .closed)
    }
    
    // Return a utilitarian large template.
    private func createUtilitarianLargeTemplate(forDate date: Date) -> CLKComplicationTemplate {
        let plantHealthPercent = Int(plant.percentageOfTimeUntilWateringDue * 100)
        let nameTextProvider = CLKSimpleTextProvider(text: "\(plant.name)")
        let waterTextProvider = CLKSimpleTextProvider(text: "\(plantHealthPercent) %")
        let combinedWaterProvider = CLKTextProvider(format: "%@ - %@", nameTextProvider, waterTextProvider)
        combinedWaterProvider.accessibilityLabel = "\(plant.name), Plant health \(plantHealthPercent) percent"
        
        return CLKComplicationTemplateUtilitarianLargeFlat(textProvider: combinedWaterProvider)
    }
    
    // Return a circular small template.
    private func createCircularSmallTemplate(forDate date: Date) -> CLKComplicationTemplate {
        let leafImage = UIImage(systemName: "leaf")!
        let imageProvider = CLKImageProvider(onePieceImage: leafImage)
        imageProvider.accessibilityLabel = "Plant health"
        
        return CLKComplicationTemplateCircularSmallRingImage(
            imageProvider: imageProvider,
            fillFraction: plant.percentageOfTimeUntilWateringDue,
            ringStyle: .closed)
    }
    
    // Return an extra-large template.
    private func createExtraLargeTemplate(forDate date: Date) -> CLKComplicationTemplate {
        let healthPercent = plant.percentageOfTimeUntilWateringDue
        let nameTextProvider = CLKSimpleTextProvider(text: plant.name)
        let healthPercentTextProvider = CLKSimpleTextProvider(text: "\(healthPercent * 100)%")
        healthPercentTextProvider.accessibilityLabel = "Plant Health: \(healthPercent * 100) percent"
        
        return CLKComplicationTemplateExtraLargeStackText(line1TextProvider: nameTextProvider, line2TextProvider: healthPercentTextProvider)
    }
    
    // Return a graphic template that fills the corner of the watch face.
    private func createGraphicCornerTemplate(forDate date: Date) -> CLKComplicationTemplate {
        let nameTextProvider = CLKSimpleTextProvider(text: plant.name)
        
        let waterRemainingDays = plant.daysUntilNextWateringDue
        let fertilizerRemainingDays = plant.daysUntilNextFertilizingDue

        let waterTextProvider = CLKSimpleTextProvider(text: "W: \(waterRemainingDays)")
        waterTextProvider.tintColor = .cyan
        
        let fertilizerTextProvider = CLKSimpleTextProvider(text: "F: \(fertilizerRemainingDays)")
        fertilizerTextProvider.tintColor = .green
        
        let innerTextProvider = CLKTextProvider(format: "%@, %@", waterTextProvider, fertilizerTextProvider)
        innerTextProvider.accessibilityLabel =
        "\(plant.accessibilityStringForTask(task: .water)), \(plant.accessibilityStringForTask(task: .fertilize))"
        
        return CLKComplicationTemplateGraphicCornerStackText(innerTextProvider: innerTextProvider, outerTextProvider: nameTextProvider)
    }
    
    // Return a graphic circle template.
    private func createGraphicCircleTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Data
        let waterRemainingDays = plant.daysUntilNextWateringDue
        let percentage = plant.percentageOfTimeUntilWateringDue

        // Create the data providers.
        let gaugeProvider = CLKSimpleGaugeProvider(style: .fill, gaugeColor: UIColor.cyan, fillFraction: percentage)
        gaugeProvider.accessibilityLabel = "Plant Health"
        
        let drop = UIImage(systemName: "drop.fill")!.withTintColor(.cyan)
        let imageProvider = CLKFullColorImageProvider(fullColorImage: drop)
        imageProvider.accessibilityLabel = "Water"
        
        let centerText = CLKSimpleTextProvider(text: "\(waterRemainingDays)")
        centerText.tintColor = .cyan
        centerText.accessibilityLabel = "in \(waterRemainingDays) days"

        let complication = CLKComplicationTemplateGraphicCircularOpenGaugeImage(
            gaugeProvider: gaugeProvider,
            bottomImageProvider: imageProvider,
            centerTextProvider: centerText)
        
        return complication
    }
    
    // Return a large rectangular graphic template.
    private func createGraphicRectangularTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Data
        let waterRemainingDays = plant.daysUntilNextWateringDue
        let fertilizerRemainingDays = plant.daysUntilNextFertilizingDue
        
        // Create the data providers.
        let titleTextProvider = CLKSimpleTextProvider(text: "\(plant.name)")
        let waterTextProvider = CLKSimpleTextProvider(text: "Water: \(waterRemainingDays)")
        let fertilizerTextProvider = CLKSimpleTextProvider(text: "Fertilize: \(fertilizerRemainingDays)")
        let bodyTextProvider = CLKTextProvider(format: "%@, %@", waterTextProvider, fertilizerTextProvider)
        bodyTextProvider.accessibilityLabel =
        "\(plant.accessibilityStringForTask(task: .water)), \(plant.accessibilityStringForTask(task: .fertilize))"
        
        let percentage = plant.percentageOfTimeUntilWateringDue
        let gaugeProvider = CLKSimpleGaugeProvider(style: .fill,
                                                   gaugeColors: [.green, .yellow, .red],
                                                   gaugeColorLocations: [0.0, 300.0 / 500.0, 450.0 / 500.0] as [NSNumber],
                                                   fillFraction: percentage)
        gaugeProvider.accessibilityLabel = "Plant health"
        
        // Create the template using the providers.
        return CLKComplicationTemplateGraphicRectangularTextGauge(
            headerTextProvider: titleTextProvider,
            body1TextProvider: bodyTextProvider,
            gaugeProvider: gaugeProvider)
    }
    
    // Return a circular template with text that wraps around the top of the watch's bezel.
    private func createGraphicBezelTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Data
        let waterRemainingDays = plant.daysUntilNextWateringDue
        let fertilizerRemainingDays = plant.daysUntilNextFertilizingDue
        
        // Create a graphic circular template with an image provider.
        let percentTextProvider = CLKSimpleTextProvider(text: "\(plant.percentageOfTimeUntilWateringDue * 100)")

        let gaugeProvider = CLKSimpleGaugeProvider(style: .fill,
                                                   gaugeColors: [.green, .yellow, .red],
                                                   gaugeColorLocations: [0.0, 300.0 / 500.0, 450.0 / 500.0] as [NSNumber],
                                                   fillFraction: plant.percentageOfTimeUntilWateringDue)
        gaugeProvider.accessibilityLabel = "Plant health"
        
        let circle = CLKComplicationTemplateGraphicCircularClosedGaugeText(
            gaugeProvider: gaugeProvider,
            centerTextProvider: percentTextProvider)
        
        // Create the text provider.
        let waterTextProvider = CLKSimpleTextProvider(text: "Water: \(waterRemainingDays)")
        let fertilizerTextProvider = CLKSimpleTextProvider(text: "Fertilize: \(fertilizerRemainingDays)")
        
        let separator = NSLocalizedString(",", comment: "Separator for compound data strings.")
        let textProvider = CLKTextProvider(format: "%@%@ %@",
                                           waterTextProvider,
                                           separator,
                                           fertilizerTextProvider)
        textProvider.accessibilityLabel = "\(plant.accessibilityStringForTask(task: .water)), \(plant.accessibilityStringForTask(task: .fertilize))"
        
        // Create the bezel template using the circle template and the text provider.
        return CLKComplicationTemplateGraphicBezelCircularText(circularTemplate: circle,
                                                               textProvider: textProvider)
    }
    
    // Returns an extra-large graphic template.
    private func createGraphicExtraLargeTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Data
        let waterRemainingDays = plant.daysUntilNextWateringDue
        let percentage = plant.percentageOfTimeUntilWateringDue

        // Create the data providers.
        let gaugeProvider = CLKSimpleGaugeProvider(style: .fill, gaugeColor: UIColor.cyan, fillFraction: percentage)
        gaugeProvider.accessibilityLabel = "Plant Health"
        
        let drop = UIImage(systemName: "drop.fill")!.withTintColor(.cyan)
        let imageProvider = CLKFullColorImageProvider(fullColorImage: drop)
        imageProvider.accessibilityLabel = "Water"
        
        let centerText = CLKSimpleTextProvider(text: "\(waterRemainingDays)")
        centerText.tintColor = .cyan
        centerText.accessibilityLabel = "in \(waterRemainingDays) days"
        
        return CLKComplicationTemplateGraphicExtraLargeCircularOpenGaugeImage(
            gaugeProvider: gaugeProvider,
            bottomImageProvider: imageProvider,
            centerTextProvider: centerText)
    }
}
