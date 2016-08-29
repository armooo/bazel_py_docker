load('//build_tools:docker.bzl', 'docker_pull')
load('//build_tools:pypi.bzl', 'pip_bootstrap', 'pypi')
load('//apt:pkgs.bzl', 'load_apt')

load_apt()
pip_bootstrap()

pypi(
    name='requests',
    version='2.10.0',
)

docker_pull(
    name='debian_jessie',
    repository='debian',
    digest='sha256:ffb60fdbc401b2a692eef8d04616fca15905dce259d1499d96521970ed0bec36',
)

docker_pull(
    name='centos_7',
    repository='centos',
    digest='sha256:81e4f2f663eaa1bf46ff9be348396dd7053734b257ef4147d7133d6f25bbf7cf',
)
