// Copyright 2015 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import CoreBluetooth

///
/// BeaconData
///
/// Uniquely identifies an Eddystone compliant beacon.
///
class BeaconData : NSObject, Equatable {

  enum BeaconType {
    case Eddystone
  }

  ///
  /// Currently there's only the Eddystone format, but we'd like to leave the door open to other
  /// possibilities, so let's have a beacon type here in the info.
  ///
  let beaconType: BeaconType

  ///
  /// The raw BeaconData data. This is typically printed out in hex format.
  ///
  let beaconData: [UInt8]

  private init(beaconType: BeaconType!, beaconData: [UInt8]) {
    self.beaconData = beaconData
    self.beaconType = beaconType
  }

  override var description: String {
    if self.beaconType == BeaconType.Eddystone {
      let hexid = hexBeaconID(self.beaconData)
      return "BeaconData beacon: \(hexid)"
    } else {
      return "BeaconData with invalid type (\(beaconType))"
    }
  }

  private func hexBeaconID(BeaconID: [UInt8]) -> String {
    var retval = ""
    for byte in BeaconID {
      var s = String(byte, radix:16, uppercase: false)
      if count(s) == 1 {
        s = "0" + s
      }
      retval += s
    }
    return retval
  }
    
    private func hexBeaconURL(beaconURL: [UInt8]) -> String {
        var retval = ""
        for byte in beaconURL {
            var s = String(byte, radix:16, uppercase: false)
            if count(s) == 1 {
                s = "0" + s
            }
            retval += s
        }
        return retval
    }

}

func ==(lhs: BeaconData, rhs: BeaconData) -> Bool {
  if lhs == rhs {
    return true;
  } else if lhs.beaconType == rhs.beaconType
    && rhs.beaconData == rhs.beaconData {
      return true;
  }

  return false;
}

///
/// BeaconInfo
///
/// Contains information fully describing a beacon, including its BeaconData, transmission power,
/// RSSI, and possibly telemetry information.
///
class BeaconInfo : NSObject {

    static let EddystoneUIDFrameTypeID: UInt8 = 0x00
    static let EddystoneURLFrameTypeID: UInt8 = 0x10
    static let EddystoneTLMFrameTypeID: UInt8 = 0x20

  enum EddystoneFrameType {
    case UnknownFrameType
    case UIDFrameType
    case URLFrameType
    case TelemetryFrameType

    var description: String {
      switch self {
      case .UnknownFrameType:
        return "Unknown Frame Type"
      case .UIDFrameType:
        return "UID Frame"
      case .URLFrameType:
        return "URL Frame"
      case .TelemetryFrameType:
        return "TLM Frame"
      }
    }
  }

  let beaconData: BeaconData
  let txPower: Int
  let RSSI: Int
  let telemetry: NSData?

  private init(beaconData: BeaconData, txPower: Int, RSSI: Int, telemetry: NSData?) {
    self.beaconData = beaconData
    self.txPower = txPower
    self.RSSI = RSSI
    self.telemetry = telemetry
  }

  class func frameTypeForFrame(advertisementFrameList: [NSObject : AnyObject])
    -> EddystoneFrameType {
    if let
      uuid = CBUUID(string: "FEAA"),
      frameData = advertisementFrameList[uuid] as? NSData {
      if frameData.length > 1 {
        let count = frameData.length
        var frameBytes = [UInt8](count: count, repeatedValue: 0)
        frameData.getBytes(&frameBytes, length: count)

        if frameBytes[0] == EddystoneUIDFrameTypeID {
          return EddystoneFrameType.UIDFrameType
        } else if frameBytes[0] == EddystoneTLMFrameTypeID {
          return EddystoneFrameType.TelemetryFrameType
        }else if frameBytes[0] == EddystoneURLFrameTypeID {
            for temp in frameBytes{
                print(temp)
            }
            println()
            return EddystoneFrameType.URLFrameType
        }
      }
    }

    return EddystoneFrameType.UnknownFrameType
  }

  class func telemetryDataForFrame(advertisementFrameList: [NSObject : AnyObject]!) -> NSData? {
    return advertisementFrameList[CBUUID(string: "FEAA")] as? NSData
  }

  ///
  /// Unfortunately, this can't be a failable convenience initialiser just yet because of a "bug"
  /// in the Swift compiler — it can't tear-down partially initialised objects, so we'll have to 
  /// wait until this gets fixed. For now, class method will do.
  ///
  class func beaconInfoForUIDFrameData(frameData: NSData, telemetry: NSData?, RSSI: Int)
    -> BeaconInfo? {
      if frameData.length > 1 {
        let count = frameData.length
        var frameBytes = [UInt8](count: count, repeatedValue: 0)
        frameData.getBytes(&frameBytes, length: count)

        if frameBytes[0] != EddystoneUIDFrameTypeID {
          NSLog("Unexpected non UID Frame passed to BeaconInfoForUIDFrameData.")
          return nil
        } else if frameBytes.count < 18 {
          NSLog("Frame Data for UID Frame unexpectedly truncated in BeaconInfoForUIDFrameData.")
        }

        let txPower = Int(Int8(bitPattern:frameBytes[1]))
        let beaconData: [UInt8] = Array(frameBytes[2..<18])
        let bid = BeaconData(beaconType: BeaconData.BeaconType.Eddystone, beaconData: beaconData)
        return BeaconInfo(beaconData: bid, txPower: txPower, RSSI: RSSI, telemetry: telemetry)
      }
      
      return nil
  }
    
    ///
    /// Unfortunately, this can't be a failable convenience initialiser just yet because of a "bug"
    /// in the Swift compiler — it can't tear-down partially initialised objects, so we'll have to
    /// wait until this gets fixed. For now, class method will do.
    ///
    class func beaconInfoForURLFrameData(frameData: NSData, telemetry: NSData?, RSSI: Int)
        -> BeaconInfo? {
            if frameData.length > 1 {
                let count = frameData.length
                var frameBytes = [UInt8](count: count, repeatedValue: 0)
                frameData.getBytes(&frameBytes, length: count)
                
                if frameBytes[0] != EddystoneURLFrameTypeID {
                    NSLog("Unexpected non UID Frame passed to BeaconInfoForUIDFrameData.")
                    return nil
                }
                
                let txPower = Int(Int8(bitPattern:frameBytes[1]))
                let beaconData: [UInt8] = Array(frameBytes[2..<frameBytes.count])
                let bid = BeaconData(beaconType: BeaconData.BeaconType.Eddystone, beaconData: beaconData)
                return BeaconInfo(beaconData: bid, txPower: txPower, RSSI: RSSI, telemetry: telemetry)
            }
            
            return nil
    }


  override var description: String {
    if self.beaconData.beaconData[0] == 0x10{
        return "Eddystone URL URL \(self.beaconData), txPower: \(self.txPower), RSSI: \(self.RSSI)"

    }
    return "Eddystone \(self.beaconData), txPower: \(self.txPower), RSSI: \(self.RSSI)"
  }
    var URL: String {
        
        return " sdf"
    }

}

