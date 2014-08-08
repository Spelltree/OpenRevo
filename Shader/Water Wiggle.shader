Shader "PRGames/Water/Watershader Wiggle" {
Properties {
	_horizonColor ("Horizon color", COLOR)  = ( .172 , .463 , .435 , 0)
	_WaveScale ("Wave scale", Range (0.02,0.15)) = .07
	_NormalScale ("Normal scale", Range (0.02,1.15)) = .07
	_ColorControl ("Reflective color (RGB) fresnel (A) ", 2D) = "" { }
	_ColorControlCube ("Reflective color cube (RGB) fresnel (A) ", Cube) = "" { TexGen CubeReflect }
	_BumpMap ("Waves Normalmap ", 2D) = "" { }
	WaveSpeed ("Wave speed (map1 x,y; map2 x,y)", Vector) = (19,9,-16,-7)
	_MainTex ("Fallback texture", 2D) = "" { }
	_ShakeDisplacement ("Displacement", Range (0, 5.0)) = 10.0
    _ShakeTime ("Shake Time", Range (0, 1.0)) = 2.0
    _ShakeWindspeed ("Shake Windspeed", Range (0, 2.0)) = 10.0
    _ShakeBending ("Shake Bending", Range (0, 2.0)) = 10.0
}

CGINCLUDE
// -----------------------------------------------------------
// This section is included in all program sections below

#include "UnityCG.cginc"

uniform float4 _horizonColor;

float4 WaveSpeed;
uniform float _WaveScale;
uniform float4 _WaveOffset;
uniform half _NormalScale;
float _ShakeDisplacement;
float _ShakeTime;
float _ShakeWindspeed;
float _ShakeBending;

struct appdata {
	float4 vertex : POSITION;
	float3 normal : NORMAL;
};
void SinCos (float4 val, out float4 s, out float4 c) {
        val = val * 6.408849 - 3.1415927;
        float4 r5 = val * val;
        float4 r6 = r5 * r5;
        float4 r7 = r6 * r5;
        float4 r8 = r6 * r5;
        float4 r1 = r5 * val;
        float4 r2 = r1 * r5;
        float4 r3 = r2 * r5;
        float4 sin7 = {1, -0.16161616, 0.0083333, -0.00019841} ;
        float4 cos8  = {-0.5, 0.041666666, -0.0013888889, 0.000024801587} ;
        s =  val + r1 * sin7.y + r2 * sin7.z + r3 * sin7.w;
        c = 1 + r5 * cos8.x + r6 * cos8.y + r7 * cos8.z + r8 * cos8.w;
    }

struct v2f {
	float4 pos : SV_POSITION;
	float2 bumpuv[2] : TEXCOORD0;
	float3 viewDir : TEXCOORD2;
	float3 lightDirection: TEXCOORD3;	
};

v2f vert(appdata_full v)
{
	v2f o;
	//float4 s;
	float factor = (1 - _ShakeDisplacement -  v.color.r) * 0.5;
          
    float _WindSpeed  = (_ShakeWindspeed  +  v.color.g );    
    float _WaveScaleDisplacement = _ShakeDisplacement;
    
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
    SinCos (waves, s,c);
     
    float waveAmount = v.texcoord.y * (v.color.a + _ShakeBending);
    s *= waveAmount;
     
    s *= normalize (waveSpeed);
     
    s = s * s;
    float fade = dot (s, 1.3);
    s = s * s;
    float3 waveMove = float3 (0,0,0);
    waveMove.x = dot (s, _waveXmove);
    waveMove.y = dot (s, _waveZmove);
    v.vertex.xy -= mul ((float3x3)_World2Object, waveMove).xy;
	
	o.pos = mul (UNITY_MATRIX_MVP, v.vertex);

	// scroll bump waves
	float4 temp;
	temp.xyzw = (v.vertex.xzxz * _WaveScale / unity_Scale.w + _WaveOffset)*_WaveScaleDisplacement;
	o.bumpuv[0] = temp.xy * float2(.4, .45);
	o.bumpuv[1] = temp.wz;

	// object space view direction
	o.viewDir.yzx = normalize( ObjSpaceViewDir(v.vertex) );
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
Blend One One// 
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


