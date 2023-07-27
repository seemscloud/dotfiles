umask 0022

alias ls='ls --color=auto --hide=".*"'
alias rm="rm -iv"
alias cp="cp -iv"
alias mv="mv -iv"
alias rmdir="rmdir -v"
alias graph="git log --graph --abbrev-commit --decorate=full --all --color=always --date=iso --log-size --raw --stat"

alias k="kubectl"
complete -o default -F __start_kubectl k

alias kctx="kubectx"
complete -o default -F _kube_contexts kctx

alias kns="kubenx"
complete -o default -F _kube_namespaces kns

bashrc_branch() {
  if git branch >/dev/null 2>&1 ; then
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1) /'
  fi
}

bashrc_kube() {
  if kubectl config view --minify -o jsonpath="{}" >/dev/null 2>&1 ; then
    printf "%*s\r%s" $(( COLUMNS-1 )) "$(kubectl config view --minify -o jsonpath="{.clusters[].name}/{.contexts[].context.namespace}")"
  fi
}

bashrc_cursor(){
  [[ "${UID}" == "0" ]] && echo '#' || echo '$'
}

export PS1="\[\e[1;34m\]\$(bashrc_kube)\[\e[m\][\[\e[32m\]\u\[\e[m\]]@[\[\e[1;34m\]\h\[\e[m\]][\[\e[1;36m\]\W\[\e[m\]]\$(bashrc_cursor) \[\e[33m\]\$(bashrc_branch)\[\e[m\]"
export HISTSIZE="10000"
export HISTFILESIZE="10000"
export HISTTIMEFORMAT="%Y-%m-%d %T "
export EDITOR="vim"
