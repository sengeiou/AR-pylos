//
//  GameKitNetworkAdapter.swift
//  AR-pylos
//
//  Created by Vitalii Poponov on 6/6/20.
//  Copyright © 2020 Vitalii Poponov. All rights reserved.
//

//Low level interface to find and handle connection
import Foundation

protocol CommunicatorAdapter {
    var outMessages: PublishRelay<Data> { get } //Messages to send to others
    var inMessages: PublishSubject<Data> { get } //Messages received from others
    
    func findMatch() -> Observable<Bool>
}

class GameKitNetworkAdapter: CommunicatorAdapter {
    
    private let disposeBag = DisposeBag()

    var outMessages: PublishRelay<Data> = PublishRelay<Data>() //Messages to send to others
    var inMessages: PublishSubject<Data> = PublishSubject<Data>() //Messages received from others
    
    func findMatch() -> Observable<Bool> {
        return Observable<Bool>.create { (observer) -> Disposable in
            self.createBindings()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                observer.onNext(true)
            }
            return Disposables.create {}
        }
    }
    
    func createBindings() {
        outMessages.subscribe { (event) in
            switch event {
                
            case .next(let message):
                print("")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    let challenge = GameStartChallengeModel()
                    guard let challengeData = try? JSONEncoder().encode(challenge) else {
                        return
                    }
                    self.inMessages.onNext(challengeData)
                }
            case .error(_):
                break
            case .completed:
                break
            }
        }.disposed(by: disposeBag)
    }
}
