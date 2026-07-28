#!/bin/bash
jq -Rsn '
  {"singles":
    [inputs
     | . / "\n"
     | (.[] | select(length > 0) | . / ",") as $input
     | {"name": $input[0], "addr": $input[1]}]}
' <$1 > disbursement.json