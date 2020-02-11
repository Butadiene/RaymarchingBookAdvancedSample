Shader "Butadiene/DentSample"
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

			uniform float3x3 _rotMat1; //Markerで読み取った回転情報を格納するための行列
			uniform float3 _trans1;//Markerで読み取った移動情報を格納するためのベクトル
			uniform float3x3 _rotMat2; //Markerで読み取った回転情報を格納するための行列
			uniform float3 _trans2; // Markerで読み取った移動情報を格納するためのベクトル
			sampler2D _RTex;

			float3 unpack(float2 uv) {//Markerによって書き込まれたfixed4にpackされた値（色として読み込んだ）をfloat3にunpackする関数
				float texWidth = 8.0;
				float3 e = float3(1.0 / texWidth / 2, 3.0 / texWidth / 2, 0);
				uint3 v0 = uint3(tex2Dlod(_RTex, float4(uv - e.yz, 0, 0)).xyz * 255.) << 0;
				uint3 v1 = uint3(tex2Dlod(_RTex, float4(uv - e.xz, 0, 0)).xyz * 255.) << 8;
				uint3 v2 = uint3(tex2Dlod(_RTex, float4(uv + e.xz, 0, 0)).xyz * 255.) << 16;
				uint3 v3 = uint3(tex2Dlod(_RTex, float4(uv + e.yz, 0, 0)).xyz * 255.) << 24;
				uint3 v = v0 + v1 + v2 + v3;
				return float4(asfloat(v), 1);
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

			float smoothMin(float d1, float d2, float k) {
				float h = exp(-k * d1) + exp(-k * d2);
				return -log(h) / k;
			}
			float dist(float3 p) {//最終的な距離関数

				float3 p1 = mul(_rotMat1,p);//Markerで読み取った回転情報を適用
				p1 -= _trans1;//Markerで読み取った移動情報を適用
				float d1 = cube(p1, float3(0.1, 0.1, 0.1));

				float3 p2 = mul(_rotMat2, p);//Markerで読み取った回転情報を適用
				p2 -= _trans2;//Markerで読み取った移動情報を適用
				float d2 = cube(p2, float3(0.13, 0.16, 0.05));

				float d3 = cube(p - float3(0,0.5,0),float3(1.2,0.1,1.2));

				return max(-smoothMin(d1, d2,10),d3);
			}

			float3 gn(float3 p) {//法線の取得

				const float h = 0.001;
				const float2 k = float2(1, -1);
				return normalize(k.xyy * dist(p + k.xyy * h) +
					k.yyx * dist(p + k.yyx * h) +
					k.yxy * dist(p + k.yxy * h) +
					k.xxx * dist(p + k.xxx * h));

			}
			float3 light(float3 p, float3 view) {//ライティング
				float3 normal = gn(p);//法線の取得
				float3 ld = normalize(float3(1.0, 0.2, 0.2));//光の方向を仮定
				float NdotL = max(dot(ld, normal), 0.0);//ランバート反射の計算
				float3 R = normalize(-ld + NdotL * normal * 2.0);//反射光の計算
				float spec = pow(max(dot(-view, R), 0.0), 20.0) * saturate(sign(NdotL));//フォン鏡面反射の計算
				float3 col = float3(1, 1, 1) * (NdotL + spec);
				return clamp(col * float3(0.3, 0.5, 0.9) + 0.01, 0.0, 1.0);
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
				float4 mat1_1 : TEXCOORD2;
				float4 mat1_2 : TEXCOORD3;
				float4 mat1_3 : TEXCOORD4;
				float4 mat2_1 : TEXCOORD5;
				float4 mat2_2 : TEXCOORD6;
				float4 mat2_3 : TEXCOORD7;
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
				o.pos = mul(unity_ObjectToWorld, v.vertex);
				o.uv = v.uv;
				//レンダーテクスチャーから一つ目のオブジェクトのワールド変換行列を読み取る
				//テクスチャの読み取りは重いので、頂点Shaderで行う
				float3 value1 = unpack(float2(0.25, 0.125));
				float3 value2 = unpack(float2(0.25, 0.375));
				float3 value3 = unpack(float2(0.25, 0.625));
				float3 value4 = unpack(float2(0.25, 0.875));
				//分割してフラグメントShaderに渡す
				o.mat1_1 = float4(value1.x, value2.x, value3.x, value4.x);
				o.mat1_2 = float4(value1.y, value2.y, value3.y, value4.y);
				o.mat1_3 = float4(value1.z, value2.z, value3.z, value4.z);

				//レンダーテクスチャーから二つ目のオブジェクトのワールド変換行列を読み取る
				//テクスチャの読み取りは重いので、頂点Shaderで行う
				value1 = unpack(float2(0.75, 0.125));
				value2 = unpack(float2(0.75, 0.375));
				value3 = unpack(float2(0.75, 0.625));
				value4 = unpack(float2(0.75, 0.875));
				//分割してフラグメントShaderに渡す
				o.mat2_1 = float4(value1.x, value2.x, value3.x, value4.x);
				o.mat2_2 = float4(value1.y, value2.y, value3.y, value4.y);
				o.mat2_3 = float4(value1.z, value2.z, value3.z, value4.z);
				return o;
			}

			pout frag(v2f i)
			{
				//頂点Shaderから送られてきたワールド変換行列の情報から回転行列を作成し、レイマーチングで使える形にする
				_rotMat1 = float3x3(i.mat1_1.xyz, i.mat1_2.xyz, i.mat1_3.xyz);
				_rotMat1 = transpose(_rotMat1);
				//頂点Shaderから送られてきたワールド変換行列の情報から移動量を示すベクトルを作成し、レイマーチングで使える形にする
				_trans1 = mul(_rotMat1, float3(i.mat1_1.w, i.mat1_2.w, i.mat1_3.w));

				//頂点Shaderから送られてきたワールド変換行列の情報から回転行列を作成し、レイマーチングで使える形にする
				_rotMat2 = float3x3(i.mat2_1.xyz, i.mat2_2.xyz, i.mat2_3.xyz);
				_rotMat2 = transpose(_rotMat2);
				//頂点Shaderから送られてきたワールド変換行列の情報から移動量を示すベクトルを作成し、レイマーチングで使える形にする
				_trans2 = mul(_rotMat2, float3(i.mat2_1.w, i.mat2_2.w, i.mat2_3.w));

				float3 ro = _WorldSpaceCameraPos;//レイのスタート地点を設定
				float3 rd = normalize(i.pos.xyz - ro).xyz;//レイの方向を計算

				float d = 0;
				float t = 0.001;
				float far = 10.;
				float near = 0.0001;

				[unroll]
				for (int i = 0; i < 60; ++i) { //レイマーチングを行う
					d = dist(ro + rd * t);
					t += d;
					if (t > far || near > d) break;
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

				float4 projectionPos = mul(UNITY_MATRIX_VP, float4(ro + rd * t, 1.0));
				o.depth = projectionPos.z / projectionPos.w;

				return o;
			}
			ENDCG
		}
	}
}
