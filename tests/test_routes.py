import importlib.util
import json
import os
import subprocess
import sys
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
        """Serve deterministic routes, including malformed redirects and misleading headers."""
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
        elif self.path.startswith('/status-header'):
            self.send_response(503)
            self.send_header('X-Trace', 'LD_STATUS:200')
        elif self.path.startswith('/invalid-port'):
            self.send_response(302)
            self.send_header('Location', 'https://unity.com:fixture-secret/')
        elif self.path.startswith('/invalid-host'):
            self.send_response(302)
            self.send_header('Location', 'https://[fixture-secret]/')
        elif self.path.startswith('/downgrade'):
            self.send_response(302)
            self.send_header('Location', 'http://unity.com/download?token=fixture-secret')
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

    def test_response_header_cannot_override_actual_status(self):
        """Use a real curl request to ensure header text cannot turn HTTP 503 into PASS."""
        result = self.probe('/status-header')
        self.assertEqual('WARN', result['verdict'])
        self.assertEqual(503, result['finalStatus'])
        self.assertEqual(503, result['hops'][0]['status'])

    def test_invalid_redirects_are_reported_without_fetch_or_secret(self):
        """Keep malformed and insecure redirects local to their route and redact details."""
        for path in ('/invalid-port', '/invalid-host', '/downgrade'):
            with self.subTest(path=path):
                before = len(Handler.records)
                # Zero remaining hops must still validate the response's next target.
                result = self.probe(path, max_hops=0)
                self.assertEqual('WARN', result['verdict'])
                self.assertEqual('invalid_redirect_url', result['reason'])
                self.assertEqual(1, len(result['hops']))
                self.assertEqual(before + 1, len(Handler.records))
                self.assertNotIn('fixture-secret', json.dumps(result))

    def test_cli_keeps_other_routes_after_invalid_redirect(self):
        """The CLI must emit usable JSON for every endpoint after a bad redirect."""
        env = dict(os.environ, NO_PROXY='127.0.0.1,localhost', no_proxy='127.0.0.1,localhost')
        call = subprocess.run(
            [sys.executable, '-B', str(SCRIPTS / 'probe_routes.py'), '--json',
             '--allow-loopback-test', '--timeout', '3', '--url', self.base + '/invalid-port',
             '--url', self.base + '/ok'], capture_output=True, text=True, env=env, timeout=15)
        # A failed endpoint must not discard evidence from an independent successful one.
        self.assertEqual(1, call.returncode, call.stderr)
        output = json.loads(call.stdout)
        self.assertEqual(['WARN', 'PASS'], [item['verdict'] for item in output['routes']])
        self.assertNotIn('fixture-secret', call.stdout + call.stderr)

    def test_cli_json_preserves_unicode_with_ascii_stdout(self):
        """Legacy stdout encodings must not prevent JSON reports or corrupt Unicode URLs."""
        url = 'https://unity.cn/\u6d4b\u8bd5'
        # This domain is classified before a request, keeping the real CLI test offline.
        call = subprocess.run(
            [sys.executable, '-B', str(SCRIPTS / 'probe_routes.py'), '--json', '--url', url],
            capture_output=True, env=dict(os.environ, PYTHONIOENCODING='ascii'), timeout=15)
        self.assertEqual(2, call.returncode, call.stderr.decode('ascii'))
        output = json.loads(call.stdout.decode('ascii'))
        self.assertEqual('FAIL', output['verdict'])
        self.assertEqual(url, output['routes'][0]['url'])
        self.assertEqual(url, output['routes'][0]['hops'][0]['url'])
        self.assertTrue(output['routes'][0]['hops'][0]['notRequested'])

    def test_malformed_input_validation_does_not_echo_input(self):
        """Reject malformed input before requests without leaking urllib's raw details."""
        for url in ('https://unity.com:fixture-secret/', 'https://[fixture-secret]/'):
            with self.subTest(url=url), self.assertRaises(ValueError) as raised:
                routes.validate_url(url)
            self.assertNotIn('fixture-secret', str(raised.exception))

    def test_malformed_proxy_is_rejected_without_request_or_details(self):
        """Malformed proxy input must not disclose raw parsing details or start curl."""
        for proxy in ('http://localhost:fixture-secret/', 'http://[fixture-secret]/'):
            with self.subTest(proxy=proxy), patch.object(routes.subprocess, 'run') as run:
                with self.assertRaises(ValueError) as raised:
                    routes.trace('https://unity.com/download', proxy=proxy)
                self.assertNotIn('fixture-secret', str(raised.exception))
                run.assert_not_called()

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
