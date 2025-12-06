//
//  SwiftReplace.swift
//
//  Created by Brian Floersch on 12/7/18.
//  Copyright © 2018 Brian Floersch. All rights reserved.
//
import Foundation

extension String {
    func replace(
        _ pattern: String,
        options: NSRegularExpression.Options = [],
        collector: ([String]) -> String
    ) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return self }
        let matches = regex.matches(
            in: self,
            options: NSRegularExpression.MatchingOptions(rawValue: 0),
            range: NSRange(location: 0, length: (self as NSString).length)
        )
        guard !matches.isEmpty else { return self }
        guard let lastMatch = matches.last,
              let lastRange = Range(lastMatch.range, in: self)
        else { return self }
        var splitStart = startIndex
        return matches.compactMap { match -> (String, [String])? in
            guard let range = Range(match.range, in: self) else { return nil }
            let split = String(self[splitStart ..< range.lowerBound])
            splitStart = range.upperBound
            return (
                split,
                (0 ..< match.numberOfRanges)
                    .compactMap { Range(match.range(at: $0), in: self) }
                    .map { String(self[$0]) }
            )
        }
        .reduce("") { "\($0)\($1.0)\(collector($1.1))" } +
        self[lastRange.upperBound ..< endIndex]
    }

    func replace(
        _ regexPattern: String,
        options: NSRegularExpression.Options = [],
        collector: @escaping () -> String
    ) -> String {
        replace(regexPattern, options: options) { (_: [String]) in collector() }
    }
}
