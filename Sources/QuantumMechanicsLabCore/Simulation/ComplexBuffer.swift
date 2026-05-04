import Foundation

public struct ComplexValue: Codable, Sendable, Equatable {
    public var real: Double
    public var imaginary: Double

    public init(real: Double, imaginary: Double = 0) {
        self.real = real
        self.imaginary = imaginary
    }

    public var magnitudeSquared: Double {
        real * real + imaginary * imaginary
    }

    public static func * (lhs: ComplexValue, rhs: ComplexValue) -> ComplexValue {
        ComplexValue(
            real: lhs.real * rhs.real - lhs.imaginary * rhs.imaginary,
            imaginary: lhs.real * rhs.imaginary + lhs.imaginary * rhs.real
        )
    }

    public static func + (lhs: ComplexValue, rhs: ComplexValue) -> ComplexValue {
        ComplexValue(real: lhs.real + rhs.real, imaginary: lhs.imaginary + rhs.imaginary)
    }

    public static func - (lhs: ComplexValue, rhs: ComplexValue) -> ComplexValue {
        ComplexValue(real: lhs.real - rhs.real, imaginary: lhs.imaginary - rhs.imaginary)
    }

    public static func * (lhs: ComplexValue, rhs: Double) -> ComplexValue {
        ComplexValue(real: lhs.real * rhs, imaginary: lhs.imaginary * rhs)
    }

    public static func * (lhs: Double, rhs: ComplexValue) -> ComplexValue {
        rhs * lhs
    }
}

public struct ComplexBuffer: Codable, Sendable, Equatable {
    public var values: [ComplexValue]

    public init(values: [ComplexValue]) {
        self.values = values
    }

    public var count: Int {
        values.count
    }

    public subscript(index: Int) -> ComplexValue {
        get { values[index] }
        set { values[index] = newValue }
    }

    public func probabilityDensity() -> [Double] {
        values.map(\.magnitudeSquared)
    }

    public func norm(spacing dx: Double) -> Double {
        probabilityDensity().reduce(0, +) * dx
    }

    public func normalized(spacing dx: Double) -> ComplexBuffer {
        let currentNorm = norm(spacing: dx)
        guard currentNorm > .ulpOfOne else {
            return self
        }

        let scale = 1 / sqrt(currentNorm)
        return ComplexBuffer(
            values: values.map {
                ComplexValue(real: $0.real * scale, imaginary: $0.imaginary * scale)
            }
        )
    }
}
