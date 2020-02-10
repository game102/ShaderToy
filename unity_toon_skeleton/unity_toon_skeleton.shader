Shader "Custom/unity_toon_skeleton"
{

    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _MainTex("Main Texture", 2D) = "white" {}
        // Ambient light is applied uniformly to all surfaces on the object.
        [HDR]
        _AmbientColor("Ambient Color", Color) = (0.4,0.4,0.4,1)
        [HDR]
        _SpecularColor("Specular Color", Color) = (0.9,0.9,0.9,1)
        // Controls the size of the specular reflection.
        _Glossiness("Glossiness", Float) = 32
        [HDR]
        _RimColor("Rim Color", Color) = (1,1,1,1)
        _RimAmount("Rim Amount", Range(0, 1)) = 0.716
        // Control how smoothly the rim blends when approaching unlit
        // parts of the surface.
        _RimThreshold("Rim Threshold", Range(0, 1)) = 0.1       
    }

    SubShader  //告诉Unity的渲染引擎,希望何时怎样及渲染这个对象
    {
        Pass
        {
            Tags  
            {
                "LightMode" = "ForwardBase"
                "PassFlags" = "OnlyDirectional"
                "RenderType" = "Opaque"
            }

            CGPROGRAM
            #pragma vertex vert   //预处理指令，表明一个以vert为名字的函数的顶点程序。
            #pragma fragment frag
            // Compile multiple versions of this shader depending on lighting settings.
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            // Files below include macros and functions to assist
            // with lighting and shadows. Include directional Light in the scene
            #include "Lighting.cginc"
            #include "AutoLight.cginc"            

            struct appdata
            {
                float4 vertex : POSITION;               
                float4 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;  //输出语义
                float3 worldNormal : NORMAL;
                float2 uv : TEXCOORD0;
                float3 viewDir : TEXCOORD1; 
                // Macro found in Autolight.cginc. Declares a vector4
                // into the TEXCOORD2 semantic with varying precision 
                // depending on platform target.
                SHADOW_COORDS(2)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);     
                o.viewDir = WorldSpaceViewDir(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                // Defined in Autolight.cginc. Assigns the above shadow coordinate
                // by transforming the vertex from world space to shadow-map space.
                TRANSFER_SHADOW(o)
                return o;
            }
            
            float4 _Color;
            float4 _AmbientColor;
            float4 _SpecularColor;
            float _Glossiness;      
            float4 _RimColor;
            float _RimAmount;
            float _RimThreshold;    

            float4 frag (v2f i) : SV_Target
            {
                float3 normal = normalize(i.worldNormal);
                float NdotL = dot(_WorldSpaceLightPos0, normal);     
                float shadow = SHADOW_ATTENUATION(i);
                //This has rendered out a realistic style of illumination. 
                //To modify it to be toon-like
                //we will divide the lighting into two bands: light and dark. 
                //float lightIntensity = NdotL > 0 ? 1 : 0;    
                //This makes it ideal for smoothly blending values
                float lightIntensity = smoothstep(0, 0.02, NdotL * shadow); 
                float4 light = lightIntensity * _LightColor0;  //_LightColor0 the color of the main directional light


                //Specular reflection    
                //The half vector is a vector between the viewing direction and the light source; we can obtain this by summing those two vectors and normalizing the result.
                float3 viewDir = normalize(i.viewDir);

                float3 halfVector = normalize(_WorldSpaceLightPos0 + viewDir);
                float NdotH = dot(normal, halfVector);
                //We multiply NdotH by lightIntensity to ensure that the reflection is only drawn when the surface is lit. 
                //_Glossiness is multiplied by itself to allow smaller values in the material editor to have a larger effect.
                float specularIntensity = pow(NdotH * lightIntensity, _Glossiness * _Glossiness);
                
                //Lower0.005return 0  Upper0.01return 1
                float specularIntensitySmooth = smoothstep(0.005, 0.01, specularIntensity); 
                float4 specular = specularIntensitySmooth * _SpecularColor;

                float4 rimDot = 1 - dot(viewDir, normal);                    
                //float rimIntensity = smoothstep(_RimAmount - 0.01, _RimAmount + 0.01, rimDot);
                float rimIntensity = rimDot * pow(NdotL, _RimThreshold);
                rimIntensity = smoothstep(_RimAmount - 0.01, _RimAmount + 0.01, rimIntensity);

                float4 rim = rimIntensity * _RimColor;                

                float4 sample = tex2D(_MainTex, i.uv);
                //return _Color * sample * NdotL;
                //return _Color * sample * (_AmbientColor + light);  
                return _Color * sample * (_AmbientColor + rim + specular + light);                
            }
            ENDCG
        }


        // Shadow casting support.
        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"        
    }
    FallBack "Diffuse"
}
