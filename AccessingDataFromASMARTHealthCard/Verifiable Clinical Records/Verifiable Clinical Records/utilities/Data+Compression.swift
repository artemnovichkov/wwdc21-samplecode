/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An extension that adds ZLIB decompression support.
*/

import Foundation
import Compression

extension Data {
    
    func decompress() throws -> Data {
        var decompressed = Data()
        let outputFilter = try OutputFilter(.decompress, using: .zlib) { (data: Data?) in
            if let data = data {
                decompressed.append(data)
            }
        }
        
        let pageSize = 512
        var index = 0
        
        // Feed data to the OutputFilter until there is none left to decompress.
        while true {
            let rangeLength = Swift.min(pageSize, count - index)
            let subdata = subdata(in: index ..< index + rangeLength)
            index += rangeLength
            
            try outputFilter.write(subdata)
            if rangeLength == 0 {
                break
            }
        }
        return decompressed
    }
}
