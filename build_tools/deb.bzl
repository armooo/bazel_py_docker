def deb_files_impl(ctx):
    deb_deps = [
        d
        for dep in ctx.attr.deps
        for d in dep.deb_deps
    ]
    deb_deps.extend(ctx.files.srcs)
    return struct(
        deb_deps=deb_deps
    )


deb_files = rule(
    implementation=deb_files_impl,
    attrs={
        'srcs': attr.label_list(allow_files=True),
        'deps': attr.label_list(
            allow_files=True,
            providers=['deb_deps'],
         ),
    },
)


def apt_fetch_impl(repository_ctx):
    url = repository_ctx.attr.url
    sha256 = repository_ctx.attr.sha256
    deps = repository_ctx.attr.deps

    dpkg = repository_ctx.which('dpkg')
    find = repository_ctx.which('find')

    out_dir = repository_ctx.path('.')

    path = repository_ctx.path(
        url.split('/')[-1]
    )
    repository_ctx.download(
        url,
        path,
        sha256,
    )

    repository_ctx.execute([
        dpkg, '-x', path, out_dir,
    ])

    deps_labels = [
        '@{dep}//:files'.format(dep=dep)
        for dep in deps
    ]

    build_file = """
load('@bazel_py_docker//build_tools:deb.bzl', 'deb_files')

deb_files(
    name='files',
    srcs=glob(['**/*'], exclude=['*.deb', 'WORKSPACE', 'BUILD']),
    deps={deps},
    visibility=['//visibility:public'],
)
    """.format(deps=repr(deps_labels))
    repository_ctx.file(
        repository_ctx.path('BUILD'),
        build_file,
    )


apt_fetch = repository_rule(
    implementation=apt_fetch_impl,
    attrs={
        'url': attr.string(
            mandatory=True,
        ),
        'sha256': attr.string(
            mandatory=True,
        ),
        'deps': attr.string_list(),
    },
)

