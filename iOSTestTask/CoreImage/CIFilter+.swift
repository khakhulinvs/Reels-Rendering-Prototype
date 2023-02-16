//
//  CIFilter+.swift
//  Env
//
//  Created by Viacheslav Khakhulin on 21.08.2022.
//  Copyright © 2022 Hazor Games. All rights reserved.
//

import CoreImage

extension CIFilter {
    static func rgbToHsvSource() -> String {
        return
"""
        // All components are in the range [0…1], including hue.
        vec3 rgbToHsv(vec3 c)
        {
            vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
            vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
            vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

            float d = q.x - min(q.w, q.y);
            float e = 1.0e-10;
            return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
        }
"""
    }
    
    static func hsvToRgbSource() -> String {
        return
"""
        // All components are in the range [0…1], including hue.
        vec3 hsvToRgb(vec3 c)
        {
            vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
            vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
            return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
        }
"""
    }

    static func rgbToYCbCrSource() -> String {
        return
"""
    // All components are in the range [0…1], including hue.
    vec3 rgbToYCbCr(vec3 c)
    {
        float y = 0.299 * c.r + 0.587 * c.g + 0.114 * c.b;
        float cb = 0.5 + -0.168736 * c.r - 0.331264 * c.g + 0.5 * c.b;
        float cr = 0.5 + 0.5 * c.r - 0.418688 * c.g - 0.081312 * c.b;
        return vec3(y, cb, cr);
    }
 """
    }

    static func rgbToCbCrSource() -> String {
        return
"""
    // All components are in the range [0…1], including hue.
    vec2 rgbToCbCr(vec3 c)
    {
        float cb = 0.5 + -0.168736 * c.r - 0.331264 * c.g + 0.5 * c.b;
        float cr = 0.5 + 0.5 * c.r - 0.418688 * c.g - 0.081312 * c.b;
        return vec2(cb, cr);
    }
 """
    }

}
