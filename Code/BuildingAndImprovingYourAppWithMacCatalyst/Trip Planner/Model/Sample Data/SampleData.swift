/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Could have been a plist
*/

import Foundation
import CoreLocation

class SampleData: Model {
    static let data: Model = SampleData(countries: Country.countries, rewardsPrograms: RewardsProgram.programs)

    let countries: [Country]
    let rewardsPrograms: [RewardsProgram]

    init(countries: [Country], rewardsPrograms: [RewardsProgram]) {
        self.countries = countries
        self.rewardsPrograms = rewardsPrograms
    }
}

extension Country {
    
    static let countries: [Country] = [japan, spain, brazil, tanzania]
    
    private static let japan = Country(itemID: "country.japan",
                                       name: "Japan",
                                       lodgings: [.tokyoTowerHotel, .sakuraRyokan, .okinawaResort],
                                       restaurants: [.mushiSushi, .lotusBento, .extremeMatcha],
                                       sights: [.fuji, .goldenPavilion, .nara],
                                       iconName: "🇯🇵")

    private static let spain = Country(itemID: "country.spain",
                                       name: "Spain",
                                       lodgings: [.barcelonaHotel, .hotelCordoba, .meridien],
                                       restaurants: [.lasRamblas, .charcuterie],
                                       sights: [.alhambra, .parqueGüell, .sagrada, .cordoba],
                                       iconName: "🇪🇸")
    
    private static let brazil = Country(itemID: "country.brazil",
                                        name: "Brazil",
                                        lodgings: [.villaParaiso, .sugarloafMountainResort, .villaIsabel],
                                        restaurants: [.pratosPetite, .rioCantina, .mercadoCafe],
                                        sights: [.redeemer, .iguazuFalls, .copacabana],
                                        iconName: "🇧🇷")

    private static let tanzania = Country(itemID: "country.tanzania",
                                          name: "Tanzania",
                                          lodgings: [.resortZanzibar, .glampKilimajaro, .nalaNalaReserve],
                                          restaurants: [.cafeChipsi, .onTheRocks, .cafeSafari],
                                          sights: [.serengeti, .kilimanjaro, .stoneTown],
                                          iconName: "🇹🇿")
}

extension Lodging {
    
    // MARK: Japan
    fileprivate static let tokyoTowerHotel = Lodging(itemID: "lodging.japan.tokyotower",
                                                     name: "東京タワーホテル Tokyo Tower Hotel",

                                                     location: CLLocation(latitude: 35.65, longitude: 139.75),
                                                     priceRange: PriceRange(lower: 29_000, upper: 36_000, localeIdentifier: "en_JP"),
                                                     iconName: "🗼",
                                                     imageName: "tokyo_tower",
                                                     altText: "A view of Tokyo Tower glowing with a vibrant orange color",
                                                     caption: """
        Enjoy the hospitality of this city escape while never leaving the city. Experience tradition and innovation all at once with classic and modern Japanese architecture and easy access to Tokyo’s train system beneath the lobby of the hotel. Tokyo Tower Hotel is a short walk from many of the cities temples and parks. You’re guaranteed the perfect rest over a panoramic view of the cityscape.
        """)
    
    fileprivate static let sakuraRyokan = Lodging(itemID: "lodging.japan.sakura",
                                                  name: "桜旅館 Sakura Ryokan",

                                                  location: CLLocation(latitude: 35.01, longitude: 135.77),
                                                  priceRange: PriceRange(lower: 12_000, upper: 20_000, localeIdentifier: "en_JP"),
                                                  iconName: "🌸",
                                                  imageName: "cherry_blossoms",
                                                  altText: "Gion cherry blossoms and wooden buildings line a river in Kyoto",
                                                  caption: """
        To be dropped into the heart of Japanese culture, start your trip at Sakura Ryokan — a beautiful a and quaint family-run inn. A ryokan is more generally a traditional Japanese inn. They are one to two story wooden structures with sliding paper-paneled walls. When you walk in, remember to take off your shoes and slip right into your slippers. You may not see a bed at first. It is likely tucked nearly away in a closet to be rolled out in the evening.
        If you paid the big yen for your room, it may include a private bath heated by none other than the author’s favorite source of energy: geothermal. This is an onsen. Be sure to heed the etiquette on the onsen — don’t get soap in the tub! You won’t want to take off your cozy yukata, and don’t worry, you don’t have to. Other people will be walking around in them too.

        """)
    
    fileprivate static let okinawaResort = Lodging(itemID: "lodging.japan.okinawa",
                                                   name: "沖縄リゾート Okinawa Slippers Resort",
                                                   location: CLLocation(latitude: 26.333, longitude: 127.856),
                                                   priceRange: PriceRange(lower: 7_000, upper: 13_000, localeIdentifier: "en_JP"),
                                                   iconName: "🌊",
                                                   imageName: "okinawa",
                                                   altText: "An aerial view of the Sea of Okinawa",
                                                   caption: """
        Stay at Okinawa Slippers Resort as you island hop outside Okinawa Honto between the clusters of islands. Okinawa has its own spirit as a very unique part of Japan. There’s sailing, fishing, kayaking, and of course whale watching to be done. If you have any energy left by the evening, venture over to Hateruma to listen to the music of the sanshin, a three-stringed Japanese banjo-like instrument.
        """)
    
    // MARK: Brazil
    fileprivate static let villaParaiso = Lodging(itemID: "lodging.brazil.paraiso",
                                                 name: "Villa Paraíso",
                                                 location: CLLocation(latitude: -7.13674, longitude: -34.836),
                                                 priceRange: PriceRange(lower: 240, upper: 400, localeIdentifier: "pt_BR"),
                                                 iconName: "🩳",
                                                 imageName: "villa_paraiso",
                                                 altText: "The cove behind Villa Paraíso is a great place for a quiet lunch",
                                                 caption: """
      Sitting right on the coast, Villa Paraíso welcomes all visitors with a beautiful beachside ambiance. Perfect for relaxing after a day at the beach, their resident pool is the best place for a hotel cocktail and a decompress from the sun. Enjoy their complimentary breakfast paired with their house-made coffee.
      """)

    fileprivate static let sugarloafMountainResort = Lodging(itemID: "lodging.brazil.sugarloaf",
                                                             name: "Sugarloaf Mountain Restort",
                                                             location: CLLocation(latitude: -22.951715, longitude: -43.15544),
                                                             priceRange: PriceRange(lower: 400, upper: 800, localeIdentifier: "pt_BR"),
                                                             iconName: "🌄",
                                                             imageName: "sugarloaf",
                                                             altText: "A serene pool nestled away in the foothills of the mountains",
                                                             caption: """
                                                   Named after the gorgeous Brazilian rock formation, Sugarloaf Mountain Resort treats residents to a beautiful sunset scene overlooking the surrounding mountain ranges. Sugarloaf Mountain Resort is only minutes away from the city, but maintains the feel of a secluded nature resort scene overlooking the surrounding mountain ranges. Sugarloaf Mountain Resort is only minutes away from the city, but maintains the feel of a secluded nature resort.
                                                   """)

    fileprivate static let villaIsabel = Lodging(itemID: "lodging.brazil.isabel",
                                                 name: "Villa Isabel",
                                                 location: CLLocation(latitude: -0.175514, longitude: -50.881646),
                                                 priceRange: PriceRange(lower: 140, upper: 320, localeIdentifier: "pt_BR"),
                                                 iconName: "🌴",
                                                 imageName: "villa_isabel",
                                                 altText: "A tiny hotel surrounded by palm trees with nothing else in sight",
                                                 caption: """
                                                   If you are looking for a cozy, secluded hostel, book your stay at Villa Isabel. This community living house makes your vacation in Northern Brazil feel more like a second home. Surrounded by Brazil's own myriad palm trees, this little slice of paradise creates an unmatched relaxing ambiance — perfect to wind down after an active day in the city.
                                                   """)

    // MARK: Tanzania
    fileprivate static let resortZanzibar = Lodging(itemID: "lodging.tanzania.oceanside",
                                                    name: "Resort Zanzibar",
                                                    location: CLLocation(latitude: -6.160475, longitude: 39.188564),
                                                    priceRange: PriceRange(lower: 37_500, upper: 45_000, localeIdentifier: "sw_TZ"),
                                                    iconName: "🩴",
                                                    imageName: "oceanside_villa",
                                                    altText: "A beachfront with huts atop volcanic rock",
                                                    caption: """
    Put your feet up and relax in your oceanside villa at Resort Zanzibar located on scenic Nakupenda Beach. Nakupenda translates to “I love you” in Swahili, and you will soon feel that sentiment. Take in the sweeping ocean views as you walk along the white sand beach. The gentle waves and clear water make for world-class snorkeling.
    """)

    fileprivate static let glampKilimajaro = Lodging(itemID: "lodging.tanzania.glamp",
                                                     name: "Glamp Kilimanjaro",
                                                     location: CLLocation(latitude: -2.892899, longitude: 37.295380),
                                                     priceRange: PriceRange(lower: 49_000, upper: 80_000, localeIdentifier: "sw_TZ"),
                                                     iconName: "⛺️",
                                                     imageName: "kilimanjaro_tent",
                                                     altText: "A spacious tent on the Savannah with a setting sun in the background",
                                                     caption: """
                                                   Untie your hiking boots and put your feet up after a long day on the mountain. You won’t have to lift a finger — your friendly porters will be ready for your arrival and will set up camp, provide food and water, perform health screens, and maintain a high level of cleanliness at the campsite. After dinner, get cozy on your sleeping pad and prepare for a midnight wakeup call to begin the final climb to the summit.
                                                   """)

    fileprivate static let nalaNalaReserve = Lodging(itemID: "loding.tanzania.nala",
                                                     name: "Nala Nala Game Reserve",
                                                     location: CLLocation(latitude: -2.459298, longitude: 34.898963),
                                                     priceRange: PriceRange(lower: 104_000, upper: 140_000, localeIdentifier: "sw_TZ"),
                                                     iconName: "🐘",
                                                     imageName: "safari_camp",
                                                     altText: "A herd of elephants right outside one of the Nala Nala huts",
                                                     caption: """
                                                   After a day on the Serengeti, your safari guide will drop you in a scenic clearing with small huts. Enjoy a family style dinner with the other members of your safari group and then unwind on the patio while taking in the sights and sounds of the wildlife. The Nala Nala Game Reserve is a hotspot for elephants. Target dawn or dusk for the best viewing of the herd.
                                                   """)

    // MARK: Spain
    fileprivate static let barcelonaHotel = Lodging(itemID: "lodging.spain.barcelonahotel",
                                                    name: "Barcelona Hotel",
                                                    location: CLLocation(latitude: 41.390213, longitude: 2.16992),
                                                    priceRange: PriceRange(lower: 74, upper: 100, localeIdentifier: "en_ES"),
                                                    iconName: "🏨",
                                                    imageName: "barcelona_hotel",
                                                    altText: "A vibrant front facade of a multistory hotel against a blue evening sky, decorated with stained glass and roses",
                                                    caption: """
                                                    Located in the heart of the city, Barcelona Hotel is the perfect destination for the romantics. Not star-crossed lovers, but enthusiasts of the era of Romanticism. Explore existentialism, individualism, glorifying nature, and subjective beauty as you spend time with others guests of the hotel who are more than willing to bikeshed your API proposals find what is in a name.
                                                    """)

    fileprivate static let hotelCordoba = Lodging(itemID: "lodging.spain.cordoba",
                                                   name: "Hotel Córdoba",
                                                   location: CLLocation(latitude: 37.878, longitude: -4.7968),
                                                   priceRange: PriceRange(lower: 100, upper: 150, localeIdentifier: "en_ES"),
                                                   iconName: "🎇",
                                                   imageName: "hotel_cordoba",
                                                   altText: "An upward looking angle of a hotel built with a modern architectural style",
                                                   caption: """
                                                   Hotel Cordoba is the flagship hotel in Cordoba. Physically, It reminds one of the Plaza Hotel in New York or the Hotel Mumbai in Bombay. You could save a lot on airfare by contenting yourself with Hotel Córdoba.

                                                   If you can manage it, ask to see an photo of the room you have reserved.  Many landmark hotels are tricksy and stack unwary guests in relatively generic “tower rooms”.
                                                   """)

    fileprivate static let meridien = Lodging(itemID: "lodging.spain.hotelmeridien",
                                                   name: "Hotel Le Meridien",
                                              location: CLLocation(latitude: 42.025, longitude: 0),
                                                   priceRange: PriceRange(lower: 60, upper: 85, localeIdentifier: "en_ES"),
                                                   iconName: "🌐",
                                                   imageName: "hotel_le_meridien",
                                                   altText: "A hotel on a street corner painted pink with four flags mounted over the front entrance. The image makes the place look very walkable.",
                                                   caption: """
                                                   At Eurostars Patios you will feel as if you had hidden away as they closed the mosque/basilica/museum, so that you could spend the night in solitary appreciation of two different artistic cultures. Hotel Le Meridien is an instance of hotel suffused with period and cultural art and architecture, that succeeds in elevating the lodging transaction beyond the typical 5-star experience
                                                   """)

}

extension Restaurant {
    
    // MARK: Japan
    fileprivate static let mushiSushi = Restaurant(itemID: "restaurant.japan.mushi",
                                                   name: "むし寿司 Mushi Sushi",
                                                   location: CLLocation(latitude: 35.46, longitude: 139.619),
                                                   priceRange: PriceRange(lower: 1_200, upper: 2_000, localeIdentifier: "en_JP"),
                                                   iconName: "🍣",
                                                   imageName: "sushi",
                                                   altText: "A pair of chopsticks grabbing one of 4 nigiri sushi rolls, wrapped in salmon.",
                                                   caption: """
    Though its name doesn't translate well, it has a nice ring to it. Located right along the harbor in Yokohama, this is where the local fishermen and dedicated  entomologists go to sell their fresh catch to be rolled and crunched into the finest rolls and later, consumed by the adventurous tourist. Remember, sushi actually refers to anything — not just raw fish  — served on or in vinegared rice.
    """)

    fileprivate static let lotusBento = Restaurant(itemID: "restaurant.japan.lotus",
                                                   name: "蓮弁当 Lotus Bento",
                                                   location: CLLocation(latitude: 35.6688, longitude: 139.698),
                                                   priceRange: PriceRange(lower: 500, upper: 900, localeIdentifier: "en_JP"),
                                                   iconName: "🍱",
                                                   imageName: "bento",
                                                   altText: "A very fancy bento box arrangement served alongside tea. In one of the boxes is pork and rice, and in the other, tempura vegetables",
                                                   caption: """
    Grab a Bento Box on the go as you head toward Meiji Jingu. Bento is meant to be taken and eaten on the move, but not too on the move. In Japan it is not very socially acceptable to eat while walking, or on short train rides. That's the answer to how they keep the streets so clean in Tokyo! Never fear, like many foods, bento can also be enjoyed as picnic food in the park.
    """)

    fileprivate static let extremeMatcha = Restaurant(itemID: "restaurant.japan.matcha",
                                                      name: "Extreme Matcha",
                                                      location: CLLocation(latitude: 34.698, longitude: 135.188),
                                                      priceRange: PriceRange(lower: 400, upper: 2_000, localeIdentifier: "en_JP"),
                                                      iconName: "🍵",
                                                      imageName: "matcha",
                                                      altText: "An aesthetic matcha latte on a smooth wooden table",
                                                      caption: """
    The matcha count in the air is over 100,000 parts per million in this happening cafe in Kobe. Their offerings include cakes, mochi, lattes, and cookies. It's a great place to take a break from a long day of walking, recharge and get that green-tea boost to post the perfect matcha picture to your social media, #matchaMadeInHeaven.
    """)
    
    // MARK: Brazil
    fileprivate static let pratosPetite = Restaurant(itemID: "restaurant.brazil.pratospetit",
                                                    name: "Pratos Petit",
                                                     location: CLLocation(latitude: -22.8986, longitude: -43.17896),
                                                    priceRange: PriceRange(lower: 21, upper: 31, localeIdentifier: "pt_BR"),
                                                    iconName: "🫔",
                                                    imageName: "grandes_pratos",
                                                     altText: "Tamales, tamales, tamales",
                                                    caption: """
     Enjoy a tasty breakfast in Brazil at Pratos Petit. Fill your small plate with homemade jams, fresh espresso, and delicious Pão de queijo before the sun rises. Return for lunch or dinner to grab their signature pamonha and pasteles that will satisfy all your cravings after a day of adventure in Rio.
     """)

    fileprivate static let rioCantina = Restaurant(itemID: "restaurant.brazil.riocantina",
                                                    name: "Rio Cantina",
                                                     location: CLLocation(latitude: -22.9033, longitude: -43.1722),
                                                    priceRange: PriceRange(lower: 25, upper: 45, localeIdentifier: "pt_BR"),
                                                    iconName: "🍽",
                                                    imageName: "rio_cantina",
                                                    altText: "A dining room nestled surrounded by bright green trees that embodies indoor/outdoor seating",
                                                    caption: """
     Be sure to snag a reservation at the famous Rio Cantina in Northern Brazil. This cozy restaurant is home to delicious traditional Brazilian cuisine, serving its customers the national dish feijoada (stew and beans). Pair your dinner with Rio Cantina’s signature cocktails, including the infamous caipirinha, garnished with refreshing sugarcane and lime.
     """)

    fileprivate static let mercadoCafe = Restaurant(itemID: "restaurant.brazil.mercado",
                                                    name: "Mercado Café",
                                                    location: CLLocation(latitude: -22.898290, longitude: -43.181501),
                                                    priceRange: PriceRange(lower: 10, upper: 20, localeIdentifier: "pt_BR"),
                                                    iconName: "☕️",
                                                    imageName: "mercado_cafe",
                                                    altText: "Small cafe seating with natural light coming through the archway entrance to this restaurant.",
                                                    caption: """
     Need a relaxing start to your day? Be sure to stop by the world famous Mercado Café. The peaceful ambiance and delicious coffee creates the perfect place for visitors and locals to enjoy a quick bite and a calming start to the day.
     """)

    // MARK: Tanzania
    fileprivate static let cafeChipsi = Restaurant(itemID: "restaurant.tanzania.chipsi",
                                                   name: "Cafe Chipsi",
                                                   location: CLLocation(latitude: -6.820995, longitude: 39.272121),
                                                   priceRange: PriceRange(lower: 900, upper: 2_300, localeIdentifier: "sw_TZ"),
                                                   iconName: "☕️",
                                                   imageName: "city_cafe",
                                                   altText: "A quiet looking cafe with wooden tables and a vibrant painting of a woman's face in the background",
                                                   caption: """
    You will find Cafe Chipsi tucked away on a quiet street in Tanzania’s largest city, Dar es Salaam. Cafe Chipsi serves Tanzania’s traditional cuisines with a twist. Try their chipsi mayai, literally “chips and eggs,” a classic Tanzanian comfort food. You can enjoy this meal like the locals might, with a splash of ketchup, or get it “California Style” with pea sprouts, avocado, and feta cheese.
    """)
    
    fileprivate static let onTheRocks = Restaurant(itemID: "restaurant.tanzania.ontherocks",
                                                   name: "On the Rocks",
                                                   location: CLLocation(latitude: -6.1376, longitude: 39.2092),
                                                   priceRange: PriceRange(lower: 4_000, upper: 10_000, localeIdentifier: "sw_TZ"),
                                                   iconName: "🏝",
                                                   imageName: "on_the_rock",
                                                   altText: "A restaurant on a rock located behind the incoming tide. You'll have to get your feet wet to get here at certain times of day!",
                                                   caption: """
    Try out On the Rocks for your fix of traditional Zanzibari cuisine while on the island. The restaurant is only accessible by foot at low tide, so plan your trip accordingly. Enjoy a local favorite, the Pepper Shark, featuring fresh-caught shark seasoned with pepper. Or try the world-famous Pweza Wa Nazi, or octopus in coconut milk. Not feeling like seafood? Some might say you came to the wrong restaurant, but we recommend the Zanzibar Pizza, a fried dough pocket filled with meat, cheese, veggies, and an egg.
    """)

    fileprivate static let cafeSafari = Restaurant(itemID: "restaurant.tanzania.cafesafari",
                                                   name: "Cafe Safari",
                                                   location: CLLocation(latitude: -2.193922, longitude: 33.9683),
                                                   priceRange: PriceRange(lower: 5_000, upper: 12_000, localeIdentifier: "sw_TZ"),
                                                   iconName: "🦁",
                                                   imageName: "safari_lunch",
                                                   altText: "Elephants are literally sharing your lunch at this one-of-a-kind dining experience",
                                                   caption: """
                                                   Get your camera ready for this magical dinner experience. Dine al fresco with your favorite safari characters after a long day out on the Serengeti. Safari Lodge serves up many of Tanzania’s traditional dishes. It wouldn’t be a trip to Tanzania without trying ugali, a porridge made from maize, similar to polenta. To eat, break off a small piece of ugali, roll it into a ball, and make a small depression in the ball using your thumb to fashion it into a spoon. Then, use your ugali spoon to scoop up your stew. Be warned, elephants need up to 375 lbs. of food per day and spend about 80% of their day feeding, so keep your plate under close watch!
                                                   """)

    // MARK: Spain
    fileprivate static let lasRamblas = Restaurant(itemID: "restaurant.spain.lasramblas",
                                                   name: "Las Ramblas Market",
                                                   location: CLLocation(latitude: 41.3567, longitude: 2.1368),
                                                   priceRange: PriceRange(lower: 3, upper: 20, localeIdentifier: "en_ES"),
                                                   iconName: "🥖",
                                                   imageName: "barcelona_market",
                                                   altText: "A wide assortment of perfectly ripened fruits and vegetables",
                                                   caption: """
    Las Ramblas is (are?) a boulevard about 1 mile long running up from the Port (near the cruise ship terminal) at its southern end to La Plaça de Catalunya and continuing unofficially through the downtown’s fine hotel and ($$$) shopping district at the northern end. Las Ramblas may be the first and greatest car-free pedestrian mall (dating back to when everybody was a pedestrian). Looking up towards Catalunya from the  port along the Ramblas on your left is the Raval (contemporary tourist) area and on your right is the Barri Gòtic (or Gothic Quarter). Las Ramblas attracts as many Barcelonians as tourists. This distinction becomes a lot clearer at night time when the the latter south end of the Rambla typically sit down to dinner an hour or two before the former do. Past Catalunya, the restaurants on each side of the boulevard also set up service in its middle — very similar to arrangements some cities and restaurants have made recently in 2020/2021. The food is both very "typical" and innovative — Catalan cuisine was "le mode" in the nineties; no need torture yourselves about which restaurant to pick.
    """)
    
    fileprivate static let charcuterie = Restaurant(itemID: "restaurant.spain.charcuterie",
                                                    name: "Charcuterie Bored",
                                                    location: CLLocation(latitude: 39.857, longitude: -4.018),
                                                    priceRange: PriceRange(lower: 10, upper: 20, localeIdentifier: "en_ES"),
                                                    iconName: "🧀",
                                                    imageName: "charcuterie",
                                                    altText: "A closeup of a charcuterie plate, including salami, and what are likely mozarella poppers ",
                                                    caption: "Have you ever considered the difference between tapas and charcuterie? Charcutuerie Bored promises to keep you waiting on small plates long enough that you begin to ask yourself these questions — the kind that matter. Is this a squares-versus-rectangles situation? Or more of a Venn Diagram? Are charcuterie plural or singular? Or is it? Be sure to add Brazil's Pratos Petit to your bucket list so that you can ask yourself these same questions, but in reverse. When your adult-snacks do eventually arrive, don't forget to snap that bird's eye picture of the plate from above. Ca-caw!!")
}

extension Sight {
    
    // MARK: Japan
    fileprivate static let fuji = Sight(itemID: "sight.japan.fuji",
                                        name: "富士山 Mount Fuji",
                                        location: CLLocation(latitude: 35.3626, longitude: 138.7301),
                                        iconName: "🗻",
                                        imageName: "fuji",
                                        altText: "A snowcapped Fujisan with a branch of small blooming white flowers in the foreground.",
                                        caption: """
    Mount Fuji is the perfect side-trip from Tokyo for the travelers who want to see the outdoors, and be challenged by them. Don't make the mistake of thinking Fuji is a day-hike. It's a dormant volcano rising up 12,388 feet and most hikers who summit from the bottom spend at least one night on the mountain to see the Coming of the Light as the sun rises across the mountain.
    """)
    
    fileprivate static let goldenPavilion = Sight(itemID: "sight.japan.golden",
                                                  name: "金閣寺 Golden Pavilion",
                                                  location: CLLocation(latitude: 35.0395, longitude: 135.73),
                                                  iconName: "🏯",
                                                  imageName: "golden_pavilion",
                                                  altText: "The classic view of Kinkaku-ji — the three story gilded pavilion from across the water",
                                                  caption: """
    Even back in 1393, people knew how to retire in style. In this case, it was Shogun Yoshimitsu Ashikaga who commissioned this villa to be converted to a temple upon his passing. The version of the building you see today was the same until a rare case of monastic arson in 1950. Enjoy a tranquil walk through the gardens surrounding the temple, then take the bus back to Kyoto and get yourself some crab legs as a reward for your day of sightseeing.
    """)
    
    fileprivate static let nara = Sight(itemID: "sight.japan.nara",
                                        name: "Nara",
                                        location: CLLocation(latitude: 34.6889, longitude: 135.84),
                                        iconName: "🦌",
                                        imageName: "nara",
                                        altText: "A fierce, majestic deer standing alone against the backdrop of Tōdai-ji temple",
                                        caption: """
    A short walk from the urban center of the city will get you to Nara park. The deer turn to 13 million annual visitors. Bowing for crackers brings tasty rewards. Rice bran crackers for X Yen are breakfast, lunch, and dinner for these guys. gluten free. Do your part and pick up any trash left behind by the hordes of tourism.
    
    """)
    
    // MARK: Brazil
    fileprivate static let redeemer = Sight(itemID: "sight.brazil.redeemer",
                                            name: "Cristo Redentor (Christ the Redeemer)",
                                            location: CLLocation(latitude: -22.9518, longitude: -43.2109),
                                            iconName: "✝️",
                                            imageName: "redeemer",
                                            altText: "The monumental statue of Jesus Christ rising above the clouds of Rio.",
                                            caption: """
                                               Standing almost 30 meters tall, Christ the Redeemer welcomes all tourists with open arms. This statue, built by Brazilian engineer Heitor da Silva Costa, is one of the most monumental Art Deco statues in the world and deemed one of the seven wonders of the world. The open arms of the statue symbolizes peace and prosperity, something you may not be able to achieve on the 220 stairway hike up to view this wonder.
                                               """)

    fileprivate static let iguazuFalls = Sight(itemID: "sight.brazil.iguazu",
                                               name: "Iguaçu Falls",
                                               location: CLLocation(latitude: -25.6925, longitude: -54.4331),
                                               iconName: "🌈",
                                               imageName: "iguazu_falls",
                                               altText: "A lush, deep green forest surrounds the roaring Iguaçu falls on an overcast day.",
                                               caption: """
                                                  Enjoy the beautiful panoramic views of Iguaçu Falls, bordering Brazil and Argentina. The shared falls signify the strength and unity of the bond between Brazil and Argentina. Residents and tourists experience breathtaking sights in Iguaçu National Park. Take the one kilometer hike to the top of the falls to close your activity rings.
                                                  """)

    fileprivate static let copacabana = Sight(itemID: "sight.brazil.ipanema",
                                              name: "Copacabana",
                                              location: CLLocation(latitude: -22.972123, longitude: -43.184477),
                                              iconName: "☀️",
                                              imageName: "ipanema",
                                              altText: "Two palms with a mountainside and a hint of a city behind them",
                                              caption: """
                                                 Your name doesn’t have to be named Lola to take a stroll down the beautiful Brazilian coast in Copacabana Beach. Famous for its 4 kilometer long coastline, Copacabana is home to over 60 beachside resorts all overlooking the breathtaking sunsets. Don’t forget to bring your yellow feathers for your hair and your favorite dress cut down to there.
                                                 """)

    // MARK: Tanzania
    fileprivate static let kilimanjaro = Sight(itemID: "sight.tanzania.kilimajaro.",
                                               name: "Mount Kilimanjaro",
                                               location: CLLocation(latitude: -3.0994, longitude: 37.3557),
                                               iconName: "🌋",
                                               imageName: "kilimanjaro", altText: "TODO",
                                               caption: """
    Not only is Kilimanjaro the highest mountain in Africa at 19,341 ft above sea level, it is the highest single free-standing mountain on earth! With an average summit success rate of 65%, you might consider Kilimanjaro as a relaxing alternative to Everest. Not so fast. Be warned, Kibo, Kilimanjaro’s highest crater, is dormant meaning an eruption is not out of the realm of possibility, . There are 7 established routes to the summit to choose from. Are cooking facilities, bathrooms, and electricity important to you? You might want to choose the Marangu Route. Enjoyed your climb? Let the other trekkers know by leaving your review in the summit book which can be found at the top of the mountain.
    """)
    
    fileprivate static let serengeti = Sight(itemID: "sight.tanzania.serengeti",
                                             name: "Serengeti National Park",
                                             location: CLLocation(latitude: -2.5153, longitude: 34.871),
                                             iconName: "🦒",
                                             imageName: "serengeti", altText: "TODO",
                                             caption: """
    See Serengeti National Park, which is said to be one of the Seven Natural Wonders of Africa. The Serengeti is known for its large populations of the crowd-pleasing predators like lions, African leopards, hyenas, East African cheetahs, and even crocodiles. With this many predators, you might wonder how the prey can catch a break. The grazing mammals have a solution — strength in numbers — just take a leaf out of the wildebeests’ book. Clocking in at 1.7 million herd members, the wildebeests migrate in a clockwise direction from the South, North to Kenya, and then back again. Go on safari to channel your inner-Simba as you witness the Great Wildebeest Migration as the herd searches for the greenest grazing pastures in Eastern Africa.
    """)
    
    fileprivate static let stoneTown = Sight(itemID: "sight.tanzania.stonetown",
                                             name: "Stone Town",
                                             location: CLLocation(latitude: -6.162, longitude: 39.192),
                                             iconName: "🪨",
                                             imageName: "stone_town", altText: "TODO",
                                             caption: """
    You might wonder why Stone Town located on Tanzania’s Zanzibar Island is on UNESCO’s list of World Heritage sites, and it is not because it is the birthplace of Freddie Mercury. During the 19th century, Stone Town was a buzzing commercial center and immigration from frequent trading communities was encouraged by the Sultan. This immigration resulted in a unique blend of architectural elements of Arab, Persian, Indian, and European influence. Work your way through the narrow streets on foot to visit shops, bazaars, and mosques, or stroll along the scenic seafront to see the popular tourist attractions like the Sultan’s Palace, Forodhani Gardens, and St. Joseph’s Cathedral.
    """)
    
    // MARK: Spain
    fileprivate static let alhambra = Sight(itemID: "sight.spain.alhambra",
                                            name: "Alhambra",
                                            location: CLLocation(latitude: 38.898, longitude: -3.05355),
                                            iconName: "🏰",
                                            imageName: "alhambra", altText: "A view of the hillsides from under an archway of the Alhambra palace",
                                            caption: """
                                            It is recommended you 'conquer' the city of Granada while in Spain, though you don't have to build a cathedral afterwards like Queen Isabella chose to do in 1523. Alhambra Palace was constructed between the XIII and XIV centuries from mostly stone and plaster (for the more ornate parts). Alhambra is not only a palace — it includes the town, gardens, and some of the surrounding areas as well. If you are traveling with children, you'll want to check out the nearby water park, constructed in the XXI century from mostly steel and plastic (for the more slippery parts).
                                            """)
    
    fileprivate static let parqueGüell = Sight(itemID: "sight.spain.guell",
                                               name: "Parque Güell",
                                               location: CLLocation(latitude: 41.41428, longitude: 2.151571),
                                               iconName: "🌳",
                                               imageName: "park_guell", altText: "Looking out over the Plaça de la Natura and low walls finished will a mosaic of ceramic shards",
                                               caption: """
    Possibly the most intriguing and difficult-to-maintain strolling park in Europe, this early 20th century garden featured buildings, passages and sculptural figures and tiles designed by Antonio Gaudi. The celebrated artist/architect who was definitely on a different wavelength than his contemporaries if not on another planet. Allow 2 hours for a visit including seat-time overlooking the city from the curvaceous plaza at the top of the Parque. (The Güell’s were one of Gaudi’s patient patrons.)
    """)

    fileprivate static let sagrada = Sight(itemID: "sight.spain.sagrada.familia",
                                           name: "La Sagrada Família",
                                           location: CLLocation(latitude: 41.40269, longitude: 2.17306),
                                           iconName: "⛪️",
                                           imageName: "sagrada_familia", altText: "The pink and orange glow of the sunset illuminates the impressively striking facade of the cathedral",
                                           caption: """
    Yes, it is possible to build a High Gothic (13th Century) Cathedral in the middle of a bustling, 20th/21st Century metropolis. This church, Gaudi’s obsession and masterpiece is ASTONISHING. This picture shows the building being worked on a few decades ago; it’s much taller and has many additional towers, now. You may judge the scale of the Church by the size of the trucks that appear near the bottom of the picture.  Caution! Be careful walking in the Cathedral’s vicinity! Transfixed pedestrians are at risk from Barcelona’s zippy drivers.
    """)

    fileprivate static let cordoba = Sight(itemID: "sight.spain.cordoba",
                                           name: "Mosque of Córdoba",
                                           location: CLLocation(latitude: 37.8788, longitude: -4.77953),
                                           iconName: "🕌",
                                           imageName: "cordoba", altText: "",
                                           caption: """
        The Great Mosque of Cordoba was constructed in 785 CE, when Córdoba was the capital of the Muslim-controlled region of Andalusia. It was expanded multiple times afterwards under his successors up to the late 10th century. The mosque was converted to a cathedral in 1236 when Córdoba was captured by the Christian forces of Castile during the Reconquista. The structure itself underwent only minor modifications until a major building project in the 16th century inserted a new Renaissance cathedral nave and transept into the center of the building. Today, the building continues to serve as the city's cathedral and Mass is celebrated daily.

        The mosque, which covers many times the area of the church, is now a museum. Both are beautiful and discovering the Cathedral all of a sudden in the middle of the vast mosque is a thrill. The Whole Cathedral-in-Mosque is a tight fit with restaurants surrounding the other wall of it. There’s one at least that serves asparagus, tomato and roquefort ice cream echoing the melding of cultures within the walls.
        """)
}

extension RewardsProgram {
    fileprivate static var semiregularSoarer = RewardsProgram(itemID: "rewards.semiregularsoarer",
                                                              name: "Semi-Regular Soarer", points: 65_536,
                                                              iconName: "airplane",
                                                              imageName: "airplane.circle")
    fileprivate static var diamondDubloon = RewardsProgram(itemID: "rewards.diamonddubloon",
                                                           name: "Diamond Dubloon", points: 10_000,
                                                           iconName: "seal",
                                                           imageName: "seal.fill")
    fileprivate static var skyFurlongs = RewardsProgram(itemID: "rewards.skyfurlong",
                                                        name: "Sky Furlongs", points: 10_696,
                                                        iconName: "ruler",
                                                        imageName: "ruler.fill")

    static let programs: [RewardsProgram] = [.semiregularSoarer, .diamondDubloon, .skyFurlongs]
}

