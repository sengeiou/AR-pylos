//
//  GameCoordinator.swift
//  AR-pylos
//
//  Created by Vitalii Poponov on 6/6/20.
//  Copyright © 2020 Vitalii Poponov. All rights reserved.
//

//This class is created after matching process. It coordinates UI and available action for current player, opens win/lose screen etc.
//it subscribes for server acrtion, and emit actions from player to server
import Foundation

protocol GameCoordinatorBridgeProtocol: class, GameCoordinatorInputProtocol, GameCoordinatorOutputProtocol {
}
protocol GameCoordinatorInputProtocol {
    //Interface to receive actions from server
    var serverStateMessages: PublishSubject<ServerMessage> { get }
}
protocol GameCoordinatorOutputProtocol {
    //Interface to send actions to server (player actions)
    var playerStateMessage: PublishSubject<PlayerMessage> { get }
}



class GameCoordinator: GameCoordinatorBridgeProtocol {
    
    private let disposeBag = DisposeBag()

    @Published var arManager: ARViewManager = ARViewManager()
    
    private var player: Player?
    internal var map: [[WrappedMapCell]] = []
    private var stashedItems: [Player: [Ball]] = [:]
    private var myStashedItems: [Ball] {
        guard let player = self.player else { return [] }
        return stashedItems[player] ?? []
    }
    
    public var currentServerPayload: ServerMessagePayloadProtocol?
    
    var gameEnded: PublishSubject<Void> = PublishSubject<Void>()
    
    //MARK: - Input
    var serverStateMessages: PublishSubject<ServerMessage> = PublishSubject<ServerMessage>()
    
    //MARK: - Output
    
    var playerStateMessage: PublishSubject<PlayerMessage> = PublishSubject<PlayerMessage>()
    
    init() {
        serverStateMessages.subscribe(onNext: { [weak self] (message) in
            self?.handle(message: message)
            }, onError: { [weak self] (_) in
                self?.gameEnded.onNext(())
        }).disposed(by: disposeBag)
        arManager.playerPickedItem.subscribe(onNext: { [weak self] (coordinate) in
            guard let self = self else { return }
            guard let payload = self.currentServerPayload as? PlayerTurnServerPayload else { return }
            if let coordinate = coordinate {
                self.arManager.updateAvailablePoints(coordinates: payload.availableToMove?[coordinate] ?? [])
            }
            else {
                self.arManager.updateAvailablePoints(coordinates: payload.availablePointsFromStash ?? [])
            }
        }).disposed(by: disposeBag)
        
        arManager.playerPlacedItem.subscribe(onNext: { [weak self] (item) in
            guard let self = self else { return }
            self.playerStateMessage.onNext(PlayerMessage(type: .playerFinishedTurn, payload: PlayerFinishedTurnMessagePayload(player: self.player!, fromCoordinate: item.0, toCoordinate: item.1, item: self.myStashedItems[0])))
        }).disposed(by: disposeBag)
    }
    
    func handle(message: ServerMessage) {
        switch message.type {
        case .initiated:
            guard let payload = message.payload as? InitiatedServerMessagePayload else { return }
            handleInitiatedState(payload: payload)
        case .gameConfig:
            guard let payload = message.payload as? GameConfigServerPayload else { return }
            self.handleUpdateGameConfig(payload: payload)
        case .playerTurn:
            guard let payload = message.payload as? PlayerTurnServerPayload else { return }
            self.handlePlayerTurn(payload: payload)
        case .playerWon:
            guard let payload = message.payload as? PlayerWonServerPayload else { return }
            self.handlePlayerWon(payload: payload)
        default:
            break
        }
    }
}

extension GameCoordinator {
    func handleInitiatedState(payload: InitiatedServerMessagePayload) {
        self.player = payload.player
        self.player?.playerName = "Vitalii"
        self.arManager.arViewInitialized.distinctUntilChanged().filter({ $0 }).subscribe { [weak self] (event) in
            guard let self = self else { return }
            self.playerStateMessage.onNext(PlayerMessage(type: .initiated, payload: InitiatedPlayerMessagePayload(player: self.player!)))
        }.disposed(by: disposeBag)
    }
}

extension GameCoordinator {
    func handleUpdateGameConfig(payload: GameConfigServerPayload) {
        self.map = payload.map
        self.stashedItems = payload.stashedItems
        self.arManager.updateGameConfig(player: self.player!, map: self.map, stashedItems: self.stashedItems)
    }
}

extension GameCoordinator {
    func handlePlayerTurn(payload: PlayerTurnServerPayload) {
        if payload.isPlayerTurn {
            self.currentServerPayload = payload
            let availableToMove: [Coordinate] = Array((payload.availableToMove ?? [:]).keys)
            self.arManager.updatePlayerTurn(availableToMove:availableToMove)
        }
        else {
            self.arManager.updateWaitingState()
        }
    }
}
extension GameCoordinator {
    func handlePlayerWon(payload: PlayerWonServerPayload) {
        self.gameEnded.onNext(())
        self.arManager.updateFinishState(isWon: payload.winner == self.player!)
    }
}
