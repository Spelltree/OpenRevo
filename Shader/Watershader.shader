Shader "PRGames/Water/Watershader" {
Properties {
	_horizonColor ("Horizon color", COLOR)  = ( .172 , .463 , .435 , 0)
	_WaveScale ("Wave scale", Range (0.02,0.15)) = .07
	_NormalScale ("Normal scale", Range (0.02,1.15)) = .07
	_ColorControl ("Reflective color (RGB) fresnel (A) ", 2D) = "" { }
	_ColorControlCube ("Reflective color cube (RGB) fresnel (A) ", Cube) = "" { TexGen CubeReflect }
	_BumpMap ("Waves Normalmap ", 2D) = "" { }
	WaveSpeed ("Wave speed (map1 x,y; map2 x,y)", Vector) = (19,9,-16,-7)
	_MainTex ("Fallback texture", 2D) = "" { }
}

CGINCLUDE
// -----------------------------------------------------------
// This section is included in all program sections below

#include "UnityCG.cginc"

uniform float4 _horizonColor;

uniform float4 WaveSpeed;
uniform float _WaveScale;
uniform float4 _WaveOffset;
uniform half _NormalScale;
struct appdata {
	float4 vertex : POSITION;
	float3 normal : NORMAL;
};

struct v2f {
	float4 pos : SV_POSITION;
	float2 bumpuv[2] : TEXCOORD0;
	float3 viewDir : TEXCOORD2;
	float3 lightDirection: TEXCOORD3;
};

v2f vert(appdata v)
{
	v2f o;
	float4 s;

	o.pos = mul (UNITY_MATRIX_MVP, v.vertex);

	// scroll bump waves
	float4 temp;
	temp.xyzw = v.vertex.xzxz * _WaveScale / unity_Scale.w + _WaveOffset;
	o.bumpuv[0] = temp.xy * float2(.4, .45);
	o.bumpuv[1] = temp.wz;

	// object space view direction
	o.viewDir.xzy = normalize( ObjSpaceViewDir(v.vertex) );
 	o.lightDirection = ObjSpaceLightDir(v.vertex);
	return o;
}

ENDCG
	
// -----------------------------------------------------------
// Fragment program

Subshader {
	Tags { "RenderType"="Transparent" }
	Pass {

Lighting On
ZTest Less
ZWrite Off
Cull Off
Blend One One//DstAlpha 
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma fragmentoption ARB_precision_hint_fastest 
#pragma fragmentoption ARB_fog_exp2
#pragma target 3.0
#include "Lighting.cginc"
sampler2D _BumpMap;
sampler2D _ColorControl;
sampler2D _MainTex;
half4 frag( v2f i ) : COLOR
{
	half3 bump1 = UnpackNormal(tex2D( _BumpMap, i.bumpuv[0] ));
	half3 bump2 = UnpackNormal(tex2D( _BumpMap, i.bumpuv[1] ));
	half3 bump = (bump1 + bump2) * 0.5;
	
	half fresnel = dot( i.viewDir, bump );
	half4 water = tex2D( _ColorControl, float2(fresnel,fresnel) );
	half4 watertex = tex2D( _MainTex,float2(fresnel,fresnel) );
	half4 col;
	
	
	float3 lightColor = UNITY_LIGHTMODEL_AMBIENT.xyz;
           	float lengthSq = dot(i.lightDirection, i.lightDirection);
		   	float atten = 1 / (1.0 + lengthSq); 
			float diff = saturate (dot (bump1, (i.lightDirection)));
			diff += lerp(bump1,bump2,1.0);
			//diff = UnpackNormal(diff);
	col.rgb = lerp (watertex.rgb, water.rgb,watertex.a);
	col.rgb = lerp (col.rgb, _horizonColor.rgb,_horizonColor.a);
	 float2 offset = ParallaxOffset (diff, _NormalScale, i.lightDirection);
            i.bumpuv[0] += offset;  
           //Angle to the light				   
				lightColor += ((_LightColor0.rgb) * (diff * atten) ); 
	col.rgb = (lightColor * col.rgb )*( _NormalScale*11);//(1+opaque);  
	
	col.a = _horizonColor.a;
	return col;
}
ENDCG
	}
}
//col.rgb = lerp( water.rgb, _horizonColor.rgb, water.a );
// -----------------------------------------------------------
//  Old cards

// three texture, cubemaps
Subshader {
	Tags { "RenderType"="Transparent" }
	Pass {
		Color (0.5,0.5,0.5,0.0)
		SetTexture [_MainTex] {
			Matrix [_WaveMatrix]
			combine texture * primary
		}
		SetTexture [_MainTex] {
			Matrix [_WaveMatrix2]
			combine texture * primary + previous
		}
		SetTexture [_ColorControlCube] {
			combine texture +- previous, primary
			Matrix [_Reflection]
		}
	}
}

// dual texture, cubemaps
Subshader {
	Tags { "RenderType"="Transparent" }
	Pass {
		Color (0.5,0.5,0.5,0)
		SetTexture [_MainTex] {
			Matrix [_WaveMatrix]
			combine texture
		}
		SetTexture [_ColorControlCube] {
			combine texture +- previous, primary
			Matrix [_Reflection]
		}
	}
}

// single texture
Subshader {
	Tags { "RenderType"="Transparent" }
	Pass {
		Color (0.5,0.5,0.5,0)
		SetTexture [_MainTex] {
			Matrix [_WaveMatrix]
			combine texture, primary
		}
	}
}

}

