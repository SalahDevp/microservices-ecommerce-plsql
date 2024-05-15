import requests


def redirect(req, service_url):
    return requests.request(
        method=req.method,
        url=f"{service_url}/{req.full_path}",
        headers={key: value for key, value in req.headers if key != "Host"},
        data=req.get_data(),
        cookies=req.cookies,
        allow_redirects=False,
    )
