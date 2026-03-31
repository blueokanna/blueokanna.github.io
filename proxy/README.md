Proxy server for Zhipu GLM-4-Flash (minimal example)

Purpose

This small Express service forwards frontend requests to the Zhipu API using a server-side environment variable for the API key. Deploying this to a serverless platform (Vercel, Cloud Run, etc.) hides the API key from end users.

Usage (development)

```bash
cd proxy
npm install
ZHIPU_API_KEY=your_key npm start
# POST JSON to http://localhost:3000/api/zhipu
```

Recommended deployment

- Vercel: set `ZHIPU_API_KEY` in Project Settings -> Environment Variables, then `vercel --prod`.
- Cloud Run: set the environment variable in the service configuration.

Frontend integration

In production, have your Flutter frontend call your proxy endpoint, for example:

```dart
final resp = await http.post(Uri.parse('https://your-proxy.example.com/api/zhipu'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({'model':'glm-4-flash','messages':messages}),
);
```

Security notes

- Do NOT commit your API key to the repository.
- Limit access to the proxy endpoint using authentication if you expect public traffic.
