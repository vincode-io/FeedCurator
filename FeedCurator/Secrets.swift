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
		static let githubId = "624fb6e8b44d770e4fe5"
		static let githubSecret = "d15c30bc8bc71beefe167dd1b52c70583ea6c1e5"
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
