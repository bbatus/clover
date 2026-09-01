# Deployment Runbook — Clover

> Kopyala-yapıştır çalışan komutlar. Genel karar kaydı ve "neden böyle":
> `vodafonepaycomtr` reposundaki `docs/OCP-DEVOPS-RUNBOOK.md`.

## 0. Hızlı referans

| | Değer |
|---|---|
| Servis | `clover` |
| Namespace | `vepas-ai-am` |
| TEST cluster | `https://api.tst-vcloud.vpara.local:6443` |
| Registry | `containers.github.vpara.local` |
| Health | `https://<route-host>/api/health/{liveness,readiness}` |
| DB | PostgreSQL, harici (DBA talebiyle) — bkz. `docs/OCP-DEVOPS-RUNBOOK.md §3` |
| MinIO | Namespace-içi, geçici — `k8s/minio.yaml` |
| Dağıtım modeli | Sadece TEST, tek cluster, 1 replica |

## Faz 0 — İlk kurulum (namespace başına BİR KEZ, elle)

```bash
oc login https://api.tst-vcloud.vpara.local:6443 -u <user>
oc project vepas-ai-am
```

**1) Image pull secret — namespace'te ZATEN VAR, yeni bir şey oluşturma**
`vodafone-githubtest` (`containers.github.vpara.local` için) namespace'te
hazır — genaiops-event-processor'ın ServiceAccount'u da (01.09.2026 sahada
doğrulandı) aynısını kullanıyor. `k8s/serviceaccount.yaml` bunu zaten
referans veriyor, ayrıca bir şey oluşturmana gerek yok — sadece var olduğunu
doğrula:
```bash
oc get secret vodafone-githubtest
```

**2) Uygulama Secret'ı**
```bash
cp k8s/.env.secret.example k8s/.env.secret   # doldur (.gitignore'da)
./k8s/create-secret.sh
```

**3) ConfigMap**
```bash
oc apply -f k8s/configmap.yaml
```

**4) MinIO (namespace-içi, geçici — bkz. k8s/minio.yaml'ın kendi notu)**
```bash
oc apply -f k8s/minio.yaml
oc wait --for=condition=ready pod -l app=clover-minio -n vepas-ai-am --timeout=120s
oc logs job/clover-minio-init -n vepas-ai-am   # bucket oluştu mu doğrula
```

**5) Sabit kaynaklar**
```bash
oc apply -f k8s/serviceaccount.yaml
oc apply -f k8s/service.yaml
oc apply -f k8s/route.yaml
oc apply -f k8s/hpa.yaml
oc get route clover -o jsonpath='{.spec.host}'; echo
oc get route clover-minio -o jsonpath='{.spec.host}'; echo
```

**6) Deployment (ilk kurulumda elle, sonra pipeline yapar)**
```bash
IMAGE_REF=<imaj> envsubst < k8s/deployment.yaml | oc apply -f -
oc rollout status deployment/clover --timeout=300s
```

**7) Doğrulama**
```bash
oc get secret,configmap,sa,svc,route -l app=clover
curl -sf https://$(oc get route clover -o jsonpath='{.spec.host}')/api/health/liveness
curl -sf https://$(oc get route clover -o jsonpath='{.spec.host}')/api/health/readiness
```

## ConfigMap / Secret değişikliği

Aynı kurallar: `k8s/configmap.yaml`/`k8s/secret.yaml` pipeline tarafından
UYGULANMAZ, elle `oc apply` + `oc rollout restart deployment/clover` gerekir.

## Rollback

```bash
oc rollout undo deployment/clover
oc rollout status deployment/clover --timeout=300s
oc scale deployment/clover --replicas=0   # acil durdurma
```

⚠️ Payload push-tabanlı şema senkronu kullanıyor (bkz.
`docs/OCP-DEVOPS-RUNBOOK.md §6.3`) — geriye dönük şema garantisi yok,
`docs/PROJECT-OVERVIEW.md §10`'daki migration kararı netleşene kadar
rollback'i şema değişikliği içeren bir sürümden yaparken dikkatli olun.

## Sorun giderme

| Belirti | Sebep | Çözüm |
|---|---|---|
| `ImagePullBackOff` | Image pull secret yok/yanlış | Faz 0 adım 1 |
| Görsel yüklenmiyor/açılmıyor | MinIO Route yok/yanlış host | `k8s/minio.yaml`'ın Route'u + `S3_PUBLIC_URL` |
| Readiness 503 | Postgres'e erişilemiyor (FW/parola) | `oc logs deploy/clover`; DB bilgisini doğrula |
| `PAYLOAD_SECRET is unset or still the dev placeholder` | Secret eksik/placeholder | `k8s/create-secret.sh` çalıştırıldı mı, gerçek değerler girildi mi |
