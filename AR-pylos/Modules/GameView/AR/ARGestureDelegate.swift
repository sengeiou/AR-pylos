//
//  ARGestureDelegate.swift
//  AR-pylos
//
//  Created by Vitalii Poponov on 6/17/20.
//  Copyright © 2020 Vitalii Poponov. All rights reserved.
//

import Foundation
import RealityKit
import Combine

extension ARGestureDelegate {
    struct Constants {
        static let boundsXRange = Range(uncheckedBounds: (lower: Float(-0.532), upper: Float(0.51)))
        static let boundsZRange = Range(uncheckedBounds: (lower: Float(0.308), upper: Float(0.91)))
    }
}
class ARGestureDelegate {
    
    unowned var arViewManager: ARViewManager
    
    var cancelBag: Set<AnyCancellable> = []
    
    init(arViewManager: ARViewManager) {
        self.arViewManager = arViewManager
    }
    
    var lastIntersectionPosition: SIMD3<Float>?
    var snappedAvailableEntity: Entity?
    
    @objc func onTap(_ gesture: EntityTranslationGestureRecognizer) {
        switch gesture.state {
            
        case .possible:
            break
        case .began:
            guard let entity = gesture.entity else { return }
            entity.scene?.subscribe(to: CollisionEvents.Began.self, on: entity, { (event) in
                guard let entityName = ARViewManager.EntityNames(rawValue: event.entityB.name) else { return }
                switch entityName {
                case .stashedBall:
                    break
                case .availableBall:
                if self.snappedAvailableEntity != event.entityB {
                    event.entityA.position = event.entityB.position
                    self.snappedAvailableEntity = event.entityB
                }
                case .filledBall:
                    self.lastIntersectionPosition = event.entityB.position
                case .table:
                    break
                }
            }).store(in: &cancelBag)
            entity.scene?.subscribe(to: CollisionEvents.Updated.self, on: entity, { (event) in
                guard event.entityA == gesture.entity else { return }
                guard let entityName = ARViewManager.EntityNames(rawValue: event.entityB.name) else { return }
                switch entityName {
                case .stashedBall, .filledBall:
                    self.lastIntersectionPosition = event.entityB.position
                    
                    if event.entityA.position.y - event.entityB.position.y - ARViewManager.Constants.ballDiameter + ARViewManager.Constants.yTranslation < 0 {
                        event.entityA.position.y += 0.007
                    }
                case .availableBall:
                    if self.snappedAvailableEntity != event.entityB {
//                        event.entityA.position = event.entityB.position
//                        self.snappedAvailableEntity = event.entityB
                    }
                default:
                    break
                }
            }).store(in: &cancelBag)
            entity.scene?.subscribe(to: CollisionEvents.Ended.self, on: entity, { (event) in
                guard let entityName = ARViewManager.EntityNames(rawValue: event.entityB.name) else { return }
                switch entityName {
                case .stashedBall, .filledBall:
                    break
                case .availableBall:
                    if self.snappedAvailableEntity == event.entityB {
                        self.snappedAvailableEntity = nil
                    }
                default:
                    break
                }
            }).store(in: &cancelBag)

        case .changed:
            guard let entity = gesture.entity else { return }
            let position = entity.position
            
            if let intersectionPosition = self.lastIntersectionPosition {
                if abs(position.x - intersectionPosition.x) > ARViewManager.Constants.ballDiameter || abs(position.z - intersectionPosition.z) > ARViewManager.Constants.ballDiameter {
                    if entity.position.y > ARViewManager.Constants.initialStashPosition.y + ARViewManager.Constants.yTranslation {
                        gesture.entity?.position.y -= ARViewManager.Constants.yTranslation
                    }
                }
            }
            
            if !Constants.boundsXRange.contains(position.x) {
                gesture.entity?.position.x = position.x < Constants.boundsXRange.lowerBound ? Constants.boundsXRange.lowerBound : Constants.boundsXRange.upperBound
            }
            if !Constants.boundsZRange.contains(position.z) {
                gesture.entity?.position.z = position.z < Constants.boundsZRange.lowerBound ? Constants.boundsZRange.lowerBound : Constants.boundsZRange.upperBound
            }
            break
        case .ended, .cancelled, .failed:
            cancelBag.removeAll()
        @unknown default:
            break
        }
    }
}
