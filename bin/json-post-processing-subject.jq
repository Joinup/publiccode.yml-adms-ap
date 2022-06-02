# Push the subject to all object, as I can't figure out how to do backwards lookups in RML.
.subject as $subject | walk(if type == "object" then . |= . + {"subject": $subject} else . end)
