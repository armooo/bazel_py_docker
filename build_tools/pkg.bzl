def tar_pkg_impl(ctx):
    if not ctx.label.name.endswith('_tar'):
        fail('tar_pkg rule names must end in _tar')

    file_map = {}

    for files in ctx.attr.files:
        prefix_len = len(files.label.package) + 1
        root_runfiles_prefix = files.label.name + '.runfiles/'
        package_runfiles_prefix = root_runfiles_prefix + ctx.workspace_name + '/'

        for f in files.files:
            file_map[f.short_path[prefix_len:]] = f

        for f in files.data_runfiles.files:
            file_map[package_runfiles_prefix + f.short_path] = f

        for f in files.default_runfiles.files:
            file_map[package_runfiles_prefix + f.short_path] = f

    tar_manifest = ctx.new_file(ctx.label.name + '.manifest')
    ctx.file_action(
        tar_manifest,
        '\n'.join([
            tar_name + ' ' + f.path
            for tar_name, f in file_map.items()
        ])
    )

    tar_file = ctx.new_file(ctx.label.name[:-4] + '.tar')

    ctx.action(
        executable=ctx.executable._build_tar,
        arguments=[
            '-m', tar_manifest.path,
            '-o', tar_file.path
        ],
        inputs=file_map.values() + [tar_manifest],
        outputs=[tar_file],
        mnemonic='Building',
    )

    return struct(
        files=set([tar_file]),
    )



tar_pkg = rule(
    implementation=tar_pkg_impl,
    attrs={
        'files': attr.label_list(allow_files=True),
        '_build_tar': attr.label(default=Label('//build_tools:build_tar'), executable=True),
    },
)
