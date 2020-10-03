#! /usr/bin/env bash

if [[ -f demo.csv ]]; then
	rm demo.csv
fi

rawjson=$(curl -H "Accept: application/json" \
	-H "Authorization: Token token=ELXlqz9M0JXT8o8PClh8Bg==" \
	https://tab.zeus.gent/users/thecy/transactions)

correctAmount=$(echo $rawjson | jq '.[0:100] | .[] | .amount = .amount/100')
correctAmount=$(echo $correctAmount | jq '[inputs]')

echo $correctAmount | jq -r \
	'(map(keys) | add | unique) as $cols | map(. as $row | $cols | map($row[.])) as $rows | $cols, $rows[] | @csv' \
	> demo.csv
