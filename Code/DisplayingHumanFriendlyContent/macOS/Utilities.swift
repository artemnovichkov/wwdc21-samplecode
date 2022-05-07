/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Utilities.swift (macOS)
*/

import AppKit

func writeToPasteboard(_ string: String) {
    NSPasteboard.general.setString(string, forType: .string)
}
