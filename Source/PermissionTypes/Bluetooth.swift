//
// Bluetooth.swift
//
// Copyright (c) 2015-2016 Damien (http://delba.io)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

#if PERMISSION_BLUETOOTH
import CoreBluetooth

internal var BluetoothManager: CBPeripheralManager?

extension Permission {
    var statusBluetooth: PermissionStatus {
        if #available(iOS 13.1, *) {
            switch CBManager.authorization {
            case .notDetermined: return .notDetermined
            case .restricted: return .disabled
            case .denied: return .denied
            case .allowedAlways: return .authorized
            }
        } else if #available(iOS 13.0, *) {
            switch CBPeripheralManager().authorization {
            case .notDetermined: return .notDetermined
            case .restricted: return .disabled
            case .denied: return .denied
            case .allowedAlways: return .authorized
            }
        }

        instantiateBluetoothManager()

        switch CBPeripheralManager.authorizationStatus() {
        case .restricted: return .disabled
        case .denied: return .denied
        case .notDetermined, .authorized: break
        }
        
        guard UserDefaults.standard.stateBluetoothManagerDetermined else { return .notDetermined }
        
        guard let bluetoothManager = BluetoothManager else { return .disabled }
        
        switch bluetoothManager.state {
        case .unsupported, .poweredOff: return .disabled
        case .unauthorized: return .denied
        case .poweredOn: return .authorized
        case .resetting, .unknown:
            return UserDefaults.standard.statusBluetooth ?? .notDetermined
        }
    }
    
    func requestBluetooth(_ callback: Callback?) {
        UserDefaults.standard.requestedBluetooth = true
        
        instantiateBluetoothManager()
        
        guard #available(iOS 13, *) else {
            // iOS 13 and later display a permission dialog when creating the manager (above).
            return
        }

        // Prior to iOS 13, to request permission one must start/stop advertising.
        guard let bluetoothManager = BluetoothManager else { return }
        guard case .poweredOn = bluetoothManager.state else { return }
        bluetoothManager.startAdvertising(nil)
        bluetoothManager.stopAdvertising()
    }
    
    private func instantiateBluetoothManager() {
        guard BluetoothManager == nil else { return }

        BluetoothManager = .init(
            delegate: Permission.bluetooth,
            queue: nil,
            options: [CBPeripheralManagerOptionShowPowerAlertKey: false]
        )
    }
}

extension Permission: CBPeripheralManagerDelegate {
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        UserDefaults.standard.stateBluetoothManagerDetermined = true
        UserDefaults.standard.statusBluetooth = statusBluetooth
        
        guard UserDefaults.standard.requestedBluetooth else { return }
        
        callback?(statusBluetooth)
        
        UserDefaults.standard.requestedBluetooth = false
    }
}
#endif
