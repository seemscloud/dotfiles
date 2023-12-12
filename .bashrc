umask 0022

###################################
#
#     Branch Name is PS1
#
sc_helper_bashrc_branch() {
  if git branch >/dev/null 2>&1; then
    git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1) /'
  fi
}

###################################
#
#     Kube Info on Right of Console
#
sc_helper_bashrc_kube() {
  if kubectl config view --minify -o jsonpath="{}" >/dev/null 2>&1; then
    printf "%*s\r%s" $((COLUMNS - 1)) "$(kubectl config view --minify -o jsonpath="{.clusters[].name}/{.contexts[].context.namespace}")"
  fi
}

###################################
#
#     Cursor Character
#
sc_helper_bashrc_cursor() {
  [[ "${UID}" == "0" ]] && echo '#' || echo '$'
}

###################################
#
#     Others
#
sc_helper_x509_decode (){
  if [ -z "${1}" ] ; then
    while IFS= read -r LINE; do
      lines="${lines}${LINE}\n"
    done
    echo -e "${lines}" | openssl x509 -noout -text
  else
    openssl x509 -noout -text -in "${1}"
  fi
}

sc_helper_x509_san_names(){
  SAN_NAMES=""

  for i in $(echo "${1}" | tr ',' '\n') ; do
    SAN_NAMES="DNS:${i},${SAN_NAMES}"
  done

  echo "$(echo "${SAN_NAMES}" | sed "s/,$//g")"
}

sc_helper_x509_ca_make() {
  [ -z "${1}" ] && CA_NAME="ca" || CA_NAME="${1}"
  [ -z "${2}" ] && CN_NAME="Root CA" || CN_NAME="${2}"

  echo "Generate CA: ${CA_NAME}/${CN_NAME}"

  openssl req \
    -nodes -x509 -days 3650 -newkey rsa:4096 \
    -subj "/CN=${CN_NAME}" \
    -keyout "${CA_NAME}".key.pem -out "${CA_NAME}".crt.pem
}

sc_helper_x509_ca_make_leaf() {
  [ -z "${1}" ] && CA_NAME="ca" || CA_NAME="${1}"
  [ -z "${2}" ] && LEAF_NAME="leaf" || LEAF_NAME="${2}"

  [ ! -f "${CA_NAME}".crt.pem ] && [ ! -f "${CA_NAME}".key.pem ] && sc_helper_x509_ca_make "${CA_NAME}"

  echo "Generate Certificate: ${CA_NAME}/${LEAF_NAME}"

  openssl req \
    -nodes -new -newkey rsa:2048 \
    -subj "/CN=${LEAF_NAME}" \
    -keyout "${CA_NAME}-${LEAF_NAME}".key.pem -out "${CA_NAME}-${LEAF_NAME}".csr.pem

  if [ -z "${3}" ] ; then
    openssl x509 \
      -req -days 730 \
      -CA "${CA_NAME}".crt.pem -CAkey "${CA_NAME}".key.pem -CAcreateserial \
      -in "${CA_NAME}-${LEAF_NAME}".csr.pem -out "${CA_NAME}-${LEAF_NAME}".crt.pem
  else
    SAN_NAMES="$(sc_helper_x509_san_names ${3})"

    openssl x509 \
      -req -days 730 \
      -CA "${CA_NAME}".crt.pem -CAkey "${CA_NAME}".key.pem -CAcreateserial \
      -in "${CA_NAME}-${LEAF_NAME}".csr.pem -out "${CA_NAME}-${LEAF_NAME}".crt.pem \
      -extfile <(printf "subjectAltName=${SAN_NAMES}")
  fi
}

sc_helper_curl_format_file(){
cat > .curl-timing-format.txt << EndOfMessage
\t%{time_namelookup}s\tNamelookup (DNS)\n
\t%{time_connect}s\tConnect (TCP)\n
\t%{time_appconnect}s\tApp Connect (SSL/SSH/etc.)\n
\t%{time_pretransfer}s\tPretransfer (just before want to start sending)\n
\t%{time_starttransfer}s\tStart Transfer (first byte + Pretransfer)\n
\t%{time_redirect}s\tRedirect (all before final request)\n
------------------------------\n
\t%{time_total}s:\tTotal\n
EndOfMessage
}

sc_helper_tcp_linux_check(){
  [ -z "${1}" ] && DEST_NAME="google.com" || DEST_NAME="${1}"
  [ -z "${2}" ] && DEST_PORT="80" || DEST_PORT="${2}"

  timeout 5 bash -c "(echo > /dev/tcp/${DEST_NAME}/${DEST_PORT}) >/dev/null 2>&1 && echo UP || echo DOWN" || echo TIMEOUT
}

sc_helper_git_log_n_commits(){
  [ -z "${1}" ] && N_COMMITS="5" || N_COMMITS="${1}"

  git log -n "${N_COMMITS}" --oneline --format='%h' | xargs -I {} sh -c 'git diff {}^..{}'
}

###################################
#
#     Exportsx
#
export PS1="\[\e[1;34m\]\$(sc_helper_bashrc_kube)\[\e[m\][\[\e[32m\]\u\[\e[m\]]@[\[\e[1;34m\]\h\[\e[m\]][\[\e[1;36m\]\W\[\e[m\]]\$(sc_helper_bashrc_cursor) \[\e[33m\]\$(sc_helper_bashrc_branch)\[\e[m\]"
export HISTSIZE="10000"
export HISTFILESIZE="10000"
export HISTTIMEFORMAT="%Y-%m-%d %T "
export EDITOR="vim"
