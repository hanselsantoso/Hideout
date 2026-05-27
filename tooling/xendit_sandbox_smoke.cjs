const secretKey = process.env.XENDIT_SECRET_KEY;
const apiBase = process.env.XENDIT_API_BASE || 'https://api.xendit.co';

function fail(message) {
  console.error(message);
  process.exitCode = 1;
}

function authHeader() {
  return `Basic ${Buffer.from(`${secretKey}:`).toString('base64')}`;
}

async function xendit(method, path, body) {
  const response = await fetch(`${apiBase}${path}`, {
    method,
    headers: {
      Authorization: authHeader(),
      'Content-Type': 'application/json',
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await response.text();
  const payload = text ? JSON.parse(text) : {};
  if (!response.ok) {
    throw new Error(
      `Xendit ${method} ${path} failed: ${response.status} ${JSON.stringify(payload)}`,
    );
  }
  return payload;
}

async function main() {
  if (!secretKey) {
    fail('Set XENDIT_SECRET_KEY in your shell before running smoke:xendit.');
    return;
  }

  const existingSessionId = process.env.XENDIT_PAYMENT_SESSION_ID;
  if (existingSessionId) {
    const session = await xendit('GET', `/sessions/${existingSessionId}`);
    console.log(JSON.stringify({
      paymentSessionId: session.payment_session_id,
      status: session.status,
      paymentLinkUrl: session.payment_link_url,
      paymentId: session.payment_id || null,
      paymentRequestId: session.payment_request_id || null,
    }, null, 2));
    return;
  }

  const referenceId = `turneysmoke${Date.now().toString(36)}`;
  const session = await xendit('POST', '/sessions', {
    reference_id: referenceId,
    session_type: 'PAY',
    mode: 'PAYMENT_LINK',
    allow_save_payment_method: 'DISABLED',
    capture_method: 'AUTOMATIC',
    amount: 10000,
    currency: 'IDR',
    country: 'ID',
    locale: 'en',
    description: 'Turney Xendit sandbox smoke test',
    success_return_url: 'https://turney.id/me/tournaments',
    cancel_return_url: 'https://turney.id/tournaments',
    metadata: {
      source: 'turney-smoke',
    },
    items: [
      {
        reference_id: referenceId,
        type: 'DIGITAL_SERVICE',
        name: 'Turney sandbox smoke test',
        net_unit_amount: 10000,
        quantity: 1,
        category: 'Tournament',
      },
    ],
  });

  console.log(JSON.stringify({
    paymentSessionId: session.payment_session_id,
    status: session.status,
    paymentLinkUrl: session.payment_link_url,
    note: 'Open paymentLinkUrl to test every sandbox payment channel enabled in the Xendit dashboard.',
  }, null, 2));
}

main().catch((error) => {
  fail(error instanceof Error ? error.message : String(error));
});
