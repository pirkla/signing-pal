//
//  SigningPalError.swift
//  Signing Pal
//
//  Created by Andrew Pirkl on 6/4/20.
//  Copyright © 2020 Pirklator. All rights reserved.
//

import Foundation
public enum SigningPalError: Error {
    case noUrlFound
    case noDataFound
    case decoderNotCreated
    case fileNotWritten(description:String)
    case noSigningId
    case signFailed
}

extension SigningPalError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noUrlFound:
            return "The file url could not be read."
        case .noDataFound:
            return "No data could be found."
        case .decoderNotCreated:
            return "The decoder could not be created."
        case .fileNotWritten(let description):
            return "The file could not be written: \(description)"
        case .noSigningId:
            return "No signing identity could be found."
        case .signFailed:
            return "The file could not be signed."
        }
    }
}
