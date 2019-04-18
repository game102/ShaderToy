# Sadertoy fantasy shaders

One Paragraph of project description goes here

## Getting Started

![image](https://github.com/game102/ShaderToy/blob/master/Cheat.png)

### Prerequisites

Content from https://www.patreon.com/TheArtOfCode

```
replace vec3 float3 
replace vec2 float2
replace vec4 float4
replace frac fract
replace mix lerp

replace atan atan2
replace texture(  atan2(

float3 lineCol = float3(1.1);   float3 lineCol = 1; 

frac(float3(p)  frac(p

frac(float2(p)  frac(p

replace mat3 float3x3

mod function
#define mod(x, y)(x-y*floor(x/y))

replace iTime _Time.y

replace float4(0.)   (0.)


p *= leftRight;   p = mul(leftRight, p)


删除fixed4 frag (v2f i) : SV_Target

void mainImage( out float4 fragColor, in float2 fragCoord )
替换成
fixed4 frag (v2f i) : SV_Target

float2 UV = (fragCoord.xy / iResolution.xy)-.5;
替换成
float2 UV = i.uv - .5;

删除 uv.y *= iResolution.y/iResolution.x;

float2 m = iMouse.xy/iResolution.xy;
替换成
float2 m = 0；

float3 pos = float3(0., camY, camDist)*RotY(turn);
替换成
float3 pos = mul(RotY(turn) ,float3(0., camY, camDist))


fragColor = float4(col, .1);
替换成
return float4(col, .1);


全局变量加static
const float twopi
static const float twopi
```

### Prerequisites

What things you need to install the software and how to install them

```
Give examples
```
