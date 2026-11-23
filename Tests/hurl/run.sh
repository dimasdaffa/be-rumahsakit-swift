#!/bin/sh
set -eu

suite_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
target=${BASE_URL:-http://localhost:8081}
target=${target%/}
image=ghcr.io/orange-opensource/hurl:8.1.0
mode=${1:-all}

case "$mode" in
    smoke) set -- 00-service.hurl ;;
    all) set -- 00-service.hurl 10-patient-workflow.hurl 20-admin.hurl ;;
    *) printf 'Usage: %s [all|smoke]\n' "$0" >&2; exit 2 ;;
esac

if [ "$mode" = all ]; then
    command -v jq >/dev/null 2>&1 || { printf 'jq is required for the booking race.\n' >&2; exit 2; }
    # Hurl masks the admin password in its output.
    : "${HURL_ADMIN_PASSWORD:?Set HURL_ADMIN_PASSWORD to the password of your local test admin}"
    export HURL_VARIABLE_admin_email="${HURL_ADMIN_EMAIL:-admin@rumahsakit.com}"
    export HURL_SECRET_admin_password="$HURL_ADMIN_PASSWORD"

    # Unique fixture names and a clinic-local date keep repeated runs independent.
    visit=$(LC_ALL=C TZ=Asia/Jakarta date -v+1d '+%Y-%m-%d %A' 2>/dev/null ||
            LC_ALL=C TZ=Asia/Jakarta date -d tomorrow '+%Y-%m-%d %A')
    export HURL_VARIABLE_visit_date="${visit% *}" HURL_VARIABLE_visit_weekday="${visit##* }"
    export HURL_VARIABLE_today="$(TZ=Asia/Jakarta date '+%Y-%m-%d')"
    export HURL_VARIABLE_run_id="$(openssl rand -hex 6)"
    printf 'Target %s | fixture HURL-%s\n' "$target" "$HURL_VARIABLE_run_id"
else
    printf 'Target %s\n' "$target"
fi
export HURL_VARIABLE_base_url="$target"
cd "$suite_dir"

run_hurl() {
    if command -v hurl >/dev/null 2>&1; then
        hurl --no-color "$@"
    else
        # Hurl in Docker reaches the same published Nginx port through the host alias.
        case "$target" in
            http://localhost:*) HURL_VARIABLE_base_url="http://host.docker.internal:${target#http://localhost:}" ;;
            http://127.0.0.1:*) HURL_VARIABLE_base_url="http://host.docker.internal:${target#http://127.0.0.1:}" ;;
        esac
        docker run --rm --workdir /suite --mount "type=bind,src=$suite_dir,dst=/suite,readonly" \
            --add-host host.docker.internal:host-gateway \
            -e HURL_VARIABLE_base_url -e HURL_VARIABLE_admin_email -e HURL_SECRET_admin_password \
            -e HURL_VARIABLE_visit_date -e HURL_VARIABLE_visit_weekday -e HURL_VARIABLE_today -e HURL_VARIABLE_run_id \
            "$image" --no-color "$@"
    fi
}

run_hurl --test --jobs 1 "$@"

if [ "$mode" = all ]; then
    # Keep detailed results in memory since they contain JWTs.
    responses=$(run_hurl --json --parallel --jobs 2 --repeat 2 30-booking-race.hurl)
    printf '%s\n' "$responses" | jq -esr '
        map(.entries[-1].calls[-1].response) as $bookings
        | ($bookings | map(.status) | sort) as $statuses
        | ($bookings | map(.headers[] | select((.name | ascii_downcase) == "x-served-by") | .value)
            | unique | length) as $upstreams
        | if $statuses == [200, 409] and $upstreams > 0 then
              "Booking paralel lulus: HTTP 200 dan 409, melalui \($upstreams) upstream Nginx."
          else error("Booking paralel: diharapkan [200,409], mendapat \($statuses)")
          end
    '
fi
