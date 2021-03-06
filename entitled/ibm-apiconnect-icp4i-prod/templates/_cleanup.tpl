{{- define "ibm-apiconnect-cip.delete-subsys-job" -}}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ template "ibm-apiconnect-cip.fullname" . }}-delete-$SUBSYS_RELEASE
  labels:
    app: {{ template "ibm-apiconnect-cip.name" . }}
    chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
    release: {{ .Release.Name }}
    heritage: {{ .Release.Service }}
    component: {{ template "ibm-apiconnect-cip.name" . }}-delete-$SUBSYS_RELEASE
spec:
  backoffLimit: 1
  template:
    metadata:
      labels:
        app: {{ template "ibm-apiconnect-cip.name" . }}
        chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
        release: {{ .Release.Name }}
        heritage: {{ .Release.Service }}
        component: {{ template "ibm-apiconnect-cip.name" . }}-delete-$SUBSYS_RELEASE
    spec:
      serviceAccountName: {{ template "ibm-apiconnect-cip.serviceAccountName" . }}
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: beta.kubernetes.io/arch
                operator: In
                values:
                  - {{ .Values.operator.arch }}
      hostNetwork: false
      hostPID: false
      hostIPC: false
      securityContext:
{{ include "ibm-apiconnect-cip.podSecurityContext" . | indent 8 }}
      restartPolicy: Never
      containers:
        - name: "subsys-delete"
{{- if .Values.operator.registry }}
          image: {{ regexReplaceAll "/$" .Values.operator.registry "" }}/{{ .Values.operator.image }}:{{ .Values.operator.tag }}
{{- else }}
          image: {{ regexReplaceAll "/$" .Values.global.registry "" }}/{{ .Values.operator.image }}:{{ .Values.operator.tag }}
{{- end }}
          imagePullPolicy: {{ .Values.operator.pullPolicy }}
          command: [ "/home/apic/init-files/init.sh" ]
          args: [ "/apicop/delete-subsys.sh", "$SUBSYS_RELEASE" ]
          workingDir: /home/apic/cleanup
          env:
            - name: HOME
              value: "/home/apic"
            - name: HELM_HOME
              value: "/home/apic/.helm"
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
          resources:
{{ include "ibm-apiconnect-cip.resources" . | indent 12 }}
          securityContext:
{{ include "ibm-apiconnect-cip.securityContext" . | indent 12 }}
          volumeMounts:
          - name: cr-files
            mountPath: /apicop/delete-subsys.sh
            subPath: delete-subsys.sh
          - name: helm-tls
{{- if .Values.operator.helmTlsSecret }}
            mountPath: "/home/apic/.helm"
{{- end }}
          - name: init-files
            mountPath: "/home/apic/init-files"
          - name: working-dir
            mountPath: /home/apic/cleanup
      volumes:
      - name: cr-files
        configMap:
          name: {{ template "ibm-apiconnect-cip.fullname" . }}-cr-files
          defaultMode: 0755
          items:
            - key: delete-subsys
              path: delete-subsys.sh
{{- if .Values.operator.helmTlsSecret }}
      - name: helm-tls
        secret:
          secretName: {{ .Values.operator.helmTlsSecret }}
          defaultMode: 0644
          items:
            - key: cert.pem
              path: cert.pem
            - key: ca.pem
              path: ca.pem
            - key: key.pem
              path: key.pem
{{- end }}
      - name: init-files
        projected:
          sources:
          - configMap:
              name: {{ template "ibm-apiconnect-cip.fullname" . }}-cr-files
              items:
                - key: init
                  path: init.sh
                  mode: 0750
                - key: helm-wrapper
                  path: helm-wrapper.sh
                  mode: 0750
      - name: working-dir
        emptyDir: {}
{{- end -}}