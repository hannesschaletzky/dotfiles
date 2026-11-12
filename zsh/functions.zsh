# Allgemeine Shell-Funktionen (wird von .zshrc geladen)

# Prozesse auf Port 5000 beenden
kill_processes_on_5000() {
  pids=$(lsof -t -i tcp:5000)
  
  if [ -z "$pids" ]; then
    echo "No processes found on TCP port 5000."
  else
    echo $pids | xargs kill -9
    echo "Killed processes on TCP port 5000."
  fi
}

# Docker Compose lokal frisch bauen und starten
dl() {
  # check if docker-compose.yml exists
  if [[ ! -f "docker-compose.yml" ]]; then
    echo "Error: docker-compose.yml file not found." >&2
    return 1
  fi

  docker container prune -f
  docker image prune -f
  docker system prune -f

  docker compose down
  docker compose build
  docker compose up
}

# Tests, Commit, Patch-Version, Push mit Tags
pp() {
  local msg="${1}"

  if ! npm run test:unit; then
    return 1
  fi

  git add .

  if [[ -n "$msg" ]]; then
    git commit -m "$msg"
    npm version patch -m "chore(release): %s - $msg"
  else
    git commit -m "version bump"
    npm version patch
  fi

  git push origin main
  git push origin --tags

  echo ""
  echo "👉 commit sha: $(git rev-parse HEAD)"
}

# Alle npm-Abhängigkeiten auf die neueste Version heben
upgradeAllDependecies() {
  npx npm-check-updates -u
  npm install
}
