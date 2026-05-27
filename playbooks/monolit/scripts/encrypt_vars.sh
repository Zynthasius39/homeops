#!/bin/sh

TMP_FILE=.tmp-vars.yml
[[ -n "$2" ]] && TMP_FILE="$2"

cp "$1" "$TMP_FILE"

SECRET_LIST=$(yq '[.. | select(type== "!!str") | key | select(type == "!!str") | select(test("KEY|PASSWORD|TOKEN|EMAIL")) | path] | .[] | join(".")' "$1")

for SECRET in $SECRET_LIST; do
  SECRET_STR="$(ansible-vault encrypt_string $(yq .$SECRET $TMP_FILE) --vault-password-file .vault_pass_client.sh | sed -e '1d' -e 's/^[ ]*//')"
  yq -i ".$SECRET = \"$SECRET_STR\" | .$SECRET tag=\"!vault\" | .$SECRET style=\"tagged\"" "$TMP_FILE"
done

sed -i "$TMP_FILE" -e 's/!vault |-/!vault |/' -e '/^[ ]*$/d'
# sed -i "$TMP_FILE" -Ee 's/"(!vault.*)"/\1/' -e ':a; s/^([ ]*)(.*)\\n[ ]*/\1\2\n\1  /; ta'
