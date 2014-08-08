Shader "PRGames/Nature/Leaves Wiggle" {
Properties {
	_Color ("Main Color", Color) = (1,1,1,1)
	_TranslucencyColor ("Translucency Color", Color) = (0.73,0.85,0.41,1) // (187,219,106,255)
	_Cutoff ("Alpha cutoff", Range(0,1)) = 0.3
	_TranslucencyViewDependency ("View dependency", Range(0,1)) = 0.7
	_ShadowStrength("Shadow Strength", Range(0,1)) = 1.0
	
	_MainTex ("Base (RGB) Alpha (A)", 2D) = "white" {}
	
	_ShakeDisplacement ("Displacement", Range (0, 1.0)) = 1.0
    _ShakeTime ("Shake Time", Range (0, 1.0)) = 1.0
    _ShakeWindspeed ("Shake Windspeed", Range (0, 1.0)) = 1.0
    _ShakeBending ("Shake Bending", Range (0, 0.25)) = 0.05
	
	// These are here only to provide default values
	_Scale ("Scale", Vector) = (1,1,1,1)
	_SquashAmount ("Squash", Float) = 1
}

SubShader { 
	Tags {
		"Queue"="AlphaTest"
		"IgnoreProjector"="True"
		"RenderType" = "TreeLeaf"
	}
	LOD 200
		
	Pass {
		Tags { "LightMode" = "ForwardBase" }
		Name "ForwardBase"
	Cull Off
	CGPROGRAM
		#include "TreeVertexLit.cginc"

		#pragma vertex VertexLeaf
		#pragma fragment FragmentLeaf
		#pragma exclude_renderers flash
		#pragma multi_compile_fwdbase nolightmap
		
		sampler2D _MainTex;
		float4 _MainTex_ST;
		float _ShakeDisplacement;
    	float _ShakeTime;
    	float _ShakeWindspeed;
    	float _ShakeBending;
		fixed _Cutoff;
		sampler2D _ShadowMapTexture;
		
    	
		struct v2f_leaf {
			float4 pos : SV_POSITION;
			fixed4 diffuse : COLOR0;
		#if defined(SHADOWS_SCREEN)
			fixed4 mainLight : COLOR1;
		#endif
			float2 uv : TEXCOORD0;
		#if defined(SHADOWS_SCREEN)
			float4 screenPos : TEXCOORD1;
		#endif
		};
		
		
		
		v2f_leaf VertexLeaf (appdata_full v)
		{
			
			float factor = (1 - _ShakeDisplacement -  v.color.r) * 0.5;
			float _WindSpeed  = (_ShakeWindspeed  +  v.color.g );    
        	float _WaveScale = _ShakeDisplacement;
        	float4 _waveXSize = float4(0.048, 0.06, 0.24, 0.096);
        	float4 _waveZSize = float4 (0.024, .08, 0.08, 0.2);
        	float4 waveSpeed = float4 (1.2, 2, 1.6, 4.8);
     
       		float4 _waveXmove = float4(0.024, 0.04, -0.12, 0.096);
        	float4 _waveZmove = float4 (0.006, .02, -0.02, 0.1);
        	float4 waves;
	        waves = v.vertex.x * _waveXSize;
	        waves += v.vertex.z * _waveZSize;
	     
	        waves += _Time.x * (1 - _ShakeTime * 2 - v.color.b ) * waveSpeed *_WindSpeed;
	     
	        float4 s, c;
	        waves = frac (waves);
	        // From Wiggle Shader
	        FastSinCos (waves, s,c);
	     
	        float waveAmount = v.texcoord.y * (v.color.a + _ShakeBending);
	        s *= waveAmount;
	     
	        s *= normalize (waveSpeed);
	     
	        s = s * s;
	        float fade = dot (s, 1.3);
	        s = s * s;
	        float3 waveMove = float3 (0,0,0);
	        waveMove.x = dot (s, _waveXmove);
	        waveMove.z = dot (s, _waveZmove);
	        v.vertex.xz -= mul ((float3x3)_World2Object, waveMove).xz;
	        
			v2f_leaf o;
			TreeVertLeaf(v);
			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			
        
			fixed ao = v.color.a;
			ao += 0.1; ao = saturate(ao * ao * ao); // emphasize AO
						
			fixed3 color = v.color.rgb * _Color.rgb * ao;
			
			float3 worldN = mul ((float3x3)_Object2World, SCALED_NORMAL);

			fixed4 mainLight;
			mainLight.rgb = ShadeTranslucentMainLight (v.vertex, worldN) * color;
			mainLight.a = v.color.a;
			o.diffuse.rgb = ShadeTranslucentLights (v.vertex, worldN) * color;
			o.diffuse.a = 1;
		#if defined(SHADOWS_SCREEN)
			o.mainLight = mainLight;
			o.screenPos = ComputeScreenPos (o.pos);
		#else
			o.diffuse *= 0.5;
			o.diffuse += mainLight;
		#endif			
			o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
			return o;
		}

		fixed4 FragmentLeaf (v2f_leaf IN) : COLOR
		{
			fixed4 albedo = tex2D(_MainTex, IN.uv);
			fixed alpha = albedo.a;
			clip (alpha - _Cutoff);

		#if defined(SHADOWS_SCREEN)
			half4 light = IN.mainLight;
			half atten = tex2Dproj(_ShadowMapTexture, UNITY_PROJ_COORD(IN.screenPos)).r;
			light.rgb *= lerp(2, 2*atten, _ShadowStrength);
			light.rgb += IN.diffuse.rgb;
		#else
			half4 light = IN.diffuse;
			light.rgb *= 2.0;
		#endif

			return fixed4 (albedo.rgb * light, 0.0);
		}
		
		
	ENDCG
	}
}

Dependency "OptimizedShader" = "Hidden/Nature/Tree Creator Leaves Fast Optimized"
Fallback "Transparent/Cutout/VertexLit"
}
