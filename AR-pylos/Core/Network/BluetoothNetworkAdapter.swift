//
//  BluetoothNetworkAdapter.swift
//  AR-pylos
//
//  Created by Vitalii Poponov on 6/6/20.
//  Copyright © 2020 Vitalii Poponov. All rights reserved.
//


//Low level interface to find and handle connection
import Foundation
import CoreBluetooth

import BluetoothKit

extension BluetoothNetworkAdapter {
    struct Constants {
        static let dataServiceUUID = CBUUID(string: "6E6B5C64-FAF7-40AE-9C21-D4933AF45B23")
        static let characteristicUUID = CBUUID(string: "6E6B5C64-FAF7-40AE-9C21-D4933AF45B24")
    }
}
class BluetoothNetworkAdapter: CommunicatorAdapter {
    
    private let disposeBag = DisposeBag()
    
    var outMessages: PublishRelay<Data> = PublishRelay<Data>() //Messages to send to others
    var inMessages: PublishSubject<Data> = PublishSubject<Data>() //Messages received from others
    deinit {
        print("")
    }
    func findMatch() -> Single<Bool> {
        return Single.create { (observer) -> Disposable in
         
            return Disposables.create {}
        }
    }
}
