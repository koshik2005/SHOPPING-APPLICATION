import http.server
import socketserver
import json
import os
import time
import base64
import uuid
from urllib.parse import urlparse, parse_qs

def decode_google_id_token_unsafe(id_token):
    """Decode Google ID token payload WITHOUT verification (for local dev only)."""
    try:
        parts = id_token.split('.')
        if len(parts) != 3:
            return {}
        payload = parts[1]
        # Add padding
        payload += '=' * (4 - len(payload) % 4)
        decoded = base64.urlsafe_b64decode(payload)
        return json.loads(decoded)
    except Exception as e:
        print(f'[AUTH] Token decode error: {e}')
        return {}

import urllib.request
import urllib.error

def forward_to_auth_service(path, headers, body_bytes):
    url = f"http://localhost:8081{path}"
    req = urllib.request.Request(url, data=body_bytes, method='POST')
    for key, val in headers.items():
        if key.lower() not in ('host', 'content-length'):
            req.add_header(key, val)
    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            return response.status, response.info(), response.read()
    except urllib.error.HTTPError as e:
        return e.code, e.headers, e.read()
    except Exception as e:
        print(f"[PROXY ERROR] Failed to connect to auth-service: {e}")
        return 502, {}, json.dumps({"error": "Auth service unavailable"}).encode('utf-8')

PORT = 8080
DB_FILE = os.path.join(os.path.dirname(__file__), 'database.json')

def read_db():
    if not os.path.exists(DB_FILE):
        return {}
    with open(DB_FILE, 'r', encoding='utf-8') as f:
        return json.load(f)

def write_db(data):
    with open(DB_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2)

class ApiHandler(http.server.BaseHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PATCH, DELETE, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, X-User-ID, X-Session-ID, X-Correlation-ID, Authorization')
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(204)
        self.end_headers()

    def do_GET(self):
        db = read_db()
        parsed_url = urlparse(self.path)
        path_only = parsed_url.path
        parts = path_only.split('/')
        
        # Delivery boy web UI
        if path_only == '/delivery':
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(self.get_delivery_html(db).encode('utf-8'))
            return

        # api/v1/wallets/balance
        elif path_only == '/api/v1/wallets/balance':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({
                "data": {
                    "id": "wallet-id-88219",
                    "customerId": "87ef769c-d021-4f11-ba32-aafe812bb31c",
                    "balance": db.get("user", {}).get("walletBalance", 50.0)
                }
            }).encode('utf-8'))
            return

        # api/v1/customers/bootstrap
        elif path_only == '/api/v1/customers/bootstrap':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({
                "data": {
                    "profile": {
                        "id": "87ef769c-d021-4f11-ba32-aafe812bb31c",
                        "displayName": db.get("user", {}).get("name", "Kishore R"),
                        "email": db.get("user", {}).get("email", "Kishore.r.cseacet@gmail.com")
                    },
                    "appConfig": db.get("config", {})
                }
            }).encode('utf-8'))
            return

        # api/v1/inventory/categories
        elif path_only == '/api/v1/inventory/categories':
            branch_categories = db.get("branches", {}).get("branch-a", {}).get("categories", [])
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"data": branch_categories}).encode('utf-8'))
            return

        # api/v1/inventory/products/shop/{shopId}
        elif path_only.startswith('/api/v1/inventory/products/shop/'):
            products = db.get("branches", {}).get("branch-a", {}).get("products", [])
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"data": products}).encode('utf-8'))
            return

        # api/v1/shops/branch/{branchId}
        elif path_only.startswith('/api/v1/shops/branch/'):
            # Return active shops
            shops = [
                {
                    "id": "87ef769c-d021-4f11-ba32-aafe812bb31c",
                    "name": "Downtown Groceries",
                    "isOpen": True
                }
            ]
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"data": shops}).encode('utf-8'))
            return

        # api/v1/search/suggestions
        elif path_only == '/api/v1/search/suggestions':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({
                "data": {
                    "autocomplete": ["milk", "egg", "badam"],
                    "trending": ["badam", "rice"],
                    "recent": ["badam"]
                }
            }).encode('utf-8'))
            return

        # api/v1/orders/{orderId}/timeline
        elif path_only.endswith('/timeline') and '/orders/' in path_only:
            order_id = path_only.split('/')[-2]
            orders = db.get("orders", [])
            order_match = next((o for o in orders if o.get("id") == order_id), {})
            history = order_match.get("history", [
                {"status": "PLACED", "remarks": "Order placed successfully", "timestamp": "2026-06-28T05:00:00Z"}
            ])
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"data": {"history": history}}).encode('utf-8'))
            return

        # Legacy routes mappings
        elif path_only == '/api/config':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(db.get('config', {})).encode('utf-8'))
            
        elif path_only == '/api/branches':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(db.get('branches', {})).encode('utf-8'))
            
        elif path_only == '/admin' or path_only == '/':
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(self.get_admin_html(db).encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        parsed_url = urlparse(self.path)
        path_only = parsed_url.path

        # If it's an auth request, proxy to Spring Boot auth-service running on port 8081
        if path_only.startswith('/api/v1/auth/'):
            content_length = int(self.headers['Content-Length'])
            body_bytes = self.rfile.read(content_length)
            
            # Send to port 8081 (Spring Boot)
            status, resp_headers, resp_body = forward_to_auth_service(path_only, self.headers, body_bytes)
            
            # Respond to client
            self.send_response(status)
            for key, val in resp_headers.items():
                key_lower = key.lower()
                # Filter out hop-by-hop and content-length/transfer-encoding headers
                if key_lower not in (
                    'access-control-allow-origin', 'access-control-allow-methods', 'access-control-allow-headers',
                    'transfer-encoding', 'connection', 'keep-alive', 'content-length'
                ):
                    self.send_header(key, val)
            self.send_header('Content-Length', str(len(resp_body)))
            self.end_headers()
            self.wfile.write(resp_body)
            return

        db = read_db()
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length).decode('utf-8')
        
        try:
            payload = json.loads(post_data)
        except Exception:
            payload = {}

        parts = path_only.split('/')



        # POST /api/v1/auth/google-login  ← REAL Google Sign-In handler
        if path_only == '/api/v1/auth/google-login':
            id_token = payload.get('idToken', '')
            claims = decode_google_id_token_unsafe(id_token)
            email = claims.get('email', '')
            name = claims.get('name', 'Unknown User')
            picture = claims.get('picture', '')
            google_sub = claims.get('sub', str(uuid.uuid4()))

            if not email:
                self.send_response(400)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({'error': 'Invalid or missing Google ID token'}).encode('utf-8'))
                return

            db = read_db()
            users = db.setdefault('users', {})

            if email in users:
                # Existing user → LOGIN_COMPLETED
                user = users[email]
                print(f'[AUTH] Existing user login: {email}')
                access_token = 'access_' + uuid.uuid4().hex
                refresh_token = 'refresh_' + uuid.uuid4().hex
                response_body = {
                    'authenticationState': 'LOGIN_COMPLETED',
                    'accessToken': access_token,
                    'refreshToken': refresh_token,
                    'expiresIn': 86400,
                    'user': {
                        'id': user['id'],
                        'email': email,
                        'role': user.get('role', 'CUSTOMER'),
                        'profile': {
                            'displayName': user.get('name', name),
                            'profilePhotoUrl': user.get('picture', picture),
                        }
                    }
                }
                write_db(db)
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({'data': response_body}).encode('utf-8'))
            else:
                # New user → REGISTRATION_REQUIRED
                print(f'[AUTH] New user registration required: {email}')
                response_body = {
                    'authenticationState': 'REGISTRATION_REQUIRED',
                    'googleProfile': {
                        'displayName': name,
                        'email': email,
                        'profilePhotoUrl': picture,
                        'googleSub': google_sub,
                    }
                }
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({'data': response_body}).encode('utf-8'))
            return

        # POST /api/v1/auth/register (complete registration after google sign-in)
        elif path_only == '/api/v1/auth/register':
            email = payload.get('email', '')
            name = payload.get('name', '')
            mobile = payload.get('mobileNumber', '')
            picture = payload.get('profilePhotoUrl', '')

            if not email:
                self.send_response(400)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({'error': 'email required'}).encode('utf-8'))
                return

            db = read_db()
            users = db.setdefault('users', {})
            user_id = str(uuid.uuid4())
            users[email] = {
                'id': user_id,
                'name': name,
                'email': email,
                'mobileNumber': mobile,
                'picture': picture,
                'role': 'CUSTOMER',
                'createdAt': time.strftime('%Y-%m-%dT%H:%M:%SZ'),
            }
            write_db(db)

            access_token = 'access_' + uuid.uuid4().hex
            refresh_token = 'refresh_' + uuid.uuid4().hex
            print(f'[AUTH] New user registered: {email}')
            response_body = {
                'authenticationState': 'LOGIN_COMPLETED',
                'accessToken': access_token,
                'refreshToken': refresh_token,
                'expiresIn': 86400,
                'user': {
                    'id': user_id,
                    'email': email,
                    'role': 'CUSTOMER',
                    'profile': {
                        'displayName': name,
                        'profilePhotoUrl': picture,
                    }
                }
            }
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'data': response_body}).encode('utf-8'))
            return

        # POST /api/v1/auth/logout
        elif path_only == '/api/v1/auth/logout':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'data': {'success': True}}).encode('utf-8'))
            return

        # POST /api/v1/wallets/credit
        elif path_only == '/api/v1/wallets/credit':
            amt = payload.get("amount", 0.0)
            current_bal = db.get("user", {}).get("walletBalance", 50.0)
            db["user"]["walletBalance"] = current_bal + amt
            write_db(db)
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"data": {"success": True}}).encode('utf-8'))
            return

        # POST /api/v1/wallets/debit
        elif path_only == '/api/v1/wallets/debit':
            amt = payload.get("amount", 0.0)
            current_bal = db.get("user", {}).get("walletBalance", 50.0)
            db["user"]["walletBalance"] = max(0.0, current_bal - amt)
            write_db(db)
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"data": {"success": True}}).encode('utf-8'))
            return

        # POST /api/v1/orders/create
        elif path_only == '/api/v1/orders/create':
            order_id = "HL-" + str(int(time.time()))[-6:]
            new_order = {
                "id": order_id,
                "customerId": "87ef769c-d021-4f11-ba32-aafe812bb31c",
                "totalPrice": payload.get("totalPrice", 100.0),
                "status": "PENDING",
                "history": [
                    {"status": "PLACED", "remarks": "Order placed successfully", "timestamp": "2026-06-28T05:00:00Z"}
                ],
                "driverName": "",
                "driverPhone": ""
            }
            if "orders" not in db:
                db["orders"] = []
            db["orders"].append(new_order)
            write_db(db)
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"data": new_order}).encode('utf-8'))
            return

        # POST /api/delivery/orders/accept
        elif path_only == '/api/delivery/orders/accept':
            order_id = payload.get("orderId")
            orders = db.get("orders", [])
            for o in orders:
                if o.get("id") == order_id:
                    o["status"] = "ACCEPTED"
                    o["driverName"] = "Rajesh Kumar"
                    o["driverPhone"] = "+15559990001"
                    o["history"].append({
                        "status": "ACCEPTED",
                        "remarks": "Order accepted by Rajesh Kumar (+15559990001)",
                        "timestamp": "2026-06-28T05:10:00Z"
                    })
                    break
            write_db(db)
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"success": True}).encode('utf-8'))
            return

        # POST /api/v1/branches/geofence
        elif path_only == '/api/v1/branches/geofence':
            lat = payload.get("latitude", 0.0)
            lng = payload.get("longitude", 0.0)
            branches = db.get("branches", {})
            
            nearest_branch = None
            min_dist = float('inf')
            
            import math
            for bid, b in branches.items():
                blat = b.get("latitude", 0.0)
                blng = b.get("longitude", 0.0)
                dist = math.sqrt((lat - blat)**2 + (lng - blng)**2) * 111.0
                if dist < min_dist:
                    min_dist = dist
                    nearest_branch = b
            
            is_within = False
            if nearest_branch:
                is_within = min_dist <= nearest_branch.get("servingRadiusKm", 5.0)
            
            response_body = {
                "nearestBranch": nearest_branch or {
                    "id": "branch-a",
                    "name": "Downtown Branch",
                    "latitude": 37.7749,
                    "longitude": -122.4194,
                    "servingRadiusKm": 5.0
                },
                "isWithinDeliveryZone": is_within,
                "serviceAvailability": "AVAILABLE" if is_within else "OUT_OF_SERVICE"
            }
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"data": response_body}).encode('utf-8'))
            return

        # Legacy routes dispatches
        elif path_only == '/api/branch/branch-a/categories':
            new_cat = {
                "id": payload.get("id", "").lower().strip(),
                "label": payload.get("label", "").strip(),
                "iconUrl": payload.get("iconUrl", "restaurant").strip(),
                "isAvailable": True,
                "displayOrder": 1
            }
            branch = db.setdefault("branches", {}).setdefault("branch-a", {})
            categories = branch.setdefault("categories", [])
            categories.append(new_cat)
            write_db(db)
            self.send_response(201)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(new_cat).encode('utf-8'))
            return

        elif path_only == '/api/branch/branch-a/products':
            new_prod = {
                "id": payload.get("id", "").lower().strip(),
                "categoryId": payload.get("categoryId", "").lower().strip(),
                "name": payload.get("name", "").strip(),
                "description": payload.get("description", "").strip(),
                "price": float(payload.get("price", 10.0)),
                "isAvailable": True
            }
            branch = db.setdefault("branches", {}).setdefault("branch-a", {})
            products = branch.setdefault("products", [])
            products.append(new_prod)
            write_db(db)
            self.send_response(201)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(new_prod).encode('utf-8'))
            return

        else:
            self.send_response(400)
            self.end_headers()

    def get_admin_html(self, db):
        branch = db.get("branches", {}).get("branch-a", {})
        categories = branch.get("categories", [])
        products = branch.get("products", [])
        return f"""<!DOCTYPE html>
<html>
<head>
    <title>HyperLocal Branch Admin Portal</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700&display=swap" rel="stylesheet">
    <style>
        * {{ box-sizing: border-box; margin: 0; padding: 0; }}
        body {{
            font-family: 'Plus Jakarta Sans', sans-serif;
            background: #f7fafc;
            color: #2d3748;
            padding: 40px 20px;
        }}
        .container {{
            max-width: 1000px;
            margin: 0 auto;
            background: #fff;
            border-radius: 16px;
            padding: 40px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.05);
        }}
        h1 {{ margin-bottom: 24px; font-weight: 700; color: #1a202c; }}
        .form-section {{
            margin-bottom: 40px;
            padding-bottom: 32px;
            border-bottom: 1px solid #e2e8f0;
        }}
        .form-group {{ margin-bottom: 16px; }}
        label {{ display: block; font-weight: 600; margin-bottom: 6px; }}
        input[type="text"], input[type="number"], select {{
            width: 100%;
            padding: 12px;
            border: 1px solid #cbd5e0;
            border-radius: 8px;
            font-family: inherit;
        }}
        .btn {{
            background: #3182ce;
            color: #fff;
            padding: 12px 24px;
            border-radius: 8px;
            font-weight: 600;
            border: none;
            cursor: pointer;
        }}
        .btn:hover {{ background: #2b6cb0; }}
        .grid {{
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
            gap: 16px;
            margin-top: 16px;
        }}
        .card {{
            border: 1px solid #e2e8f0;
            border-radius: 12px;
            padding: 16px;
            text-align: center;
            background: #fcfcfc;
        }}
        .emoji {{ font-size: 32px; margin-bottom: 8px; }}
    </style>
</head>
<body>
    <div class="container">
        <h1>HyperLocal Branch Admin Portal</h1>
        
        <!-- Category Manager -->
        <div class="form-section">
            <h2>Add Category</h2>
            <form id="catForm" onsubmit="addCategory(event)">
                <div class="form-group">
                    <label>ID</label>
                    <input type="text" id="catId" required placeholder="e.g. food, grocery">
                </div>
                <div class="form-group">
                    <label>Label</label>
                    <input type="text" id="catLabel" required placeholder="e.g. Restaurant, Supermarket">
                </div>
                <div class="form-group">
                    <label>Emoji / Icon (Reference Round Logo)</label>
                    <input type="text" id="catIcon" required placeholder="e.g. 🍔, 🥦, 🍎">
                </div>
                <button type="submit" class="btn">Add Category</button>
            </form>
            
            <div class="grid">
                {"".join([f'<div class="card"><div class="emoji">{c.get("iconUrl")}</div><strong>{c.get("label")}</strong></div>' for c in categories])}
            </div>
        </div>

        <!-- Product Manager -->
        <div class="form-section">
            <h2>Add Product</h2>
            <form id="prodForm" onsubmit="addProduct(event)">
                <div class="form-group">
                    <label>Category</label>
                    <select id="prodCat" required>
                        {"".join([f'<option value="{c.get("id")}">{c.get("label")}</option>' for c in categories])}
                    </select>
                </div>
                <div class="form-group">
                    <label>Product Name</label>
                    <input type="text" id="prodName" required>
                </div>
                <div class="form-group">
                    <label>Price ($)</label>
                    <input type="number" id="prodPrice" required step="0.01">
                </div>
                <button type="submit" class="btn">Add Product</button>
            </form>
            
            <div class="grid">
                {"".join([f'<div class="card"><strong>{p.get("name")}</strong><p>${p.get("price")}</p></div>' for p in products])}
            </div>
        </div>
    </div>
    <script>
        async function addCategory(e) {{
            e.preventDefault();
            const id = document.getElementById('catId').value;
            const label = document.getElementById('catLabel').value;
            const iconUrl = document.getElementById('catIcon').value;
            await fetch('/api/branch/branch-a/categories', {{
                method: 'POST',
                headers: {{ 'Content-Type': 'application/json' }},
                body: JSON.stringify({{ id, label, iconUrl }})
            }});
            location.reload();
        }}
        async function addProduct(e) {{
            e.preventDefault();
            const categoryId = document.getElementById('prodCat').value;
            const name = document.getElementById('prodName').value;
            const price = document.getElementById('prodPrice').value;
            await fetch('/api/branch/branch-a/products', {{
                method: 'POST',
                headers: {{ 'Content-Type': 'application/json' }},
                body: JSON.stringify({{ id: name.toLowerCase(), categoryId, name, price }})
            }});
            location.reload();
        }}
    </script>
</body>
</html>
"""

    def get_delivery_html(self, db):
        orders = db.get("orders", [])
        orders_json = json.dumps(orders)
        return f"""<!DOCTYPE html>
<html>
<head>
    <title>HyperLocal Delivery Console</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700&display=swap" rel="stylesheet">
    <style>
        * {{ box-sizing: border-box; margin: 0; padding: 0; }}
        body {{
            font-family: 'Plus Jakarta Sans', sans-serif;
            background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
            min-height: 100vh;
            padding: 40px 20px;
            color: #2d3748;
        }}
        .container {{
            max-width: 900px;
            margin: 0 auto;
            background: rgba(255, 255, 255, 0.9);
            backdrop-filter: blur(10px);
            border-radius: 24px;
            padding: 40px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
        }}
        h1 {{
            font-weight: 700;
            color: #1a202c;
            margin-bottom: 8px;
            text-align: center;
        }}
        p.subtitle {{
            text-align: center;
            color: #718096;
            margin-bottom: 40px;
        }}
        .order-card {{
            background: #ffffff;
            border-radius: 16px;
            padding: 24px;
            margin-bottom: 20px;
            border: 1px solid #e2e8f0;
            box-shadow: 0 4px 6px rgba(0,0,0,0.02);
        }}
        .card-header {{
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 16px;
        }}
        .order-id {{
            font-weight: 700;
            color: #2b6cb0;
        }}
        .status-badge {{
            padding: 6px 12px;
            border-radius: 99px;
            font-size: 12px;
            font-weight: 700;
            text-transform: uppercase;
        }}
        .status-pending {{ background: #feebc8; color: #c05621; }}
        .status-accepted {{ background: #c6f6d5; color: #22543d; }}
        .btn {{
            display: inline-block;
            background: #3182ce;
            color: #fff;
            padding: 12px 24px;
            border-radius: 8px;
            font-weight: 600;
            border: none;
            cursor: pointer;
        }}
        .btn:hover {{ background: #2b6cb0; }}
        .driver-info {{
            margin-top: 16px;
            padding-top: 16px;
            border-top: 1px dashed #e2e8f0;
            font-size: 14px;
            color: #4a5568;
        }}
    </style>
</head>
<body>
    <div class="container">
        <h1>HyperLocal Delivery Console</h1>
        <p class="subtitle">Real-time driver dispatch panel & UAT tester</p>
        <div id="orders-list"></div>
    </div>
    <script>
        const orders = {orders_json};
        const listDiv = document.getElementById('orders-list');

        function renderOrders() {{
            if (orders.length === 0) {{
                listDiv.innerHTML = '<p style="text-align: center; color: #a0aec0; padding: 40px 0;">No placed orders found. Submit an order from the Customer App to test dispatches!</p>';
                return;
            }}
            listDiv.innerHTML = orders.map(o => `
                <div class="order-card">
                    <div class="card-header">
                        <span class="order-id">ID: ${{o.id}}</span>
                        <span class="status-badge status-${{o.status.toLowerCase()}}">${{o.status}}</span>
                    </div>
                    <p>Total: <strong>$${{o.totalPrice}}</strong></p>
                    ${{o.status === 'PENDING' ? `
                        <button class="btn" style="margin-top: 16px;" onclick="acceptOrder('${{o.id}}')">Accept Order</button>
                    ` : `
                        <div class="driver-info">
                            <p>👨‍✈️ Driver: <strong>Rajesh Kumar</strong></p>
                            <p>📞 Mobile: <strong>+15559990001</strong></p>
                        </div>
                    `}}
                </div>
            `).join('');
        }}

        async function acceptOrder(orderId) {{
            const res = await fetch('/api/delivery/orders/accept', {{
                method: 'POST',
                headers: {{ 'Content-Type': 'application/json' }},
                body: JSON.stringify({{ orderId }})
            }});
            if (res.ok) {{
                location.reload();
            }} else {{
                alert('Failed to accept order');
            }}
        }}

        renderOrders();
    </script>
</body>
</html>
"""

Handler = ApiHandler
with socketserver.TCPServer(("", PORT), Handler) as httpd:
    print("Local backend API server active at port", PORT)
    print("Access admin panel at http://localhost:8080/admin")
    httpd.serve_forever()
