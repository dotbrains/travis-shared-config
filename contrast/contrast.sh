#!/usr/bin/env bash

npm install -g @contrast/agent@4.23.1

npx contrast-transpile server.js \
	--assess.enable true \
	--agent.node.rewrite_cache.enable true \
	--agent.node.rewrite_cache.path ./rewrite_cache
