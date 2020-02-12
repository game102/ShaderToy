Shader "Custom/flowing_river" {
    Properties {
        _Color ("Base Color", Color) = (1,1,1,1)

        [Header(Spec Layer 1)]
        _Specs1 ("Specs", 2D) = "white" {}
        _SpecColor1 ("Spec Color", Color) = (1,1,1,1)
        _SpecDirection1 ("Spec Direction", Vector) = (0, 1, 0, 0)

        [Header(Spec Layer 2)]
        _Specs2 ("Specs", 2D) = "white" {}
        _SpecColor2 ("Spec Color", Color) = (1,1,1,1)
        _SpecDirection2 ("Spec Direction", Vector) = (0, 1, 0, 0)

        [Header(Foam)]
        _FoamNoise("Foam Noise", 2D) = "white" {}
        _FoamDirection ("Foam Direction", Vector) = (0, 1, 0, 0)
        _FoamColor ("Foam Color", Color) = (1,1,1,1)
        _FoamAmount ("Foam Amount", Range(0, 2)) = 1
    }
    SubShader {
        //
        Tags { "RenderType"="Transparent" "Queue"="Transparent" "ForceNoShadowCasting"="True"}
        //Level of details
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types, then set it to render transparent
        //this is a surface shader  编译指令 https://gameinstitute.qq.com/community/detail/121998
        #pragma surface surf Standard vertex:vert fullforwardshadows alpha
        //Use of more modern GPI functionality,use higher shader compilation targets.
        #pragma target 4.0

        struct Input {
            float2 uv_Specs1;
            float2 uv_Specs2;
            float2 uv_FoamNoise;
            float eyeDepth;
            //Screenspace Coordinates in Surface Shaders just adding a variable called screenPos 
            //to the surface input struct will make unity generate code that fills it with the correct data.            
            float4 screenPos; 
        };

        //Then we get the depth behind the surface by reading from the depth texture. So we add a new texture 
        //variable called _CameraDepthTexture. By adding it to our shader it will be automatically assigned. 
        //To read from it we have to get the screen coordinates, luckily we can get them easily by adding a 
        //variable called screenPos to our input struct.
        sampler2D_float _CameraDepthTexture;

        fixed4 _Color;

        sampler2D _Specs1;
        fixed4 _SpecColor1;
        float2 _SpecDirection1;

        sampler2D _Specs2;
        fixed4 _SpecColor2;
        float2 _SpecDirection2;

        sampler2D _FoamNoise;
        fixed4 _FoamColor;
        float _FoamAmount;
        float2 _FoamDirection;  //只用到向量的前两个值

        void vert (inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input, o);
            //computes eye space depth of the vertex and outputs it in o. 
            //Use it in a vertex program when not rendering into a depth texture
            COMPUTE_EYEDEPTH(o.eyeDepth);
        }

        void surf (Input IN, inout SurfaceOutputStandard o) 
        {
            //set river base color
            fixed4 col = _Color;
            //add first layer of moving specs
            float2 specCoordinates1 = IN.uv_Specs1 + _SpecDirection1 * _Time.y;  //Scrolling UVs  _Time.y:Time since level load (t/20, t, t*2, t*3)
            fixed4 specLayer1 = tex2D(_Specs1, specCoordinates1) * _SpecColor1;
            col.rgb = lerp(col.rgb, specLayer1.rgb, specLayer1.a);
            col.a = lerp(col.a, 1, specLayer1.a);


            //add second layer of moving specs
            float2 specCoordinates2 = IN.uv_Specs2 + _SpecDirection2 * _Time.y;
            fixed4 specLayer2 = tex2D(_Specs2, specCoordinates2) * _SpecColor2;
            col.rgb = lerp(col.rgb, specLayer2.rgb, specLayer2.a);  //Multiple scrolling textures
            col.a = lerp(col.a, 1, specLayer2.a);                   //Multiple scrolling textures


            //In the surface function we can then get the projection coordinate by passing the screenPos to 
            //the UNITY_PROJ_COORD macro. With it we can sample the depth texture by passing the depth texture
            //as well as the projection coordinates to the SAMPLE_DEPTH_TEXTURE_PROJ macro to get the raw depth. 
            //The last step to get the scene depth from that is to simply pass it to the LinearEyeDepth function.
            float4 projCoords = UNITY_PROJ_COORD(IN.screenPos);  ////处理平台差异，一般直接返回输入的值
            float rawZ = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, projCoords); //1深度纹理  2由顶点着色器输出插值而得到的屏幕坐标
            float sceneZ = LinearEyeDepth(rawZ);  //given high precision value from depth texture i, returns corresponding eye space depth.
            float surfaceZ = IN.eyeDepth;

            float2 foamCoords = IN.uv_FoamNoise + _FoamDirection * _Time.y;
            float foamNoise = tex2D(_FoamNoise, foamCoords).r;
            float foam = 1 - ((sceneZ - surfaceZ) / _FoamAmount);
            foam = saturate(foam - foamNoise);  //saturate:规范到0~1之间时

            col.rgb = lerp(col.rgb, _FoamColor.rgb, foam);
            col.a = lerp(col.a, 1, foam * _FoamColor.a);

            o.Albedo = col.rgb;
            o.Alpha = col.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}