import SwiftUI
import UniformTypeIdentifiers
import QuantumMechanicsLabCore

struct JSONSnapshotDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var snapshot: SimulationSnapshot

    init(snapshot: SimulationSnapshot) {
        self.snapshot = snapshot
    }

    init(configuration: ReadConfiguration) throws {
        let data = configuration.file.regularFileContents ?? Data()
        self.snapshot = try JSONDecoder().decode(SimulationSnapshot.self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(snapshot)
        return FileWrapper(regularFileWithContents: data)
    }
}

struct CSVDataDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    var csvString: String

    init(csvString: String) {
        self.csvString = csvString
    }

    init(snapshot: SimulationSnapshot) {
        if case let .oneD(grid) = snapshot.grid {
            let density = snapshot.psi.probabilityDensity()
            let potential = snapshot.potential?.values ?? Array(repeating: 0.0, count: grid.pointCount)

            var lines = ["x,density,potential"]
            for i in 0..<grid.pointCount {
                let x = grid.xValues[i]
                lines.append("\(x),\(density[i]),\(potential[i])")
            }
            self.csvString = lines.joined(separator: "\n")
        } else {
            self.csvString = "Export not supported for non-1D grids"
        }
    }

    init(configuration: ReadConfiguration) throws {
        let data = configuration.file.regularFileContents ?? Data()
        self.csvString = String(decoding: data, as: UTF8.self)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(csvString.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}

struct SharedConfigDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var config: SharedExperimentConfig

    init(config: SharedExperimentConfig) {
        self.config = config
    }

    init(configuration: ReadConfiguration) throws {
        let data = configuration.file.regularFileContents ?? Data()
        self.config = try JSONDecoder().decode(SharedExperimentConfig.self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(config)
        return FileWrapper(regularFileWithContents: data)
    }
}
