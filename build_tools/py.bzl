def py_library_impl(ctx):
    py_deps = [
        d
        for dep in ctx.attr.deps
        for d in getattr(dep, 'py_deps', [])
    ]
    py_deps_external = [
        d
        for dep in ctx.attr.deps
        for d in getattr(dep, 'py_deps_external', [])
    ]
    if ctx.attr.external:
        py_deps_external.extend(ctx.files.srcs)
    else:
        py_deps.extend(ctx.files.srcs)

    deb_deps = [
        d
        for dep in ctx.attr.deps
        for d in getattr(dep, 'deb_deps', [])
    ]

    return struct(
        deb_deps=deb_deps,
        py_deps=py_deps,
        py_deps_external=py_deps_external,
    )


py_library = rule(
    implementation=py_library_impl,
    attrs={
        'srcs': attr.label_list(allow_files=['.py', '.so']),
        'external': attr.bool(default=False),
        'deps': attr.label_list(
            providers=[
                ['py_deps'],
                ['py_deps_external'],
                ['deb_deps'],
            ],
        ),
        'external': attr.bool(default=False),
    }
)


def copy_files(ctx, files, name):
    if files:
        ctx.action(
            outputs=[i[1] for i in files],
            inputs=[i[0] for i in files],
            executable=ctx.executable.copy_files,
            arguments=[
                '{}={}'.format(i[0].path, i[1].path)
                for i in files
            ],
            progress_message='building {} {}'.format(name, ctx.label)
        )
    return [i[1] for i in files]


def py_binary_impl(ctx):
    files = [ctx.file.src]
    py_root_cp = []
    deb_root_cp = []

    py_root = ctx.label.name + '@py_root/'
    deb_root = ctx.label.name + '@deb_root/'

    symlinks = {}
    for dep in ctx.attr.deps + [ctx.attr.python]:
        files += getattr(dep, 'py_deps', [])
        for f in getattr(dep, 'py_deps_external', []):

            local_path = f.path
            if f.root.path:
                local_path = f.path[len(f.root.path) + 1:]
            local_path = local_path[len(f.owner.workspace_root) + 1:]

            py_file = ctx.new_file(py_root + local_path)
            py_root_cp.append([f, py_file])

        for f in getattr(dep, 'deb_deps', []):
            local_path = f.path[len(f.owner.workspace_root) + 1:]
            deb_file = ctx.new_file(deb_root + local_path)
            deb_root_cp.append([f, deb_file])

    files += copy_files(ctx, py_root_cp, 'py_root')
    files += copy_files(ctx, deb_root_cp, 'deb_root')

    run_script = ctx.new_file(ctx.label.name)
    sh_path = ''
    if run_script.owner.workspace_root:
        sh_path = run_script.owner.workspace_root + '/' + run_script.short_path
    else:
        sh_path = run_script.short_path

    ctx.template_action(
        template=ctx.files._py_run_tmpl[0],
        output=run_script,
        substitutions={
            '{python_script}': str(ctx.files.src[0].path),
            '{sh_script}': sh_path,
            '{workspace_name}': ctx.workspace_name,
            '{package}': ctx.label.package,
            '{name}': ctx.label.name,
        },
        executable=True,
    )

    return struct(
        files=set([run_script]),
        runfiles = ctx.runfiles(
            files=files,
            collect_data=True,
            collect_default=True,
        ),
    )


py_binary = rule(
    implementation=py_binary_impl,
    attrs={
        'src': attr.label(
            single_file=True,
            allow_files=['.py'],
        ),
        'deps': attr.label_list(),
        'python': attr.label(
            default=Label(
                '@python//:files',
                relative_to_caller_repository=True,
            ),
        ),
        '_py_run_tmpl': attr.label(
            allow_files=True,
            single_file=True,
            default=Label('//build_tools:py_run.tmpl'),
        ),
        'copy_files': attr.label(
            default=Label('//build_tools:copy_files'),
            executable=True,
        ),
    },
    executable=True,
)
