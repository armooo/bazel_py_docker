def docker_pull_impl(repository_ctx):
    repository_ctx.file(
        repository_ctx.path('WORKSPACE'),
        'workspace(name=\'{}\')'.format(
            repository_ctx.name,
        ),
    )

    image_name = '{}@{}'.format(
        repository_ctx.attr.repository,
        repository_ctx.attr.digest,
    )
    repository_ctx.execute(
        ['docker', 'pull', image_name]
    )

    image_path = repository_ctx.path('docker_save.tar')
    repository_ctx.execute(
        ['docker', 'save', '-o', image_path, image_name]
    )


    build_file = """
load('@bazel_tools//tools/build_defs/docker:docker.bzl', 'docker_build')

genrule(
    name='layer',
    srcs=['docker_save.tar'],
    outs=['layer.tar'],
    tools=['@//build_tools:flatten_image'],
    cmd='$(location @//build_tools:flatten_image) $< $@',
)

docker_build(
    name='image',
    tars=[':layer'],
    visibility=['//visibility:public'],
)
    """
    repository_ctx.file(
        repository_ctx.path('BUILD'),
        build_file,
    )


docker_pull = repository_rule(
    implementation=docker_pull_impl,
    attrs={
        'repository': attr.string(mandatory=True),
        'digest': attr.string(mandatory=True),
    },
)
