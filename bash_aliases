# Helper shortcuts
alias cls='clear && ls -l'
alias lsa='ls -al'

# NeoVim helper
alias vim='nvim'

# Project Specific
alias tfo="terraform output -raw kubeconfig > kube.config && export KUBECONFIG=${HOME}/web-prod/kube.config"

kns() {
    if [ -z "$1" ]; then
    namespace=$(kubectl get namespace --no-headers | fzf | awk '{ print $1}')
    kubectl config set-context --current --namespace=${namespace}
    echo "Namespace changed to: $namespace"
  else
    kubectl config set-context --current --namespace="$1"
  fi
}