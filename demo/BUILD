load('@bazel_tools//tools/build_defs/docker:docker.bzl', 'docker_build')
load('//build_tools:py.bzl', 'py_binary', 'py_library')
load('//build_tools:pkg.bzl', 'tar_pkg')


py_library(
    name='hello_world_lib',
    srcs=['hello_world.py'],
    deps=[
        '@requests//:requests',
        '@python-mysqldb//:files',
    ]
)

py_binary(
    name='hello_world_helper',
    src='hello_world_helper.py',
    visibility=['//visibility:public'],
    deps=[
        ':hello_world_lib',
    ]
)

py_binary(
    name='hello_world',
    src='wsgi_server.py',
    visibility=['//visibility:public'],
    deps=[
        ':hello_world_helper',
    ]
)


tar_pkg(
    name='hello_world_tar',
    files=['hello_world'],
)


docker_build(
    name='test_app',
    base='@debian_jessie//:image',
    directory='/srv',
    tars=[':hello_world_tar'],
    entrypoint=['/srv/hello_world'],
    ports=['8000'],
    visibility=['//visibility:public'],
)
