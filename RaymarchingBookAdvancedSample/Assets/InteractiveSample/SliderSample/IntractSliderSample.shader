Shader "Butadiene/IntractSliderSample"
{
	Properties
	{
		_RTex("Render Texture", 2D) = "white" {}

	}
		SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 100

		Cull Front

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			uniform float _slider1;//読み取ったスライダーの値を格納するための変数
			uniform float _slider2;//読み取ったスライダーの値を格納するための変数

			sampler2D _RTex;

			float4 unpack(float2 index) {//スライダーによって書き込まれたfixed4にpackされた値（色として読み込んだ）をfloat3にunpackする関数

				float2 uv = float2 ((index.x * 2 + 1) / 128, ((31 - index.y) * 2 + 1) / 64);
				float3 e = float3(1.0 / 512, 3.0 / 512, 0);
				uint3 v0 = uint3(tex2Dlod(_RTex, float4(uv - e.yz, 0, 0)).xyz * 255.) << 0;
				uint3 v1 = uint3(tex2Dlod(_RTex, float4(uv - e.xz, 0, 0)).xyz * 255.) << 8;
				uint3 v2 = uint3(tex2Dlod(_RTex, float4(uv + e.xz, 0, 0)).xyz * 255.) << 16;
				uint3 v3 = uint3(tex2Dlod(_RTex, float4(uv + e.yz, 0, 0)).xyz * 255.) << 24;
				uint3 v = v0 + v1 + v2 + v3;
				return float4(asfloat(v), 1);
			}

			float4 unpackf(float2 index) {
				return unpack(index) - unpack(float2(index.x, index.y + 14));
			}

			float2 rot(float2 p,float r) {//回転のための関数
				float2x2 m = float2x2(cos(r),sin(r),-sin(r),cos(r));
				return mul(m,p);
			}

			float cube(float3 p,float3 s) {//キューブを作る関数
				float3 q = abs(p);
				float3 m = max(s - q,0.0);
				return length(max(q - s,0.0)) - min(min(m.x,m.y),m.z);
			}


			float hasira(float3 p,float3 s) {//柱を作る関数
				float2 q = abs(p.xy);
				float2 m = max(s.xy - q.xy,float2(0.0,0.0));
				return length(max(q.xy - s.xy,0.0)) - min(m.x,m.y);
			}

			float closs(float3 p,float3 s) {//柱が三本垂直に交差した十字架っぽいオブジェクトを作る関数
				float d1 = hasira(p,s);
				float d2 = hasira(p.yzx,s.yzx);
				float d3 = hasira(p.zxy,s.zxy);
				return min(min(d1,d2),d3);
			}

			float2 getSliderValue(){
				_slider1 = unpackf(float2(0, 0)).y;//レンダーテクスチャーからID(0,0)のスライダーの値を読み込む(今回はSlider1)
				_slider2 = unpackf(float2(1, 0)).y;//レンダーテクスチャーからID(1,0)のスライダーの値を読み込む(今回はSlider2)
				return float2(_slider1, _slider2);
			}


			float dist(float3 p) {//最終的な距離関数
				//IFSで十字架みたいなやつをぐちゃぐちゃにする感じのやつの形状を作ります。
				
				float rot1 = _slider1;
				float rot2 = _slider2;
				float d2 = cube(p, float3(0.5, 0.5, 0.5));
				
				float s = 7;
				p *= s;
				p.yz = rot(p.yz, 0.76);//45度傾ける
				[unroll]//IFS
				for (int i = 0; i < 4; i++) {
					p = abs(p) - 0.4;
					p.xy = rot(p.xy, rot1*3.14+1);
					p.yz = rot(p.yz, rot2*3.14+1);
				}
				
				float d1 = closs(p,float3(0.06,0.06,0.06));//十字架の距離関数を作る

				return max(d1/s,d2);
			}

			float3 gn(float3 p) {//法線の取得

				const float h = 0.001;
				const float2 k = float2(1, -1);
				return normalize(k.xyy * dist(p + k.xyy * h) +
					k.yyx * dist(p + k.yyx * h) +
					k.yxy * dist(p + k.yxy * h) +
					k.xxx * dist(p + k.xxx * h));

			}
			float3 light(float3 p,float3 view) {//ライティング
				float3 normal = gn(p);//法線の取得
				float3 ld = normalize(float3(cos(_Time.y*3.0),sin(_Time.y*2.7),sin(_Time.y*0.1)));//光の方向を仮定
				float NdotL = max(dot(ld, normal), 0.0);//ランバート反射の計算
				float3 R = normalize(-ld + NdotL * normal * 2.0);//反射光の計算
				float spec = pow(max(dot(-view, R), 0.0), 20.0) * saturate(sign(NdotL));//フォン鏡面反射の計算
				float3 col = float3(1, 1, 1) * (NdotL + spec);
				float  k = 0.5;
				float emissive = saturate(0.001/abs((abs(fmod(abs(p.y+p.x)+_Time.y, k)) - 0.5 * k)));//エミッションを加える
 				return clamp(col * float3(0.3,0.5,0.9)*0.7 +emissive*float3(0.2,0.2,1.0),0.0,1.0);
			}



			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float3 pos: TEXCOORD1;
				float4 vertex : SV_POSITION;
				float2 slide : TEXCOORD2;
			};

			struct pout
			{
				fixed4 color : SV_Target;
				float depth : SV_Depth;
			};


			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.pos = v.vertex;
				o.uv = v.uv;
				o.slide = getSliderValue();//テクスチャを読み込む処理は重たいので、頂点Shaderで全部読み込んでしまう。
				return o;
			}

			pout frag(v2f i)
			{
				_slider1 = i.slide.x;//頂点Shaderで読み込んだスライダーの値をフラグメントShaderに受け渡し
				_slider2 = i.slide.y;//頂点Shaderで読み込んだスライダーの値をフラグメントShaderに受け渡し
				float3 ro = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1)).xyz;//レイのスタート地点を設定
				float3 rd = normalize(i.pos.xyz - ro).xyz;//レイの方向を計算

				float d = 0;
				float t = 0.001;
				float far = 10.;
				float near = 0.001;

				[unroll]
				for (int i = 0; i < 32; ++i) { //レイマーチングを行う
					d = dist(ro + rd * t);
					t += d;
					if (t > far||near>d) break;
				}
				float3 col = float3(0, 0, 0);
				if (t > far) {
					discard;
				}
				else {
					col = light(ro + rd * t, rd);//ライティングを計算
				}
				
				col = clamp(col, 0.0, 1.0);

				pout o;

				o.color = float4(col, 1.0);

				float4 projectionPos = UnityObjectToClipPos(float4(ro+rd*t, 1.0));
				o.depth = projectionPos.z / projectionPos.w;//デプスの書き込み

				return o;
			}
			ENDCG
		}
	}
}
