/**
 * Supabase Edge Function: nach neuer Zeile in website_anfragen E-Mail an Admin (Resend).
 *
 * Secrets (Supabase CLI): RESEND_API_KEY, optional NOTIFY_EMAIL, RESEND_FROM
 * Deploy: supabase functions deploy notify-anfrage --no-verify-jwt
 *   (oder mit JWT – dann Aufruf mit anon Authorization wie im Website-Skript)
 */
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.4';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function buildBody(payload: Record<string, unknown>, id: string): string {
  const lines: string[] = [];
  lines.push('Neue Website-Anfrage (gespeichert in Supabase)');
  lines.push('ID: ' + id);
  lines.push('');
  lines.push(JSON.stringify(payload, null, 2));
  return lines.join('\n');
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: cors });
  }
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'method' }), {
      status: 405,
      headers: { ...cors, 'Content-Type': 'application/json' },
    });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
    if (!supabaseUrl || !serviceKey) {
      return new Response(JSON.stringify({ error: 'server_config' }), {
        status: 500,
        headers: { ...cors, 'Content-Type': 'application/json' },
      });
    }

    const body = (await req.json()) as { id?: string };
    const id = typeof body.id === 'string' ? body.id : '';
    if (!id) {
      return new Response(JSON.stringify({ error: 'missing_id' }), {
        status: 400,
        headers: { ...cors, 'Content-Type': 'application/json' },
      });
    }

    const admin = createClient(supabaseUrl, serviceKey);
    const { data: row, error } = await admin.from('website_anfragen').select('*').eq('id', id).maybeSingle();
    if (error || !row) {
      return new Response(JSON.stringify({ error: 'not_found' }), {
        status: 404,
        headers: { ...cors, 'Content-Type': 'application/json' },
      });
    }

    const created = new Date(String(row.created_at));
    if (Number.isNaN(created.getTime()) || Date.now() - created.getTime() > 5 * 60 * 1000) {
      return new Response(JSON.stringify({ error: 'stale' }), {
        status: 400,
        headers: { ...cors, 'Content-Type': 'application/json' },
      });
    }

    const resendKey = Deno.env.get('RESEND_API_KEY');
    if (!resendKey) {
      return new Response(JSON.stringify({ emailed: false, reason: 'no_resend_key' }), {
        headers: { ...cors, 'Content-Type': 'application/json' },
      });
    }

    const payload = (row.payload || {}) as Record<string, unknown>;
    const betrieb = String(payload.betrieb_name || payload.name || 'Anfrage');
    const subject = `Neue Website-Anfrage: ${betrieb}`;
    const text = buildBody(payload, id);
    const to = Deno.env.get('NOTIFY_EMAIL') || 'dahoam.digital@gmail.com';
    const from = Deno.env.get('RESEND_FROM') || 'onboarding@resend.dev';

    const r = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${resendKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ from, to: [to], subject, text }),
    });

    if (!r.ok) {
      const t = await r.text();
      return new Response(JSON.stringify({ emailed: false, resend: t }), {
        status: 502,
        headers: { ...cors, 'Content-Type': 'application/json' },
      });
    }

    return new Response(JSON.stringify({ emailed: true }), {
      headers: { ...cors, 'Content-Type': 'application/json' },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...cors, 'Content-Type': 'application/json' },
    });
  }
});
