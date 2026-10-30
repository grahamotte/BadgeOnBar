#!/usr/bin/env bash
set -o errexit -o pipefail

exec mise run $(node -e '
  const fs = require("fs");
  const config = JSON.parse(fs.readFileSync("config.json"));
  const has = (key) => config.subdomains.some((subdomain) => subdomain[key]);
  const tasks = [];
  if (has("backend")) tasks.push("start:backend", "start:jobs");
  if (has("backend") || has("directory")) tasks.push("start:subdomains");
  if (has("website")) tasks.push("start:website");
  console.log(tasks.join(" ::: "));
')
