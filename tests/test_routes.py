import importlib.util
import json
import os
from pathlib import Path
import tempfile
import threading
import unittest
from unittest.mock import patch
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

SCRIPTS = Path(__file__).resolve().parents[1] / 'skills/ld-unitysetup-online/scripts'
spec = importlib.util.spec_from_file_location('routes', SCRIPTS / 'probe_routes.py')
routes = importlib.util.module_from_spec(spec)
spec.loader.exec_module(routes)


class Handler(BaseHTTPRequestHandler):
    records = []

    def log_message(self, *args):
        pass

    def do_HEAD(self):
        self.respond()

    def do_GET(self):
        self.respond()

    def respond(self):
        self.records.append((self.command, dict(self.headers)))
        if self.path.startswith('/relative'):
            self.send_response(302)
            self.send_header('Location', '/ok')
        elif self.path.startswith('/china'):
            self.send_response(302)
            self.send_header('Location', 'https://unity.cn/releases?token=fixture-secret')
        elif self.path.startswith('/loop'):
            self.send_response(302)
            self.send_header('Location', '/loop')
        elif self.path.startswith('/bad'):
            self.send_response(503)
        else:
            self.send_response(200)
        self.end_headers()


@unittest.skipUnless(routes.shutil.which('curl.exe') or routes.shutil.which('curl'), 'curl required')
class RouteTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()
        cls.base = 'http://127.0.0.1:' + str(cls.server.server_port)

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join(timeout=3)

    def probe(self, path, **kwargs):
        with patch.dict(os.environ, {'NO_PROXY': '127.0.0.1,localhost', 'no_proxy': '127.0.0.1,localhost'}):
            return routes.trace(self.base + path, allow_loopback=True, timeout=3, **kwargs)

    def test_relative_location_reaches_original_host(self):
        result = self.probe('/relative')
        self.assertEqual('PASS', result['verdict'])
        self.assertEqual([302, 200], [h['status'] for h in result['hops']])

    def test_china_hop_fails_before_fetch_even_at_hop_limit(self):
        result = self.probe('/china', max_hops=0)
        self.assertEqual('FAIL', result['verdict'])
        self.assertEqual(1, len(result['hops']))
        self.assertNotIn('fixture-secret', json.dumps(result))

    def test_query_is_not_exposed(self):
        result = self.probe('/ok?token=fixture-secret')
        self.assertEqual('PASS', result['verdict'])
        self.assertNotIn('fixture-secret', json.dumps(result))

    def test_oauth_session_path_is_not_exposed(self):
        cleaned = routes.public_url('https://login.unity.com/en/conversations/private-session-id?code=fixture-secret')
        self.assertNotIn('private-session-id', cleaned)
        self.assertNotIn('fixture-secret', cleaned)

    def test_redirect_loop_is_not_pass(self):
        self.assertEqual('redirect_loop', self.probe('/loop')['reason'])

    def test_http_error_is_not_pass(self):
        self.assertEqual('WARN', self.probe('/bad')['verdict'])

    def test_binary_uses_head_and_curlrc_cookies_are_ignored(self):
        with tempfile.TemporaryDirectory() as temp:
            Path(temp, '.curlrc').write_text('cookie = "secret=fixture-secret"\n')
            with patch.dict(os.environ, {'CURL_HOME': temp}):
                result = self.probe('/setup.exe')
        self.assertEqual('HEAD', result['hops'][0]['method'])
        self.assertNotIn('Cookie', Handler.records[-1][1])

    def test_host_boundary_and_public_tls_requirement(self):
        self.assertTrue(routes.china_host('download.unitychina.cn'))
        self.assertFalse(routes.china_host('unity.cn.example.org'))
        with self.assertRaises(ValueError):
            routes.validate_url('http://unity.com/releases/editor/archive')
        with self.assertRaises(ValueError):
            routes.validate_url('https://user:password@unity.com/')


if __name__ == '__main__':
    unittest.main()
