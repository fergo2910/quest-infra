fullnameOverride: ${ fullname_override }

webhookTemplate: "{ \"blocks\": [ { \"type\": \"section\", \"text\": { \"type\": \"mrkdwn\", \"text\": \"*rearc Instance Interruption*\\n *InstanceId*: {{ .InstanceID }}\\n *InstanceType*: {{ .InstanceType }}\\n *LocalHostname*: {{ .LocalHostname }}\\n *LocalIP*: {{ .LocalIP }}\\n *Description*: {{ .Description }}\" } } ] }"
podTerminationGracePeriod: -1 # If negative, the default value specified in the pod will be used.	
