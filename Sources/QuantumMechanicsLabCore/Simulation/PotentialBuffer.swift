import Foundation

public struct PotentialBuffer: Codable, Sendable, Equatable {
    public var values: [Double]

    public init(values: [Double]) {
        self.values = values
    }

    public static func zero(count: Int) -> PotentialBuffer {
        PotentialBuffer(values: Array(repeating: 0, count: count))
    }
}
