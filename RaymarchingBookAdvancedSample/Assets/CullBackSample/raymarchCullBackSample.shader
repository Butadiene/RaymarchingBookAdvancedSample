Shader "Butadiene/raymarchCullBackSample"
{
	
		SubShader
	{
		Tags { "RenderType" = "Opaque"  "LightMode" = "ForwardBase" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
	
			float sphere(float3 p) //球の距離関数
			{
				return length(p) - 0.5;
			}

			float dist(float3 p) {//最終的な距離関数
				return sphere(p);
			}

			float3 getnormal(float3 p)//法線を導出する関数
			{
				float d = 0.0001;
				return normalize(float3(
					dist(p + float3(d, 0.0, 0.0)) - dist(p + float3(-d, 0.0, 0.0)),
					dist(p + float3(0.0, d, 0.0)) - dist(p + float3(0.0, -d, 0.0)),
					dist(p + float3(0.0, 0.0, d)) - dist(p + float3(0.0, 0.0, -d))
				));
			}


			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float3 pos : TEXCOORD1;
				float4 vertex : SV_POSITION;
			};



			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.pos = v.vertex.xyz;//メッシュのローカル座標を代入
				o.uv = v.uv;
				return o;
			}



			fixed4 frag(v2f i) : SV_Target
			{
				//以下、ローカル座標で話が進む
				float3 ro = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1)).xyz;//レイのスタート位置をカメラのローカル座標とする
				float3 rd = normalize(i.pos.xyz - ro);//メッシュのローカル座標の、視点のローカル座標からの方向を求めることでレイの方向を定義
				ro = i.pos;//ここでレイの出発点をメッシュ表面にする
				float d =0;
				float t=0;
				float3 p = float3(0, 0, 0);
				for (int i = 0; i < 60; ++i) { //レイマーチングのループを実行
					p = ro + rd * t;
					d = dist(p);
					t += d;
				}
				p = ro + rd * t;
				float4 col = float4(0,0,0,1);
				if (d > 0.01) { //レイが衝突していないと判断すれば描画しない
					discard;
				}
				else {
					float3 normal = getnormal(p);
					float3 lightdir = normalize(mul(unity_WorldToObject, _WorldSpaceLightPos0).xyz);//ローカル座標で計算しているので、ディレクショナルライトの角度もローカル座標にする
					float NdotL = max(0, dot(normal, lightdir));//ランバート反射を計算
					col = float4(float3(1, 1, 1) * NdotL, 1);//描画
				}
				return col;

			}
			ENDCG
		}

	}
}