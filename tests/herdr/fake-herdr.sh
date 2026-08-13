#!/usr/bin/env bash
# Fake herdr v0.8.0 CLI for contract tests. JSON shapes mirror observed v0.8.0
# output (wave-0 spike evidence). State lives in FAKE_HERDR_STATE; every
# invocation is appended to FAKE_HERDR_LOG as:
#   session=<name> <%q-escaped argv...> [text=<%q typed command>]   (pane run)
set -u

STATE="${FAKE_HERDR_STATE:?FAKE_HERDR_STATE must point at a writable state dir}"
LOG="${FAKE_HERDR_LOG:?FAKE_HERDR_LOG must point at a writable log file}"

session=""
while [[ $# -gt 0 ]]; do
  case "$1" in
  --session)
    session="$2"
    shift 2
    ;;
  --session=*)
    session="${1#--session=}"
    shift
    ;;
  *) break ;;
  esac
done

log_invocation() {
  local line="session=${session:-<default>}" a text
  for a in "$@"; do line+=" $(printf '%q' "$a")"; done
  if [[ ${1:-} == "pane" && ${2:-} == "run" && $# -ge 4 ]]; then
    shift 2
    shift
    text="$*"
    line+=" text=$(printf '%q' "$text")"
  fi
  printf '%s\n' "$line" >>"$LOG"
}
log_invocation "$@"

session_dir() { printf '%s/sessions/%s' "$STATE" "$1"; }
pane_dir() { printf '%s/panes/%s' "$(session_dir "$1")" "${2//:/_}"; }
socket_path() { printf '%s/.config/herdr/sessions/%s/herdr.sock' "$HOME" "$1"; }

server_alive() {
  local f pid
  f="$(session_dir "$1")/server.pid"
  [[ -f $f ]] || return 1
  pid=$(<"$f")
  [[ -n $pid ]] && kill -0 "$pid" 2>/dev/null
}

require_server() {
  if [[ -z $session ]] || ! server_alive "$session"; then
    printf '{"id":"cli:%s","error":{"code":"server_not_running","message":"no herdr server is running at %s; run `herdr session attach %s` to start or attach it"}}\n' \
      "$1" "$(socket_path "${session:-default}")" "${session:-default}"
    exit 1
  fi
}

prompt() { printf 'fake@herdr:%s > ' "$1" >>"$2"; }

cmd="${1:-}"
case "$cmd" in
--version | -V)
  echo "herdr 0.8.0"
  ;;
"")
  echo "fake-herdr: TUI attach is not simulated; server state unchanged" >&2
  ;;
status)
  printf 'client:\n  version: 0.8.0  channel: stable  protocol: 19\n\n'
  if [[ -n $session ]] && server_alive "$session"; then
    printf 'server:\n  status: running\n  version: 0.8.0\n  protocol: 19\n  compatible: yes\n  socket: %s\n' "$(socket_path "$session")"
  else
    printf 'server:\n  status: not running\n  socket: %s\n' "$(socket_path "${session:-default}")"
  fi
  printf '\nupdate:\n  restart_needed: no\n'
  ;;
server)
  if server_alive "$session"; then
    echo "fake-herdr: server already running for session $session" >&2
    exit 0
  fi
  mkdir -p "$(session_dir "$session")/panes" "$(dirname "$(socket_path "$session")")"
  : >"$(socket_path "$session")"
  printf '%s' "$$" >"$(session_dir "$session")/server.pid"
  printf 'herdr server running; you can use any herdr CLI command in another terminal.\napi socket: %s\n' "$(socket_path "$session")"
  while :; do sleep 3600; done
  ;;
workspace)
  sub="${2:-}"
  case "$sub" in
  list)
    require_server "workspace:list"
    sdir="$(session_dir "$session")"
    focused=""
    [[ -f $sdir/focused ]] && focused=$(<"$sdir/focused")
    first=1
    printf '{"id":"cli:workspace:list","result":{"type":"workspace_list","workspaces":['
    for wdir in "$sdir"/workspaces/w*/; do
      [[ -d $wdir ]] || continue
      wid=$(basename "$wdir")
      label=$(<"$wdir/label")
      num="${wid#w}"
      foc=false
      if [[ -n $focused ]]; then
        [[ $focused == "$wid" ]] && foc=true
      else
        [[ $num == 1 ]] && foc=true
      fi
      ((first)) || printf ','
      first=0
      jq -nc --arg wid "$wid" --arg label "$label" --argjson num "$num" --argjson foc "$foc" \
        '{active_tab_id:($wid+":t1"),agent_status:"unknown",focused:$foc,label:$label,number:$num,pane_count:1,tab_count:1,workspace_id:$wid}'
    done
    printf ']}}\n'
    ;;
  create)
    require_server "workspace:create"
    shift 2
    cwd="$PWD"
    label=""
    do_focus=false
    while [[ $# -gt 0 ]]; do
      case "$1" in
      --cwd)
        cwd="$2"
        shift 2
        ;;
      --label)
        label="$2"
        shift 2
        ;;
      --focus)
        do_focus=true
        shift
        ;;
      --no-focus) shift ;;
      --env) shift 2 ;;
      *) shift ;;
      esac
    done
    sdir="$(session_dir "$session")"
    lock="$STATE/.lock"
    while ! mkdir "$lock" 2>/dev/null; do sleep 0.02; done
    num=1
    while [[ -d $sdir/workspaces/w$num ]]; do num=$((num + 1)); done
    mkdir -p "$sdir/workspaces/w$num"
    rmdir "$lock"
    wid="w$num"
    pane_id="$wid:p1"
    shell_pid=$((10000 + num))
    [[ -z $label ]] && label="$num"
    printf '%s' "$label" >"$sdir/workspaces/w$num/label"
    $do_focus && printf '%s' "$wid" >"$sdir/focused"
    pdir="$(pane_dir "$session" "$pane_id")"
    mkdir -p "$pdir"
    printf '%s' "$cwd" >"$pdir/cwd"
    printf '%s' "$shell_pid" >"$pdir/shell-pid"
    transcript="$pdir/transcript"
    : >"$transcript"
    prompt "$cwd" "$transcript"
    term_id=$(printf 'term_fake%08d' "$num")
    jq -nc \
      --arg cwd "$cwd" --arg label "$label" --arg wid "$wid" \
      --arg pane "$pane_id" --arg tab "$wid:t1" --arg term "$term_id" \
      '{id:"cli:workspace:create",result:{root_pane:{agent_status:"unknown",cwd:$cwd,focused:true,foreground_cwd:$cwd,pane_id:$pane,revision:0,scroll:{max_offset_from_bottom:0,offset_from_bottom:0,viewport_rows:24},tab_id:$tab,terminal_id:$term,workspace_id:$wid},tab:{agent_status:"unknown",focused:true,label:"1",number:1,pane_count:1,tab_id:$tab,workspace_id:$wid},type:"workspace_created",workspace:{active_tab_id:$tab,agent_status:"unknown",focused:true,label:$label,number:1,pane_count:1,tab_count:1,workspace_id:$wid}}}'
    ;;
  get)
    require_server "workspace:get"
    wid="${3:-}"
    sdir="$(session_dir "$session")"
    if [[ ! -d $sdir/workspaces/$wid ]]; then
      printf '{"id":"cli:workspace:get","error":{"code":"workspace_not_found","message":"no workspace with id %s"}}\n' "$wid"
      exit 1
    fi
    label=$(<"$sdir/workspaces/$wid/label")
    num="${wid#w}"
    jq -nc --arg wid "$wid" --arg label "$label" --argjson num "$num" \
      '{id:"cli:workspace:get",result:{type:"workspace_info",workspace:{active_tab_id:($wid+":t1"),agent_status:"unknown",focused:false,label:$label,number:$num,pane_count:1,tab_count:1,workspace_id:$wid}}}'
    ;;
  focus)
    require_server "workspace:focus"
    wid="${3:-}"
    sdir="$(session_dir "$session")"
    if [[ ! -d $sdir/workspaces/$wid ]]; then
      printf '{"id":"cli:workspace:focus","error":{"code":"workspace_not_found","message":"no workspace with id %s"}}\n' "$wid"
      exit 1
    fi
    printf '%s' "$wid" >"$sdir/focused"
    jq -nc --arg wid "$wid" \
      '{id:"cli:workspace:focus",result:{type:"workspace_focused",workspace_id:$wid}}'
    ;;
  *)
    echo "fake-herdr: unknown workspace subcommand: ${2:-}" >&2
    exit 2
    ;;
  esac
  ;;
pane)
  sub="${2:-}"
  case "$sub" in
  list)
    require_server "pane:list"
    sdir="$(session_dir "$session")"
    first=1
    printf '{"id":"cli:pane:list","result":{"type":"pane_list","panes":['
    for pdir in "$sdir"/panes/*/; do
      [[ -d $pdir ]] || continue
      key=$(basename "$pdir")
      pane_id="${key/_/:}"
      wid="${pane_id%%:*}"
      cwd=$(<"$pdir/cwd")
      ((first)) || printf ','
      first=0
      jq -nc --arg pane "$pane_id" --arg wid "$wid" --arg tab "$wid:t1" --arg cwd "$cwd" \
        '{agent_status:"unknown",cwd:$cwd,focused:false,foreground_cwd:$cwd,pane_id:$pane,revision:0,tab_id:$tab,workspace_id:$wid}'
    done
    printf ']}}\n'
    ;;
  get)
    require_server "pane:get"
    pane_id="${3:-}"
    pdir="$(pane_dir "$session" "$pane_id")"
    if [[ ! -d $pdir ]]; then
      printf '{"id":"cli:pane:get","error":{"code":"pane_not_found","message":"no pane with id %s"}}\n' "$pane_id"
      exit 1
    fi
    cwd=$(<"$pdir/cwd")
    wid="${pane_id%%:*}"
    jq -nc --arg cwd "$cwd" --arg pane "$pane_id" --arg tab "$wid:t1" --arg wid "$wid" \
      '{id:"cli:pane:get",result:{pane:{agent_status:"unknown",cwd:$cwd,focused:true,foreground_cwd:$cwd,pane_id:$pane,revision:0,scroll:{max_offset_from_bottom:0,offset_from_bottom:0,viewport_rows:24},tab_id:$tab,terminal_id:"term_fake00000001",workspace_id:$wid},type:"pane_info"}}'
    ;;
  process-info)
    require_server "pane:process_info"
    shift 2
    pane_id=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
      --pane)
        pane_id="$2"
        shift 2
        ;;
      *) shift ;;
      esac
    done
    pdir="$(pane_dir "$session" "$pane_id")"
    if [[ ! -d $pdir ]]; then
      printf '{"id":"cli:pane:process_info","error":{"code":"pane_not_found","message":"no pane with id %s"}}\n' "$pane_id"
      exit 1
    fi
    shell_pid=$(<"$pdir/shell-pid")
    cwd=$(<"$pdir/cwd")
    fg_pid=""
    if [[ -f $pdir/fg.pid ]]; then
      cand=$(<"$pdir/fg.pid")
      if [[ -n $cand ]] && kill -0 "$cand" 2>/dev/null; then
        fg_pid="$cand"
      fi
    fi
    if [[ -n $fg_pid ]]; then
      fg_name=$(<"$pdir/fg.name")
      fg_cmd=$(<"$pdir/fg.cmd")
      jq -nc --arg pane "$pane_id" --arg cwd "$cwd" --arg name "$fg_name" --arg cmdline "$fg_cmd" \
        --argjson shell "$shell_pid" --argjson fg "$fg_pid" \
        '{id:"cli:pane:process_info",result:{process_info:{foreground_process_group_id:$fg,foreground_processes:[{argv:[$cmdline],cmdline:$cmdline,cwd:$cwd,name:$name,pid:$fg}],pane_id:$pane,shell_pid:$shell},type:"pane_process_info"}}'
    else
      jq -nc --arg pane "$pane_id" --arg cwd "$cwd" \
        --argjson shell "$shell_pid" \
        '{id:"cli:pane:process_info",result:{process_info:{foreground_process_group_id:$shell,foreground_processes:[{argv:["/run/current-system/sw/bin/zsh"],cmdline:"/run/current-system/sw/bin/zsh",cwd:$cwd,name:"zsh",pid:$shell}],pane_id:$pane,shell_pid:$shell},type:"pane_process_info"}}'
    fi
    ;;
  run)
    require_server "pane:run"
    pane_id="${3:-}"
    shift 3
    pdir="$(pane_dir "$session" "$pane_id")"
    if [[ ! -d $pdir ]]; then
      printf '{"id":"cli:pane:run","error":{"code":"pane_not_found","message":"no pane with id %s"}}\n' "$pane_id"
      exit 1
    fi
    text="$*"
    cwd=$(<"$pdir/cwd")
    transcript="$pdir/transcript"
    printf '%s\n' "$text" >>"$transcript"
    # setsid: pane processes belong to the server session, so they must
    # outlive the client pty that invoked `pane run` (SIGHUP on pty close).
    setsid bash -c '
          cwd=$1; text=$2; transcript=$3
          cd "$cwd" 2>/dev/null || true
          bash -c "$text" >>"$transcript" 2>&1
          printf "fake@herdr:%s > " "$cwd" >>"$transcript"
        ' _ "$cwd" "$text" "$transcript" &
    fpid=$!
    printf '%s' "$fpid" >"$pdir/fg.pid"
    first_word="${text%%[[:space:]]*}"
    printf '%s' "${first_word##*/}" >"$pdir/fg.name"
    printf '%s' "$text" >"$pdir/fg.cmd"
    ;;
  read)
    require_server "pane:read"
    pane_id="${3:-}"
    shift 3
    lines=1000
    while [[ $# -gt 0 ]]; do
      case "$1" in
      --lines)
        lines="$2"
        shift 2
        ;;
      --source | --format) shift 2 ;;
      --ansi | --raw) shift ;;
      *) shift ;;
      esac
    done
    pdir="$(pane_dir "$session" "$pane_id")"
    if [[ ! -d $pdir ]]; then
      printf '{"id":"cli:pane:read","error":{"code":"pane_not_found","message":"no pane with id %s"}}\n' "$pane_id"
      exit 1
    fi
    tail -n "$lines" "$pdir/transcript"
    ;;
  report-metadata)
    require_server "pane:report_metadata"
    pane_id="${3:-}"
    shift 3
    source="" token="" ttl=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
      --source)
        source="$2"
        shift 2
        ;;
      --token)
        token="$2"
        shift 2
        ;;
      --ttl-ms)
        ttl="$2"
        shift 2
        ;;
      *) shift ;;
      esac
    done
    printf '%s\t%s\t%s\t%s\n' "$pane_id" "$source" "$token" "$ttl" \
      >>"$(session_dir "$session")/metadata.log"
    ;;
  *)
    echo "fake-herdr: unknown pane subcommand: $sub" >&2
    exit 2
    ;;
  esac
  ;;
*)
  echo "fake-herdr: unknown command: $cmd" >&2
  exit 2
  ;;
esac
