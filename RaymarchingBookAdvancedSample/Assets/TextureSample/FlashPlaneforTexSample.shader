﻿Shader "Butadiene/FlashPlaneforTexSample"
{
	Properties
	{

	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"


			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

		

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv =v.uv;
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target
			{
				float t = _Time.y*1.0;
				float r = 1.2*abs(sin(t))-0.2;
				fixed4 col =saturate(float4(r,r,r,1));

				return col;
			}
			ENDCG
		}
	}
}
