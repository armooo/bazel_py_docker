from wsgiref.simple_server import make_server
import os
import subprocess


def simple_app(environ, start_response):
    status = '200 OK'
    headers = [('Content-type', 'text/plain')]

    start_response(status, headers)

    helper_path = os.path.join(
        os.environ['WORKSPACE_RUNFILES'],
        'demo/hello_world_helper',
    )
    out = subprocess.check_output(helper_path)

    return [out]


httpd = make_server('', 8000, simple_app)
print "Serving on port 8000..."
httpd.serve_forever()
