//
//  Mocks.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 17/05/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils
import BuildaGitServer
import Buildasaur
import XcodeServerSDK
import BuildaKit

class MockXcodeServer: XcodeServer {
    init() {
        let config = try! XcodeServerConfig(host: "", user: "", password: "")
        super.init(config: config, endpoints: XcodeServerEndpoints(serverConfig: config))
    }
}

class MockGitHubServer: GitHubServer {
    init() {
        super.init(endpoints: GitHubEndpoints(baseURL: "", token: ""))
    }
}

class MockProject: Project {
    override init() {
        super.init()
    }
    required init?(json: NSDictionary) { fatalError("init(json:) has not been implemented") }
}

class MockRepo: Repo {
    
    class func mockDictionary() -> NSDictionary {
        return [
            "name": "TestRepo",
            "full_name": "me/TestRepo",
            "ssh_url": "git@github.com:me/TestRepo.git",
            "clone_url": "https://github.com/me/TestRepo.git",
        ]
    }
    
    convenience init() {
        self.init(json: MockRepo.mockDictionary())
    }
    
    required init(json: NSDictionary) {
        super.init(json: json)
    }
}

class MockBranch: Branch {
    
    class func mockDictionary(name: String = "master", sha: String = "1234f") -> NSDictionary {
        return [
            "name": name,
            "commit": [
                "sha": sha
            ]
        ]
    }
    
    convenience init(name: String = "master", sha: String = "1234f") {
        self.init(json: MockBranch.mockDictionary(name, sha: sha))
    }
    
    required init(json: NSDictionary) {
        super.init(json: json)
    }
}

class MockPullRequestBranch: PullRequestBranch {
    
    class func mockDictionary(ref: String = "mock_ref", sha: String = "1234f") -> NSDictionary {
        return [
            "ref": ref,
            "sha": sha,
            "repo": MockRepo.mockDictionary()
        ]
    }
    
    convenience init() {
        self.init(json: MockPullRequestBranch.mockDictionary())
    }
    
    required init(json: NSDictionary) {
        super.init(json: json)
    }
}

class MockIssue: Issue {
    
    class func mockDictionary(number: Int = 1, body: String = "body", title: String = "title") -> NSDictionary {
        return [
            "number": number,
            "body": body,
            "title": title
        ]
    }
    
    convenience init() {
        self.init(json: MockIssue.mockDictionary())
    }
    
    required init(json: NSDictionary) {
        super.init(json: json)
    }
}

class MockPullRequest: PullRequest {
    
    class func mockDictionary(number: Int, title: String, head: NSDictionary, base: NSDictionary) -> NSDictionary {
        let dict = MockIssue.mockDictionary(number, body: "body", title: title).mutableCopy() as! NSMutableDictionary
        dict["head"] = head
        dict["base"] = base
        return dict.copy() as! NSDictionary
    }
    
    class func mockDictionary(number: Int, title: String) -> NSDictionary {
        
        let head = MockPullRequestBranch.mockDictionary("head", sha: "head_sha")
        let base = MockPullRequestBranch.mockDictionary("base", sha: "base_sha")
        return self.mockDictionary(number, title: title, head: head, base: base)
    }
    
    convenience init(number: Int = 1, title: String = "PR title") {
        self.init(json: MockPullRequest.mockDictionary(number, title: title))
    }

    required init(json: NSDictionary) {
        super.init(json: json)
    }
}

class MockSourceControlBlueprint: SourceControlBlueprint {
    
    init() {
        super.init(branch: "branch", projectWCCIdentifier: "wcc_id", wCCName: "wcc_name", projectName: "project_name", projectURL: "project_url", projectPath: "project_path", publicSSHKey: "SSH public", privateSSHKey: "SSH private", sshPassphrase: "SSH passphrase")
    }

    required init(json: NSDictionary) {
        super.init(json: json)
    }
}

class MockBotConfiguration: BotConfiguration {
    
    init() {
        super.init(
            builtFromClean: BotConfiguration.CleaningPolicy.Never,
            analyze: true,
            test: true,
            archive: true,
            schemeName: "scheme",
            schedule: BotSchedule.manualBotSchedule(),
            triggers: [],
            deviceSpecification: DeviceSpecification(testingDeviceIDs: []),
            sourceControlBlueprint: MockSourceControlBlueprint())
    }

    required init(json: NSDictionary) {
        super.init(json: json)
    }
}

class MockBot: Bot {
    
    init(name: String) {
        super.init(name: name, configuration: MockBotConfiguration())
    }

    required init(json: NSDictionary) {
        super.init(json: json)
    }
}

class MockIntegration: Integration {
    
    init(number: Int = 1, step: Step = Step.Completed, sha: String = "head_sha", result: Result = Result.Succeeded) {
        
        let dict = MockHelpers.loadSampleIntegration()
        dict["currentStep"] = step.rawValue
        dict["number"] = number
        dict["result"] = result.rawValue
        let d1 = dict["revisionBlueprint"] as! NSMutableDictionary
        let d2 = d1["DVTSourceControlWorkspaceBlueprintLocationsKey"] as! NSMutableDictionary
        let d3 = d2["CEE8472CC4AB69CD27173B930EB93B6B4AA4BAFC"] as! NSMutableDictionary
        d3["DVTSourceControlLocationRevisionKey"] = sha
        super.init(json: dict)
    }

    required init(json: NSDictionary) {
        super.init(json: json)
    }
}




