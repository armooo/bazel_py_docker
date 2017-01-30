def pypi_library_impl(ctx):
    out_path = ctx.configuration.bin_dir.path + '/' + ctx.label.workspace_root

    ctx.action(
        inputs=[ctx.file.src,],
        outputs=ctx.outputs.outs,
        executable=ctx.executable._pip,
        arguments=[
            'install',
            '--no-cache-dir',
            '--no-deps',
            '--upgrade',
            '--target', out_path,
            ctx.file.src.path,
        ],
    )
    return struct(
        py_deps_external=ctx.outputs.outs,
    )


pypi_library = rule(
    implementation=pypi_library_impl,
    attrs={
        'src': attr.label(
            allow_single_file=['.whl'],
        ),
        'outs': attr.output_list(
            mandatory=True,
            non_empty=True,
        ),
        '_pip': attr.label(
            default=Label('@pip_bootstrap//pip:pip_exe'),
            executable=True,
            cfg='host',
        ),
    }
)


def pypi_impl(repository_ctx):
    result = repository_ctx.execute([
        repository_ctx.path(repository_ctx.attr._pypi_get),
        repository_ctx.path('.'),
        repository_ctx.name,
        repository_ctx.attr.version,
    ])
    if result.return_code:
        fail('failed to get wheel:\nstdout:\n{}\nstderr:\n{}'.format(
            result.stdout, result.stderr,
        ))


pypi = repository_rule(
    implementation=pypi_impl,
    attrs={
        'version': attr.string(mandatory=True),
        '_pypi_get': attr.label(
            default=Label('//build_tools:pypi_get.sh', ),
            executable=True,
            cfg='host',
        ),
    },
)


PIP_BUILD = """
load('@bazel_py_docker//build_tools:py.bzl', 'py_binary', 'py_library')
py_library(
   name='pip_lib',
   external=True,
   srcs=glob(['**/*.py'], exclude=['__main__.py']),
)

py_binary(
   name='pip_exe',
   src='__main__.py',
   deps=[':pip_lib'],
   visibility=['//visibility:public'],
)
"""


def pip_bootstrap_impl(repository_ctx):
    repository_ctx.download(
        'https://bootstrap.pypa.io/3.2/get-pip.py',
        'get-pip.py',
        '2cc501b7dc0c3f17f8c352d69e541fda3fa658eb7a03764427a81e9c10d2dbd0',
        True,
    )
    result = repository_ctx.execute([
        repository_ctx.path('get-pip.py'),
        '--target', repository_ctx.path('.'),
    ])
    if result.return_code:
        print('get-pip failed\nstdout:\n{}\nstderr:{}'.format(
            result.stdout, result.stderr,
        ))

    repository_ctx.file(
        'pip/BUILD',
        PIP_BUILD,
    )


pip_bootstrap_internal = repository_rule(
    implementation=pip_bootstrap_impl,
)


def pip_bootstrap():
    pip_bootstrap_internal(name='pip_bootstrap')
