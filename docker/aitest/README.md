# ai test

```bash
docker run --name aitest -p 8033:80 -p 8022:22 -d --gpus all aitest
docker exec -ti aitest bash
/usr/sbin/sshd
```