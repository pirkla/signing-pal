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
}

extension SigningPalError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noUrlFound:
            return "The file url could not be read."
        }
    }
}
