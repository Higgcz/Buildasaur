//
//  WorkspaceMetadata.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 29/09/2015.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils

public enum CheckoutType: String {
    case SSH = "SSH"
    //        case HTTPS - not yet supported, right now only SSH is supported
    //        (for bots reasons, will be built in when I have time)
    //        case SVN - not yet supported yet
}

public struct WorkspaceMetadata {
    
    public let projectName: String
    public let projectPath: String
    public let projectWCCIdentifier: String
    public let projectWCCName: String
    public let projectURL: NSURL
    public let checkoutType: CheckoutType
    
    init(projectName: String?, projectPath: String?, projectWCCIdentifier: String?, projectWCCName: String?, projectURLString: String?) throws {
        
        let errorForMissingKey: (String) -> ErrorType = { Error.withInfo("Can't find/parse \"\($0)\" in workspace metadata!") }
        guard let projectName = projectName else { throw errorForMissingKey("Project Name") }
        guard let projectPath = projectPath else { throw errorForMissingKey("Project Path") }
        guard let projectWCCIdentifier = projectWCCIdentifier else { throw errorForMissingKey("Project WCC Identifier") }
        guard let projectWCCName = projectWCCName else { throw errorForMissingKey("Project WCC Name") }
        guard let projectURLString = projectURLString else { throw errorForMissingKey("Project URL") }
        guard let checkoutType = WorkspaceMetadata.parseCheckoutType(projectURLString) else {
            let allowedString = [CheckoutType.SSH].map({ $0.rawValue }).joinWithSeparator(", ")
            let error = Error.withInfo("Disallowed checkout type, the project must be checked out over one of the supported schemes: \(allowedString)")
            throw error
        }
        
        //we have to prefix SSH urls with "git@" (for a reason I don't remember)
        var correctedProjectUrlString = projectURLString
        if case .SSH = checkoutType where !projectURLString.hasPrefix("git@") {
            correctedProjectUrlString = "git@" + projectURLString
        }
        
        guard let projectURL = NSURL(string: correctedProjectUrlString) else { throw Error.withInfo("Can't parse url \"\(projectURLString)\"") }
        
        self.projectName = projectName
        self.projectPath = projectPath
        self.projectWCCIdentifier = projectWCCIdentifier
        self.projectWCCName = projectWCCName
        self.projectURL = projectURL
        self.checkoutType = checkoutType
    }
    
    func duplicateWithForkURL(forkUrlString: String?) throws -> WorkspaceMetadata {
        return try WorkspaceMetadata(projectName: self.projectName, projectPath: self.projectPath, projectWCCIdentifier: self.projectWCCIdentifier, projectWCCName: self.projectWCCName, projectURLString: forkUrlString)
    }
}

extension WorkspaceMetadata {
    
    internal static func parseCheckoutType(projectURLString: String) -> CheckoutType? {
        
        let urlString = projectURLString
        let scheme = NSURL(string: projectURLString)!.scheme
        switch scheme {
        case "github.com":
            return CheckoutType.SSH
        case "https":
            
            if urlString.hasSuffix(".git") {
                //HTTPS git
            } else {
                //SVN
            }
            
            Log.error("HTTPS or SVN not yet supported, please create an issue on GitHub if you want it added (czechboy0/Buildasaur)")
            return nil
        default:
            return nil
        }
    }
}
