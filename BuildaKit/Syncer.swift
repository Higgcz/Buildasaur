//
//  Syncer.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 14/02/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaGitServer
import BuildaUtils
import XcodeServerSDK

public protocol SyncerDelegate: class {
    
    func syncerBecameActive(syncer: Syncer)
    func syncerStopped(syncer: Syncer)
    func syncerDidStartSyncing(syncer: Syncer)
    func syncerDidFinishSyncing(syncer: Syncer)
    func syncerEncounteredError(syncer: Syncer, error: NSError)
}

@objc public class Syncer: NSObject {
    
    public weak var delegate: SyncerDelegate?
    
    //public
    public internal(set) var reports: [String: String] = [:]
    public private(set) var lastSuccessfulSyncFinishedDate: NSDate?
    public private(set) var lastSyncFinishedDate: NSDate?
    public private(set) var lastSyncStartDate: NSDate?
    public private(set) var lastSyncError: NSError?
    
    private var currentSyncError: NSError?
    
    /// How often, in seconds, the syncer should pull data from both sources and resolve pending actions
    public let syncInterval: NSTimeInterval
    
    private var isSyncing: Bool {
        didSet {
            if !oldValue && self.isSyncing {
                self.lastSyncStartDate = NSDate()
                self.delegate?.syncerDidStartSyncing(self)
            } else if oldValue && !self.isSyncing {
                self.lastSyncFinishedDate = NSDate()
                self.delegate?.syncerDidFinishSyncing(self)
            }
        }
    }
    
    public var active: Bool {
        didSet {
            if active && !oldValue {
                let s = Selector("_sync")
                let timer = NSTimer(timeInterval: self.syncInterval, target: self, selector: s, userInfo: nil, repeats: true)
                self.timer = timer
                NSRunLoop.mainRunLoop().addTimer(timer, forMode: kCFRunLoopCommonModes as String)
                self._sync() //call for the first time, next one will be called by the timer
                self.delegate?.syncerBecameActive(self)
            } else if !active && oldValue {
                self.timer?.invalidate()
                self.timer = nil
                self.delegate?.syncerStopped(self)
            }
        }
    }

    //private
    var timer: NSTimer?

    //---------------------------------------------------------
    
    public init(syncInterval: NSTimeInterval) {
        self.syncInterval = syncInterval
        self.active = false
        self.isSyncing = false
    }
    
    func _sync() {
        
        //this shouldn't even be getting called now
        if !self.active {
            self.timer?.invalidate()
            self.timer = nil
            return
        }

        if self.isSyncing {
            //already is syncing, wait till it's finished
            Log.info("Trying to sync again even though the previous sync hasn't finished. You might want to consider making the sync interval longer. Just sayin'")
            return
        }
        
        Log.untouched("\n------------------------------------\n")
        
        self.isSyncing = true
        self.currentSyncError = nil
        self.reports.removeAll(keepCapacity: true)
        
        let start = NSDate()
        Log.info("Sync starting at \(start)")
        
        self.sync { () -> () in
            
            let end = NSDate()
            let finishState: String
            if let error = self.currentSyncError {
                finishState = "with error"
                self.lastSyncError = error
            } else {
                finishState = "successfully"
                self.lastSyncError = nil
                self.lastSuccessfulSyncFinishedDate = NSDate()
            }
            Log.info("Sync finished \(finishState) at \(end), took \(end.timeIntervalSinceDate(start).clipTo(3)) seconds.")
            self.isSyncing = false
        }
    }
    
    func notifyErrorString(errorString: String, context: String?) {
        self.notifyError(Error.withInfo(errorString), context: context)
    }
    
    func notifyError(error: NSError?, context: String?) {
        
        var message = "Syncing encountered a problem. "
        
        if let error = error {
            message += "Error: \(error.localizedDescription). "
        }
        if let context = context {
            message += "Context: \(context)"
        }
        Log.error(message)
        self.currentSyncError = error
        self.delegate?.syncerEncounteredError(self, error: Error.withInfo(message))
    }
    
    /**
    To be overriden by subclasses to do their logic in
    */
    public func sync(completion: () -> ()) {
        //sync logic here
        assertionFailure("Should be overriden by subclasses")
    }
}
