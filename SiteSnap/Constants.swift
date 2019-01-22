//
//  Constants.swift
//  SiteSnap
//
//  Created by Paul Oprea on 14/01/2019.
//  Copyright © 2019 Paul Oprea. All rights reserved.
//

import Foundation
import AWSCognitoIdentityProvider

let CognitoIdentityUserPoolRegion: AWSRegionType = AWSRegionType.APSoutheast2//.EUCentral1
let CognitoIdentityUserPoolId = "ap-southeast-2_6J5KCh9Ln"//"eu-central-1_1xg72Xc1Q" //
let CognitoIdentityUserPoolAppClientId = "5532ehhq7ubloviarashnvu76o"//"1b4jcf8hspoag9isgl0kbq6jq3"//
let CognitoIdentityUserPoolAppClientSecret = "161ouv23clckdhmgimeioudqsnt22rnq732cls881a8dc26p3j2u"

let AWSCognitoUserPoolsSignInProviderKey = "UserPool"

let siteSnapBackendHost: String = "https://backend.sitesnap.com.au:443/api/"

/*
 LIST OF UserDefaults used in app
    email - current email for logged user
    token - last token obtained from Amazon Cognito
    given_name - first name for logged user
    family_name - last name for logged user
    currentProjectId - the id of the project that the user chooses
    currentProjectName - the name of the project that the user chooses
    deviceId - deviceId used like parameter in uploading process
    saveToGallery - settings
    debugMode - settings
 */
