workers ENV.fetch("WEB_CONCURRENCY") { 2 }          # Only relevant for production
threads_count = ENV.fetch("MAX_THREADS") { 5 }
threads threads_count, threads_count

preload_app!

port ENV.fetch("PORT") { 9292 }
environment ENV.fetch("RACK_ENV") { "development" }

# Puma PID file (matches entrypoint.sh)
pidfile "tmp/pids/puma.pid"

# Optional stdout/stderr logs
stdout_redirect "log/puma.stdout.log", "log/puma.stderr.log", true
