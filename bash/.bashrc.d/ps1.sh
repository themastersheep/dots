# fast-prompt: zero-fork prompt with git branch + worktree support
_prompt_update() {
  local exit_code=$?
  local d=$PWD head root line

  if [[ $exit_code -eq 0 ]]; then
    PROMPT_CHAR=$'\001\e[1;32m\002\U0000F1D0\001\e[0m\002'
  else
    PROMPT_CHAR=$'\001\e[1;31m\002\U000F08D9\001\e[0m\002'
  fi

  while [[ -n "$d" ]]; do
    if [[ -f "$d/.git/HEAD" ]]; then
      read -r head < "$d/.git/HEAD"
    elif [[ -f "$d/.git" ]]; then
      read -r line < "$d/.git"
      line="${line#gitdir: }"
      [[ -f "$line/HEAD" ]] && read -r head < "$line/HEAD"
    fi

    if [[ -n "$head" ]]; then
      root="${d##*/}"
      if [[ "$PWD" == "$d" ]]; then
        PROMPT_DIR="${root}"
      else
        PROMPT_DIR="${root}/${PWD#$d/}"
      fi
      if [[ "$head" == ref:\ * ]]; then
        PROMPT_BRANCH=" ${head#ref: refs/heads/}"
      else
        PROMPT_BRANCH=" ${head:0:7}"
      fi
      return
    fi
    d=${d%/*}
  done

  PROMPT_DIR="$PWD"
  PROMPT_BRANCH=""
}

PROMPT_COMMAND="_prompt_update${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
declare -a PROMPT_JOBS=([0]='' [1]=' ')
PS1=$'\n\[\e[36m\]${PROMPT_DIR}\[\e[0m\]\[\e[35m\]${PROMPT_BRANCH}\[\e[0m\]\[\e[1;34m\]${PROMPT_JOBS[\j]- \uef0c \j}\[\e[0m\]\n${PROMPT_CHAR} '
