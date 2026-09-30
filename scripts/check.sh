#!/bin/sh
# Structural check: the skills, their aliases and the OpenCode commands must fit together.
set -u

root=$(git rev-parse --show-toplevel) || exit 1
cd "$root" || exit 1

errors=0
fail() {
    echo "error: $*" >&2
    errors=$((errors + 1))
}

# Print the first line of the frontmatter block ($2 is the key), if any.
frontmatter() {
    sed -n '1{/^---[[:space:]]*$/!q};1d;/^---[[:space:]]*$/q;s/^'"$2"':[[:space:]]*//p' "$1" | sed -n 1p
}

for dir in skills/*/; do
    name=${dir#skills/}
    name=${name%/}
    file=${dir}SKILL.md

    if [ ! -f "$file" ]; then
        fail "$dir: SKILL.md is missing"
        continue
    fi

    fm_name=$(frontmatter "$file" name)
    fm_desc=$(frontmatter "$file" description)
    [ -n "$fm_name" ] || fail "$file: frontmatter has no 'name:'"
    [ -n "$fm_desc" ] || fail "$file: frontmatter has no 'description:'"
    if [ -n "$fm_name" ] && [ "$fm_name" != "$name" ]; then
        fail "$file: name '$fm_name' differs from folder name '$name'"
    fi

    case $name in
    wf-*)
        targets=$(grep -o '\.\./[^/[:space:]`]*/SKILL\.md' "$file" | sort -u)
        if [ -z "$targets" ]; then
            fail "$file: alias does not reference any ../<target>/SKILL.md"
        fi
        for target in $targets; do
            [ -f "$dir/$target" ] || fail "$file: alias points to $target, which does not exist"
        done
        ;;
    esac

    [ -f "opencode/commands/$name.md" ] ||
        fail "$name: no matching opencode/commands/$name.md"
done

if [ "$errors" -gt 0 ]; then
    echo "check failed: $errors problem(s)" >&2
    exit 1
fi
echo "check passed"
