import apt
import sys


def get_required_version(package_name):
    cache = apt.Cache()
    versions = []
    seen = set()
    packages = [cache[package_name]]

    while packages:
        package = packages.pop()
        seen.add(package)

        version = package.versions[0]
        if version.priority == 'required':
            continue
        versions.append(version)
        for deps in version.dependencies:
            if deps:
                dep_name = deps[0].name.split(':')[0]
                if dep_name not in seen:
                    packages.append(cache[dep_name])

    return versions


def generate_apt_fetch(package_name, versions):
    rule = []
    rule.append('apt_fetch(')
    rule.append('    name=\'{}\','.format(package_name))
    rule.append('    packages={')
    for version in versions:
        rule.append('        \'{}\':'.format(version.uri))
        rule.append('         \'{}\','.format(version.sha256))
    rule.append('    }')
    rule.append(')')
    return '\n'.join(rule)


def main(package_name):
    versions = get_required_version(package_name)
    rule = generate_apt_fetch(package_name, versions)
    print '# ==== start {} ===='.format(package_name)
    print rule
    print '# ==== end {} ======'.format(package_name)


if __name__ == '__main__':
    main(sys.argv[1])
