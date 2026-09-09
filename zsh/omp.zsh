# Keep an OMP agent run alive while it is working.
# The wrapper stays in the user's shell, while the inhibitor runs the real omp binary.
ompw() {
  local omp_bin

  case "$(uname -s)" in
    Darwin)
      omp_bin="$(command -v omp)" || return
      command caffeinate -i "$omp_bin" "$@"
      ;;
    Linux)
      if command -v systemd-inhibit >/dev/null 2>&1; then
        omp_bin="$(command -v omp)" || return
        command systemd-inhibit \
          --what=sleep \
          --why="Oh My Pi agent is running" \
          --mode=block \
          "$omp_bin" "$@"
      else
        command omp "$@"
      fi
      ;;
    *)
      command omp "$@"
      ;;
  esac
}
