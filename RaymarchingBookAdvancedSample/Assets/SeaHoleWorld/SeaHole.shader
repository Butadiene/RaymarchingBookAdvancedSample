Shader "Butadiene/SeaHole"
{
	Properties
	{
		
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Cull Front

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			
			#include "UnityCG.cginc"


			float2  rot(float2 p,float r) {
				float2x2 m = float2x2(cos(r),sin(r),-sin(r),cos(r));
				return mul(m,p);
			}

			float cube(float3 p,float3 s) {
				float3 q = abs(p);
				float3 m = max(s - q,0.0);
				return length(max(q - s,0.0)) - min(min(m.x,m.y),m.z);
			}


			float hasira(float3 p,float3 s) {
				float2 q = abs(p.xy);
				float2 m = max(s.xy - q.xy,float2(0.0,0.0));
				return length(max(q.xy - s.xy,0.0)) - min(m.x,m.y);
			}

			float closs(float3 p,float3 s) {
				float d1 = hasira(p,s);
				float d2 = hasira(p.yzx,s.yzx);
				float d3 = hasira(p.zxy,s.zxy);
				return min(min(d1,d2),d3);
			}

			float menger(float3 p,float3 s) {
				float3 pm = p;
				float d1 = cube(p,float3(100000.,100000.,10000.));
				[unroll]
				for (int i = 0; i < 3; i++) {
					float fi = 3.0 * float(i + 4);
					if (i == 0) {
						fi = 1.0;
					}

					float k = 2.0 / fi;
					pm -= 1.0 * fi;
					pm = abs(fmod(pm,k)) - 0.5 * k;

					float d2 = closs(pm,s / (3.0 * fi));
					d1 = max(d1,-d2);
				}

				return d1;

			}

			float dist(float3 p) {

				p.xy = rot(p.xy,1.0);
				p.z -= abs(fmod(1.0 * _Time.y,2000.));
				[unroll]
				for (int i = 0; i < 3; i++) {
				  p.xy = rot(p.xy,p.x + p.y + p.z);
				}
			
				float d1 = menger(p,float3(1.0,1.0,1.0));
				return d1;
			}

		

			float3 gn(float3 p) {

				const float h = 0.001;
				const float2 k = float2(1, -1);
				return normalize(k.xyy * dist(p + k.xyy * h) +
					k.yyx * dist(p + k.yyx * h) +
					k.yxy * dist(p + k.yxy * h) +
					k.xxx * dist(p + k.xxx * h));

			}
			float3 light(float3 p,float3 view) {
				float3 normal = gn(p);
				float3 ld = normalize(float3(cos(_Time.y),sin(_Time.y),0.2));
				float NdotL = max(dot(ld, normal), 0.0);
				float3 R = normalize(-ld + NdotL * normal * 2.0);
				float spec = pow(max(dot(-view, R), 0.0), 11.0) * saturate(sign(NdotL));
				float3 col = float3(1, 1, 1) * (NdotL + spec);
				return clamp(col * float3(0.5,0.7,0.9) +  0.05,0.0,1.0);
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

	
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.pos = v.vertex;
				o.uv = v.uv;

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float3 ro = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1)).xyz;
				float3 rd = normalize(i.pos.xyz - mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1)).xyz);

				float d = 0;
				float t = 0.001;
				float far = 10.;
				
				[unroll]
				for (int i = 0; i < 60; ++i) { 
					d = dist(ro + rd * t);
					t += d;
					if (t > far) break;
				}


				float tk = 0.0;
				float dk = 0.0;

				float3 bcol = float3(0.1, 0.4, 0.8);
				float3 col = light(ro + rd * t, rd);
				
				float near = 1.0;


				col = lerp(bcol, col, clamp((far - t) / (far - near), 0.0, 1.0));

				col = clamp(col, 0.0, 1.0);

				return float4(col*float3(0.7,0.9,1.0),1.0);
			}
			ENDCG
		}
	}
}
