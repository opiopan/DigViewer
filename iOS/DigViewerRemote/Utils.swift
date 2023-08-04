//
//  Utils.swift
//  DigViewerRemote
//
//  Created by Hiroshi Murayama on 2023/08/04.
//  Copyright © 2023 Hiroshi Murayama <opiopan@gmail.com>. All rights reserved.
//

import Foundation

func DVRKeyWindow() -> UIWindow? {
    let scenes = UIApplication.shared.connectedScenes
    let windowScene = scenes.first as? UIWindowScene
    return windowScene?.windows.first
}
