//Markerの姿勢を色表示して伝えるShader
Shader "Butadiene/Marker"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_num("CubeNumber",float) = 1
	}
		SubShader
		{
			Tags { "RenderType" = "Transparent" "Queue" = "Overlay" }
			LOD 100

			Pass
			{
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				// make fog work
				#pragma multi_compile_fog

				#include "UnityCG.cginc"

				uniform float _num;

			float3 pack(float3 xyz, uint ix) {//float3で受け取った値をfixed4として返す関数
				uint3 xyzI = asuint(xyz);
				xyzI = (xyzI >> (ix * 8)) % 256;
				return (float3(xyzI)+0.5) / 255.0;
			}


			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			v2f vert(appdata v)
			{
				v2f o;
				float2 pos;
				pos = v.uv*float2(0.5,1)+0.5*float2(_num-1,0);//_numに1が入ってるときはスクリーンの左半分、2が入ってるときはスクリーンの右半分に表示する
				o.vertex = float4(pos.x * 2 - 1, 1 - pos.y * 2, 0, 1);
				float orth = UNITY_MATRIX_P[3][3];
				if (orth == 0) {
					o.vertex = float4 (0, 0, 0, 1);//これによって平行投影のカメラにのみ写るようになります。
				}
				o.uv = v.uv;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float4 objPos = mul(unity_ObjectToWorld, float4(0,0,0,1));
				float xmod = 4 * i.uv.x - frac(4 * i.uv.x);
				float ymod = 4 * i.uv.y - frac(4 * i.uv.y);
				//unity_ObjectToWorldのうち、(0,0,0,1)だとわかっているunity_ObjectToWorld[3]を除いて色として書き込み。
				//一列にfixed4(floar3をパックしたもの)を書き込めるのでそれをY方向に4列並べている
				float3 input = float3(unity_ObjectToWorld[0][0], unity_ObjectToWorld[1][0], unity_ObjectToWorld[2][0])*(ymod==0)
							 + float3(unity_ObjectToWorld[0][1], unity_ObjectToWorld[1][1], unity_ObjectToWorld[2][1])* (ymod == 1)
							 + float3(unity_ObjectToWorld[0][2], unity_ObjectToWorld[1][2], unity_ObjectToWorld[2][2])* (ymod == 2)
							 + float3(unity_ObjectToWorld[0][3], unity_ObjectToWorld[1][3], unity_ObjectToWorld[2][3])* (ymod == 3);
				float4 retcol = float4 (pack(input, xmod),1);//書き込み

				return retcol;
			}
			ENDCG
		}
	}
}
