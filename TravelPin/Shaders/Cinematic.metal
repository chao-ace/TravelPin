#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// [[ stitchable ]] attribute for SwiftUI ShaderLibrary
[[ stitchable ]]
half4 filmGrain(float2 position, half4 color, float time, float amount) {
    // Standard pseudo-random noise logic
    float grain = fract(sin(dot(position + time, float2(12.9898, 78.233))) * 43758.5453);
    
    // Apply noise intensity (typically subtle, around 0.05)
    float noise = (grain - 0.5) * amount;
    
    return half4(color.rgb + half3(noise), color.a);
}

[[ stitchable ]]
half4 warmFilm(float2 position, half4 color, float warmth) {
    // Warm Film Grade: Enhance Red/Yellow in midtones
    // warmth: 0.0 to 1.0 (recommended 0.1 - 0.2)
    half3 warmShift = half3(1.05, 1.0, 0.95); // Slightly more red, slightly less blue
    half3 shifted = color.rgb * mix(half3(1.0), warmShift, (half)warmth);
    
    return half4(shifted, color.a);
}
