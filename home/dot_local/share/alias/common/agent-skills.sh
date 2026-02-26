# Agent Skills Management
# Unified skills location: ~/.config/agent-skills/

export AGENT_SKILLS_DIR="${HOME}/.config/agent-skills"
export AGENT_SKILLS_CONF="${HOME}/.config/agent-skills.yaml"

_nskill_platforms() {
    echo "claude codex gemini trae-cn trae antigravity"
}

_nskill_get_platform_path() {
    local platform="$1"
    echo "${HOME}/.$platform/skills"
}

_nskill_is_local_only() {
    local skill="$1"
    if [[ -f "$AGENT_SKILLS_CONF" ]]; then
        grep -q -- "^[[:space:]]*-[[:space:]]*${skill}[[:space:]]*$" "$AGENT_SKILLS_CONF" 2>/dev/null
    else
        return 1
    fi
}

_nskill_add_local_only() {
    local skill="$1"
    if [[ ! -f "$AGENT_SKILLS_CONF" ]]; then
        cat > "$AGENT_SKILLS_CONF" << 'EOF'
# Agent Skills 配置
local_only:
EOF
    fi
    if ! _nskill_is_local_only "$skill"; then
        if grep -q "^local_only:" "$AGENT_SKILLS_CONF"; then
            sed -i '' "/^local_only:/a\\
  - $skill" "$AGENT_SKILLS_CONF"
        else
            echo -e "\nlocal_only:\n  - $skill" >> "$AGENT_SKILLS_CONF"
        fi
    fi
}

_nskill_remove_local_only() {
    local skill="$1"
    if [[ -f "$AGENT_SKILLS_CONF" ]]; then
        sed -i '' "/^[[:space:]]*-[[:space:]]*${skill}[[:space:]]*\$/d" "$AGENT_SKILLS_CONF"
    fi
}

_nskill_get_local_only_list() {
    if [[ -f "$AGENT_SKILLS_CONF" ]]; then
        grep "^[[:space:]]*-[[:space:]]*" "$AGENT_SKILLS_CONF" 2>/dev/null | sed 's/^[[:space:]]*-[[:space:]]*//'
    fi
}

_nskill_distribute_single() {
    local skill_name="$1"
    local skill_dir="$AGENT_SKILLS_DIR/$skill_name"
    local platforms=$(_nskill_platforms)
    
    for platform in $platforms; do
        local target_dir=$(_nskill_get_platform_path "$platform")
        local parent_dir="${target_dir%/*}"
        
        if [[ -d "$parent_dir" ]]; then
            mkdir -p "$target_dir"
            local target_skill_dir="$target_dir/$skill_name"
            
            if [[ -L "$target_skill_dir" ]]; then
                rm "$target_skill_dir"
            elif [[ -d "$target_skill_dir" ]]; then
                continue
            fi
            
            ln -sf "$skill_dir" "$target_skill_dir"
            echo "   ✅ Linked to $platform"
        fi
    done
}

_nskill_is_pinned() {
    local skill_name="$1"
    local source_file="$AGENT_SKILLS_DIR/$skill_name/.source"
    if [[ -f "$source_file" ]]; then
        grep -q "^pinned=true" "$source_file" 2>/dev/null
    else
        return 1
    fi
}

_nskill_do_update() {
    local skill_name="$1"
    local force="$2"
    local skill_dir="$AGENT_SKILLS_DIR/$skill_name"
    local source_file="$skill_dir/.source"
    
    if [[ ! -f "$source_file" ]]; then
        echo "⏭️  $skill_name: no remote source, skipping"
        return 0
    fi
    
    if [[ "$force" != "true" ]] && _nskill_is_pinned "$skill_name"; then
        echo "📌 $skill_name: pinned, skipping (use -f to force)"
        return 0
    fi
    
    local url=$(grep "^url=" "$source_file" | cut -d= -f2-)
    local branch=$(grep "^branch=" "$source_file" | cut -d= -f2-)
    local downloaded=$(grep "^downloaded=" "$source_file" | cut -d= -f2-)
    local pinned=$(grep "^pinned=" "$source_file" | cut -d= -f2-)
    
    if [[ -z "$url" ]]; then
        echo "⏭️  $skill_name: invalid source file, skipping"
        return 0
    fi
    
    local git_url="$url" subdir=""
    if [[ "$url" == *"github.com/"*"/tree/"* ]]; then
        local path_part="${url#*github.com/}"
        local gh_owner="${path_part%%/*}"
        path_part="${path_part#*/}"
        local gh_repo="${path_part%%/*}"
        path_part="${path_part#*/tree/}"
        local gh_branch="${path_part%%/*}"
        subdir="${path_part#*/}"
        
        if [[ -n "$gh_owner" && -n "$gh_repo" && -n "$gh_branch" && -n "$subdir" ]]; then
            git_url="https://github.com/$gh_owner/$gh_repo.git"
            [[ -z "$branch" ]] && branch="$gh_branch"
        fi
    fi
    
    echo "🔄 Updating $skill_name..."
    echo "   Source: $url"
    [[ -n "$branch" ]] && echo "   Branch: $branch"
    [[ -n "$subdir" ]] && echo "   Subdir: $subdir"
    [[ -n "$downloaded" ]] && echo "   Last download: $downloaded"
    
    local is_local=$(_nskill_is_local_only "$skill_name" && echo "true" || echo "false")
    
    local tmp_dir=$(mktemp -d)
    local clone_args=("--depth" "1")
    [[ -n "$branch" ]] && clone_args+=("--branch" "$branch")
    [[ -n "$subdir" ]] && clone_args+=("--filter=blob:none" "--sparse")
    
    local tmp_err="${tmp_dir}/err.log"
    if git clone "${clone_args[@]}" "$git_url" "$tmp_dir/repo" 2>"$tmp_err"; then
        if [[ -n "$subdir" ]]; then
            (cd "$tmp_dir/repo" && git sparse-checkout set "$subdir" 2>/dev/null)
            if [[ ! -d "$tmp_dir/repo/$subdir" ]]; then
                echo "   ❌ Subdirectory not found: $subdir"
                rm -rf "$tmp_dir"
                return 1
            fi
            rm -rf "$skill_dir"
            mv "$tmp_dir/repo/$subdir" "$skill_dir"
        else
            rm -rf "$tmp_dir/repo/.git"
            rm -rf "$skill_dir"
            mv "$tmp_dir/repo" "$skill_dir"
        fi
        
        rm -rf "$tmp_dir"
        
        cat > "$skill_dir/.source" << EOF
url=$url
branch=$branch
downloaded=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
pinned=$pinned
EOF
        
        if [[ "$is_local" == "false" ]] && command -v chezmoi &>/dev/null; then
            chezmoi add "$skill_dir" 2>/dev/null
        fi
        
        _nskill_distribute_single "$skill_name"
        echo "   ✅ Updated successfully"
    else
        echo "   ❌ Failed to update"
        if [[ -s "$tmp_err" ]]; then
            local err_msg=$(grep -E "^(fatal|error):" "$tmp_err" | head -1)
            [[ -n "$err_msg" ]] && echo "   $err_msg"
        fi
        rm -rf "$tmp_dir"
    fi
}

nskill() {
    local cmd="${1:-}"
    shift 2>/dev/null
    
    case "$cmd" in
        ls|list)
            _nskill_cmd_list "$@"
            ;;
        new|create)
            _nskill_cmd_new "$@"
            ;;
        edit)
            _nskill_cmd_edit "$@"
            ;;
        rm|remove|delete)
            _nskill_cmd_rm "$@"
            ;;
        sync)
            _nskill_cmd_sync "$@"
            ;;
        download|dl)
            _nskill_cmd_download "$@"
            ;;
        update|up)
            _nskill_cmd_update "$@"
            ;;
        pin)
            _nskill_cmd_pin "$@"
            ;;
        unpin)
            _nskill_cmd_unpin "$@"
            ;;
        local)
            _nskill_cmd_local "$@"
            ;;
        upload)
            _nskill_cmd_upload "$@"
            ;;
        platforms)
            _nskill_cmd_platforms "$@"
            ;;
        info)
            _nskill_cmd_info "$@"
            ;;
        help|--help|-h|"")
            _nskill_cmd_help
            ;;
        *)
            echo "Unknown command: $cmd"
            echo "Run 'nskill help' for usage"
            return 1
            ;;
    esac
}

_nskill_cmd_help() {
    cat << 'EOF'
nskill - Agent Skills Manager

Usage: nskill <command> [options]

Commands:
  ls, list              List all skills
  new <name>            Create a new skill
  edit <name>           Edit skill's SKILL.md
  rm <name>             Remove a skill
  sync [path]           Sync skills across platforms (or import from path)
  download <url>        Download skill from git repository
  update [name]         Update skill(s) from remote source
  pin <name>            Pin skill version (disable auto-update)
  unpin <name>          Unpin skill (enable auto-update)
  local <name>          Mark skill as local-only (no chezmoi upload)
  upload <name>         Remove local-only mark and upload to chezmoi
  platforms             Show platform symlink status
  info <name>           Show skill details
  help                  Show this help

Examples:
  nskill new my-skill
  nskill download https://github.com/user/skill
  nskill update --all
  nskill pin my-skill
EOF
}

_nskill_cmd_list() {
    echo "📦 Available Agent Skills:"
    echo ""
    
    local local_only_list=$(_nskill_get_local_only_list)
    local has_skills=false
    
    for skill_dir in "$AGENT_SKILLS_DIR"/*/; do
        if [[ -d "$skill_dir" ]]; then
            local skill_name=$(basename "$skill_dir")
            has_skills=true
            
            local tags=""
            if echo "$local_only_list" | grep -q "^$skill_name$"; then
                tags+="local "
            else
                tags+="upload "
            fi
            if [[ -f "$skill_dir/.source" ]]; then
                if _nskill_is_pinned "$skill_name"; then
                    tags+="📌"
                else
                    tags+="🔗"
                fi
            fi
            
            local desc=""
            if [[ -f "$skill_dir/SKILL.md" ]]; then
                desc=$(grep -A1 "^description:" "$skill_dir/SKILL.md" 2>/dev/null | tail -1 | sed 's/^[- ]*//' | cut -c1-50)
            fi
            
            printf "  %-12s %s\n" "[$tags]" "$skill_name"
            [[ -n "$desc" ]] && echo "              $desc..."
        fi
    done
    
    if [[ "$has_skills" == false ]]; then
        echo "  (no skills installed)"
    fi
    
    echo ""
    echo "Legend: 🔗=remote source, 📌=pinned"
}

_nskill_cmd_new() {
    local local_flag=false
    local name=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --local|-l) local_flag=true; shift ;;
            -*) echo "Unknown option: $1"; return 1 ;;
            *) name="$1"; shift ;;
        esac
    done
    
    if [[ -z "$name" ]]; then
        echo "Usage: nskill new [--local] <skill-name>"
        return 1
    fi
    
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    local skill_dir="$AGENT_SKILLS_DIR/$name"
    
    if [[ -d "$skill_dir" ]]; then
        echo "❌ Skill '$name' already exists"
        return 1
    fi
    
    mkdir -p "$skill_dir"
    cat > "$skill_dir/SKILL.md" << EOF
---
name: $name
description: Describe what this skill does and when to use it.
---

## Overview

Brief description of the skill.

## Steps

1. First step
2. Second step

## Examples

Provide examples of usage.
EOF
    
    if [[ "$local_flag" == true ]]; then
        _nskill_add_local_only "$name"
        echo "✅ Created local-only skill: $name"
    else
        echo "✅ Created skill: $name"
    fi
    echo "   Edit: $skill_dir/SKILL.md"
}

_nskill_cmd_edit() {
    local name="${1:-}"
    if [[ -z "$name" ]]; then
        echo "Usage: nskill edit <skill-name>"
        return 1
    fi
    
    local skill_file="$AGENT_SKILLS_DIR/$name/SKILL.md"
    if [[ -f "$skill_file" ]]; then
        ${EDITOR:-vim} "$skill_file"
    else
        echo "❌ Skill '$name' not found"
        return 1
    fi
}

_nskill_cmd_rm() {
    local name="${1:-}"
    local force=false
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--force) force=true; shift ;;
            -*) echo "Unknown option: $1"; return 1 ;;
            *) name="$1"; shift ;;
        esac
    done
    
    if [[ -z "$name" ]]; then
        echo "Usage: nskill rm [-f] <skill-name>"
        return 1
    fi
    
    local skill_dir="$AGENT_SKILLS_DIR/$name"
    if [[ ! -d "$skill_dir" ]]; then
        echo "❌ Skill '$name' not found"
        return 1
    fi
    
    if [[ "$force" != true ]]; then
        echo -n "Delete skill '$name'? [y/N] "
        read -r confirm
        [[ "$confirm" != "y" && "$confirm" != "Y" ]] && { echo "Cancelled."; return 0; }
    fi
    
    local platforms=$(_nskill_platforms)
    for platform in $platforms; do
        local link="$(_nskill_get_platform_path "$platform")/$name"
        if [[ -L "$link" ]]; then
            rm "$link" && echo "   🗑️  Removed link: $platform"
        elif [[ -e "$link" ]]; then
            rm -rf "$link" && echo "   🗑️  Removed dir: $platform"
        fi
    done
    
    rm -rf "$skill_dir" && echo "   🗑️  Removed: ~/.config/agent-skills/$name"
    
    if command -v chezmoi &>/dev/null; then
        local chezmoi_path=$(chezmoi source-path "$skill_dir" 2>/dev/null)
        if [[ -n "$chezmoi_path" && -d "$chezmoi_path" ]]; then
            rm -rf "$chezmoi_path" && echo "   🗑️  Removed: chezmoi source"
        fi
    fi
    
    _nskill_remove_local_only "$name"
    echo "✅ Deleted: $name"
}

_nskill_cmd_sync() {
    local import_path=""
    local local_flag=false
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --local|-l) local_flag=true; shift ;;
            -*) echo "Unknown option: $1"; return 1 ;;
            *) import_path="$1"; shift ;;
        esac
    done
    
    mkdir -p "$AGENT_SKILLS_DIR"
    
    if [[ -n "$import_path" ]]; then
        import_path="${import_path%/}"
        [[ ! -d "$import_path" ]] && { echo "❌ Directory not found: $import_path"; return 1; }
        
        local skill_name="${import_path##*/}"
        local target="$AGENT_SKILLS_DIR/$skill_name"
        
        [[ -d "$target" ]] && rm -rf "$target"
        cp -r "$import_path" "$target"
        echo "✅ Imported: $skill_name"
        
        if [[ "$local_flag" == true ]]; then
            _nskill_add_local_only "$skill_name"
        elif command -v chezmoi &>/dev/null; then
            chezmoi add "$target" 2>/dev/null
        fi
        
        _nskill_distribute_single "$skill_name"
        return 0
    fi
    
    echo "🔄 Syncing agent skills..."
    echo ""
    
    echo "Phase 1: Collecting from platforms..."
    local platforms=$(_nskill_platforms)
    for platform in $platforms; do
        local platform_skills=$(_nskill_get_platform_path "$platform")
        if [[ -d "$platform_skills" ]]; then
            for skill_path in "$platform_skills"/*/; do
                if [[ -d "$skill_path" && ! -L "$skill_path" ]]; then
                    local skill_name=$(basename "$skill_path")
                    [[ "$skill_name" == ".system" || "$skill_name" == "*" ]] && continue
                    local target="$AGENT_SKILLS_DIR/$skill_name"
                    if [[ ! -d "$target" ]]; then
                        cp -r "$skill_path" "$target"
                        echo "  📥 $skill_name (from $platform)"
                    fi
                fi
            done
        fi
    done
    
    echo ""
    echo "Phase 2: Uploading to chezmoi..."
    if command -v chezmoi &>/dev/null; then
        for skill_dir in "$AGENT_SKILLS_DIR"/*/; do
            if [[ -d "$skill_dir" ]]; then
                local skill_name=$(basename "$skill_dir")
                if ! _nskill_is_local_only "$skill_name"; then
                    local chezmoi_path=$(chezmoi source-path "$skill_dir" 2>/dev/null)
                    [[ -z "$chezmoi_path" || ! -d "$chezmoi_path" ]] && \
                        chezmoi add "$skill_dir" 2>/dev/null && echo "  ☁️  $skill_name"
                fi
            fi
        done
    fi
    
    echo ""
    echo "Phase 3: Distributing to platforms..."
    for platform in $platforms; do
        local target_dir=$(_nskill_get_platform_path "$platform")
        local parent_dir="${target_dir%/*}"
        
        if [[ -d "$parent_dir" ]]; then
            mkdir -p "$target_dir"
            for skill_dir in "$AGENT_SKILLS_DIR"/*/; do
                if [[ -d "$skill_dir" ]]; then
                    local skill_name=$(basename "$skill_dir")
                    local target_skill_dir="$target_dir/$skill_name"
                    [[ -L "$target_skill_dir" ]] && rm "$target_skill_dir"
                    [[ -d "$target_skill_dir" ]] && continue
                    ln -sf "$skill_dir" "$target_skill_dir"
                fi
            done
            echo "  ✅ $platform"
        fi
    done
    
    echo ""
    echo "✨ Sync complete!"
}

_nskill_cmd_download() {
    local url="" local_flag=false branch="" skill_name="" subdir=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --local|-l) local_flag=true; shift ;;
            --branch|-b) branch="$2"; shift 2 ;;
            --name|-n) skill_name="$2"; shift 2 ;;
            -*) echo "Unknown option: $1"; return 1 ;;
            *) url="$1"; shift ;;
        esac
    done
    
    if [[ -z "$url" ]]; then
        echo "Usage: nskill download [options] <git-url>"
        echo ""
        echo "Options:"
        echo "  -l, --local        Mark as local-only"
        echo "  -b, --branch <br>  Specify branch/tag"
        echo "  -n, --name <name>  Override skill name"
        echo ""
        echo "Supports:"
        echo "  - Full repo: https://github.com/user/repo"
        echo "  - Subdirectory: https://github.com/user/repo/tree/main/path/to/skill"
        return 1
    fi
    
    command -v git &>/dev/null || { echo "❌ git required"; return 1; }
    
    local git_url="$url"
    if [[ "$url" == *"github.com/"*"/tree/"* ]]; then
        local path_part="${url#*github.com/}"
        local gh_owner="${path_part%%/*}"
        path_part="${path_part#*/}"
        local gh_repo="${path_part%%/*}"
        path_part="${path_part#*/tree/}"
        local gh_branch="${path_part%%/*}"
        subdir="${path_part#*/}"
        
        if [[ -n "$gh_owner" && -n "$gh_repo" && -n "$gh_branch" && -n "$subdir" ]]; then
            git_url="https://github.com/$gh_owner/$gh_repo.git"
            [[ -z "$branch" ]] && branch="$gh_branch"
            [[ -z "$skill_name" ]] && skill_name=$(basename "$subdir" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
            echo "📂 Detected subdirectory: $subdir"
        fi
    fi
    
    [[ -z "$skill_name" ]] && skill_name=$(basename "$git_url" .git | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    
    local target="$AGENT_SKILLS_DIR/$skill_name"
    if [[ -d "$target" ]]; then
        echo -n "⚠️  '$skill_name' exists. Update? [y/N] "
        read -r confirm
        [[ "$confirm" != "y" && "$confirm" != "Y" ]] && { echo "Cancelled."; return 0; }
        rm -rf "$target"
    fi
    
    mkdir -p "$AGENT_SKILLS_DIR"
    echo "📥 Downloading: $git_url"
    [[ -n "$branch" ]] && echo "   Branch: $branch"
    [[ -n "$subdir" ]] && echo "   Subdir: $subdir"
    
    local tmp_dir=$(mktemp -d)
    local clone_args=("--depth" "1")
    [[ -n "$branch" ]] && clone_args+=("--branch" "$branch")
    
    if [[ -n "$subdir" ]]; then
        clone_args+=("--filter=blob:none" "--sparse")
    fi
    
    local tmp_err="${tmp_dir}/err.log"
    if git clone "${clone_args[@]}" "$git_url" "$tmp_dir/repo" 2>"$tmp_err"; then
        if [[ -n "$subdir" ]]; then
            (cd "$tmp_dir/repo" && git sparse-checkout set "$subdir" 2>/dev/null)
            if [[ -d "$tmp_dir/repo/$subdir" ]]; then
                mv "$tmp_dir/repo/$subdir" "$target"
            else
                echo "❌ Subdirectory not found: $subdir"
                rm -rf "$tmp_dir"
                return 1
            fi
        else
            mv "$tmp_dir/repo" "$target"
        fi
        
        rm -rf "$target/.git"
        rm -rf "$tmp_dir"
        
        cat > "$target/.source" << EOF
url=$url
branch=$branch
downloaded=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
pinned=false
EOF
        
        [[ ! -f "$target/SKILL.md" ]] && echo "⚠️  No SKILL.md found"
        echo "✅ Downloaded: $skill_name"
        
        if [[ "$local_flag" == true ]]; then
            _nskill_add_local_only "$skill_name"
            echo "   (local-only)"
        elif command -v chezmoi &>/dev/null; then
            chezmoi add "$target" 2>/dev/null && echo "   ☁️  Uploaded to chezmoi"
        fi
        
        _nskill_distribute_single "$skill_name"
    else
        echo "❌ Clone failed"
        [[ -s "$tmp_err" ]] && grep -E "^(fatal|error):" "$tmp_err" | head -1
        rm -rf "$tmp_dir"
        return 1
    fi
}

_nskill_cmd_update() {
    local name="" all_flag=false force_flag=false
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all|-a) all_flag=true; shift ;;
            --force|-f) force_flag=true; shift ;;
            -*) echo "Unknown option: $1"; return 1 ;;
            *) name="$1"; shift ;;
        esac
    done
    
    if [[ "$all_flag" == false && -z "$name" ]]; then
        echo "Usage: nskill update [options] <skill-name>"
        echo "       nskill update --all"
        echo ""
        echo "Options:"
        echo "  -a, --all    Update all remote skills"
        echo "  -f, --force  Force update (ignore pin)"
        echo ""
        echo "Skills with remote source:"
        local has_source=false
        for skill_dir in "$AGENT_SKILLS_DIR"/*/; do
            if [[ -f "$skill_dir/.source" ]]; then
                local sname=$(basename "$skill_dir")
                local surl=$(grep "^url=" "$skill_dir/.source" | cut -d= -f2-)
                local pin_icon=""
                _nskill_is_pinned "$sname" && pin_icon=" 📌"
                echo "  $sname$pin_icon"
                echo "    └─ $surl"
                has_source=true
            fi
        done
        [[ "$has_source" == false ]] && echo "  (none)"
        return 1
    fi
    
    local force_str="false"
    [[ "$force_flag" == true ]] && force_str="true"
    
    if [[ "$all_flag" == true ]]; then
        echo "🔄 Updating all skills..."
        echo ""
        local updated=0 skipped=0 pinned=0
        for skill_dir in "$AGENT_SKILLS_DIR"/*/; do
            if [[ -d "$skill_dir" ]]; then
                local sname=$(basename "$skill_dir")
                if [[ -f "$skill_dir/.source" ]]; then
                    if [[ "$force_str" != "true" ]] && _nskill_is_pinned "$sname"; then
                        echo "📌 $sname: pinned, skipping"
                        ((pinned++))
                    else
                        _nskill_do_update "$sname" "$force_str"
                        ((updated++))
                    fi
                else
                    ((skipped++))
                fi
            fi
        done
        echo ""
        echo "✨ Done! Updated: $updated, Pinned: $pinned, No source: $skipped"
    else
        [[ ! -d "$AGENT_SKILLS_DIR/$name" ]] && { echo "❌ Skill '$name' not found"; return 1; }
        [[ ! -f "$AGENT_SKILLS_DIR/$name/.source" ]] && { echo "❌ No remote source"; return 1; }
        
        if [[ "$force_flag" == false ]]; then
            echo -n "Update '$name'? [y/N] "
            read -r confirm
            [[ "$confirm" != "y" && "$confirm" != "Y" ]] && { echo "Cancelled."; return 0; }
        fi
        
        _nskill_do_update "$name" "$force_str"
    fi
}

_nskill_cmd_pin() {
    local name="${1:-}"
    [[ -z "$name" ]] && { echo "Usage: nskill pin <skill-name>"; return 1; }
    
    local source_file="$AGENT_SKILLS_DIR/$name/.source"
    [[ ! -f "$source_file" ]] && { echo "❌ Skill '$name' has no remote source"; return 1; }
    
    if _nskill_is_pinned "$name"; then
        echo "ℹ️  '$name' is already pinned"
        return 0
    fi
    
    if grep -q "^pinned=" "$source_file"; then
        sed -i '' "s/^pinned=.*/pinned=true/" "$source_file"
    else
        echo "pinned=true" >> "$source_file"
    fi
    
    if command -v chezmoi &>/dev/null && ! _nskill_is_local_only "$name"; then
        chezmoi add "$AGENT_SKILLS_DIR/$name" 2>/dev/null
    fi
    
    echo "📌 Pinned: $name (auto-update disabled)"
}

_nskill_cmd_unpin() {
    local name="${1:-}"
    [[ -z "$name" ]] && { echo "Usage: nskill unpin <skill-name>"; return 1; }
    
    local source_file="$AGENT_SKILLS_DIR/$name/.source"
    [[ ! -f "$source_file" ]] && { echo "❌ Skill '$name' has no remote source"; return 1; }
    
    if ! _nskill_is_pinned "$name"; then
        echo "ℹ️  '$name' is not pinned"
        return 0
    fi
    
    sed -i '' "s/^pinned=.*/pinned=false/" "$source_file"
    
    if command -v chezmoi &>/dev/null && ! _nskill_is_local_only "$name"; then
        chezmoi add "$AGENT_SKILLS_DIR/$name" 2>/dev/null
    fi
    
    echo "🔓 Unpinned: $name (auto-update enabled)"
}

_nskill_cmd_local() {
    local name="${1:-}"
    [[ -z "$name" ]] && { echo "Usage: nskill local <skill-name>"; return 1; }
    [[ ! -d "$AGENT_SKILLS_DIR/$name" ]] && { echo "❌ Skill '$name' not found"; return 1; }
    
    if _nskill_is_local_only "$name"; then
        echo "ℹ️  '$name' is already local-only"
        return 0
    fi
    
    _nskill_add_local_only "$name"
    
    if command -v chezmoi &>/dev/null; then
        local chezmoi_path=$(chezmoi source-path "$AGENT_SKILLS_DIR/$name" 2>/dev/null)
        if [[ -n "$chezmoi_path" && -d "$chezmoi_path" ]]; then
            rm -rf "$chezmoi_path"
            echo "   🗑️  Removed from chezmoi source"
        fi
    fi
    
    echo "✅ Marked '$name' as local-only"
}

_nskill_cmd_upload() {
    local name="${1:-}"
    [[ -z "$name" ]] && { echo "Usage: nskill upload <skill-name>"; return 1; }
    [[ ! -d "$AGENT_SKILLS_DIR/$name" ]] && { echo "❌ Skill '$name' not found"; return 1; }
    
    if ! _nskill_is_local_only "$name"; then
        echo "ℹ️  '$name' is not local-only"
        return 0
    fi
    
    _nskill_remove_local_only "$name"
    
    if command -v chezmoi &>/dev/null; then
        chezmoi add "$AGENT_SKILLS_DIR/$name" 2>/dev/null
        echo "   ☁️  Uploaded to chezmoi"
    fi
    
    echo "✅ Removed local-only mark from '$name'"
}

_nskill_cmd_platforms() {
    echo "🔗 Platform symlink status:"
    echo ""
    
    local platforms=$(_nskill_platforms)
    for platform in $platforms; do
        local path=$(_nskill_get_platform_path "$platform")
        local parent="${path%/*}"
        
        if [[ -d "$parent" ]]; then
            if [[ -d "$path" ]]; then
                local count=$(find "$path" -maxdepth 1 -type l 2>/dev/null | wc -l | tr -d ' ')
                echo "  ✅ $platform: $count skills"
            else
                echo "  ⚠️  $platform: no skills dir"
            fi
        else
            echo "  ⏭️  $platform: not installed"
        fi
    done
}

_nskill_cmd_info() {
    local name="${1:-}"
    [[ -z "$name" ]] && { echo "Usage: nskill info <skill-name>"; return 1; }
    
    local skill_dir="$AGENT_SKILLS_DIR/$name"
    [[ ! -d "$skill_dir" ]] && { echo "❌ Skill '$name' not found"; return 1; }
    
    echo "📦 Skill: $name"
    echo "   Path: $skill_dir"
    
    if _nskill_is_local_only "$name"; then
        echo "   Storage: local-only"
    else
        echo "   Storage: synced to chezmoi"
    fi
    
    if [[ -f "$skill_dir/.source" ]]; then
        local url=$(grep "^url=" "$skill_dir/.source" | cut -d= -f2-)
        local branch=$(grep "^branch=" "$skill_dir/.source" | cut -d= -f2-)
        local downloaded=$(grep "^downloaded=" "$skill_dir/.source" | cut -d= -f2-)
        
        echo "   Remote: $url"
        [[ -n "$branch" ]] && echo "   Branch: $branch"
        [[ -n "$downloaded" ]] && echo "   Downloaded: $downloaded"
        
        if _nskill_is_pinned "$name"; then
            echo "   Auto-update: disabled (pinned 📌)"
        else
            echo "   Auto-update: enabled"
        fi
    else
        echo "   Remote: (none - local skill)"
    fi
    
    if [[ -f "$skill_dir/SKILL.md" ]]; then
        local desc=$(grep -A1 "^description:" "$skill_dir/SKILL.md" 2>/dev/null | tail -1 | sed 's/^[- ]*//')
        [[ -n "$desc" ]] && echo "   Description: $desc"
    fi
}
