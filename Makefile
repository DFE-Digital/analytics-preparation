SHELL=/usr/bin/zsh

compile:
	cat scripts/{lookups,support,reports}/*.sql > full.sql
