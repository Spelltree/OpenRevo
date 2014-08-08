/* Code provided by Chris Morris of Six Times Nothing (http://www.sixtimesnothing.com) */
/* Free to use and modify  */

/* Modified to fit with 6 Texture Layers
/* No Fallback right now for 4 Texture Layers on Old GPU's

Shader "Hidden/TerrainEngine/Splatmap/Lightmap-FirstPass" {
Properties {
	_Control ("Control (RGBA)", 2D) = "red" {}
	_Splat5 ("Layer 5 (A)", 2D) = "white" {}
	_Splat4 ("Layer 4 (A)", 2D) = "white" {}
	_Splat3 ("Layer 3 (A)", 2D) = "white" {}
	_Splat2 ("Layer 2 (B)", 2D) = "white" {}
	_Splat1 ("Layer 1 (G)", 2D) = "white" {}
	_Splat0 ("Layer 0 (R)", 2D) = "white" {}
	// used in fallback on old cards
	_MainTex ("BaseMap (RGB)", 2D) = "white" {}
	_Color ("Main Color", Color) = (1,1,1,1)
	
	_SpecColor ("Specular Color", Color) = (0, 0, 0, 0)
}

SubShader {
	Tags {
		"SplatCount" = "4"
		"Queue" = "Geometry-100"
		"RenderType" = "Opaque"
	}
CGPROGRAM
#pragma surface surf BlinnPhong vertex:vert
#pragma target 3.0
#include "UnityCG.cginc"

struct Input {
	float3 worldPos;
	float2 uv_Control : TEXCOORD0;
	float2 uv_Splat0 : TEXCOORD1;
	float2 uv_Splat1 : TEXCOORD2;
	float2 uv_Splat2 : TEXCOORD3;
	float2 uv_Splat3 : TEXCOORD4;
	float2 uv_Splat4 : TEXCOORD5;
	float2 uv_Splat5 : TEXCOORD6;
};

// Supply the shader with tangents for the terrain
void vert (inout appdata_full v) {

	// A general tangent estimation	
	float3 T1 = float3(1, 0, 1);
	float3 Bi = cross(T1, v.normal);
	float3 newTangent = cross(v.normal, Bi);
	
	normalize(newTangent);

	v.tangent.xyz = newTangent.xyz;
	
	if (dot(cross(v.normal,newTangent),Bi) < 0)
		v.tangent.w = -1.0f;
	else
		v.tangent.w = 1.0f;
}

sampler2D _Control;
sampler2D _BumpMap0, _BumpMap1, _BumpMap2, _BumpMap3,_BumpMap4,_BumpMap5;
sampler2D _Splat0,_Splat1,_Splat2,_Splat3,_Splat4,_Splat5;
float _Spec0, _Spec1, _Spec2, _Spec3,_Spec4,_Spec5, _Tile0, _Tile1, _Tile2, _Tile3,_Tile4,_Tile5, _TerrainX, _TerrainZ;
float4 _v4CameraPos;

void surf (Input IN, inout SurfaceOutput o) {

	half4 splat_control = tex2D (_Control, IN.uv_Control);	
	half3 col;
	
	// 4 splats, normals, and specular settings
	col  = splat_control.r * tex2D (_Splat0, IN.uv_Splat0).rgb/1.13;
	o.Normal = splat_control.r * UnpackNormal(tex2D(_BumpMap0, float2(IN.uv_Control.x * (_TerrainX/_Tile0), IN.uv_Control.y * (_TerrainZ/_Tile0))));
	o.Gloss = _Spec0 * splat_control.r;
	o.Specular = _Spec0 * splat_control.r;

	col += splat_control.g * tex2D (_Splat1, IN.uv_Splat1).rgb/1.13;
	o.Normal += splat_control.g * UnpackNormal(tex2D(_BumpMap1, float2(IN.uv_Control.x * (_TerrainX/_Tile1), IN.uv_Control.y * (_TerrainZ/_Tile1))));
	o.Gloss += _Spec1 * splat_control.g;
	o.Specular += _Spec1 * splat_control.g;
	
	col += splat_control.b * tex2D (_Splat2, IN.uv_Splat2).rgb/1.13;
	o.Normal += splat_control.b * UnpackNormal(tex2D(_BumpMap2, float2(IN.uv_Control.x * (_TerrainX/_Tile2), IN.uv_Control.y * (_TerrainZ/_Tile2))));
	o.Gloss += _Spec2 * splat_control.b;
	o.Specular +=_Spec2 * splat_control.b;
	
	col += splat_control.a * tex2D (_Splat3, IN.uv_Splat3).rgb/1.13;
	o.Normal += splat_control.a * UnpackNormal(tex2D(_BumpMap3, float2(IN.uv_Control.x * (_TerrainX/_Tile3), IN.uv_Control.y * (_TerrainZ/_Tile3))))/3;
	o.Gloss += _Spec3 * splat_control.a;
	o.Specular += _Spec3 * splat_control.a;
	
	col += splat_control.a * tex2D (_Splat4, IN.uv_Splat4).rgb/6.33;
	o.Normal += splat_control.a * UnpackNormal(tex2D(_BumpMap4, float2(IN.uv_Control.x * (_TerrainX/_Tile4), IN.uv_Control.y * (_TerrainZ/_Tile4)))) /4;
	o.Gloss += _Spec4 * splat_control.a;
	o.Specular += _Spec4 * splat_control.a;
	
	col += splat_control.a * tex2D (_Splat5, IN.uv_Splat5).rgb/6.33;
	o.Normal += splat_control.a * UnpackNormal(tex2D(_BumpMap5, float2(IN.uv_Control.x * (_TerrainX/_Tile5), IN.uv_Control.y * (_TerrainZ/_Tile5)))) /5;
	o.Gloss += _Spec5 * splat_control.a;
	o.Specular += _Spec5 * splat_control.a;
	
	o.Albedo = col;
	o.Alpha = 0.0;
}
ENDCG  
}

// Fallback to Diffuse
Fallback "Diffuse"
}
