//
//  Shaders.metal
//

// File for Metal kernel and shader functions

#include <metal_stdlib>
#include <simd/simd.h>

// Including header shared between this Metal shader code and Swift/C code executing Metal API commands
#import "ShaderTypes.h"

using namespace metal;

typedef struct
{
    float3 position [[attribute(VertexAttributePosition)]];
    float2 texCoord [[attribute(VertexAttributeTexcoord)]];
} Vertex;

typedef struct
{
    float4 position [[position]];
    float2 texCoord;
} ColorInOut;

// Adjusted function to handle homogeneous coordinates
float4 invertPosition(float4 position, float3 center, float radius) {
    float3 positionRelativeToCenter = position.xyz - center;
    float3 invertedPosition = center + (radius * radius) / dot(positionRelativeToCenter, positionRelativeToCenter) * positionRelativeToCenter;
    return float4(invertedPosition, position.w); // Preserve the original w component
}
vertex ColorInOut vertexShader(Vertex in [[stage_in]],
                               ushort amp_id [[amplification_id]],
                               constant UniformsArray & uniformsArray [[ buffer(BufferIndexUniforms) ]])
{
    ColorInOut out;

    Uniforms uniforms = uniformsArray.uniforms[amp_id];

    float4 position = float4(in.position, 1.0);

    // Hardcoded sphere center and radius for testing
    float3 center = float3(1.0, 1.0, 1.0); // Example center
    float radius = 5.5; // Example radius

    // Call the new function to invert the position
    float4 invertedPosition = invertPosition(position, center, radius);

    // Use the inverted position for transformation
    position = invertPosition(invertedPosition,center,radius);
    position = invertPosition(position,center,radius);
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;
    
    out.texCoord = in.texCoord;

    return out;
}

fragment float4 fragmentShader(ColorInOut in [[stage_in]],
                               texture2d<half> colorMap     [[ texture(TextureIndexColor) ]])
{
    constexpr sampler colorSampler(mip_filter::linear,
                                   mag_filter::linear,
                                   min_filter::linear);

    half4 colorSample   = colorMap.sample(colorSampler, in.texCoord.xy);

    return float4(colorSample);
}
