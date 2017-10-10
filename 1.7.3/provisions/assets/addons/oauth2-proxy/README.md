# oauth2-proxy

## Usage
* Create the secret:
```bash
kubectl create secret generic oauth2-proxy \
    --from-literal="oauth2.proxy.client.secret=${OAUTH2_CLIENT_SECRET}" \
    --from-literal="oauth2.proxy.cookie.secret=$(python -c 'import os,base64; print base64.b64encode(os.urandom(16))')" \
    -n kube-system
```
* Deploy the deployment and service:
```bash
kubectl create -f oauth2-proxy
```


## To add to an ingress
Add these annotations
```yaml
annotations:
  ingress.kubernetes.io/auth-signin: https://oauth.valuphone.com/oauth2/sign_in
  ingress.kubernetes.io/auth-url: https://oauth.valuphone.com/oauth2/auth
```


## References
* [external-auth](https://github.com/kubernetes/ingress/tree/858e3ff2354fb0f5066a88774b904b2427fb9433/examples/external-auth/nginx)
