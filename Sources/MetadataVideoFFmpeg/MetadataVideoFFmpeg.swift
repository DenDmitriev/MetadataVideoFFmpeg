// The Swift Programming Language
// https://docs.swift.org/swift-book
//
//  MetadataVideo.swift
//  GrabShot
//
//  Created by Denis Dmitriev on 05.12.2023.
//

import Foundation

public struct MetadataVideo: Codable {
    /// Media streams array.
    ///
    /// Contains video, audio, subtitle and data streams types.
    public let streams: [StreamMetadata]
    
    /// Format file.
    ///
    /// Contains file properties such as name, numeric streams, duration, size, bit rate.
    public let format: FormatMetadata
}

extension MetadataVideo: Hashable, Equatable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(format.fileName)
    }
    
    public static func == (lhs: MetadataVideo, rhs: MetadataVideo) -> Bool {
        lhs.format.fileName == rhs.format.fileName
    }
}

extension MetadataVideo {
    static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = Locale.current
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        return dateFormatter
    }()
    
    static let dateFormatterDecoder: DateFormatter = {
        let formatter = Self.dateFormatter
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter
    }()
    
    static func fileSize(value: Int, unit: FileSize.Unit) -> FileSize {
        let fileSize = FileSize(size: value, unit: unit)
        return fileSize
    }
    
    static func decodeIfPresentDuration<Key: CodingKey>(container: KeyedDecodingContainer<Key>, key: Key) throws -> Duration? {
        if let string = try container.decodeIfPresent(String.self, forKey: key),
           let double = Double(string) {
            return Duration.seconds(double)
        } else {
            return nil
        }
    }
    
    static func decodeIfPresentInt<Key: CodingKey>(container: KeyedDecodingContainer<Key>, key: Key) throws -> Int? {
        if let string = try container.decodeIfPresent(String.self, forKey: key),
           let int = Int(string) {
            return int
        } else {
            return nil
        }
    }
    
    static func fileSizeFormatted(value: Int?, unit: FileSize.Unit, rule: FloatingPointRoundingRule? = nil) -> String? {
        if let value {
            let fileSize = MetadataVideo.fileSize(value: value, unit: unit)
            return fileSize.optimal(rule: rule).formatted()
        } else {
            return nil
        }
    }
}

extension MetadataVideo {
    
    /// JSON MetadataVideo placeholder file for debug.
    public static let placeholder: Self? = {
        let url = Bundle.main.url(forResource: "metadata", withExtension: "json")
        guard let url else { return nil }
        do {
            let data = try Data(contentsOf: url)
            let metadata = try JSONDecoder().decode(MetadataVideo.self, from: data)
            return metadata
        } catch {
            return nil
        }
    }()
}

extension MetadataVideo {
    
    /// Due to incorrect formatting of FFmpeg/FFprobe console output, line breaks and quote characters need to be converted.
    ///
    /// From:
    /// ```txt
    /// {\n    \"streams\": [...], \"format\": {..}}
    /// ```
    /// To:
    /// ```json
    /// {
    ///     "streams": [...],
    ///     "format": {...}
    /// }
    /// ```
    ///
    public static func convertMediaInformationToJSON(_ mediaInformation: String) -> Data? {
        let converted = mediaInformation
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\\u{22}", with: "\u{22}")
        let data = converted.data(using: .utf8)
        return data
    }
}
