/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Utilities.swift (iOS)
*/

import UIKit

func writeToPasteboard(_ string: String) {
    UIPasteboard.general.string = string
}
