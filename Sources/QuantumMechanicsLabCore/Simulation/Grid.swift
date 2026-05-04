import Foundation

public struct Grid1D: Codable, Sendable, Equatable {
    public var pointCount: Int
    public var length: Double

    public init(pointCount: Int = 2_048, length: Double = 20) {
        self.pointCount = pointCount
        self.length = length
    }

    public var spacing: Double {
        length / Double(pointCount)
    }

    public var xValues: [Double] {
        (0..<pointCount).map { index in
            (Double(index) + 0.5) * spacing - length / 2
        }
    }
}

public struct Grid2D: Codable, Sendable, Equatable {
    public var width: Int
    public var height: Int
    public var lengthX: Double
    public var lengthY: Double

    public init(width: Int = 128, height: Int = 128, lengthX: Double = 20, lengthY: Double = 20) {
        self.width = width
        self.height = height
        self.lengthX = lengthX
        self.lengthY = lengthY
    }

    public var pointCount: Int {
        width * height
    }

    public var spacingX: Double {
        lengthX / Double(width)
    }

    public var spacingY: Double {
        lengthY / Double(height)
    }

    public func xValue(at column: Int) -> Double {
        (Double(column) + 0.5) * spacingX - lengthX / 2
    }

    public func yValue(at row: Int) -> Double {
        (Double(row) + 0.5) * spacingY - lengthY / 2
    }

    public func linearIndex(column: Int, row: Int) -> Int {
        row * width + column
    }
}

public enum GridDescriptor: Codable, Sendable, Equatable {
    case oneD(Grid1D)
    case twoD(Grid2D)
    case orbital(resolution: Int)
}
