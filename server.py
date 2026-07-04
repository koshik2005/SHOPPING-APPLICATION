import http.server
import socketserver
import json
import os
import time
import base64
import uuid
import threading
import queue
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

# ─── SSE Subscriber Registry ────────────────────────────────────────────────
_sse_subscribers = []
_sse_lock = threading.Lock()
_event_log = []   # keeps last 500 events in memory

def broadcast_event(event_type: str, action: str, payload: dict):
    """Broadcast a structured event to all connected SSE clients."""
    event = {
        'id': str(uuid.uuid4())[:8],
        'type': event_type,
        'action': action,
        'payload': payload,
        'ts': time.strftime('%Y-%m-%dT%H:%M:%SZ'),
    }
    _event_log.append(event)
    if len(_event_log) > 500:
        _event_log.pop(0)
    with _sse_lock:
        dead = []
        for q in _sse_subscribers:
            try:
                q.put_nowait(event)
            except Exception:
                dead.append(q)
        for q in dead:
            _sse_subscribers.remove(q)

def make_mock_jwt(user_id, email, role, roles, branch_id=None, shop_id=None):
    import base64
    header = {"alg": "RS256", "kid": "key-1"}
    payload = {
        "sub": user_id,
        "email": email,
        "role": role,
        "roles": roles,
        "branchId": branch_id,
        "shopId": shop_id,
        "sessionId": str(uuid.uuid4())
    }
    
    def b64url(d):
        s = json.dumps(d).encode('utf-8')
        return base64.urlsafe_b64encode(s).decode('utf-8').rstrip('=')
        
    return f"{b64url(header)}.{b64url(payload)}.mock_signature"

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
        
        # ─── PORTAL: Server-Sent Events (Live Event Monitor) ────────────────────────
        if path_only == '/api/portal/events':
            my_q = queue.Queue()
            with _sse_lock:
                _sse_subscribers.append(my_q)
            try:
                self.send_response(200)
                self.send_header('Content-Type', 'text/event-stream')
                self.send_header('Cache-Control', 'no-cache')
                self.send_header('Connection', 'keep-alive')
                self.end_headers()
                # Send last 50 events as replay
                for ev in _event_log[-50:]:
                    self.wfile.write(f"data: {json.dumps(ev)}\n\n".encode())
                    self.wfile.flush()
                while True:
                    try:
                        ev = my_q.get(timeout=25)
                        self.wfile.write(f"data: {json.dumps(ev)}\n\n".encode())
                        self.wfile.flush()
                    except queue.Empty:
                        self.wfile.write(b": keepalive\n\n")
                        self.wfile.flush()
            except Exception:
                pass
            finally:
                with _sse_lock:
                    if my_q in _sse_subscribers:
                        _sse_subscribers.remove(my_q)
            return

        # ─── PORTAL: Dashboard stats ─────────────────────────────────────────────────
        elif path_only == '/api/portal/dashboard':
            orders = db.get('orders', [])
            users = db.get('users', {})
            partners = db.get('delivery_partners', [])
            branches = db.get('branches', {})
            shops = db.get('shops', [])
            categories = list(db.get('branches', {}).get('branch-a', {}).get('categories', []))
            products = list(db.get('branches', {}).get('branch-a', {}).get('products', []))
            wallet_balance = db.get('user', {}).get('walletBalance', 0)
            pending_orders = [o for o in orders if o.get('status') == 'PENDING']
            today_revenue = sum(o.get('totalPrice', 0) for o in orders if o.get('status') not in ['CANCELLED', 'REFUNDED'])
            onboarding = db.get('onboarding_requests', [])
            stats = {
                'totalOrders': len(orders),
                'pendingOrders': len(pending_orders),
                'totalCustomers': len(users),
                'totalBranches': len(branches),
                'activeShops': len(shops),
                'totalCategories': len(categories),
                'totalProducts': len(products),
                'deliveryPartners': len(partners),
                'onlinePartners': len([p for p in partners if p.get('status') != 'OFFLINE']),
                'todayRevenue': round(today_revenue, 2),
                'walletBalance': wallet_balance,
                'pendingOnboarding': len([r for r in onboarding if r.get('status') == 'PENDING_APPROVAL']),
                'sseSubscribers': len(_sse_subscribers),
                'eventLogCount': len(_event_log),
            }
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'data': stats}).encode())
            return

        # ─── PORTAL: Full DB snapshot (read-only) ────────────────────────────────────
        elif path_only == '/api/portal/db-snapshot':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'data': db}).encode())
            return

        # ─── PORTAL: All orders ───────────────────────────────────────────────────────
        elif path_only == '/api/portal/orders':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'data': db.get('orders', [])}).encode())
            return

        # ─── PORTAL: All users ────────────────────────────────────────────────────────
        elif path_only == '/api/portal/users':
            users_map = db.get('users', {})
            users_list = [{'email': k, **v} for k, v in users_map.items()]
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'data': users_list}).encode())
            return

        # ─── PORTAL: Banners ─────────────────────────────────────────────────────────
        elif path_only == '/api/portal/banners':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'data': db.get('banners', [])}).encode())
            return

        # ─── PORTAL: Offers ──────────────────────────────────────────────────────────
        elif path_only == '/api/portal/offers':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'data': db.get('offers', [])}).encode())
            return

        # ─── PORTAL: Notification history ────────────────────────────────────────────
        elif path_only == '/api/portal/notifications':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'data': db.get('notification_log', [])}).encode())
            return

        # ─── PORTAL: App config ───────────────────────────────────────────────────────
        elif path_only == '/api/portal/config':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'data': db.get('config', {})}).encode())
            return

        # ─── PORTAL: Delivery Partners ────────────────────────────────────────────────
        elif path_only == '/api/portal/partners':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'data': db.get('delivery_partners', [])}).encode())
            return

        # ─── PORTAL: Branches ─────────────────────────────────────────────────────────
        elif path_only == '/api/portal/branches':
            branches_list = [{'id': k, **v} for k, v in db.get('branches', {}).items()]
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'data': branches_list}).encode())
            return

        # ─── PORTAL: Categories ───────────────────────────────────────────────────────
        elif path_only == '/api/portal/categories':
            cats = db.get('branches', {}).get('branch-a', {}).get('categories', [])
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'data': cats}).encode())
            return

        # ─── PORTAL: Products ─────────────────────────────────────────────────────────
        elif path_only == '/api/portal/products':
            prods = db.get('branches', {}).get('branch-a', {}).get('products', [])
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'data': prods}).encode())
            return

        # ─── PORTAL: Shops ────────────────────────────────────────────────────────────
        elif path_only == '/api/portal/shops':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'data': db.get('shops', [])}).encode())
            return

        # Delivery boy web UI
        elif path_only == '/delivery':
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(self.get_delivery_html(db).encode('utf-8'))
            return

        # GET /api/delivery/onboarding-requests
        elif path_only == '/api/delivery/onboarding-requests':
            requests = db.get("onboarding_requests", [])
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"data": requests}).encode('utf-8'))
            return

        # GET /api/delivery/active-partners
        elif path_only == '/api/delivery/active-partners':
            partners = db.get("delivery_partners", [])
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"data": partners}).encode('utf-8'))
            return

        # GET /api/delivery/orders
        elif path_only == '/api/delivery/orders':
            orders = db.get("orders", [])
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"data": orders}).encode('utf-8'))
            return

        # GET /api/v1/deliveries/order/{orderId}/status
        elif path_only.startswith('/api/v1/deliveries/order/') and path_only.endswith('/status'):
            order_id = path_only.split('/')[-2]
            orders = db.get("orders", [])
            order_match = next((o for o in orders if o.get("id") == order_id), {})
            partner_id = order_match.get("partnerId")
            
            partners = db.get("delivery_partners", [])
            partner = next((p for p in partners if p.get("id") == partner_id), {})
            
            response_body = {
                "orderId": order_id,
                "partnerId": partner_id,
                "status": order_match.get("status", "PENDING"),
                "etaMinutes": "12 Mins",
                "driverName": partner.get("name", "Rajesh Kumar"),
                "driverPhone": partner.get("mobile", "+15559990001"),
                "latitude": partner.get("latitude", 37.7749),
                "longitude": partner.get("longitude", -122.4194)
            }
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"data": response_body}).encode('utf-8'))
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
            shops = db.get("shops", [
                {
                    "id": "87ef769c-d021-4f11-ba32-aafe812bb31c",
                    "name": "Downtown Groceries",
                    "isOpen": True
                }
            ])
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
            
            if status == 502:
                print(f"[AUTH MOCK] Intercepting down auth-service for path {path_only}")
                try:
                    payload = json.loads(body_bytes.decode('utf-8')) if body_bytes else {}
                except Exception:
                    payload = {}
                
                mock_data = {}
                if path_only == '/api/v1/auth/google-login':
                    id_token = payload.get('idToken', '')
                    google_user = {}
                    try:
                        parts = id_token.split('.')
                        if len(parts) == 3:
                            import base64
                            payload_b64 = parts[1]
                            payload_b64 += '=' * (4 - len(payload_b64) % 4)
                            google_user = json.loads(base64.urlsafe_b64decode(payload_b64).decode('utf-8'))
                    except Exception as e:
                        print(f"[JWT DECODE ERROR] {e}")
                    
                    email = google_user.get('email', '')
                    name = google_user.get('name', '')
                    picture = google_user.get('picture', '')
                    sub = google_user.get('sub', '')
                    
                    print(f"[AUTH MOCK] Decoded ID Token: email={email}, name={name}, picture={picture}, sub={sub}")
                    
                    # If this is our pre-registered test account, complete login directly
                    if email == 'Kishore.r.cseacet@gmail.com':
                        mock_data = {
                            "status": "SUCCESS",
                            "data": {
                                "authenticationState": "LOGIN_COMPLETED",
                                "accessToken": "mock_access_token_google",
                                "refreshToken": "mock_refresh_token_google",
                                "expiresIn": 3600,
                                "user": {
                                    "id": "87ef769c-d021-4f11-ba32-aafe812bb31c",
                                    "email": email,
                                    "mobileNumber": "+15559990001",
                                    "role": "CUSTOMER",
                                    "profile": {
                                        "displayName": name or "Kishore R",
                                        "profilePhotoUrl": picture or ""
                                    }
                                }
                            }
                        }
                    else:
                        # Return REGISTRATION_REQUIRED for new Google Accounts
                        mock_data = {
                            "status": "SUCCESS",
                            "data": {
                                "authenticationState": "REGISTRATION_REQUIRED",
                                "googleProfile": {
                                    "displayName": name or "Alex Johnson",
                                    "email": email or "alex.j@example.com",
                                    "profilePhotoUrl": picture or "https://cdn.hyperlocal.app/users/avatars/default.png",
                                    "googleSub": sub or "google_sub_1092837482"
                                }
                            }
                        }
                elif path_only == '/api/v1/auth/verify-password':
                    email = payload.get("email", "Kishore.r.cseacet@gmail.com")
                    is_admin = "admin" in email.lower()
                    user_role = "ROLE_SUPER_ADMIN" if is_admin else "ROLE_CUSTOMER"
                    user_roles = ["ROLE_SUPER_ADMIN"] if is_admin else ["ROLE_CUSTOMER"]
                    mock_token = make_mock_jwt("87ef769c-d021-4f11-ba32-aafe812bb31c", email, user_role, user_roles)
                    mock_data = {
                        "status": "SUCCESS",
                        "data": {
                            "authenticationState": "LOGIN_COMPLETED",
                            "accessToken": mock_token,
                            "refreshToken": "mock_refresh_token_pass",
                            "expiresIn": 3600,
                            "user": {
                                "id": "87ef769c-d021-4f11-ba32-aafe812bb31c",
                                "email": email,
                                "mobileNumber": "+15559990001",
                                "role": user_role,
                                "roles": user_roles,
                                "profile": {
                                    "displayName": "Administrator" if is_admin else "Kishore R",
                                    "profilePhotoUrl": ""
                                }
                            }
                        }
                    }
                else:
                    email = payload.get("email", "Kishore.r.cseacet@gmail.com")
                    is_admin = "admin" in email.lower()
                    user_role = "ROLE_SUPER_ADMIN" if is_admin else "ROLE_CUSTOMER"
                    user_roles = ["ROLE_SUPER_ADMIN"] if is_admin else ["ROLE_CUSTOMER"]
                    mock_token = make_mock_jwt("87ef769c-d021-4f11-ba32-aafe812bb31c", email, user_role, user_roles)
                    mock_data = {
                        "status": "SUCCESS",
                        "data": {
                            "authenticationState": "LOGIN_COMPLETED",
                            "accessToken": mock_token,
                            "refreshToken": "mock_refresh_token_generic",
                            "expiresIn": 3600,
                            "user": {
                                "id": "87ef769c-d021-4f11-ba32-aafe812bb31c",
                                "email": email,
                                "mobileNumber": "+15559990001",
                                "role": user_role,
                                "roles": user_roles,
                                "profile": {
                                    "displayName": "Administrator" if is_admin else "Kishore R",
                                    "profilePhotoUrl": ""
                                }
                            }
                        }
                    }
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps(mock_data).encode('utf-8'))
                return

            # Respond to client
            self.send_response(status)
            for key, val in resp_headers.items():
                key_lower = key.lower()
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
            partner_id = payload.get("partnerId")
            
            partners = db.get("delivery_partners", [])
            partner = next((p for p in partners if p.get("id") == partner_id), {
                "name": "Rajesh Kumar",
                "mobile": "+15559990001"
            })
            
            orders = db.get("orders", [])
            for o in orders:
                if o.get("id") == order_id:
                    o["status"] = "ACCEPTED"
                    o["partnerId"] = partner_id
                    o["driverName"] = partner.get("name")
                    o["driverPhone"] = partner.get("mobile")
                    o["history"].append({
                        "status": "ACCEPTED",
                        "remarks": f"Order accepted by {partner.get('name')} ({partner.get('mobile')})",
                        "timestamp": "2026-06-28T05:10:00Z"
                    })
                    break
            write_db(db)
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"success": True}).encode('utf-8'))
            return

        # POST /api/delivery/register
        elif path_only == '/api/delivery/register':
            new_req = {
                "id": str(uuid.uuid4()),
                "name": payload.get("name", "").strip(),
                "mobile": payload.get("mobile", "").strip(),
                "email": payload.get("email", "").strip(),
                "dob": payload.get("dob", "").strip(),
                "vehicleType": payload.get("vehicleType", "MOTORCYCLE").strip(),
                "status": "PENDING_APPROVAL",
                "registeredAt": int(time.time())
            }
            onboard = db.setdefault("onboarding_requests", [])
            onboard.append(new_req)
            write_db(db)
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"success": True, "data": new_req}).encode('utf-8'))
            return

        # POST /api/delivery/approve
        elif path_only == '/api/delivery/approve':
            req_id = payload.get("requestId")
            onboard = db.get("onboarding_requests", [])
            target = None
            for req in onboard:
                if req.get("id") == req_id:
                    req["status"] = "APPROVED"
                    target = req
                    break
            if target:
                login_id = "DB-" + target["mobile"][-4:]
                password = "pass" + target["mobile"][-4:]
                
                partners = db.setdefault("delivery_partners", [])
                new_partner = {
                    "id": target["id"],
                    "loginId": login_id,
                    "password": password,
                    "name": target["name"],
                    "mobile": target["mobile"],
                    "email": target["email"],
                    "vehicleType": target["vehicleType"],
                    "status": "OFFLINE",
                    "latitude": 37.7749,
                    "longitude": -122.4194
                }
                partners.append(new_partner)
                write_db(db)
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({
                    "success": True, 
                    "loginId": login_id, 
                    "password": password
                }).encode('utf-8'))
            else:
                self.send_response(404)
                self.end_headers()
            return

        # POST /api/delivery/login
        elif path_only == '/api/delivery/login':
            login_id = payload.get("loginId")
            password = payload.get("password")
            mobile = payload.get("mobile")
            
            partners = db.get("delivery_partners", [])
            match = None
            for p in partners:
                if p.get("loginId") == login_id and p.get("password") == password and p.get("mobile") == mobile:
                    match = p
                    break
            if match:
                match["status"] = "AVAILABLE"
                write_db(db)
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"success": True, "partner": match}).encode('utf-8'))
            else:
                self.send_response(401)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"error": "Invalid credentials or SIM verification failure"}).encode('utf-8'))
            return

        # POST /api/delivery/update-location
        elif path_only == '/api/delivery/update-location':
            partner_id = payload.get("partnerId")
            lat = float(payload.get("latitude", 37.7749))
            lng = float(payload.get("longitude", -122.4194))
            
            partners = db.get("delivery_partners", [])
            for p in partners:
                if p.get("id") == partner_id:
                    p["latitude"] = lat
                    p["longitude"] = lng
                    break
            write_db(db)
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"success": True}).encode('utf-8'))
            return

        # POST /api/branch/register-shop
        elif path_only == '/api/branch/register-shop':
            new_shop = {
                "id": payload.get("id", str(uuid.uuid4())),
                "name": payload.get("name", "").strip(),
                "isOpen": payload.get("isOpen", True)
            }
            shops = db.setdefault("shops", [])
            shops.append(new_shop)
            write_db(db)
            self.send_response(201)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(new_shop).encode('utf-8'))
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

        # ─── PORTAL POST ROUTES ───────────────────────────────────────────────────────

        elif path_only.startswith('/api/portal/'):
            action = path_only[len('/api/portal/'):]
            ok = {'success': True}

            # BRANCHES
            if action == 'branches/create':
                bid = payload.get('id', 'branch-' + str(uuid.uuid4())[:4])
                new_branch = {
                    'id': bid, 'name': payload.get('name','New Branch'),
                    'address': payload.get('address',''), 'isOpen': True,
                    'latitude': payload.get('latitude', 37.7749),
                    'longitude': payload.get('longitude', -122.4194),
                    'servingRadiusKm': payload.get('servingRadiusKm', 5.0),
                    'deliveryFee': payload.get('deliveryFee', 2.5),
                    'workingHours': payload.get('workingHours','08:00 AM - 10:00 PM'),
                    'taxRate': payload.get('taxRate', 0.08),
                    'categories': [], 'products': []
                }
                db.setdefault('branches', {})[bid] = new_branch
                write_db(db)
                broadcast_event('BRANCH', 'CREATE', {'branchId': bid, 'name': new_branch['name']})
                ok['data'] = new_branch

            elif action == 'branches/update':
                bid = payload.get('id', 'branch-a')
                branch = db.setdefault('branches', {}).setdefault(bid, {})
                for k in ['name','address','isOpen','servingRadiusKm','deliveryFee','workingHours','taxRate']:
                    if k in payload: branch[k] = payload[k]
                write_db(db)
                broadcast_event('BRANCH', 'UPDATE', {'branchId': bid})
                ok['data'] = branch

            elif action == 'branches/delete':
                bid = payload.get('id')
                if bid and bid in db.get('branches', {}):
                    del db['branches'][bid]
                    write_db(db)
                    broadcast_event('BRANCH', 'DELETE', {'branchId': bid})

            # SHOPS
            elif action == 'shops/create':
                new_shop = {
                    'id': payload.get('id', str(uuid.uuid4())),
                    'name': payload.get('name','').strip(),
                    'isOpen': payload.get('isOpen', True),
                    'rating': payload.get('rating', 4.5),
                    'deliveryTime': payload.get('deliveryTime', '20-30 min'),
                    'logoUrl': payload.get('logoUrl', ''),
                    'bannerUrl': payload.get('bannerUrl', ''),
                    'status': 'ACTIVE',
                }
                db.setdefault('shops', []).append(new_shop)
                write_db(db)
                broadcast_event('SHOP', 'CREATE', {'name': new_shop['name']})
                ok['data'] = new_shop

            elif action == 'shops/toggle':
                sid = payload.get('id')
                for s in db.get('shops', []):
                    if s.get('id') == sid:
                        s['isOpen'] = not s.get('isOpen', True)
                        write_db(db)
                        broadcast_event('SHOP', 'TOGGLE', {'id': sid, 'isOpen': s['isOpen']})
                        ok['data'] = s
                        break

            elif action == 'shops/update':
                sid = payload.get('id')
                for s in db.get('shops', []):
                    if s.get('id') == sid:
                        for k in ['name','isOpen','rating','deliveryTime','logoUrl','bannerUrl','status']:
                            if k in payload: s[k] = payload[k]
                        write_db(db)
                        broadcast_event('SHOP', 'UPDATE', {'id': sid})
                        ok['data'] = s
                        break

            elif action == 'shops/delete':
                sid = payload.get('id')
                db['shops'] = [s for s in db.get('shops', []) if s.get('id') != sid]
                write_db(db)
                broadcast_event('SHOP', 'DELETE', {'id': sid})

            # CATEGORIES
            elif action == 'categories/create':
                new_cat = {
                    'id': payload.get('id', payload.get('label','').lower().replace(' ', '-')),
                    'label': payload.get('label',''),
                    'iconUrl': payload.get('iconUrl','📦'),
                    'isAvailable': True,
                    'displayOrder': payload.get('displayOrder', 99),
                }
                branch = db.setdefault('branches', {}).setdefault('branch-a', {})
                branch.setdefault('categories', []).append(new_cat)
                write_db(db)
                broadcast_event('CATEGORY', 'CREATE', {'label': new_cat['label']})
                ok['data'] = new_cat

            elif action == 'categories/update':
                cid = payload.get('id')
                cats = db.get('branches',{}).get('branch-a',{}).get('categories',[])
                for c in cats:
                    if c.get('id') == cid:
                        for k in ['label','iconUrl','isAvailable','displayOrder']:
                            if k in payload: c[k] = payload[k]
                        write_db(db)
                        broadcast_event('CATEGORY', 'UPDATE', {'id': cid})
                        ok['data'] = c
                        break

            elif action == 'categories/delete':
                cid = payload.get('id')
                branch = db.setdefault('branches', {}).setdefault('branch-a', {})
                branch['categories'] = [c for c in branch.get('categories', []) if c.get('id') != cid]
                write_db(db)
                broadcast_event('CATEGORY', 'DELETE', {'id': cid})

            elif action == 'categories/reorder':
                order = payload.get('order', [])  # list of ids in new order
                cats = db.get('branches',{}).get('branch-a',{}).get('categories',[])
                id_map = {c['id']: c for c in cats}
                new_list = [id_map[oid] for oid in order if oid in id_map]
                for i, c in enumerate(new_list): c['displayOrder'] = i + 1
                db['branches']['branch-a']['categories'] = new_list
                write_db(db)
                broadcast_event('CATEGORY', 'REORDER', {'order': order})

            # PRODUCTS
            elif action == 'products/create':
                new_prod = {
                    'id': payload.get('id', str(uuid.uuid4())[:8]),
                    'categoryId': payload.get('categoryId',''),
                    'name': payload.get('name',''),
                    'description': payload.get('description',''),
                    'price': float(payload.get('price', 0)),
                    'discountPrice': payload.get('discountPrice'),
                    'taxRate': float(payload.get('taxRate', 0)),
                    'stock': int(payload.get('stock', 100)),
                    'isAvailable': True,
                    'imageUrl': payload.get('imageUrl',''),
                    'tags': payload.get('tags', []),
                }
                branch = db.setdefault('branches',{}).setdefault('branch-a',{})
                branch.setdefault('products',[]).append(new_prod)
                write_db(db)
                broadcast_event('PRODUCT', 'CREATE', {'name': new_prod['name']})
                ok['data'] = new_prod

            elif action == 'products/toggle':
                pid = payload.get('id')
                for p in db.get('branches',{}).get('branch-a',{}).get('products',[]):
                    if p.get('id') == pid:
                        p['isAvailable'] = not p.get('isAvailable', True)
                        write_db(db)
                        broadcast_event('PRODUCT', 'TOGGLE', {'id': pid, 'isAvailable': p['isAvailable']})
                        ok['data'] = p
                        break

            elif action == 'products/update':
                pid = payload.get('id')
                for p in db.get('branches',{}).get('branch-a',{}).get('products',[]):
                    if p.get('id') == pid:
                        for k in ['name','description','price','discountPrice','taxRate','stock','isAvailable','imageUrl','categoryId']:
                            if k in payload: p[k] = payload[k]
                        write_db(db)
                        broadcast_event('PRODUCT', 'UPDATE', {'id': pid})
                        ok['data'] = p
                        break

            elif action == 'products/delete':
                pid = payload.get('id')
                branch = db.setdefault('branches',{}).setdefault('branch-a',{})
                branch['products'] = [p for p in branch.get('products',[]) if p.get('id') != pid]
                write_db(db)
                broadcast_event('PRODUCT', 'DELETE', {'id': pid})

            # INVENTORY
            elif action == 'inventory/adjust':
                pid = payload.get('productId')
                delta = int(payload.get('delta', 0))
                set_to = payload.get('setTo')
                for p in db.get('branches',{}).get('branch-a',{}).get('products',[]):
                    if p.get('id') == pid:
                        if set_to is not None:
                            p['stock'] = int(set_to)
                        else:
                            p['stock'] = max(0, int(p.get('stock', 0)) + delta)
                        if p['stock'] == 0:
                            p['isAvailable'] = False
                        write_db(db)
                        broadcast_event('INVENTORY', 'ADJUST', {'productId': pid, 'stock': p['stock']})
                        ok['data'] = {'stock': p['stock']}
                        break

            # ORDERS
            elif action == 'orders/create-test':
                order_id = 'HL-TEST-' + str(int(time.time()))[-6:]
                new_order = {
                    'id': order_id,
                    'customerId': payload.get('customerId','87ef769c-d021-4f11-ba32-aafe812bb31c'),
                    'branchId': payload.get('branchId','branch-a'),
                    'totalPrice': float(payload.get('totalPrice', 99.0)),
                    'deliveryFee': float(payload.get('deliveryFee', 2.5)),
                    'status': 'PENDING',
                    'history': [{'status': 'PENDING', 'remarks': 'Test order created by portal', 'timestamp': time.strftime('%Y-%m-%dT%H:%M:%SZ')}],
                    'driverName': '', 'driverPhone': '',
                    'items': payload.get('items', []),
                    'createdAt': time.strftime('%Y-%m-%dT%H:%M:%SZ'),
                }
                db.setdefault('orders', []).append(new_order)
                write_db(db)
                broadcast_event('ORDER', 'CREATED', {'orderId': order_id, 'totalPrice': new_order['totalPrice']})
                ok['data'] = new_order

            elif action == 'orders/advance-status':
                STATUS_FLOW = ['PENDING','ACCEPTED','PREPARING','PACKED','READY','PICKED_UP','IN_TRANSIT','DELIVERED']
                order_id = payload.get('orderId')
                new_status = payload.get('status')
                remarks = payload.get('remarks', f'Status updated via Testing Portal')
                for o in db.get('orders', []):
                    if o.get('id') == order_id:
                        o['status'] = new_status
                        o.setdefault('history', []).append({
                            'status': new_status, 'remarks': remarks,
                            'timestamp': time.strftime('%Y-%m-%dT%H:%M:%SZ')
                        })
                        write_db(db)
                        broadcast_event('ORDER', 'STATUS_UPDATE', {'orderId': order_id, 'status': new_status})
                        ok['data'] = o
                        break

            # WALLET
            elif action == 'wallet/adjust':
                amount = float(payload.get('amount', 0))
                operation = payload.get('operation', 'CREDIT')  # CREDIT or DEBIT
                current = db.get('user', {}).get('walletBalance', 0)
                if operation == 'CREDIT':
                    db.setdefault('user', {})['walletBalance'] = round(current + amount, 2)
                else:
                    db.setdefault('user', {})['walletBalance'] = round(max(0, current - amount), 2)
                write_db(db)
                new_bal = db['user']['walletBalance']
                broadcast_event('WALLET', operation, {'amount': amount, 'balance': new_bal})
                ok['data'] = {'walletBalance': new_bal, 'operation': operation}

            # PAYMENT
            elif action == 'payment/inject':
                order_id = payload.get('orderId')
                result = payload.get('result', 'SUCCESS')  # SUCCESS, FAILED, PENDING, TIMEOUT, REFUNDED
                for o in db.get('orders', []):
                    if o.get('id') == order_id:
                        o['paymentStatus'] = result
                        o.setdefault('history', []).append({
                            'status': f'PAYMENT_{result}', 'remarks': f'Payment injected as {result} by portal',
                            'timestamp': time.strftime('%Y-%m-%dT%H:%M:%SZ')
                        })
                        write_db(db)
                        broadcast_event('PAYMENT', result, {'orderId': order_id})
                        ok['data'] = {'orderId': order_id, 'paymentStatus': result}
                        break

            # NOTIFICATIONS
            elif action == 'notifications/send':
                notif = {
                    'id': str(uuid.uuid4())[:8],
                    'type': payload.get('type', 'INFO'),
                    'title': payload.get('title',''),
                    'body': payload.get('body',''),
                    'targetType': payload.get('targetType', 'ALL'),
                    'sentAt': time.strftime('%Y-%m-%dT%H:%M:%SZ'),
                }
                db.setdefault('notification_log', []).append(notif)
                write_db(db)
                broadcast_event('NOTIFICATION', payload.get('type','INFO'), notif)
                ok['data'] = notif

            # BANNERS
            elif action == 'banners/create':
                new_banner = {
                    'id': str(uuid.uuid4()),
                    'title': payload.get('title',''),
                    'imageUrl': payload.get('imageUrl',''),
                    'linkUrl': payload.get('linkUrl',''),
                    'priority': int(payload.get('priority', 1)),
                    'isActive': True,
                    'createdAt': time.strftime('%Y-%m-%dT%H:%M:%SZ'),
                }
                db.setdefault('banners', []).append(new_banner)
                write_db(db)
                broadcast_event('BANNER', 'CREATE', {'title': new_banner['title']})
                ok['data'] = new_banner

            elif action == 'banners/toggle':
                bid = payload.get('id')
                for b in db.get('banners', []):
                    if b.get('id') == bid:
                        b['isActive'] = not b.get('isActive', True)
                        write_db(db)
                        broadcast_event('BANNER', 'TOGGLE', {'id': bid})
                        break

            elif action == 'banners/delete':
                bid = payload.get('id')
                db['banners'] = [b for b in db.get('banners', []) if b.get('id') != bid]
                write_db(db)
                broadcast_event('BANNER', 'DELETE', {'id': bid})

            # OFFERS
            elif action == 'offers/create':
                new_offer = {
                    'id': str(uuid.uuid4()),
                    'type': payload.get('type','COUPON'),
                    'code': payload.get('code','').upper(),
                    'title': payload.get('title',''),
                    'discountType': payload.get('discountType','PERCENT'),
                    'discountValue': float(payload.get('discountValue', 10)),
                    'minOrderValue': float(payload.get('minOrderValue', 0)),
                    'maxDiscount': payload.get('maxDiscount'),
                    'isActive': True,
                    'expiresAt': payload.get('expiresAt',''),
                    'createdAt': time.strftime('%Y-%m-%dT%H:%M:%SZ'),
                }
                db.setdefault('offers', []).append(new_offer)
                write_db(db)
                broadcast_event('OFFER', 'CREATE', {'code': new_offer['code'], 'type': new_offer['type']})
                ok['data'] = new_offer

            elif action == 'offers/toggle':
                oid = payload.get('id')
                for o in db.get('offers', []):
                    if o.get('id') == oid:
                        o['isActive'] = not o.get('isActive', True)
                        write_db(db)
                        broadcast_event('OFFER', 'TOGGLE', {'id': oid})
                        break

            elif action == 'offers/delete':
                oid = payload.get('id')
                db['offers'] = [o for o in db.get('offers', []) if o.get('id') != oid]
                write_db(db)
                broadcast_event('OFFER', 'DELETE', {'id': oid})

            # CONFIG
            elif action == 'config/update':
                cfg = db.setdefault('config', {})
                for k, v in payload.items():
                    cfg[k] = v
                write_db(db)
                broadcast_event('CONFIG', 'UPDATE', payload)
                ok['data'] = cfg

            # USERS
            elif action == 'users/create':
                email = payload.get('email', '')
                if email:
                    db.setdefault('users', {})[email] = {
                        'id': str(uuid.uuid4()),
                        'name': payload.get('name', ''),
                        'email': email,
                        'mobileNumber': payload.get('mobileNumber', ''),
                        'role': payload.get('role', 'CUSTOMER'),
                        'status': 'ACTIVE',
                        'picture': '',
                        'createdAt': time.strftime('%Y-%m-%dT%H:%M:%SZ'),
                    }
                    write_db(db)
                    broadcast_event('USER', 'CREATE', {'email': email, 'role': payload.get('role','CUSTOMER')})
                    ok['data'] = db['users'][email]

            elif action == 'users/manage':
                email = payload.get('email', '')
                action_type = payload.get('action', 'SUSPEND')  # SUSPEND, ACTIVATE, DELETE
                users = db.get('users', {})
                if email in users:
                    if action_type == 'DELETE':
                        del users[email]
                    else:
                        users[email]['status'] = 'SUSPENDED' if action_type == 'SUSPEND' else 'ACTIVE'
                    write_db(db)
                    broadcast_event('USER', action_type, {'email': email})

            # DELIVERY GPS
            elif action == 'delivery/move-rider':
                partner_id = payload.get('partnerId')
                lat = float(payload.get('latitude', 37.7749))
                lng = float(payload.get('longitude', -122.4194))
                for p in db.get('delivery_partners', []):
                    if p.get('id') == partner_id:
                        p['latitude'] = lat
                        p['longitude'] = lng
                        write_db(db)
                        broadcast_event('DELIVERY', 'GPS_UPDATE', {'partnerId': partner_id, 'lat': lat, 'lng': lng})
                        ok['data'] = {'latitude': lat, 'longitude': lng}
                        break

            # PERMISSION FLAGS
            elif action == 'permissions/set':
                perm = db.setdefault('portal_permissions', {})
                perm.update(payload)
                write_db(db)
                broadcast_event('PERMISSION', 'SET', payload)
                ok['data'] = perm

            else:
                self.send_response(404)
                self.end_headers()
                self.wfile.write(json.dumps({'error': f'Unknown portal action: {action}'}).encode())
                return

            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(ok).encode())

        else:
            self.send_response(400)
            self.end_headers()

    def get_admin_html(self, db):
        branch = db.get("branches", {}).get("branch-a", {})
        categories = branch.get("categories", [])
        products = branch.get("products", [])
        shops = db.get("shops", [
            {"id": "87ef769c-d021-4f11-ba32-aafe812bb31c", "name": "Downtown Groceries", "isOpen": True}
        ])
        return f"""<!DOCTYPE html>
<html>
<head>
    <title>HyperLocal Branch Admin Portal</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        * {{ box-sizing: border-box; margin: 0; padding: 0; }}
        body {{
            font-family: 'Plus Jakarta Sans', sans-serif;
            background: radial-gradient(circle at top, #1e1b4b 0%, #0f172a 100%);
            color: #f8fafc;
            min-height: 100vh;
            display: flex;
        }}
        /* Layout */
        .sidebar {{
            width: 280px;
            background: rgba(15, 23, 42, 0.6);
            backdrop-filter: blur(20px);
            border-right: 1px solid rgba(255, 255, 255, 0.08);
            padding: 30px 20px;
            display: flex;
            flex-direction: column;
            gap: 30px;
        }}
        .logo {{
            font-size: 20px;
            font-weight: 700;
            background: linear-gradient(135deg, #06b6d4 0%, #3b82f6 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            letter-spacing: 0.5px;
            text-align: center;
        }}
        .menu {{
            display: flex;
            flex-direction: column;
            gap: 8px;
        }}
        .menu-item {{
            padding: 14px 16px;
            border-radius: 12px;
            color: #94a3b8;
            font-weight: 600;
            text-decoration: none;
            cursor: pointer;
            transition: all 0.3s ease;
            display: flex;
            align-items: center;
            gap: 12px;
        }}
        .menu-item:hover, .menu-item.active {{
            background: rgba(255, 255, 255, 0.06);
            color: #22d3ee;
        }}
        .main-content {{
            flex: 1;
            padding: 40px;
            overflow-y: auto;
            max-width: 1200px;
            margin: 0 auto;
            width: 100%;
        }}
        .tab-content {{
            display: none;
        }}
        .tab-content.active {{
            display: block;
        }}
        h1 {{
            font-size: 28px;
            font-weight: 700;
            margin-bottom: 8px;
            background: linear-gradient(135deg, #f8fafc 0%, #cbd5e1 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }}
        p.subtitle {{
            color: #94a3b8;
            margin-bottom: 30px;
        }}
        /* Form Card style */
        .glass-card {{
            background: rgba(30, 41, 59, 0.4);
            border: 1px solid rgba(255, 255, 255, 0.05);
            border-radius: 20px;
            padding: 30px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.2);
            margin-bottom: 30px;
        }}
        h2 {{
            font-size: 20px;
            margin-bottom: 20px;
            font-weight: 600;
            color: #38bdf8;
        }}
        .form-row {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }}
        .form-group {{
            display: flex;
            flex-direction: column;
            gap: 6px;
        }}
        label {{
            font-size: 13px;
            color: #94a3b8;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }}
        input[type="text"], input[type="number"], select {{
            background: rgba(15, 23, 42, 0.8);
            border: 1px solid rgba(255, 255, 255, 0.1);
            padding: 12px 16px;
            border-radius: 10px;
            color: #f8fafc;
            font-family: inherit;
            outline: none;
            transition: border-color 0.3s;
        }}
        input[type="text"]:focus, input[type="number"]:focus, select:focus {{
            border-color: #06b6d4;
        }}
        .btn {{
            background: linear-gradient(135deg, #06b6d4 0%, #3b82f6 100%);
            color: #fff;
            padding: 12px 24px;
            border-radius: 10px;
            font-weight: 600;
            border: none;
            cursor: pointer;
            transition: opacity 0.3s;
        }}
        .btn:hover {{
            opacity: 0.9;
        }}
        /* Table / Grid list */
        .grid {{
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
            gap: 16px;
        }}
        .card {{
            background: rgba(15, 23, 42, 0.4);
            border: 1px solid rgba(255, 255, 255, 0.05);
            border-radius: 14px;
            padding: 20px;
            text-align: center;
            transition: transform 0.3s;
        }}
        .card:hover {{
            transform: translateY(-4px);
        }}
        .emoji {{
            font-size: 32px;
            margin-bottom: 8px;
        }}
        /* Onboarding request table */
        table {{
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
        }}
        th, td {{
            text-align: left;
            padding: 14px 16px;
            border-bottom: 1px solid rgba(255, 255, 255, 0.05);
        }}
        th {{
            color: #94a3b8;
            font-weight: 600;
            font-size: 13px;
            text-transform: uppercase;
        }}
        td {{
            font-size: 14px;
            color: #cbd5e1;
        }}
        .badge {{
            padding: 4px 10px;
            border-radius: 99px;
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
        }}
        .badge-pending {{ background: rgba(245, 158, 11, 0.15); color: #f59e0b; }}
        .badge-approved {{ background: rgba(16, 185, 129, 0.15); color: #10b981; }}
        .badge-busy {{ background: rgba(59, 130, 246, 0.15); color: #3b82f6; }}
        .badge-offline {{ background: rgba(100, 116, 139, 0.15); color: #64748b; }}
        
        .credentials-box {{
            background: rgba(16, 185, 129, 0.1);
            border: 1px solid rgba(16, 185, 129, 0.2);
            padding: 10px;
            border-radius: 8px;
            margin-top: 8px;
            font-size: 13px;
        }}
    </style>
</head>
<body>
    <div class="sidebar">
        <div class="logo">HYPERLOCAL BRANCH ADMIN</div>
        <div class="menu">
            <div class="menu-item active" onclick="switchTab('dashboard')">📊 Overview</div>
            <div class="menu-item" onclick="switchTab('categories')">📁 Categories</div>
            <div class="menu-item" onclick="switchTab('shops')">🏪 Shops</div>
            <div class="menu-item" onclick="switchTab('products')">📦 Products</div>
            <div class="menu-item" onclick="switchTab('onboarding')">🤝 Fleet Onboarding</div>
            <div class="menu-item" onclick="switchTab('tracking')">📍 Fleet Tracking</div>
        </div>
    </div>
    
    <div class="main-content">
        <!-- Dashboard Overview -->
        <div id="dashboard" class="tab-content active">
            <h1>Dashboard Overview</h1>
            <p class="subtitle">Live branch status & operations dashboard</p>
            <div class="form-row">
                <div class="glass-card text-center" style="text-align:center;">
                    <h3>Total Categories</h3>
                    <h1 style="font-size: 40px; color: #22d3ee; margin-top: 10px;">{len(categories)}</h1>
                </div>
                <div class="glass-card text-center" style="text-align:center;">
                    <h3>Total Shops</h3>
                    <h1 style="font-size: 40px; color: #3b82f6; margin-top: 10px;">{len(shops)}</h1>
                </div>
                <div class="glass-card text-center" style="text-align:center;">
                    <h3>Active Delivery Boys</h3>
                    <h1 id="active-count" style="font-size: 40px; color: #10b981; margin-top: 10px;">0</h1>
                </div>
            </div>
        </div>

        <!-- Categories Tab -->
        <div id="categories" class="tab-content">
            <h1>Category Manager</h1>
            <p class="subtitle">Upload and update active categories</p>
            <div class="glass-card">
                <h2>Add Category</h2>
                <form id="catForm" onsubmit="addCategory(event)">
                    <div class="form-row">
                        <div class="form-group">
                            <label>ID</label>
                            <input type="text" id="catId" required placeholder="e.g. medical, food">
                        </div>
                        <div class="form-group">
                            <label>Category Label</label>
                            <input type="text" id="catLabel" required placeholder="e.g. Pharmacy, Restaurant">
                        </div>
                        <div class="form-group">
                            <label>Emoji / Icon</label>
                            <input type="text" id="catIcon" required placeholder="e.g. 😷, 🍔, 🥦">
                        </div>
                    </div>
                    <button type="submit" class="btn">Upload Category</button>
                </form>
            </div>
            <div class="glass-card">
                <h2>Uploaded Categories</h2>
                <div class="grid" id="catList">
                    {"".join([f'<div class="card"><div class="emoji">{c.get("iconUrl")}</div><strong>{c.get("label")}</strong></div>' for c in categories])}
                </div>
            </div>
        </div>

        <!-- Shops Tab -->
        <div id="shops" class="tab-content">
            <h1>Shops Manager</h1>
            <p class="subtitle">Upload and configuration of stores available in the location</p>
            <div class="glass-card">
                <h2>Register New Shop</h2>
                <form id="shopForm" onsubmit="addShop(event)">
                    <div class="form-row">
                        <div class="form-group">
                            <label>Shop ID (UUID / String)</label>
                            <input type="text" id="shopId" required placeholder="e.g. shop-1">
                        </div>
                        <div class="form-group">
                            <label>Shop Name</label>
                            <input type="text" id="shopName" required placeholder="e.g. Downtown Pharmacy">
                        </div>
                        <div class="form-group">
                            <label>Open Status</label>
                            <select id="shopOpen">
                                <option value="true">Open</option>
                                <option value="false">Closed</option>
                            </select>
                        </div>
                    </div>
                    <button type="submit" class="btn">Register Shop</button>
                </form>
            </div>
            <div class="glass-card">
                <h2>Available Shops</h2>
                <div class="grid" id="shopList">
                    {"".join([f'<div class="card"><div class="emoji">🏪</div><strong>{s.get("name")}</strong><p style="font-size:12px;color:#94a3b8;margin-top:4px;">Status: {"Open" if s.get("isOpen") else "Closed"}</p></div>' for s in shops])}
                </div>
            </div>
        </div>

        <!-- Products Tab -->
        <div id="products" class="tab-content">
            <h1>Product Catalog</h1>
            <p class="subtitle">Assign and modify branch inventory items</p>
            <div class="glass-card">
                <h2>Add Product</h2>
                <form id="prodForm" onsubmit="addProduct(event)">
                    <div class="form-row">
                        <div class="form-group">
                            <label>Category</label>
                            <select id="prodCat" required>
                                {"".join([f'<option value="{c.get("id")}">{c.get("label")}</option>' for c in categories])}
                            </select>
                        </div>
                        <div class="form-group">
                            <label>Product Name</label>
                            <input type="text" id="prodName" required placeholder="e.g. Paracetamol Tablet">
                        </div>
                        <div class="form-group">
                            <label>Price ($)</label>
                            <input type="number" id="prodPrice" required step="0.01" placeholder="9.99">
                        </div>
                    </div>
                    <button type="submit" class="btn">Add Product</button>
                </form>
            </div>
            <div class="glass-card">
                <h2>Available Products</h2>
                <div class="grid">
                    {"".join([f'<div class="card"><strong>{p.get("name")}</strong><p style="color:#22d3ee;font-weight:700;margin-top:6px;">${p.get("price")}</p></div>' for p in products])}
                </div>
            </div>
        </div>

        <!-- Fleet Onboarding Tab -->
        <div id="onboarding" class="tab-content">
            <h1>Delivery Onboarding Portal</h1>
            <p class="subtitle">Appoint and manage delivery partners (Review verification details)</p>
            <div class="glass-card">
                <h2>Pending Onboarding Requests</h2>
                <table id="requestsTable">
                    <thead>
                        <tr>
                            <th>Candidate Details</th>
                            <th>Mobile / Email</th>
                            <th>Birth Date</th>
                            <th>Vehicle Type</th>
                            <th>Govt Documents</th>
                            <th>Onboard Action</th>
                        </tr>
                    </thead>
                    <tbody id="requestsBody">
                        <tr>
                            <td colspan="6" style="text-align:center; color:#94a3b8;">Loading onboarding fleet requests...</td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- Fleet Tracking Tab -->
        <div id="tracking" class="tab-content">
            <h1>Live Fleet Tracking</h1>
            <p class="subtitle">Monitor active delivery boys delivering orders</p>
            <div class="glass-card">
                <h2>Active Delivery Partners</h2>
                <table id="partnersTable">
                    <thead>
                        <tr>
                            <th>Partner Details</th>
                            <th>Mobile</th>
                            <th>Live Location (Lat / Lng)</th>
                            <th>Current Status</th>
                        </tr>
                    </thead>
                    <tbody id="partnersBody">
                        <tr>
                            <td colspan="4" style="text-align:center; color:#94a3b8;">Loading active fleet positions...</td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <script>
        function switchTab(tabId) {{
            document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('active'));
            document.querySelectorAll('.menu-item').forEach(el => el.classList.remove('active'));
            document.getElementById(tabId).classList.add('active');
            
            // Find menu item with matching text or parameter
            const menuItems = Array.from(document.querySelectorAll('.menu-item'));
            const matchingItem = menuItems.find(el => el.getAttribute('onclick').includes(tabId));
            if (matchingItem) matchingItem.classList.add('active');
            
            if (tabId === 'onboarding') loadRequests();
            if (tabId === 'tracking') loadActivePartners();
        }}

        async function loadRequests() {{
            const res = await fetch('/api/delivery/onboarding-requests');
            const json = await res.json();
            const list = json.data || [];
            const body = document.getElementById('requestsBody');
            if (list.length === 0) {{
                body.innerHTML = '<tr><td colspan="6" style="text-align:center;color:#94a3b8;padding:24px 0;">No pending delivery registrations found.</td></tr>';
                return;
            }}
            body.innerHTML = list.map(req => `
                <tr>
                    <td><strong>$\{{req.name}}</strong></td>
                    <td>$\{{req.mobile}}<br/><span style="font-size:11px;color:#94a3b8;">$\{{req.email}}</span></td>
                    <td>$\{{req.dob}}</td>
                    <td>$\{{req.vehicleType}}</td>
                    <td>
                        <span style="font-size:11px;display:block;">Aadhar: Approved</span>
                        <span style="font-size:11px;display:block;">License: Approved</span>
                        <span style="font-size:11px;display:block;">PAN: Approved</span>
                    </td>
                    <td>
                        $\{{req.status === 'PENDING_APPROVAL' ? `
                            <button class="btn" style="padding:6px 12px;font-size:12px;" onclick="approvePartner('$\{{req.id}}')">Approve & Appoint</button>
                        ` : `
                            <span class="badge badge-approved">Approved</span>
                            <div class="credentials-box">
                                🔑 ID: <strong>DB-$\{{req.mobile.slice(-4)}}</strong><br/>
                                🔑 Pass: <strong>pass$\{{req.mobile.slice(-4)}}</strong>
                            </div>
                        `}}
                    </td>
                </tr>
            `).join('');
        }}

        async function approvePartner(requestId) {{
            const res = await fetch('/api/delivery/approve', {{
                method: 'POST',
                headers: {{ 'Content-Type': 'application/json' }},
                body: JSON.stringify({{ requestId }})
            }});
            if (res.ok) {{
                alert('Delivery candidate successfully appointed and approved!');
                loadRequests();
            }} else {{
                alert('Failed to approve candidate');
            }}
        }}

        async function loadActivePartners() {{
            const res = await fetch('/api/delivery/active-partners');
            const json = await res.json();
            const list = json.data || [];
            const body = document.getElementById('partnersBody');
            document.getElementById('active-count').innerText = list.length;
            if (list.length === 0) {{
                body.innerHTML = '<tr><td colspan="4" style="text-align:center;color:#94a3b8;padding:24px 0;">No active delivery partners registered.</td></tr>';
                return;
            }}
            body.innerHTML = list.map(p => `
                <tr>
                    <td><strong>$\{{p.name}}</strong><br/><span style="font-size:11px;color:#64748b;">ID: $\{{p.loginId}}</span></td>
                    <td>$\{{p.mobile}}</td>
                    <td>$\{{p.latitude.toFixed(4)}}, $\{{p.longitude.toFixed(4)}}</td>
                    <td><span class="badge badge-$\{{p.status.toLowerCase()}}">$\{{p.status}}</span></td>
                </tr>
            `).join('');
        }}

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

        async function addShop(e) {{
            e.preventDefault();
            const id = document.getElementById('shopId').value;
            const name = document.getElementById('shopName').value;
            const isOpen = document.getElementById('shopOpen').value === 'true';
            await fetch('/api/branch/register-shop', {{
                method: 'POST',
                headers: {{ 'Content-Type': 'application/json' }},
                body: JSON.stringify({{ id, name, isOpen }})
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
    <title>HyperLocal Delivery Fleet Portal</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        * {{ box-sizing: border-box; margin: 0; padding: 0; }}
        body {{
            font-family: 'Plus Jakarta Sans', sans-serif;
            background: radial-gradient(circle at top, #0f172a 0%, #020617 100%);
            color: #f8fafc;
            min-height: 100vh;
            padding: 40px 20px;
        }}
        .container {{
            max-width: 800px;
            margin: 0 auto;
        }}
        h1 {{
            font-size: 26px;
            font-weight: 700;
            text-align: center;
            margin-bottom: 8px;
            background: linear-gradient(135deg, #38bdf8 0%, #818cf8 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }}
        p.subtitle {{
            text-align: center;
            color: #94a3b8;
            margin-bottom: 30px;
            font-size: 14px;
        }}
        .tab-nav {{
            display: flex;
            gap: 10px;
            margin-bottom: 30px;
            justify-content: center;
        }}
        .tab-btn {{
            padding: 12px 20px;
            border-radius: 12px;
            background: rgba(30, 41, 59, 0.4);
            border: 1px solid rgba(255, 255, 255, 0.05);
            color: #94a3b8;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
        }}
        .tab-btn.active {{
            background: rgba(56, 189, 248, 0.15);
            border-color: #38bdf8;
            color: #38bdf8;
        }}
        .glass-card {{
            background: rgba(30, 41, 59, 0.4);
            border: 1px solid rgba(255, 255, 255, 0.05);
            border-radius: 20px;
            padding: 30px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
            margin-bottom: 24px;
        }}
        .tab-panel {{
            display: none;
        }}
        .tab-panel.active {{
            display: block;
        }}
        /* Form elements */
        .form-group {{
            display: flex;
            flex-direction: column;
            gap: 6px;
            margin-bottom: 16px;
        }}
        .form-row {{
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 16px;
        }}
        label {{
            font-size: 12px;
            color: #94a3b8;
            font-weight: 600;
            text-transform: uppercase;
        }}
        input, select {{
            background: rgba(15, 23, 42, 0.8);
            border: 1px solid rgba(255, 255, 255, 0.1);
            padding: 12px;
            border-radius: 10px;
            color: #f8fafc;
            font-family: inherit;
            outline: none;
        }}
        .btn {{
            width: 100%;
            background: linear-gradient(135deg, #38bdf8 0%, #818cf8 100%);
            color: #fff;
            padding: 14px;
            border-radius: 10px;
            font-weight: 600;
            border: none;
            cursor: pointer;
            margin-top: 10px;
        }}
        .btn-sec {{
            background: rgba(255,255,255,0.06);
            border: 1px solid rgba(255,255,255,0.1);
            color: #f8fafc;
            padding: 10px 16px;
            border-radius: 8px;
            cursor: pointer;
            font-weight: 600;
        }}
        /* Orders list & location simulator */
        .order-card {{
            background: rgba(15, 23, 42, 0.5);
            border: 1px solid rgba(255,255,255,0.05);
            border-radius: 14px;
            padding: 20px;
            margin-bottom: 16px;
        }}
        .order-header {{
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 12px;
        }}
        .badge {{
            padding: 4px 10px;
            border-radius: 99px;
            font-size: 11px;
            font-weight: 700;
        }}
        .badge-pending {{ background: rgba(245,158,11,0.15); color: #f59e0b; }}
        .badge-accepted {{ background: rgba(16,185,129,0.15); color: #10b981; }}
        
        .verify-box {{
            background: rgba(129, 140, 248, 0.1);
            border: 1px solid rgba(129, 140, 248, 0.2);
            padding: 20px;
            border-radius: 12px;
            margin-top: 15px;
            text-align: center;
        }}
        @keyframes spin {{
            0% {{ transform: rotate(0deg); }}
            100% {{ transform: rotate(360deg); }}
        }}
        .map-sim {{
            background: #020617;
            border-radius: 12px;
            padding: 20px;
            text-align: center;
            margin-top: 20px;
            border: 1px dashed rgba(255,255,255,0.1);
        }}
    </style>
</head>
<body>
    <!-- Beautiful SMS Simulator Banner -->
    <div id="smsBanner" style="display:none; position:fixed; top:20px; left:50%; transform:translateX(-50%); width:90%; max-width:450px; background:rgba(15, 23, 42, 0.95); border:1px solid #38bdf8; padding:16px 20px; border-radius:16px; box-shadow:0 10px 40px rgba(0,0,0,0.5); z-index:9999; backdrop-filter:blur(10px); transition:all 0.5s cubic-bezier(0.175, 0.885, 0.32, 1.275);">
        <div style="display:flex; align-items:start; gap:12px;">
            <div style="font-size:24px;">💬</div>
            <div style="flex:1;">
                <strong style="color:#38bdf8; font-size:14px; display:block; margin-bottom:2px; text-transform:none;">Simulated Carrier SMS</strong>
                <p id="smsMessage" style="font-size:13px; color:#cbd5e1; line-height:1.4;"></p>
            </div>
            <button onclick="document.getElementById('smsBanner').style.display='none'" style="background:none; border:none; color:#94a3b8; cursor:pointer; font-size:16px;">✕</button>
        </div>
    </div>

    <div class="container">
        <h1>HyperLocal Delivery Fleet Portal</h1>
        <p class="subtitle">Driver Registration, UPI-style Login & Location Tracking Simulator</p>
        
        <div class="tab-nav">
            <button class="tab-btn active" onclick="switchTab('apply')">📝 Apply to Join</button>
            <button class="tab-btn" onclick="switchTab('login')">🔑 Partner Login</button>
            <button class="tab-btn" onclick="switchTab('console')">🏍️ Driver Dashboard</button>
        </div>

        <!-- Apply Tab -->
        <div id="apply" class="tab-panel active">
            <div class="glass-card">
                <h2>Registration Request</h2>
                <form id="regForm" onsubmit="submitApplication(event)">
                    <div class="form-row">
                        <div class="form-group">
                            <label>Full Name</label>
                            <input type="text" id="regName" required placeholder="John Doe">
                        </div>
                        <div class="form-group">
                            <label>Mobile Number</label>
                            <input type="text" id="regMobile" required placeholder="+15559990001">
                        </div>
                    </div>
                    <div class="form-row">
                        <div class="form-group">
                            <label>Email Address</label>
                            <input type="email" id="regEmail" required placeholder="john@example.com">
                        </div>
                        <div class="form-group">
                            <label>Date of Birth</label>
                            <input type="text" id="regDob" required placeholder="YYYY-MM-DD">
                        </div>
                    </div>
                    <div class="form-row">
                        <div class="form-group">
                            <label>Vehicle Type</label>
                            <select id="regVehicle">
                                <option value="BICYCLE">Bicycle</option>
                                <option value="MOTORCYCLE">Motorcycle</option>
                                <option value="CAR">Car</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label>Aadhar Card Number</label>
                            <input type="text" id="regAadhar" required placeholder="12-digit number">
                        </div>
                    </div>
                    <div class="form-row">
                        <div class="form-group">
                            <label>Driving License</label>
                            <input type="text" id="regLicense" required placeholder="License Key">
                        </div>
                        <div class="form-group">
                            <label>PAN Card</label>
                            <input type="text" id="regPan" required placeholder="PAN number">
                        </div>
                    </div>
                    <button type="submit" class="btn">Submit Application</button>
                </form>
                <div id="regSuccess" style="display:none;margin-top:20px;text-align:center;color:#10b981;">
                    🎉 Application submitted successfully! Please open the <strong>Branch Admin Panel</strong> at <a href="/admin" style="color:#38bdf8;">/admin</a> to approve your application and retrieve your credentials.
                </div>
            </div>
        </div>

        <!-- Login Tab -->
        <div id="login" class="tab-panel">
            <div class="glass-card">
                <h2>SIM & Device Authentication</h2>
                <div id="loginFormSection">
                    <div class="form-group">
                        <label>Login ID (provided on approval)</label>
                        <input type="text" id="loginId" placeholder="e.g. DB-0001">
                    </div>
                    <div class="form-group">
                        <label>Password</label>
                        <input type="password" id="loginPass">
                    </div>
                    <div class="form-group">
                        <label>Registered Phone Number</label>
                        <input type="text" id="loginMobile" placeholder="+15559990001">
                    </div>
                    <button class="btn" onclick="startSimVerification()">Verify & Log In</button>
                </div>

                <!-- SIM Checking Loading Animation -->
                <div id="simLoadingBox" class="verify-box" style="display:none;">
                    <div style="display:inline-block; width:40px; height:40px; border:4px solid rgba(56,189,248,0.1); border-left-color:#38bdf8; border-radius:50%; animation:spin 1s linear infinite; margin-bottom:15px;"></div>
                    <h3>Verifying SIM Card...</h3>
                    <p style="color:#94a3b8; font-size:13px; margin-top:8px;" id="simLoadingText">Checking SIM signatures on network carrier...</p>
                </div>

                <!-- Sim verification overlay -->
                <div id="simVerificationBox" class="verify-box" style="display:none;">
                    <h3>UPI-style SIM Check</h3>
                    <p style="color:#94a3b8;font-size:13px;margin:10px 0 20px;">We need to verify that your login number matches the SIM card installed in this device.</p>
                    <div style="display:flex;justify-content:center;gap:12px;">
                        <button class="btn-sec" onclick="selectSim(1)">SIM 1 (Active SIM)</button>
                        <button class="btn-sec" onclick="selectSim(2)">SIM 2 (Secondary SIM)</button>
                    </div>
                </div>

                <!-- OTP verification overlay -->
                <div id="otpBox" class="verify-box" style="display:none;">
                    <h3>Enter 6-Digit SMS OTP</h3>
                    <p style="color:#94a3b8;font-size:13px;margin:8px 0 16px;">SMS sent verification code to your device</p>
                    <input type="text" id="loginOtp" maxlength="6" style="text-align:center;font-size:20px;letter-spacing:4px;width:150px;margin-bottom:14px;" placeholder="123456">
                    <button class="btn" onclick="verifyOtp()">Confirm OTP</button>
                </div>
            </div>
        </div>

        <!-- Console Tab -->
        <div id="console" class="tab-panel">
            <div class="glass-card">
                <h2>Active Driver Console</h2>
                <div id="driverDetailsHeader" style="margin-bottom:20px;display:none;">
                    <p>👨‍✈️ Driver: <strong id="consoleDriverName">---</strong> | Status: <span class="badge badge-approved" id="consoleDriverStatus">AVAILABLE</span></p>
                </div>

                <div id="noLoginWarning" style="color:#94a3b8;text-align:center;padding:40px 0;">
                    Please log in from the <strong>Partner Login</strong> tab to access active jobs and UAT tracking.
                </div>

                <div id="consoleActiveSection" style="display:none;">
                    <h3>Assigned Orders</h3>
                    <div id="ordersList" style="margin-top:15px;"></div>
                    
                    <div class="map-sim">
                        <h3>📍 Live Coordinate Tracker</h3>
                        <p style="color:#94a3b8;font-size:12px;margin:6px 0 16px;">Simulate physical delivery coordinates directly on the host database</p>
                        <div style="font-size:18px;font-weight:700;color:#38bdf8;margin-bottom:14px;" id="coordsDisplay">
                            Latitude: 37.7749 | Longitude: -122.4194
                        </div>
                        <div style="display:grid;grid-template-columns:repeat(3, 100px);gap:10px;justify-content:center;margin-bottom:15px;">
                            <div></div>
                            <button class="btn-sec" onclick="moveCoords('N')">▲ North</button>
                            <div></div>
                            <button class="btn-sec" onclick="moveCoords('W')">◀ West</button>
                            <div style="display:flex;align-items:center;justify-content:center;font-size:20px;">🚲</div>
                            <button class="btn-sec" onclick="moveCoords('E')">East ▶</button>
                            <div></div>
                            <button class="btn-sec" onclick="moveCoords('S')">▼ South</button>
                            <div></div>
                        </div>
                        <button class="btn-sec" style="color:#10b981;border-color:#10b981;" id="btnAutoSim" onclick="toggleAutoSim()">Auto-Simulate Route</button>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        let loggedInPartner = null;
        let orders = {orders_json};
        let partnerLat = 37.7749;
        let partnerLng = -122.4194;
        let autoSimInterval = null;

        function switchTab(tabId) {{
            document.querySelectorAll('.tab-panel').forEach(el => el.classList.remove('active'));
            document.querySelectorAll('.tab-btn').forEach(el => el.classList.remove('active'));
            document.getElementById(tabId).classList.add('active');
            
            // Highlight tab button
            const tabBtn = Array.from(document.querySelectorAll('.tab-btn')).find(btn => btn.getAttribute('onclick').includes(tabId));
            if (tabBtn) tabBtn.classList.add('active');
        }}

        async function submitApplication(e) {{
            e.preventDefault();
            const name = document.getElementById('regName').value;
            const mobile = document.getElementById('regMobile').value;
            const email = document.getElementById('regEmail').value;
            const dob = document.getElementById('regDob').value;
            const vehicleType = document.getElementById('regVehicle').value;
            
            const res = await fetch('/api/delivery/register', {{
                method: 'POST',
                headers: {{ 'Content-Type': 'application/json' }},
                body: JSON.stringify({{ name, mobile, email, dob, vehicleType }})
            }});
            if (res.ok) {{
                document.getElementById('regForm').style.display = 'none';
                document.getElementById('regSuccess').style.display = 'block';
            }} else {{
                alert('Application submission failed');
            }}
        }}

        let generatedOtp = '123456';

        function startSimVerification() {{
            const loginId = document.getElementById('loginId').value;
            const password = document.getElementById('loginPass').value;
            const mobile = document.getElementById('loginMobile').value;
            if (!loginId || !password || !mobile) {{
                alert('Please enter all login credentials');
                return;
            }}
            document.getElementById('loginFormSection').style.display = 'none';
            document.getElementById('simVerificationBox').style.display = 'block';
        }}

        function selectSim(simNo) {{
            document.getElementById('simVerificationBox').style.display = 'none';
            document.getElementById('simLoadingBox').style.display = 'block';
            
            const mobile = document.getElementById('loginMobile').value;
            document.getElementById('simLoadingText').innerText = `Simulating SIM matching verification for registered number $\{{mobile}} on SIM $\{{simNo}}...`;
            
            setTimeout(() => {{
                document.getElementById('simLoadingBox').style.display = 'none';
                
                // Generate a random 6-digit OTP code
                generatedOtp = Math.floor(100000 + Math.random() * 900000).toString();
                
                // Show SMS Banner Notification
                document.getElementById('smsMessage').innerText = `Your HyperLocal verification code is: $\{{generatedOtp}}. Do not share this OTP.`;
                document.getElementById('smsBanner').style.display = 'block';
                
                // Play notification sound or simple console log
                console.log(`[SMS OTP SIMULATOR] Code: $\{{generatedOtp}}`);
                
                // Show OTP input box
                document.getElementById('otpBox').style.display = 'block';
            }}, 1800);
        }}

        async function verifyOtp() {{
            const loginId = document.getElementById('loginId').value;
            const password = document.getElementById('loginPass').value;
            const mobile = document.getElementById('loginMobile').value;
            const otp = document.getElementById('loginOtp').value;

            if (otp !== generatedOtp) {{
                alert('Invalid verification OTP code. Please check the SMS banner at the top of the page!');
                return;
            }}

            const res = await fetch('/api/delivery/login', {{
                method: 'POST',
                headers: {{ 'Content-Type': 'application/json' }},
                body: JSON.stringify({{ loginId, password, mobile }})
            }});
            if (res.ok) {{
                const json = await res.json();
                loggedInPartner = json.partner;
                
                // Transition to active console
                document.getElementById('otpBox').style.display = 'none';
                document.getElementById('noLoginWarning').style.display = 'none';
                
                document.getElementById('consoleDriverName').innerText = loggedInPartner.name;
                document.getElementById('driverDetailsHeader').style.display = 'block';
                document.getElementById('consoleActiveSection').style.display = 'block';
                
                renderConsoleOrders();
                switchTab('console');
            }} else {{
                alert('Login credentials verification failed. Make sure candidate is Approved first!');
                document.getElementById('otpBox').style.display = 'none';
                document.getElementById('loginFormSection').style.display = 'block';
            }}
        }}

        function renderConsoleOrders() {{
            const listDiv = document.getElementById('ordersList');
            if (orders.length === 0) {{
                listDiv.innerHTML = '<p style="color:#94a3b8;text-align:center;">No pending orders in database.</p>';
                return;
            }}
            listDiv.innerHTML = orders.map(o => `
                <div class="order-card">
                    <div class="order-header">
                        <span>Order ID: <strong>$\{{o.id}}</strong></span>
                        <span class="badge badge-$\{{o.status.toLowerCase()}}">$\{{o.status}}</span>
                    </div>
                    <p style="font-size:14px;color:#94a3b8;margin-bottom:12px;">Total: $\$\{{o.totalPrice}}</p>
                    $\{{o.status === 'PENDING' ? `
                        <button class="btn" style="margin-top:0;" onclick="acceptOrder('$\{{o.id}}')">Accept Order</button>
                    ` : `
                        <p style="font-size:13px;color:#10b981;">🚲 You are delivering this order!</p>
                    `}}
                </div>
            `).join('');
        }}

        async function acceptOrder(orderId) {{
            const res = await fetch('/api/delivery/orders/accept', {{
                method: 'POST',
                headers: {{ 'Content-Type': 'application/json' }},
                body: JSON.stringify({{ orderId, partnerId: loggedInPartner.id }})
            }});
            if (res.ok) {{
                alert('Order accepted! You can now simulate coordinates to track delivery.');
                location.reload();
            }} else {{
                alert('Failed to accept order');
            }}
        }}

        async function moveCoords(dir) {{
            if (!loggedInPartner) return;
            const delta = 0.0005;
            if (dir === 'N') partnerLat += delta;
            if (dir === 'S') partnerLat -= delta;
            if (dir === 'E') partnerLng += delta;
            if (dir === 'W') partnerLng -= delta;

            document.getElementById('coordsDisplay').innerText = `Latitude: $\{{partnerLat.toFixed(5)}} | Longitude: $\{{partnerLng.toFixed(5)}}`;

            await fetch('/api/delivery/update-location', {{
                method: 'POST',
                headers: {{ 'Content-Type': 'application/json' }},
                body: JSON.stringify({{
                    partnerId: loggedInPartner.id,
                    latitude: partnerLat,
                    longitude: partnerLng
                }})
            }});
        }}

        function toggleAutoSim() {{
            const btn = document.getElementById('btnAutoSim');
            if (autoSimInterval) {{
                clearInterval(autoSimInterval);
                autoSimInterval = null;
                btn.innerText = 'Auto-Simulate Route';
                btn.style.color = '#10b981';
                btn.style.borderColor = '#10b981';
            }} else {{
                btn.innerText = 'Stop Auto-Simulation';
                btn.style.color = '#ef4444';
                btn.style.borderColor = '#ef4444';
                autoSimInterval = setInterval(() => {{
                    partnerLat += 0.0002;
                    partnerLng += 0.0003;
                    document.getElementById('coordsDisplay').innerText = `Latitude: $\{{partnerLat.toFixed(5)}} | Longitude: $\{{partnerLng.toFixed(5)}}`;
                    
                    fetch('/api/delivery/update-location', {{
                        method: 'POST',
                        headers: {{ 'Content-Type': 'application/json' }},
                        body: JSON.stringify({{
                            partnerId: loggedInPartner.id,
                            latitude: partnerLat,
                            longitude: partnerLng
                        }})
                    }});
                }}, 3000);
            }}
        }}

        async function pollOrders() {{
            try {{
                const res = await fetch('/api/delivery/orders');
                if (res.ok) {{
                    const json = await res.json();
                    const newOrders = json.data || [];
                    
                    // Check if there are new orders that weren't present before
                    if (loggedInPartner && newOrders.length > orders.length && orders.length > 0) {{
                        showSmsNotification("New order placed by customer! Check UAT dashboard.");
                    }}
                    
                    orders = newOrders;
                    if (loggedInPartner) {{
                        renderConsoleOrders();
                    }}
                }}
            }} catch(e) {{
                console.error("Failed to poll orders:", e);
            }}
        }}

        function showSmsNotification(msg) {{
            document.getElementById('smsMessage').innerText = msg;
            document.getElementById('smsBanner').style.display = 'block';
            setTimeout(() => {{
                document.getElementById('smsBanner').style.display = 'none';
            }}, 6000);
        }}

        // Periodically poll backend database for new customer orders
        setInterval(pollOrders, 3000);
    </script>
</body>
</html>
"""


class ThreadingServer(socketserver.ThreadingMixIn, socketserver.TCPServer):
    daemon_threads = True
    allow_reuse_address = True

Handler = ApiHandler
with ThreadingServer(("", PORT), Handler) as httpd:
    print("Local backend API server active at port", PORT)
    print("Testing portal at http://localhost:3000")
    print("Admin panel at http://localhost:8080/admin")
    httpd.serve_forever()
