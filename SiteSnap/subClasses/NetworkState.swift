//
//  NetworkState.swift
//  SiteSnap
//
//  Created by Paul Oprea on 10/05/2019.
//  Copyright © 2019 Paul Oprea. All rights reserved.
//

import Foundation
import Alamofire

class NetworkState {
    class func isConnected() ->Bool {
        return NetworkReachabilityManager()!.isReachable
    }
    
}
