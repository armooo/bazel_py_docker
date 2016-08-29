load('@bazel_tools//tools/build_defs/docker:docker.bzl', 'docker_build')
load('//build_tools:py.bzl', 'py_binary', 'py_library')
load('//build_tools:pkg.bzl', 'tar_pkg')


# Some python code that depends on requests from pypi and PyMySQL from Debian.
py_library(
    name='hello_world_lib',
    srcs=['hello_world.py'],
    deps=[
        '@requests//:requests',
        '@python-mysqldb//:files',
    ]
)


# A python binary that wrappes hello_world_lib.
py_binary(
    name='hello_world',
    src='hello_world_helper.py',
    visibility=['//visibility:public'],
    deps=[
        ':hello_world_lib',
    ]
)


# A python wsgi server that shells out to hello_world.
py_binary(
    name='hello_world_server',
    src='wsgi_server.py',
    visibility=['//visibility:public'],
    deps=[
        ':hello_world',
    ]
)


# A tar file including hello_world_server and all of its dependicies.
tar_pkg(
    name='hello_world_server_tar',
    files=[':hello_world_server'],
)


# A docker image build on top of a jessie base image that installs our app in
# to /srv, runs it by default and exports port 8000 to the world.
docker_build(
    name='hello_world_image',
    base='@debian_jessie//:image',
    directory='/srv',
    tars=[':hello_world_server_tar'],
    entrypoint=['/srv/hello_world_server'],
    ports=['8000'],
    visibility=['//visibility:public'],
)
