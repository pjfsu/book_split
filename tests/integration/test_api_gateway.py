# tests/integration/test_api_gateway.py

import requests
import pytest

BASE_URL = "http://api-gateway"

@pytest.mark.parametrize("path, expected_fragment", [
    ("/health", "OK"),
    ("/bookmarks/", "bookmarks-service stub"),
    ("/split/",      "split-service stub"),
])
def test_proxies_to_stub(path, expected_fragment):
    """
    Hitting each path on the gateway should return a 200
    and the stub text from our http-echo services.
    """
    resp = requests.get(f"{BASE_URL}{path}")
    assert resp.status_code == 200
    assert expected_fragment in resp.text
