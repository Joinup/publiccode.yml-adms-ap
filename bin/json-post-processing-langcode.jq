# Push down the language element, which makes the RML transformation much easier.
.description |= ( to_entries | map( .value + {"langcode": .key} ) )
