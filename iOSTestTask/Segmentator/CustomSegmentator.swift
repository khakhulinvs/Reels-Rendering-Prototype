//
//  CustomSegmentator.swift
//  Env
//
//  Created by Viacheslav Khakhulin on 09.07.2022.
//  Copyright © 2022 Hazor Games. All rights reserved.
//

import CoreML

@available(iOS 11.0, *)
class CustomSegmentator: BaseSegmentator {
    // We make model static cos recreation may cause memory leaks
    private static let model = try? segmentation_8bit(configuration: MLModelConfiguration()).model
        
    init() {
        guard let model = CustomSegmentator.model else {
            fatalError()
        }

        super.init(model: model)
    }
}
