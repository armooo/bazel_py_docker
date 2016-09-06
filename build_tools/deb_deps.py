import apt
import re
import sys


class RequiredPackage(object):
    def __init__(self, version, deps):
        self.version = version
        self.deps = deps


def get_required_version(package_name):
    cache = apt.Cache()
    requirments = []
    seen = set()
    packages = [cache[package_name]]

    while packages:
        package = packages.pop()
        seen.add(package)

        # We only care about the newest versions and the results seems sorted
        # to me
        version = package.versions[0]

        # We assume the base system has all required packages
        if version.priority == 'required':
            continue

        dep_names = set()
        for deps in version.dependencies:
            if deps:
                dep_name = deps[0].name.split(':')[0]
                dep_pkg = cache[dep_name]
                if dep_pkg.versions[0].priority != 'required':
                    dep_names.add(dep_name)
                if dep_name not in seen:
                    packages.append(dep_pkg)

        requirments.append(RequiredPackage(version, dep_names))

    return requirments


def escape_name(name):
    return re.sub(r'[^A-Za-z0-9-_.]', '_', name)


def indent(s, depth):
    return ' ' * depth + s


def generate_apt_fetch(package, indent_depth=4):
    rule = []
    rule.append(indent('apt_fetch(', indent_depth))
    rule.append(indent('name=\'{}\','.format(
        escape_name(package.version.package.name)),
        indent_depth + 4,
    ))
    rule.append(indent(
        'url=\'{}\','.format(package.version.uri),
        indent_depth + 4,
    ))
    rule.append(indent(
        'sha256=\'{}\','.format(package.version.sha256),
        indent_depth + 4,
    ))
    rule.append(indent('deps=[', indent_depth + 4))
    for dep in sorted(package.deps):
        rule.append(indent(
            '\'{}\','.format(escape_name(dep)),
            indent_depth + 8,
        ))
    rule.append(indent(']', indent_depth + 4))
    rule.append(indent(')', indent_depth))
    return '\n'.join(rule)


def main(package_list_file, output_filename):
    packages = []
    with open(package_list_file) as package_list:
        for package_name in package_list:
            packages.extend(get_required_version(package_name.strip()))

    packages_by_name = {
        pkg.version.package.name: pkg
        for pkg in packages
    }

    packages = packages_by_name.values()
    packages.sort(key=lambda x: x.version.package.name)

    with open(output_filename, 'w') as output:
        output.write(
            'load(\'@bazel_py_docker//build_tools:deb.bzl\', '
            '\'apt_fetch\')\n'
        )
        output.write('\n')
        output.write('def load_apt():\n')
        for package in packages:
            rule = generate_apt_fetch(package)
            output.write(rule)
            output.write('\n\n')

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
