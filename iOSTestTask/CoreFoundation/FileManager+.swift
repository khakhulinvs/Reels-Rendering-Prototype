//
//  FileManager+.swift
//  iOSTestTask
//
//  Created by Viacheslav Khakhulin on 14.02.2023.
//

import Foundation

public extension FileManager {
    func temporaryFileURL(fileName: String = UUID().uuidString) -> URL? {
        return URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(fileName)
    }
    
    func removeIfExists(url: URL) {
        let path = url.path()
        if fileExists(atPath: path) {
            try? removeItem(at: url)
        }
    }
}
