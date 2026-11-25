import SwiftUI
import TripPickCore

struct TripHomeView: View {
    let session: TripSession
    let trip: TripRecord

    var body: some View {
        Text(verbatim: "\(session.summary.total)")
            .navigationTitle(trip.name)
    }
}
