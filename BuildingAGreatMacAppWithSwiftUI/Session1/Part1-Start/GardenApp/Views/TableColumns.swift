/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The table colum views.
*/

/** TABLE COLUMNS
 TableColumn("Date Planted", value: \.datePlanted) { plant in
     Text(plant.datePlanted.formatted(date: .abbreviated, time: .omitted))
 }

 TableColumn("Harvest Date", value: \.harvestDate) { plant in
     Text(plant.harvestDate.formatted(date: .abbreviated, time: .omitted))
 }

 TableColumn("Last Watered", value: \.lastWateredOn) { plant in
     Text(plant.lastWateredOn.formatted(date: .abbreviated, time: .omitted))
 }

 TableColumn("Favorite", value: \.favorite, comparator: BoolComparator()) { plant in
     Toggle("Favorite", isOn: gardenBinding[plant.id].favorite)
         .labelsHidden()
 }
 .width(50)
 */
