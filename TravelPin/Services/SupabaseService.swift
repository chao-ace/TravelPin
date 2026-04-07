import Foundation
import Supabase
import Combine

class SupabaseService {
    static let shared = SupabaseService()

    let client = SupabaseClient(
        supabaseURL: URL(string: "https://ywikwxamnllxsrrxvylv.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl3aWt3eGFtbmxseHNycnh2eWx2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU0Nzg4MDMsImV4cCI6MjA5MTA1NDgwM30.GD7veMf9bWr1GyCEsrYJKtivKxsxbt8af8q9bwRgvuM"
    )

    private init() {}

    // MARK: - Auth
    
    func getCurrentUserId() async throws -> UUID {
        if let session = try? await client.auth.session {
            return session.user.id
        }
        // Fallback to anonymous sign in if no session
        let session = try await client.auth.signInAnonymously()
        return session.user.id
    }

    // MARK: - Sync Operations
    
    func syncTrip(_ travel: Travel) async throws {
        let userId = try await getCurrentUserId()
        
        // 1. Sync Travel Core
        let travelDTO = TravelDTO(from: travel, userId: userId)
        try await client.database.from("travels").upsert(travelDTO).execute()
        
        // 2. Sync Itineraries
        for itinerary in travel.itineraries {
            let itineraryDTO = ItineraryDTO(from: itinerary, travelId: travel.id)
            try await client.database.from("itineraries").upsert(itineraryDTO).execute()
        }
        
        // 3. Sync Spots
        for spot in travel.spots {
            let spotDTO = SpotDTO(from: spot, travelId: travel.id, itineraryId: spot.itinerary?.id)
            try await client.database.from("spots").upsert(spotDTO).execute()
        }
        
        // 4. Sync Luggage
        for item in travel.luggageItems {
            let itemDTO = LuggageItemDTO(from: item, travelId: travel.id)
            try await client.database.from("luggage_items").upsert(itemDTO).execute()
        }
        
        print("📊 [Supabase] Successfully synced full trip tree for: \(travel.name)")
    }
    
    func deleteTrip(id: UUID) async throws {
        try await client.database.from("travels").delete().eq("id", value: id.uuidString).execute()
    }
}

// MARK: - Data Transfer Objects (DTOs)

struct TravelDTO: Codable {
    let id: UUID
    let user_id: UUID
    let name: String
    let start_date: Date
    let end_date: Date
    let status: String
    let type: String
    let companion_names: [String]
    let updated_at: Date
    
    init(from travel: Travel, userId: UUID) {
        self.id = travel.id
        self.user_id = userId
        self.name = travel.name
        self.start_date = travel.startDate
        self.end_date = travel.endDate
        self.status = travel.status.rawValue
        self.type = travel.type.rawValue
        self.companion_names = travel.companionNames
        self.updated_at = Date()
    }
}

struct ItineraryDTO: Codable {
    let id: UUID
    let travel_id: UUID
    let day: Int
    let origin: String
    let destination: String
    let is_completed: Bool
    
    init(from itinerary: Itinerary, travelId: UUID) {
        self.id = itinerary.id
        self.travel_id = travelId
        self.day = itinerary.day
        self.origin = itinerary.origin
        self.destination = itinerary.destination
        self.is_completed = itinerary.isCompleted
    }
}

struct SpotDTO: Codable {
    let id: UUID
    let travel_id: UUID?
    let itinerary_id: UUID?
    let name: String
    let type: String
    let status: String
    let estimated_date: Date?
    let actual_date: Date?
    let sequence: Int
    let notes: String
    let latitude: Double?
    let longitude: Double?
    let photo_urls: [String]
    
    init(from spot: Spot, travelId: UUID?, itineraryId: UUID?) {
        self.id = spot.id
        self.travel_id = travelId
        self.itinerary_id = itineraryId
        self.name = spot.name
        self.type = spot.type.rawValue
        self.status = spot.status.rawValue
        self.estimated_date = spot.estimatedDate
        self.actual_date = spot.actualDate
        self.sequence = spot.sequence
        self.notes = spot.notes
        self.latitude = spot.latitude
        self.longitude = spot.longitude
        self.photo_urls = spot.photoPaths
    }
}

struct LuggageItemDTO: Codable {
    let id: UUID
    let travel_id: UUID
    let name: String
    let category: String
    let is_checked: Bool
    
    init(from item: LuggageItem, travelId: UUID) {
        self.id = item.id
        self.travel_id = travelId
        self.name = item.name
        self.category = item.category.rawValue
        self.is_checked = item.isChecked
    }
}
