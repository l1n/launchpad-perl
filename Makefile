default: init execute

init: .jirarc

.jirarc:
	@read -s -p "Enter your Jira password followed: " PASS; \
	echo ""; \
	echo $${USER}:$${PASS} | tr -d '\n' | openssl base64 > .jirarc
	chmod 600 .jirarc

queue: init
	perl jira-queue-toasts.pl standalone

execute: init
	perl launchpad.pl

clean:
	rm .jirarc
