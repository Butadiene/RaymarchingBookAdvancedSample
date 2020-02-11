//スライダーの位置を示すためのShader
Shader "ButadieneSlidersystem/targetposition"
{
	
	Properties
	{
		_Index("index X(from0to63)",float)=0//このスライダーのIDを指定できるようにする
		_Indey("index Y(from0to13)",float)=0
		_range("range",float)=0.075
	}


	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue" = "Overlay" }
		LOD 100

		Pass
		{
			Ztest always

			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog

			
			uniform float4 _ppos;
			uniform float _Index;
			uniform float _Indey;
			uniform float _range;
			sampler2D _PTex;

			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float2 uv1 : TEXCOORD1;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			
			};

			
			
			float3 pack(float3 xyz, uint ix) {//float3で受け取った値をfixed4として返す関数
					uint3 xyzI = asuint(xyz);
					xyzI = (xyzI >> (ix * 8)) % 256;
					return (float3(xyzI) + 0.5) / 255.0;
			}

						


			v2f vert (appdata v)
			{
				v2f o;
				o.uv = v.uv * float2(4/256.,1/32.0) + float2(4*_Index/256.,(31-_Indey)/32.0);//指定されたIDを受けて、スクリーンスペース上で表示する位置を決めます
				o.vertex = float4(o.uv.x*2-1,1-o.uv.y*2,0,1);
				float orth  = UNITY_MATRIX_P[3][3];
				if(orth == 0){
				 o.vertex=float4 (0,0,0,1);//これによって平行投影のカメラにのみ写るようになります。
				}
				o.uv1 = v.uv;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
					 		 
				float4 objPos = mul ( unity_ObjectToWorld, float4(0,0,0,1) );								
				float xmod = 4*i.uv1.x-frac(4*i.uv1.x);
				float4 retcol= float4 (pack(objPos.xyz/_range, xmod),1);//float3をpack関数によってfixed4にして色として書き込み
								
				return retcol;
			}
			ENDCG
		}
	}
}
