//
//  Secrets.swift
//  Freetime
//
//  Created by Sherlock, James on 23/11/2017.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//
// This file taken from GitHawk.  -Mo

import Foundation

enum Secrets {
	
	enum Release {
		static let githubId = "{GITHUBID}"
		static let githubSecret = "{GITHUBSECRET}"
	}
	
	enum GitHub {
		static let clientId = Secrets.environmentVariable(named: "GITHUB_CLIENT_ID") ?? Release.githubId
		static let clientSecret = Secrets.environmentVariable(named: "GITHUB_CLIENT_SECRET") ?? Release.githubSecret
	}
	
	fileprivate static func environmentVariable(named: String) -> String? {
		let processInfo = ProcessInfo.processInfo
		guard let value = processInfo.environment[named] else {
			print("‼️ Missing Environment Variable: '\(named)'")
			return nil
		}
		return value
	}
	
}
