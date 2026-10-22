// Protected live-class access decision. The meeting URL is returned only after server-side checks.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
const url=Deno.env.get("SUPABASE_URL")??"", key=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")??"";
const origins=(Deno.env.get("SIFA_ALLOWED_ORIGINS")??"").split(",").map(s=>s.trim()).filter(Boolean);
const base={"Content-Type":"application/json","Cache-Control":"no-store","Vary":"Origin"};
function out(status:number,body:Record<string,unknown>,origin:string|null){return new Response(JSON.stringify(body),{status,headers:{...base,...(origin&&origins.includes(origin)?{"Access-Control-Allow-Origin":origin,"Access-Control-Allow-Headers":"authorization, apikey, content-type, x-client-info","Access-Control-Allow-Methods":"POST, OPTIONS"}:{})}})}
Deno.serve(async req=>{
 const origin=req.headers.get("origin");if(req.method==="OPTIONS")return origin&&origins.includes(origin)?new Response(null,{status:204,headers:{...base,"Access-Control-Allow-Origin":origin,"Access-Control-Allow-Headers":"authorization, apikey, content-type, x-client-info","Access-Control-Allow-Methods":"POST, OPTIONS"}}):new Response(null,{status:403,headers:base});
 if(req.method!=="POST")return out(405,{error:"Method not allowed."},origin);if(!origin||!origins.includes(origin))return out(403,{error:"Origin not allowed."},origin);
 const token=(req.headers.get("authorization")||"").replace(/^Bearer\s+/i,"");if(!token)return out(401,{error:"Sign in to check your learning access."},origin);if(!url||!key)return out(503,{error:"Learning access is not configured."},origin);
 const db=createClient(url,key,{auth:{persistSession:false,autoRefreshToken:false}});const {data:u,error:ue}=await db.auth.getUser(token);if(ue||!u.user)return out(401,{error:"Your session has expired."},origin);
 const today=new Date().toISOString().slice(0,10);
 const {data:enrollments,error}=await db.from("sifa_enrollments").select("id,program,status,start_date,end_date,access_exception_reason,access_exception_expires_at").eq("student_user_id",u.user.id).eq("status","active");
 if(error)return out(500,{error:"Could not verify your enrollment. Contact SIFA support."},origin);
 for(const e of enrollments||[]){
   if(e.start_date&&e.start_date>today)continue;if(e.end_date&&e.end_date<today)continue;
   const exception=!!e.access_exception_reason&&!!e.access_exception_expires_at&&e.access_exception_expires_at>=new Date().toISOString();
   const {data:invoices, error:ie}=await db.from("sifa_fee_invoices").select("status,due_date,period_start,period_end,invoice_type").eq("enrollment_id",e.id).eq("invoice_type","monthly_course").lte("period_start",today).gte("period_end",today).order("period_start",{ascending:false}).limit(1);
   if(ie)return out(500,{error:"Could not verify your fee status."},origin);
   const inv=invoices?.[0];const paid=!!inv&&["paid","waived"].includes(inv.status);let grace=false;
   if(inv&&["unpaid","overdue"].includes(inv.status)){const graceDate=new Date(`${inv.due_date}T00:00:00Z`);graceDate.setUTCDate(graceDate.getUTCDate()+14);grace=today<=graceDate.toISOString().slice(0,10);}
   if(paid||grace||exception){const meet=Deno.env.get("SIFA_LIVE_CLASS_URL")??"";if(!meet)return out(503,{error:"Learning access is approved, but the class link is not configured. Contact SIFA support."},origin);return out(200,{authorized:true,program:e.program,access_basis:paid?"verified_payment":grace?"grace_period":"authorized_exception",meeting_url:meet,message:"Do not share the private class link. The instructor may verify attendance."},origin)}
 }
 return out(403,{authorized:false,message:"Your learning access is not currently active. Submit a payment receipt or contact SIFA if you have an approved scholarship or fee waiver."},origin);
});
