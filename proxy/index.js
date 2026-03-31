const express = require('express');
const fetch = require('node-fetch');
const app = express();
app.use(express.json());

const API_ENDPOINT = 'https://open.bigmodel.cn/api/paas/v4/chat/completions';
const API_KEY = process.env.ZHIPU_API_KEY;

if (!API_KEY) {
    console.warn('Warning: ZHIPU_API_KEY not set in environment. Proxy will return 500.');
}

app.post('/api/zhipu', async (req, res) => {
    if (!API_KEY) return res.status(500).json({ error: 'Server missing ZHIPU_API_KEY' });
    try {
        const resp = await fetch(API_ENDPOINT, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${API_KEY}`,
            },
            body: JSON.stringify(req.body),
        });
        const text = await resp.text();
        res.status(resp.status).send(text);
    } catch (err) {
        console.error('Proxy error', err);
        res.status(500).json({ error: 'Proxy failed' });
    }
});

const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`Proxy listening on ${port}`));
