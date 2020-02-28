Shader "Butadiene/VisualizingSample2"
{
	Properties
	{

	}
		SubShader
	{
		Tags { "RenderType" = "TransparentCutout" "Queue" = "AlphaTest" }
		LOD 100

		Cull Front

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag


			#include "UnityCG.cginc"
			uniform float _rot1;
			uniform float _rot2;

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
			float rand(float2 co) {//乱数の作成
				return frac(sin(dot(co.xy, float2(12.9898, 78.233))) * 43758.5453);
			}

			float noise(float2 st) {//ノイズの作成
				float2 i = floor(st);
				float2 f = frac(st);

				float a = rand(i);
				float b = rand(i + float2(1.0, 0.0));
				float c = rand(i + float2(0.0, 1.0));
				float d = rand(i + float2(1.0, 1.0));


				float2 u = f * f * (3.0 - 2.0 * f);

				return lerp(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
			}

			float dist(float3 p) {//最終的な距離関数
				float k = 0.9;
				float3 sxyz = floor((p.xyz - 0.5 * k) / k) * k;
				float sz = rand(sxyz.xz);
				float t = _Time.y*0.05;
				p.xy = rot(p.xy, t*sign(sz-0.5) * (sz * 0.5 + 0.7));
				p.z += t*sign(sz - 0.5)*(sz*0.5+0.7);
				p = abs(fmod(p, k)) - 0.5*k;
				float s = 7;
				p *= s;
				p.yz = rot(p.yz, 0.76);//45度傾ける
				[unroll]//IFS
				for (int i = 0; i < 4; i++) {
					p = abs(p) - 0.4+(0.25+0.1*sz)*sin(t*(0.5+sz));
					p.xy = rot(p.xy, t*(0.7+sz));
					p.yz = rot(p.yz, 1.3*t+sz);
				}
				
				float d1 = closs(p,float3(0.06,0.06,0.06));
				
				return d1/s;
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
				float3 vn = clamp(dot(-view, normal),0.0,1.0);
				float3 ld = normalize(float3(-1,0.9*sin(_Time.y*0.5)-0.1,0));//光の方向を仮定
				float NdotL = max(dot(ld, normal), 0.0);
				float3 R = normalize(-ld + NdotL * normal * 2.0);
				float spec = pow(max(dot(-view, R), 0.0), 20.0) * saturate(sign(NdotL));
				float3 col = float3(1, 1, 1) * (pow(vn,4.0)*0.9 +spec * 0.3);
				float  k = 0.5;
				float ks = 0.9;
				float2 sxz = floor((p.xz - 0.5 * ks) / ks) * ks;
				float sx = rand(sxz);
				float sy = rand(sxz+100.1);
				float emissive = saturate(0.001/abs((abs(fmod(abs(p.y*sx+p.x*sy)+_Time.y*sign(sx-0.5)*0.4, k)) - 0.5 * k)));
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
			};



			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.pos = v.vertex;
				o.uv = v.uv;

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float3 ro = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1)).xyz;//レイのスタート地点を設定
				float3 rd = normalize(i.pos.xyz - mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1)).xyz);//レイの方向を計算

				float d = 0;
				float t = 0.01;
				float far = 14.;
				float near = t;
				float hit = 0.0001;
				[unroll]
				for (int i = 0; i < 60; ++i) { //レイマーチングを行う
					d = dist(ro + rd * t);
					t += d;
					if (hit>d) break;
				}
				
				
				float3 bcol = float3(0.1, 0.1, 0.8);//背景の色の設定
				float3 col = light(ro + rd * t, rd);//ライティングを計算

				


				col = lerp(bcol, col, clamp((far - t) / (far - near), 0.0, 1.0));//フォグの計算

				return float4(pow(col,2.2),1.0);
			}
			ENDCG
		}
	}
}
