def deb_files_impl(ctx):
    return struct(
        deb_deps=ctx.files.srcs
    )


deb_files = rule(
    implementation=deb_files_impl,
    attrs={
        'srcs': attr.label_list(allow_files=True)
    },
)


def apt_fetch_impl(repository_ctx):
    packages = repository_ctx.attr.packages

    dpkg = repository_ctx.which('dpkg')
    find = repository_ctx.which('find')

    out_dir = repository_ctx.path('.')

    for url, sha256 in packages.items():
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

    build_file = """
load('@//build_tools:deb.bzl', 'deb_files')

deb_files(
    name='files',
    srcs=glob(['**/*'], exclude=['*.deb']),
    visibility=['//visibility:public'],
)
    """
    repository_ctx.file(
        repository_ctx.path('BUILD'),
        build_file,
    )


apt_fetch = repository_rule(
    implementation=apt_fetch_impl,
    attrs={
        'packages': attr.string_dict(
            mandatory=True,
            non_empty=True,
        ),
    },
)

