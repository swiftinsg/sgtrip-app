
import SwiftUI
import MapKit
import CoreLocation
import UIKit
import PhotosUI
import ImageIO

// MARK: - 1. DATA MODELS

struct Place: Identifiable {
    let id = UUID()
    let name: String
    let region: SingaporeRegion
    let infoType: String
    let locationDescription: String
    let photoPrompt: String
    let coordinate: CLLocationCoordinate2D
}

struct CapturedMemory: Identifiable {
    let id = UUID()
    let placeName: String
    let infoType: String
    let coordinate: CLLocationCoordinate2D
    let image: UIImage
    let dateTaken: Date
    let rawImageData: Data?
}

// MARK: - 2. SHARED SINGAPORE PLACE CATALOG (59 LOCATIONS ACROSS ALL OF SINGAPORE)

enum PlaceCatalog {
    static let allPlaces: [Place] = [
        // MARK: - NORTH SINGAPORE (TOP)
        Place(
            name: "Sungei Buloh Wetland Reserve",
            region: .north,
            infoType: "Nature & Mangroves",
            locationDescription: "301 Neo Tiew Crescent",
            photoPrompt: "Snap a photo along the mangrove boardwalk or from the Eagle Point pod!",
            coordinate: CLLocationCoordinate2D(latitude: 1.4467, longitude: 103.7302)
        ),
        Place(
            name: "Kranji Marshes",
            region: .north,
            infoType: "Nature & Birdwatching",
            locationDescription: "11 Neo Tiew Lane 2",
            photoPrompt: "Take a photo from the Raptor Tower overlooking the freshwater marshes!",
            coordinate: CLLocationCoordinate2D(latitude: 1.4184, longitude: 103.7262)
        ),
        Place(
            name: "Woodlands Waterfront Park",
            region: .north,
            infoType: "Coastal & Scenic",
            locationDescription: "Admiralty Road West",
            photoPrompt: "Capture a wide shot along the 400-metre jetty looking across the Johor Strait!",
            coordinate: CLLocationCoordinate2D(latitude: 1.4526, longitude: 103.7788)
        ),
        Place(
            name: "Admiralty Park",
            region: .north,
            infoType: "Nature & Recreation",
            locationDescription: "31 Riverside Road",
            photoPrompt: "Snap a photo of the mangrove trails or giant outdoor slides!",
            coordinate: CLLocationCoordinate2D(latitude: 1.4494, longitude: 103.7797)
        ),
        Place(
            name: "Mandai Boardwalk",
            region: .north,
            infoType: "Nature & Lakeside",
            locationDescription: "80 Mandai Lake Road",
            photoPrompt: "Take a scenic photo along the elevated boardwalk beside Upper Seletar Reservoir!",
            coordinate: CLLocationCoordinate2D(latitude: 1.4043, longitude: 103.7885)
        ),
        Place(
            name: "Upper Seletar Reservoir Park",
            region: .north,
            infoType: "Scenic & Nature",
            locationDescription: "Mandai Road Track 7",
            photoPrompt: "Capture the iconic rocket-shaped viewing tower by the water!",
            coordinate: CLLocationCoordinate2D(latitude: 1.4005, longitude: 103.8075)
        ),
        Place(
            name: "Lower Seletar Reservoir Park",
            region: .north,
            infoType: "Waterfront & Scenic",
            locationDescription: "Yishun Avenue 1",
            photoPrompt: "Take a photo along the Heritage Bridge or Family Bay!",
            coordinate: CLLocationCoordinate2D(latitude: 1.4126, longitude: 103.8358)
        ),
        Place(
            name: "Sembawang Hot Spring Park",
            region: .north,
            infoType: "Unique Heritage & Nature",
            locationDescription: "Gambas Avenue",
            photoPrompt: "Snap a photo of the cascading thermal spring pools and floral walk!",
            coordinate: CLLocationCoordinate2D(latitude: 1.4346, longitude: 103.8225)
        ),
        Place(
            name: "Windsor Nature Park",
            region: .north,
            infoType: "Nature & Hiking",
            locationDescription: "30 Venus Drive",
            photoPrompt: "Take a photo along the Hanguana Trail or sub-canopy boardwalk!",
            coordinate: CLLocationCoordinate2D(latitude: 1.3566, longitude: 103.8214)
        ),
        Place(
            name: "Kampong Lorong Buangkok",
            region: .north,
            infoType: "Historic Kampong",
            locationDescription: "7 Lorong Buangkok",
            photoPrompt: "Take a photo in Singapore's last surviving mainland kampong!",
            coordinate: CLLocationCoordinate2D(latitude: 1.3839, longitude: 103.8785)
        ),
        Place(
            name: "Thomson Nature Park",
            region: .north,
            infoType: "Nature & Heritage",
            locationDescription: "Upper Thomson Road",
            photoPrompt: "Snap a photo of the lush forest trails or old Hainan village ruins!",
            coordinate: CLLocationCoordinate2D(latitude: 1.3865, longitude: 103.8211)
        ),

        // MARK: - WEST SINGAPORE (LEFT)
        Place(
            name: "Raffles Marina Lighthouse",
            region: .west,
            infoType: "Coastal Landmark",
            locationDescription: "10 Tuas West Drive",
            photoPrompt: "Capture the white lighthouse at the end of the pier overlooking the Tuas Second Link!",
            coordinate: CLLocationCoordinate2D(latitude: 1.3444, longitude: 103.6352)
        ),
        Place(
            name: "Jurong Lake Gardens",
            region: .west,
            infoType: "National Gardens",
            locationDescription: "Yuan Ching Road",
            photoPrompt: "Snap a photo of the Lone Tree sculpture, grasslands, or Rasau Walk!",
            coordinate: CLLocationCoordinate2D(latitude: 1.3396, longitude: 103.7267)
        ),
        Place(
            name: "Chinese & Japanese Gardens",
            region: .west,
            infoType: "Cultural Gardens",
            locationDescription: "1 Chinese Garden Road",
            photoPrompt: "Take a photo of the Twin Pagodas, Stone Boat, or Bonsai Garden!",
            coordinate: CLLocationCoordinate2D(latitude: 1.3388, longitude: 103.7303)
        ),
        Place(
            name: "Bukit Batok Nature Park (Little Guilin)",
            region: .west,
            infoType: "Scenic Quarry",
            locationDescription: "Bukit Batok East Avenue 5",
            photoPrompt: "Capture the dramatic granite cliffs reflecting in the lake!",
            coordinate: CLLocationCoordinate2D(latitude: 1.3562, longitude: 103.7538)
        ),
        Place(
            name: "Bukit Timah Nature Reserve",
            region: .west,
            infoType: "Rainforest & Summit",
            locationDescription: "Hindhede Drive",
            photoPrompt: "Take a photo at the summit stone (163m) or Hindhede Quarry!",
            coordinate: CLLocationCoordinate2D(latitude: 1.3547, longitude: 103.7764)
        ),
        Place(
            name: "Rail Corridor (Bukit Timah Railway Station)",
            region: .west,
            infoType: "Historic Railway",
            locationDescription: "1 Railway Station",
            photoPrompt: "Snap a photo along the historic railway tracks or truss bridge!",
            coordinate: CLLocationCoordinate2D(latitude: 1.3350, longitude: 103.7812)
        ),
        Place(
            name: "Clementi Forest",
            region: .west,
            infoType: "Nature & Trail",
            locationDescription: "King Albert Park / Clementi Road",
            photoPrompt: "Capture the misty green valley or historic old railway arch!",
            coordinate: CLLocationCoordinate2D(latitude: 1.3302, longitude: 103.7775)
        ),
        Place(
            name: "Haw Par Villa",
            region: .west,
            infoType: "Cultural & Chinese Folklore",
            locationDescription: "262 Pasir Panjang Road",
            photoPrompt: "Take a photo with the iconic statues or Hell's Museum entrance!",
            coordinate: CLLocationCoordinate2D(latitude: 1.2845, longitude: 103.7825)
        ),
        Place(
            name: "Innovis",
            region: .west,
            infoType: "Tech & Innovation",
            locationDescription: "2 Fusionopolis Way",
            photoPrompt: "Snap a photo of the modern architecture or tech hub at Fusionopolis!",
            coordinate: CLLocationCoordinate2D(latitude: 1.2984, longitude: 103.7887)
        ),

        // MARK: - CENTRAL SINGAPORE (MIDDLE)
        Place(
            name: "Bishan-Ang Mo Kio Park",
            region: .central,
            infoType: "Nature & River Park",
            locationDescription: "1384 Ang Mo Kio Avenue 1",
            photoPrompt: "Snap a photo by the naturalised Kallang River or Recycle Hill!",
            coordinate: CLLocationCoordinate2D(latitude: 1.3622, longitude: 103.8466)
        ),
        Place(
            name: "MacRitchie Reservoir & TreeTop Walk",
            region: .central,
            infoType: "Rainforest & Suspension Bridge",
            locationDescription: "Lornie Road",
            photoPrompt: "Take a photo by the reservoir edge or high above the forest canopy!",
            coordinate: CLLocationCoordinate2D(latitude: 1.3447, longitude: 103.8224)
        ),
        Place(
            name: "Singapore Botanic Gardens",
            region: .central,
            infoType: "UNESCO World Heritage",
            locationDescription: "1 Cluny Road",
            photoPrompt: "Take a photo by Swan Lake, the Bandstand, or National Orchid Garden!",
            coordinate: CLLocationCoordinate2D(latitude: 1.3151, longitude: 103.8162)
        ),
        Place(
            name: "Fort Canning Park",
            region: .central,
            infoType: "Historic & Nature",
            locationDescription: "River Valley Road",
            photoPrompt: "Snap a photo at the famous Tree Tunnel or Sang Nila Utama Garden!",

coordinate: CLLocationCoordinate2D(latitude: 1.2944, longitude: 103.8469)
),
Place(
name: "Kampong Gelam",
region: .central,
infoType: "Cultural & Historic",
locationDescription: "Muscat Street / Haji Lane",
photoPrompt: "Capture the golden dome of Sultan Mosque or colourful street murals!",
coordinate: CLLocationCoordinate2D(latitude: 1.3023, longitude: 103.8592)
),
Place(
name: "Chinatown",
region: .central,
infoType: "Cultural & Culinary",
locationDescription: "Pagoda Street / Smith Street",
photoPrompt: "Snap a photo of the heritage shophouses, lanterns, or Buddha Tooth Relic Temple!",
coordinate: CLLocationCoordinate2D(latitude: 1.2820, longitude: 103.8448)
),
Place(
name: "Little India",
region: .central,
infoType: "Cultural & Culinary",
locationDescription: "Serangoon Road / Buffalo Road",
photoPrompt: "Take a photo of the vibrant shophouses, flower garlands, or Tekka Centre!",
coordinate: CLLocationCoordinate2D(latitude: 1.3061, longitude: 103.8507)
),
Place(
name: "Tiong Bahru Estate",
region: .central,
infoType: "Art Deco Heritage",
locationDescription: "Tiong Poh Road / Seng Poh Road",
photoPrompt: "Snap a photo of the pre-war Art Deco flats or spiral staircases!",
coordinate: CLLocationCoordinate2D(latitude: 1.2836, longitude: 103.8340)
),
Place(
name: "Burma Social",
region: .central,
infoType: "Burmese & Pan-Asian",
locationDescription: "34 Tras Street, Tanjong Pagar",
photoPrompt: "Snap a photo of your Burmese tea leaf salad or heritage shophouse exterior!",
coordinate: CLLocationCoordinate2D(latitude: 1.2788, longitude: 103.8443)
),
Place(
name: "Masjid Haji Muhammad Salleh & Maqam Habib Noh",
region: .central,
infoType: "Islamic Heritage",
locationDescription: "37 Palmer Road",
photoPrompt: "Take a photo of the historic hilltop shrine and mosque!",
coordinate: CLLocationCoordinate2D(latitude: 1.2728, longitude: 103.8474)
),
Place(
name: "Fuk Tak Chi Museum",
region: .central,
infoType: "Historic Temple Museum",
locationDescription: "76 Telok Ayer Street",
photoPrompt: "Capture the oldest Chinese temple facade along Telok Ayer Street!",
coordinate: CLLocationCoordinate2D(latitude: 1.2829, longitude: 103.8488)
),
Place(
name: "Sri Layan Sithi Vinayagar Temple",
region: .central,
infoType: "Hindu Heritage",
locationDescription: "73 Keong Saik Road",
photoPrompt: "Snap a photo of the colourful 5-tier gopuram amidst Keong Saik shophouses!",
coordinate: CLLocationCoordinate2D(latitude: 1.2814, longitude: 103.8417)
),
// MARK: - EAST SINGAPORE (RIGHT)
Place(
name: "Tampines Eco Green",
region: .east,
infoType: "Nature & Birdwatching",
locationDescription: "Tampines Ave 9 & Ave 12",
photoPrompt: "Snap a photo of the eco-toilets, bird hides, or open grasslands!",
coordinate: CLLocationCoordinate2D(latitude: 1.3638, longitude: 103.9482)
),
Place(
name: "Lorong Halus Wetland",
region: .east,
infoType: "Nature & Scenic",
locationDescription: "326 Lorong Halus",
photoPrompt: "Take a photo along the red Lorong Halus Bridge or reed beds!",
coordinate: CLLocationCoordinate2D(latitude: 1.3789, longitude: 103.9275)
),
Place(
name: "Tampines Changkat Butterfly Garden",
region: .east,
infoType: "Nature & Community",
locationDescription: "124 Tampines Street 11",
photoPrompt: "Capture a close-up of a butterfly or blooming nectar plants!",
coordinate: CLLocationCoordinate2D(latitude: 1.3456, longitude: 103.9478)
),
Place(
name: "Pasir Ris Park Maze Garden & Bird Watching Tower",
region: .east,
infoType: "Nature & Wildlife",
locationDescription: "Pasir Ris Central / Elias Road",
photoPrompt: "Take a photo from the 3-storey bird watching tower or inside the hedge maze!",
coordinate: CLLocationCoordinate2D(latitude: 1.3806, longitude: 103.9495)
),
Place(
name: "Changi Point Coastal Walk",
region: .east,
infoType: "Coastal & Scenic",
locationDescription: "6 Changi Village Road",
photoPrompt: "Snap a scenic coastal view along the boardwalk or at Sunset Walk!",
coordinate: CLLocationCoordinate2D(latitude: 1.3913, longitude: 103.9866)
),
Place(
name: "Sensory Trail (Pulau Ubin)",
region: .east,
infoType: "Nature & Heritage",
locationDescription: "220B Pulau Ubin",
photoPrompt: "Take a photo of traditional kampong fruit trees, herbs, or mangroves!",
coordinate: CLLocationCoordinate2D(latitude: 1.4036, longitude: 103.9720)
),
Place(
name: "Pulau Ubin & Chek Jawa Wetlands",
region: .east,
infoType: "Nature & Wildlife",
locationDescription: "Eastern Tip of Pulau Ubin",
photoPrompt: "Snap a photo from the Jejawi Tower or along the coastal boardwalk!",
coordinate: CLLocationCoordinate2D(latitude: 1.4105, longitude: 103.9905)
),
Place(
name: "Siglap Canal Lookout Deck",
region: .east,
infoType: "Waterfront & Scenic",
locationDescription: "East Coast Park / Siglap Canal Outfall",
photoPrompt: "Take a photo overlooking the canal and sea breeze from the lookout deck!",
coordinate: CLLocationCoordinate2D(latitude: 1.3054, longitude: 103.9278)
),
Place(
name: "The Intan",
region: .east,
infoType: "Peranakan Heritage",
locationDescription: "69 Joo Chiat Terrace",
photoPrompt: "Snap a photo of intricate Peranakan beaded slippers or porcelain!",
coordinate: CLLocationCoordinate2D(latitude: 1.3147, longitude: 103.9010)
),
Place(
name: "Katong Antique House",
region: .east,
infoType: "Peranakan Heritage",
locationDescription: "208 East Coast Road",
photoPrompt: "Take a photo of the historic two-storey Peranakan shophouse facade!",
coordinate: CLLocationCoordinate2D(latitude: 1.3073, longitude: 103.9072)
),
Place(
name: "Eurasian Heritage Gallery",
region: .east,
infoType: "Cultural & Heritage",
locationDescription: "139 Ceylon Road",
photoPrompt: "Snap a photo at the Eurasian Community House or heritage exhibits!",
coordinate: CLLocationCoordinate2D(latitude: 1.3095, longitude: 103.9019)
),
Place(
name: "Joo Chiat & Katong Heritage Houses",
region: .east,
infoType: "Historic Architecture",
locationDescription: "Koon Seng Road / Joo Chiat Road",
photoPrompt: "Take a wide shot of the colourful pastel Peranakan shophouses!",
coordinate: CLLocationCoordinate2D(latitude: 1.3113, longitude: 103.9011)
),
Place(
name: "East Coast Park",
region: .east,
infoType: "Nature & Scenic",
locationDescription: "East Coast Park Service Road",
photoPrompt: "Explore the coastline and snap a photo by the beach or swaying palms!",
coordinate: CLLocationCoordinate2D(latitude: 1.3040, longitude: 103.9264)
),
Place(
name: "Changi Chapel and Museum",
region: .east,
infoType: "WWII History",
locationDescription: "1000 Upper Changi Road North",
photoPrompt: "Take a respectful photo of the Changi Chapel courtyard!",
coordinate: CLLocationCoordinate2D(latitude: 1.3623, longitude: 103.9733)
),
Place(
name: "Loyang Tua Pek Kong Temple",
region: .east,
infoType: "Multi-Faith Heritage",
locationDescription: "20 Loyang Way",
photoPrompt: "Snap a photo of the ornate temple architecture and lanterns!",
coordinate: CLLocationCoordinate2D(latitude: 1.3711, longitude: 103.9699)
),
Place(
name: "Sri Senpaga Vinayagar Temple",
region: .east,
infoType: "Hindu Heritage",
locationDescription: "19 Ceylon Road",
photoPrompt: "Capture the towering 21-metre golden Raja Gopuram entrance!",
coordinate: CLLocationCoordinate2D(latitude: 1.3056, longitude: 103.9025)
),
Place(
name: "Jewel Changi Airport",
region: .east,
infoType: "Iconic Architecture",
locationDescription: "78 Airport Boulevard",
photoPrompt: "Take a wide shot of the HSBC Rain Vortex indoor waterfall!",
coordinate: CLLocationCoordinate2D(latitude: 1.3602, longitude: 103.9898)
),
// MARK: - SOUTH SINGAPORE (BOTTOM)
Place(
name: "Marina Barrage",
region: .south,
infoType: "Nature & Skyline",
locationDescription: "8 Marina Gardens Drive",
photoPrompt: "Take a wide shot of the Singapore skyline from the Green Roof!",
coordinate: CLLocationCoordinate2D(latitude: 1.2805, longitude: 103.8711)
),
Place(
name: "Mount Faber Peak",
region: .south,
infoType: "Scenic & Hilltop",
locationDescription: "109 Mount Faber Road",
photoPrompt: "Snap a photo of the cable cars, mini Merlion, or harbour panorama!",
coordinate: CLLocationCoordinate2D(latitude: 1.2711, longitude: 103.8198)
),
Place(
name: "Telok Blangah Hill Park & Alkaff Mansion",
region: .south,
infoType: "Heritage & Park",
locationDescription: "10 Telok Blangah Green",
photoPrompt: "Take a photo of the white European-style Alkaff Mansion or Terrace Garden!",
coordinate: CLLocationCoordinate2D(latitude: 1.2790, longitude: 103.8130)
),
Place(
name: "HortPark",
region: .south,
infoType: "Themed Gardens",
locationDescription: "33 Hyderabad Road",
photoPrompt: "Snap a photo in the themed gardens or vertical greenery displays!",
coordinate: CLLocationCoordinate2D(latitude: 1.2780, longitude: 103.8010)
),
Place(
name: "Gillman Barracks",
region: .south,
infoType: "Contemporary Art",
locationDescription: "9 Lock Road",
photoPrompt: "Take a photo of the colonial barracks buildings or outdoor art installations!",
coordinate: CLLocationCoordinate2D(latitude: 1.2783, longitude: 103.8044)
),
Place(
name: "Kent Ridge Park & Reflections at Bukit Chandu",
region: .south,
infoType: "WWII History & Canopy Walk",
locationDescription: "31-K Pepys Road",
photoPrompt: "Snap a photo of the restored black-and-white bungalow or Canopy Walk!",
coordinate: CLLocationCoordinate2D(latitude: 1.2803, longitude: 103.7945)
),
Place(
name: "Canterbury Park",
region: .south,
infoType: "Nature & Colonial",
locationDescription: "Canterbury Road",
photoPrompt: "Take a photo of the open green hillside or black-and-white colonial bungalows!",
coordinate: CLLocationCoordinate2D(latitude: 1.2870, longitude: 103.7798)
),
Place(
name: "Labrador Nature Reserve & Berlayer Creek",
region: .south,
infoType: "Coastal & Mangrove",
locationDescription: "Labrador Villa Road",
photoPrompt: "Snap a photo along the mangrove boardwalk or rocky coastal cliff!",
coordinate: CLLocationCoordinate2D(latitude: 1.2658, longitude: 103.8019)
),
Place(
name: "Keppel Coastal Trail",
region: .south,
infoType: "Coastal Boardwalk",
locationDescription: "91 Labrador Villa Road",
photoPrompt: "Take a photo along the elevated coastal forest boardwalk overlooking the sea!",
coordinate: CLLocationCoordinate2D(latitude: 1.2645, longitude: 103.8035)
),
Place(
name: "Keppel Hill Reservoir",
region: .south,
infoType: "Hidden Heritage",
locationDescription: "11 Keppel Hill",
photoPrompt: "Snap a photo of the historic abandoned reservoir trail!",
coordinate: CLLocationCoordinate2D(latitude: 1.2707, longitude: 103.8172)
),
Place(
name: "Masjid Temenggong Daeng Ibrahim",
region: .south,
infoType: "Historic Mosque",
locationDescription: "30 Telok Blangah Road",
photoPrompt: "Take a photo of the historic Johor state mosque in Telok Blangah!",
coordinate: CLLocationCoordinate2D(latitude: 1.2663, longitude: 103.8243)
),
Place(
name: "Sri Ruthra Kaliamman Temple",
region: .south,
infoType: "Hindu Heritage",
locationDescription: "100 Depot Road",
photoPrompt: "Snap a photo of the vibrant temple tower along Depot Road!",
coordinate: CLLocationCoordinate2D(latitude: 1.2814, longitude: 103.8139)
),
Place(
name: "Fort Siloso & Siloso Skywalk",
region: .south,
infoType: "WWII History & Skywalk",
locationDescription: "Siloso Road, Sentosa",
photoPrompt: "Take a photo 11 storeys up on the Skywalk or beside the coastal cannons!",
coordinate: CLLocationCoordinate2D(latitude: 1.2581, longitude: 103.8105)
),
Place(
name: "Tanjong Rimau (Sentosa)",
region: .south,
infoType: "Coastal Cliffs & Caves",
locationDescription: "Western Tip of Sentosa",
photoPrompt: "Snap a photo of the dramatic coastal cliffs and sea views at Sentosa's western tip!",
coordinate: CLLocationCoordinate2D(latitude: 1.2595, longitude: 103.8075)
),
Place(
name: "St. John's & Lazarus Islands",
region: .south,
infoType: "Southern Islands",
locationDescription: "Southern Islands (via Marina South Pier)",
photoPrompt: "Take a photo of the crescent white-sand lagoon or causeway bridge!",
coordinate: CLLocationCoordinate2D(latitude: 1.2221, longitude: 103.8553)
),
Place(
name: "Kusu Island (Da Bo Gong Temple & Malay Keramat)",
region: .south,
infoType: "Southern Islands & Heritage",
locationDescription: "Kusu Island (via Marina South Pier)",
photoPrompt: "Snap a photo of the tortoise sanctuary, temple, or hilltop keramat!",
coordinate: CLLocationCoordinate2D(latitude: 1.2239, longitude: 103.8608)
)
]
}
// MARK: - 3. SHEET CONTROLLER
enum RecommendationSheet: Identifiable {
case place(Place)
case memory(CapturedMemory)
var id: UUID {
switch self {
case .place(let place):
return place.id
case .memory(let memory):
return memory.id
}
}
}
// MARK: - 4. RECOMMENDATION TAB
struct RecommendationTab: View {
@Environment(TripStore.self) private var tripStore
@StateObject private var locationManager = LocationManager()
@Namespace private var mapScope
// MARK: Default Singapore Map Region
private static let defaultSingaporeRegion = MKCoordinateRegion(
center: CLLocationCoordinate2D(latitude: 1.3450, longitude: 103.8250),
span: MKCoordinateSpan(latitudeDelta: 0.28, longitudeDelta: 0.36)
)
// MARK: All Recommended Places
private let places: [Place] = PlaceCatalog.allPlaces
// MARK: State Variables
@State private var selectedRegionFilter: SingaporeRegion? = nil
@State private var currentPrompt: Place?
@State private var didSkipPrompt = false
@State private var hasLockedUserRecommendation = false
@State private var activeSheet: RecommendationSheet?
@State private var savedMemories: [CapturedMemory] = []
@State private var cameraPosition: MapCameraPosition = .region(defaultSingaporeRegion)
@State private var confirmationMessage: String?
private var visiblePlaces: [Place] {
guard let region = selectedRegionFilter else { return places }
return places.filter { $0.region == region }
}
private var completedPlaceNames: Set <String> {
Set(tripStore.memories.map { $0.placeName })
}
private func isPlaceCompleted(_ place: Place) -> Bool {
completedPlaceNames.contains(place.name)
}
private func completedPhoto(for place: Place) -> UIImage? {
if let localMemory = savedMemories.first(where: { $0.placeName == place.name }) {
return localMemory.image
}
if let storedMemory = tripStore.memories.first(where: { $0.placeName == place.name }) {
return UIImage(data: storedMemory.imageData)
}
return nil
}
private func formattedDistance(to place: Place) -> String? {
guard let userLoc = locationManager.userLocation else { return nil }
let placeLoc = CLLocation(
latitude: place.coordinate.latitude,
longitude: place.coordinate.longitude
)
let meters = userLoc.distance(from: placeLoc)
if meters < 1000 {
return String(Int(meters)) + " m away"
} else {
let km = String(format: "%.1f", meters / 1000.0)
return km + " km away"
}
}
private func sortedPlacesByProximity(excluding excludedName: String? = nil) -> [Place] {
let candidates = places.filter { $0.name != excludedName }
guard let userLoc = locationManager.userLocation else {
return candidates
}
return candidates.sorted { a, b in
let locA = CLLocation(latitude: a.coordinate.latitude, longitude: a.coordinate.longitude)
let locB = CLLocation(latitude: b.coordinate.latitude, longitude: b.coordinate.longitude)
return userLoc.distance(from: locA) < userLoc.distance(from: locB)
}
}
// MARK: Main Body
var body: some View {
NavigationStack {
ZStack {
tripMap
.ignoresSafeArea()
VStack(spacing: 8) {
// TOP: Prompt Card + Region Filter Strip + Confirmation Toast
VStack(spacing: 8) {
promptSheet
.padding(.top, 10)
regionFilterStrip
if let confirmationMessage {
HStack(spacing: 8) {
Image(systemName: "checkmark.circle.fill")
.foregroundStyle(.white)
Text(confirmationMessage)
.font(.caption.weight(.semibold))
.foregroundStyle(.white)
}
.padding(.horizontal, 14)
.padding(.vertical, 10)
.background(Color.green.gradient, in: Capsule())
.shadow(color: .black.opacity(0.2), radius: 6, y: 3)
.transition(.move(edge: .top).combined(with: .opacity))
}
}
Spacer()
// BOTTOM: Scale & Compass on Left, Reset Map Button on Right
HStack(alignment: .bottom) {
HStack(spacing: 8) {
MapCompass(scope: mapScope)
.mapControlVisibility(.visible)
MapScaleView(scope: mapScope)
}
Spacer()
Button {
withAnimation(.easeInOut(duration: 0.4)) {
selectedRegionFilter = nil
}
resetMapToSingapore()
} label: {
Image(systemName: "arrow.counterclockwise")
.font(.system(size: 16, weight: .semibold))
.foregroundStyle(.primary)
.frame(width: 42, height: 42)
.background(.regularMaterial, in: Circle())
.overlay(
Circle()
.stroke(Color.primary.opacity(0.1), lineWidth: 1)
)
.shadow(color: .black.opacity(0.18), radius: 6, y: 3)
}
.buttonStyle(.plain)
.accessibilityLabel("Reset map to Singapore")
}
.padding(.horizontal, 16)
.padding(.bottom, 12)
}
}
.mapScope(mapScope)
.toolbar(.hidden, for: .navigationBar)
.statusBarHidden(true)
.sheet(item: $activeSheet) { sheet in
switch sheet {
case .place(let place):
LocationDetailView(
place: place,
isCompleted: isPlaceCompleted(place),
completedImage: completedPhoto(for: place),
currentLocation: locationManager.userLocation?.coordinate
) { memory in
let wasAlreadyCompleted = isPlaceCompleted(place)
let placeTitle = place.name
if let existingIndex = savedMemories.firstIndex(where: { $0.placeName == placeTitle }) {
savedMemories[existingIndex] = memory
} else {
savedMemories.insert(memory, at: 0)
}
let imageDataToSave = memory.rawImageData
?? memory.image.jpegData(compressionQuality: 0.9)
if let imageData = imageDataToSave {
tripStore.memories.removeAll { $0.placeName == placeTitle }
tripStore.addMemory(
placeName: memory.placeName,
locationDescription: place.locationDescription,
date: memory.dateTaken,
latitude: memory.coordinate.latitude,
longitude: memory.coordinate.longitude,
imageData: imageData
)
}
if wasAlreadyCompleted {
showConfirmation(placeTitle + " photo replaced!")
} else {
showConfirmation(placeTitle + " completed! Puzzle piece unlocked.")
hasLockedUserRecommendation = false
loadCurrentPrompt()
}
}
case .memory(let memory):
MemoryDetailView(memory: memory)
}
}
.task {
locationManager.startUpdatingLocation()
loadCurrentPrompt()
await midnightRefreshLoop()
}
.onChange(of: locationManager.userLocation) { _, newLocation in
guard newLocation != nil, !didSkipPrompt, !hasLockedUserRecommendation else { return }
loadCurrentPrompt()
hasLockedUserRecommendation = true
}
}
}
// MARK: - COMPACT REGION FILTER STRIP
private var regionFilterStrip: some View {
ScrollView(.horizontal, showsIndicators: false) {
HStack(spacing: 6) {
allRegionsButton
ForEach(SingaporeRegion.allCases) { region in
regionFilterButton(for: region)
}
}
.padding(.horizontal, 16)
}
}
private var allRegionsButton: some View {
let isSelected = selectedRegionFilter == nil
let labelText = "All (" + String(places.count) + ")"
return Button {
withAnimation(.easeInOut(duration: 0.3)) {
selectedRegionFilter = nil
cameraPosition = .region(Self.defaultSingaporeRegion)
}
} label: {
Text(labelText)
.font(.caption2.weight(.semibold))
.foregroundStyle(isSelected ? .white : .primary)
.padding(.horizontal, 10)
.padding(.vertical, 6)
.background(
isSelected ? AnyShapeStyle(Color.primary) : AnyShapeStyle(.regularMaterial),
in: Capsule()
)
.shadow(color: .black.opacity(0.1), radius: 3, y: 1)
}
.buttonStyle(.plain)
}
private func regionFilterButton(for region: SingaporeRegion) -> some View {
let isSelected = selectedRegionFilter == region
let count = places.filter { $0.region == region }.count
let labelText = region.rawValue + " (" + String(count) + ")"
return Button {
withAnimation(.easeInOut(duration: 0.35)) {
selectedRegionFilter = region
focusCamera(on: region)
}
} label: {
HStack(spacing: 4) {
Image(systemName: region.iconName)
.font(.system(size: 10))
Text(labelText)
.font(.caption2.weight(.semibold))
}
.foregroundStyle(isSelected ? .white : .primary)
.padding(.horizontal, 10)
.padding(.vertical, 6)
.background(
isSelected ? AnyShapeStyle(region.accentColor) : AnyShapeStyle(.regularMaterial),
in: Capsule()
)
.shadow(color: .black.opacity(0.1), radius: 3, y: 1)
}
.buttonStyle(.plain)
}
private func focusCamera(on region: SingaporeRegion) {
let regionPlaces = places.filter { $0.region == region }
guard !regionPlaces.isEmpty else { return }
let lats = regionPlaces.map { $0.coordinate.latitude }
let lons = regionPlaces.map { $0.coordinate.longitude }
if let minLat = lats.min(),
let maxLat = lats.max(),
let minLon = lons.min(),
let maxLon = lons.max() {
let center = CLLocationCoordinate2D(
latitude: (minLat + maxLat) / 2.0,
longitude: (minLon + maxLon) / 2.0
)
let span = MKCoordinateSpan(
latitudeDelta: max(0.04, (maxLat - minLat) * 1.45),
longitudeDelta: max(0.04, (maxLon - minLon) * 1.45)
)
cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
}
}
private func showConfirmation(_ text: String) {
Task {
try? await Task.sleep(nanoseconds: 250_000_000)
withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
confirmationMessage = text
}
try? await Task.sleep(nanoseconds: 1_000_000_000)
withAnimation(.easeOut(duration: 0.25)) {
confirmationMessage = nil
}
}
}
// MARK: - 5. TODAY'S PROMPT CARD
private var promptCard: some View {
VStack(alignment: .leading, spacing: 6) {
HStack(spacing: 6) {
Image(systemName: "location.north.circle.fill")
.font(.caption)
.foregroundStyle(.orange)
Text("NEARBY CHALLENGE")
.font(.caption2)
.fontWeight(.bold)
.foregroundStyle(.secondary)
if let prompt = currentPrompt, let distanceText = formattedDistance(to: prompt) {
Text("• " + distanceText)
.font(.caption2.weight(.semibold))
.foregroundStyle(.orange)
}
Spacer()
if !didSkipPrompt {
Button {
skipCurrentPrompt()
} label: {
Label("Skip", systemImage: "forward.fill")
.font(.caption2.weight(.semibold))
.foregroundStyle(.orange)
.padding(.horizontal, 8)
.padding(.vertical, 3)
.background(Color.orange.opacity(0.12), in: Capsule())
}
.buttonStyle(.borderless)
.disabled(currentPrompt == nil)
}
}
VStack(alignment: .leading, spacing: 5) {
if let prompt = currentPrompt {
let completed = isPlaceCompleted(prompt)
HStack {
Text(prompt.name)
.font(.headline)
.fontWeight(.bold)
.lineLimit(1)
if completed {
Label("Completed", systemImage: "checkmark.circle.fill")
.font(.caption2.weight(.semibold))
.foregroundStyle(.green)
.padding(.horizontal, 8)
.padding(.vertical, 3)
.background(Color.green.opacity(0.15), in: Capsule())
}
}
Text(prompt.photoPrompt)
.font(.caption)
.foregroundStyle(.secondary)
.fixedSize(horizontal: false, vertical: true)
HStack(alignment: .center, spacing: 8) {
HStack(alignment: .top, spacing: 4) {
Image(systemName: "location.fill")
.font(.caption2)
.foregroundStyle(.secondary)
.padding(.top, 1)
Text(prompt.locationDescription)
.font(.caption2)
.foregroundStyle(.secondary)
.fixedSize(horizontal: false, vertical: true)
}
Spacer(minLength: 8)
if completed {
Button {
activeSheet = .place(prompt)
} label: {
Label("View Photo", systemImage: "checkmark.circle.fill")
.font(.caption2)
.fontWeight(.semibold)
}
.buttonStyle(.bordered)
.tint(.green)
.controlSize(.small)
.fixedSize(horizontal: true, vertical: false)
} else {
Button {
activeSheet = .place(prompt)
} label: {
Label("Choose Photo", systemImage: "photo")
.font(.caption2)
.fontWeight(.semibold)
}
.buttonStyle(.borderedProminent)
.controlSize(.small)
.fixedSize(horizontal: true, vertical: false)
}
}
.padding(.top, 2)
Divider()
.padding(.vertical, 2)
mapLegend
} else {
Text("No prompts available")
.font(.subheadline)
.fontWeight(.semibold)
Text("Please check back for more photo challenges.")
.font(.caption)
.foregroundStyle(.secondary)
mapLegend
.padding(.top, 2)
}
}
}
.padding(10)
.frame(maxWidth: .infinity, alignment: .leading)
}
// MARK: Prompt Sheet
private var promptSheet: some View {
promptCard
.padding(4)
.background(
RoundedRectangle(cornerRadius: 20)
.fill(Color(.secondarySystemBackground))
.shadow(color: .black.opacity(0.15), radius: 8, y: 3)
)
.padding(.horizontal)
}
// MARK: - 6. MAP LEGEND (RED = RECOMMENDED, GREEN = VISITED)
private var mapLegend: some View {
let unlockedSummary = String(completedPlaceNames.count) + "/" + String(places.count) + " Unlocked"
return HStack(spacing: 16) {
Label("Recommended", systemImage: "mappin.circle.fill")
.foregroundStyle(.red)
Label("Visited", systemImage: "checkmark.circle.fill")
.foregroundStyle(.green)
Spacer()
Text(unlockedSummary)
.foregroundStyle(.secondary)
}
.font(.system(size: 10, weight: .medium))
}
// MARK: - 7. INTERACTIVE MAP (CLEAN RED RECOMMENDED & GREEN VISITED PINS)
private var tripMap: some View {
Map(position: $cameraPosition, scope: mapScope) {
UserAnnotation()
// Place Pins: Red mappin when recommended, Green checkmark when visited
ForEach(visiblePlaces) { place in
let completed = isPlaceCompleted(place)
Annotation(place.name, coordinate: place.coordinate, anchor: .bottom) {
Image(systemName: completed ? "checkmark.circle.fill" : "mappin.circle.fill")
.font(.title2)
.foregroundStyle(completed ? .green : .red)
.background(Color.white)
.clipShape(Circle())
.shadow(color: .black.opacity(0.2), radius: 2, y: 1)
.onTapGesture {
activeSheet = .place(place)
}
}
.annotationTitles(.automatic)
}
// Green Pins: Any custom visited memories not in the default places list
ForEach(tripStore.memories) { memory in
if !places.contains(where: { $0.name == memory.placeName }),
let coordinate = extractCoordinate(memory) {
Annotation(memory.placeName, coordinate: coordinate, anchor: .bottom) {
Image(systemName: "checkmark.circle.fill")
.font(.title2)
.foregroundStyle(.green)
.background(Color.white)
.clipShape(Circle())
.shadow(color: .black.opacity(0.2), radius: 2, y: 1)
.onTapGesture {
let customPlace = Place(
name: memory.placeName,
region: .central,
infoType: "Visited Place",
locationDescription: memory.locationDescription,
photoPrompt: "Memory captured at " + memory.placeName,
coordinate: coordinate
)
activeSheet = .place(customPlace)
}
}
.annotationTitles(.automatic)
}
}
}
.mapControls { }
}
// MARK: - 8. MAP & PROMPT MANAGEMENT (PROXIMITY-BASED)
private func resetMapToSingapore() {
withAnimation(.easeInOut(duration: 0.5)) {
cameraPosition = .region(Self.defaultSingaporeRegion)
}
}
private func loadCurrentPrompt() {
let sortedPlaces = sortedPlacesByProximity()
let nearestIncomplete = sortedPlaces.first { !isPlaceCompleted($0) }
if let nearestIncomplete {
currentPrompt = nearestIncomplete
} else if let recommendedPlace = tripStore.getNextPrompt(),
!completedPlaceNames.contains(recommendedPlace.name) {
currentPrompt = Place(
name: recommendedPlace.name,
region: .central,
infoType: recommendedPlace.infoType,
locationDescription: recommendedPlace.locationDescription,
photoPrompt: recommendedPlace.photoPrompt,
coordinate: recommendedPlace.coordinate
)
} else {
currentPrompt = sortedPlaces.first ?? places.first
}
}
private func skipCurrentPrompt() {
didSkipPrompt = true
tripStore.skipPrompt()
let sortedRemaining = sortedPlacesByProximity(excluding: currentPrompt?.name)
if let nextNearestUncompleted = sortedRemaining.first(where: { !isPlaceCompleted($0) }) {
currentPrompt = nextNearestUncompleted
} else {
currentPrompt = sortedRemaining.first ?? currentPrompt
}
}
// MARK: - 9. DAILY MIDNIGHT RESET
private func midnightRefreshLoop() async {
while !Task.isCancelled {
let calendar = Calendar.current
let now = Date()
let tomorrow = calendar.date(
byAdding: .day,
value: 1,
to: calendar.startOfDay(for: now)
) ?? now.addingTimeInterval(86400)
let secondsUntilMidnight = max(1, tomorrow.timeIntervalSince(now) + 1)
do {
try await Task.sleep(nanoseconds: UInt64(secondsUntilMidnight * 1_000_000_000))
} catch {
return
}
guard !Task.isCancelled else { return }
didSkipPrompt = false
hasLockedUserRecommendation = false
loadCurrentPrompt()
}
}
// MARK: - 10. GPS COORDINATE EXTRACTION
private func extractCoordinate(_ memory: SavedMemory) -> CLLocationCoordinate2D? {
tripStore.extractCoordinate(from: memory.imageData)
}
}
// MARK: - 11. LOCATION DETAIL VIEW (EXIF METADATA VERIFICATION + COMPLETION & REPLACE PHOTO)
struct LocationDetailView: View {
@Environment(\.dismiss) private var dismiss
let place: Place
let isCompleted: Bool
let completedImage: UIImage?
let currentLocation: CLLocationCoordinate2D?
var onSaveMemory: (CapturedMemory) -> Void
@State private var detailCamera: MapCameraPosition
@State private var selectedPhotoItem: PhotosPickerItem?
@State private var verificationMessage: String?
@State private var isVerificationError = false
@State private var isCheckingMetadata = false
private let maxAllowedDistanceMeters: Double = 500.0
init(
place: Place,
isCompleted: Bool,
completedImage: UIImage?,
currentLocation: CLLocationCoordinate2D?,
onSaveMemory: @escaping (CapturedMemory) -> Void
) {
self.place = place
self.isCompleted = isCompleted
self.completedImage = completedImage
self.currentLocation = currentLocation
self.onSaveMemory = onSaveMemory
_detailCamera = State(
initialValue: .region(
MKCoordinateRegion(
center: place.coordinate,
span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
)
)
)
}
var body: some View {
VStack(spacing: 16) {
HStack {
Spacer()
Button {
dismiss()
} label: {
Image(systemName: "xmark")
.font(.headline)
.foregroundStyle(.primary)
.frame(width: 36, height: 36)
.background(Color(.systemGray5))
.clipShape(RoundedRectangle(cornerRadius: 8))
.contentShape(Rectangle())
}
.buttonStyle(.plain)
}
.zIndex(1)
if isCompleted, let completedImage {
ZStack(alignment: .bottom) {
Image(uiImage: completedImage)
.resizable()
.scaledToFill()
.frame(maxWidth: .infinity)
.frame(height: 200)
.clipped()
HStack {
Label("Captured Memory", systemImage: "checkmark.seal.fill")
.font(.caption.weight(.semibold))
.foregroundStyle(.white)
.padding(.horizontal, 10)
.padding(.vertical, 6)
.background(.ultraThinMaterial)
.clipShape(Capsule())
Spacer()
PhotosPicker(
selection: $selectedPhotoItem,
matching: .images,
photoLibrary: .shared()
) {
HStack(spacing: 5) {
if isCheckingMetadata {
ProgressView()
.controlSize(.mini)
.tint(.white)
} else {
Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
}
Text(isCheckingMetadata ? "Checking..." : "Replace Photo")
}
.font(.caption.weight(.semibold))
.foregroundStyle(.white)
.padding(.horizontal, 12)
.padding(.vertical, 6)
.background(Color.blue.opacity(0.9))
.clipShape(Capsule())
.shadow(color: .black.opacity(0.25), radius: 4, y: 2)
}
.disabled(isCheckingMetadata)
}
.padding(10)
}
.clipShape(RoundedRectangle(cornerRadius: 16))
} else {
Map(position: $detailCamera) {
Marker(place.name, coordinate: place.coordinate)
UserAnnotation()
MapCircle(center: place.coordinate, radius: maxAllowedDistanceMeters)
.foregroundStyle(Color.blue.opacity(0.15))
.stroke(Color.blue, lineWidth: 2)
}
.frame(height: 180)
.clipShape(RoundedRectangle(cornerRadius: 16))
}
VStack(alignment: .leading, spacing: 8) {
HStack {
Text(place.name)
.font(.title2)
.bold()
if isCompleted {
Label("Completed", systemImage: "checkmark.seal.fill")
.font(.caption.weight(.semibold))
.foregroundStyle(.green)
.padding(.horizontal, 10)
.padding(.vertical, 4)
.background(Color.green.opacity(0.15))
.clipShape(Capsule())
}
}
HStack(spacing: 4) {
Image(systemName: "location.fill")
.foregroundStyle(.secondary)
Text(place.locationDescription)
.font(.subheadline)
.foregroundStyle(.secondary)
}
}
.frame(maxWidth: .infinity, alignment: .leading)
if let verificationMessage {
HStack(spacing: 8) {
Image(systemName: isVerificationError ? "xmark.octagon.fill" : "checkmark.shield.fill")
.foregroundStyle(isVerificationError ? .red : .green)
Text(verificationMessage)
.font(.caption.weight(.medium))
.foregroundStyle(isVerificationError ? .red : .green)
Spacer()
}
.padding(10)
.background(isVerificationError ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
.clipShape(RoundedRectangle(cornerRadius: 10))
} else if isCompleted {
HStack(spacing: 8) {
Image(systemName: "checkmark.circle.fill")
.foregroundStyle(.green)
Text("Challenge Completed! You have unlocked the " + place.name + " jigsaw piece.")
.font(.caption.weight(.medium))
.foregroundStyle(.green)
Spacer()
}
.padding(10)
.background(Color.green.opacity(0.12))
.clipShape(RoundedRectangle(cornerRadius: 10))
}
HStack {
VStack(alignment: .leading, spacing: 6) {
Text("Take Photo Prompt")
.font(.caption)
.bold()
.foregroundStyle(.secondary)
Text(place.photoPrompt)
.font(.subheadline)
.foregroundStyle(.secondary)
.multilineTextAlignment(.leading)
.padding(10)
.frame(maxWidth: .infinity, alignment: .leading)
.background(Color.gray.opacity(0.1))
.cornerRadius(10)
}
if isCompleted {
Image(systemName: "checkmark.circle.fill")
.font(.title2)
.foregroundStyle(.white)
.padding(14)
.background(Color.green)
.clipShape(RoundedRectangle(cornerRadius: 12))
} else {
PhotosPicker(
selection: $selectedPhotoItem,
matching: .images,
photoLibrary: .shared()
) {
if isCheckingMetadata {
ProgressView()
.tint(.white)
.padding(14)
.background(Color.blue)
.clipShape(RoundedRectangle(cornerRadius: 12))
} else {
Image(systemName: "photo.badge.checkmark")
.font(.title2)
.foregroundStyle(.white)
.padding(14)
.background(Color.blue)
.clipShape(RoundedRectangle(cornerRadius: 12))
}
}
.disabled(isCheckingMetadata)
}
}
.padding()
.background(Color(.systemGray6))
.clipShape(RoundedRectangle(cornerRadius: 12))
Text("We will check the place!")
.font(.caption2)
.foregroundStyle(.secondary)
.multilineTextAlignment(.center)
Spacer()
}
.padding()
.onChange(of: selectedPhotoItem) { _, newItem in
guard let newItem else { return }
verifyAndSavePhoto(from: newItem)
}
}
// MARK: - EXIF GPS Metadata Extraction & Verification
private func verifyAndSavePhoto(from item: PhotosPickerItem) {
isCheckingMetadata = true
verificationMessage = nil
Task {
defer {
isCheckingMetadata = false
selectedPhotoItem = nil
}
guard let rawData = try? await item.loadTransferable(type: Data.self),
let uiImage = UIImage(data: rawData) else {
isVerificationError = true
verificationMessage = "Could not load photo data. Please try another photo."
return
}
guard let photoCoordinate = extractEXIFCoordinate(from: rawData) else {
isVerificationError = true
verificationMessage = "Rejected: No GPS location metadata found in this photo. Enable Camera Location Services on your iPhone."
return
}
let photoLoc = CLLocation(
latitude: photoCoordinate.latitude,
longitude: photoCoordinate.longitude
)
let placeLoc = CLLocation(
latitude: place.coordinate.latitude,
longitude: place.coordinate.longitude
)
let distanceMeters = Int(photoLoc.distance(from: placeLoc))
guard Double(distanceMeters) <= maxAllowedDistanceMeters else {
isVerificationError = true
verificationMessage = "Rejected: Photo metadata shows it was taken " + String(distanceMeters) + "m away from " + place.name + " (must be within 500m)."
return
}
isVerificationError = false
verificationMessage = "Verified! Photo metadata confirmed " + String(distanceMeters) + "m from " + place.name + "."
let memory = CapturedMemory(
placeName: place.name,
infoType: place.infoType,
coordinate: photoCoordinate,
image: uiImage,
dateTaken: extractEXIFDate(from: rawData) ?? Date(),
rawImageData: rawData
)
onSaveMemory(memory)
dismiss()
}
}
private func extractEXIFCoordinate(from data: Data) -> CLLocationCoordinate2D? {
guard let source = CGImageSourceCreateWithData(data as CFData, nil),
let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any],
let lat = gps[kCGImagePropertyGPSLatitude] as? Double,
let latRef = gps[kCGImagePropertyGPSLatitudeRef] as? String,
let lon = gps[kCGImagePropertyGPSLongitude] as? Double,
let lonRef = gps[kCGImagePropertyGPSLongitudeRef] as? String else {
return nil
}
let finalLat = (latRef == "S") ? -lat : lat
let finalLon = (lonRef == "W") ? -lon : lon
return CLLocationCoordinate2D(latitude: finalLat, longitude: finalLon)
}
private func extractEXIFDate(from data: Data) -> Date? {
guard let source = CGImageSourceCreateWithData(data as CFData, nil),
let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any],
let dateString = exif[kCGImagePropertyExifDateTimeOriginal] as? String else {
return nil
}
let formatter = DateFormatter()
formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
return formatter.date(from: dateString)
}
}
// MARK: - 12. MEMORY DETAIL VIEW
struct MemoryDetailView: View {
@Environment(\.dismiss) private var dismiss
let memory: CapturedMemory
var body: some View {
VStack(spacing: 16) {
HStack {
Text("Photo Memory")
.font(.headline)
Spacer()
Button {
dismiss()
} label: {
Image(systemName: "xmark")
.frame(width: 32, height: 32)
.background(Color(.systemGray5))
.clipShape(Circle())
.contentShape(Rectangle())
}
.buttonStyle(.plain)
}
.zIndex(1)
Image(uiImage: memory.image)
.resizable()
.scaledToFit()
.frame(maxHeight: 300)
.clipShape(RoundedRectangle(cornerRadius: 16))
VStack(alignment: .leading, spacing: 8) {
Text(memory.placeName)
.font(.title2)
.bold()
Text("Captured on " + memory.dateTaken.formatted(date: .abbreviated, time: .shortened))
.font(.caption)
.foregroundStyle(.secondary)
}
.frame(maxWidth: .infinity, alignment: .leading)
Spacer()
}
.padding()
}
}
// MARK: - 13. PREVIEW
#Preview {
RecommendationTab()
.environment(TripStore())
}

